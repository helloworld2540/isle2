extends Node2D

@export var MIN_BG_SPEED := 75.0
@export var MAX_BG_SPEED := 120.0
@export var SPAWN_INTERVAL := 0.8

var depth := 0.0
var running := true
var drag_velocity := Vector2.ZERO
var dragging := false
var fish := 0
var garbage := 0.0
var _leaving := false
var _garbage_combo := 0
var _combo_timer := 0.0

@onready var items: Node2D = $"Items"
@onready var drone: CharacterBody2D = $"Drone"
@onready var timer: Timer = $"SpawnTimer"
@onready var garbage_label: Label = $"UI/GarbageLabel"
@onready var fish_label: Label = $"UI/FishLabel"
@onready var depth_label: Label = $"UI/DepthLabel"
@onready var combo_label: Label = $"UI/ComboLabel"
@onready var low_health_vignette: TextureRect = $"UI/LowHealthVignette"
@onready var return_btn: Button = $"UI/ReturnToMapButton"

@onready var game_over_canvas: CanvasLayer = $"GameOverCanvas"
@onready var go_title: Label = $"GameOverCanvas/GameOverPanel/VBox/Title"
@onready var go_body: Label = $"GameOverCanvas/GameOverPanel/VBox/Body"
@onready var go_return_btn: Button = $"GameOverCanvas/GameOverPanel/VBox/ReturnButton"

var _edge_markers: Dictionary = {}
var _fish_limit := 3
## Depth milestones that fire a one-time toast per dive (meters).
const DEPTH_MILESTONES: Array[int] = [100, 250, 400, 700, 900]
var _milestones_hit: Dictionary = {}

@onready var shake_camera: Camera2D = $"ShakeCamera"

const _FLOATING_TEXT_SCENE := preload("res://scenes/ui/floating_text.tscn")
const _EDGE_MARKER_SCENE := preload("res://scenes/ui/edge_marker.tscn")

func _ready() -> void:
	TutorialDirector.scene_started("reef")
	# Reef Charter bought at the shop tolerates extra fish bumps.
	_fish_limit = 3 + GameState.get_reef_bonus_lives()
	if timer:
		timer.wait_time = SPAWN_INTERVAL
		if not timer.timeout.is_connected(_spawn_item):
			timer.timeout.connect(_spawn_item)
		timer.start()
	var collect_shape: CollisionShape2D = $"Drone/Area2D/CollisionShape2D"
	if collect_shape and collect_shape.shape is CircleShape2D:
		(collect_shape.shape as CircleShape2D).radius = 66.27 + GameState.get_collection_radius_bonus()
	AudioManager.play_bgm("reef")
	_update_ui()
	_update_low_health()
	if return_btn:
		return_btn.pressed.connect(_leave_to_map)
	if go_return_btn:
		go_return_btn.pressed.connect(_leave_after_summary)

func _process(delta: float) -> void:
	if not running:
		return
	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_garbage_combo = 0
			if combo_label:
				combo_label.visible = false
	var vp := get_viewport_rect().size
	if low_health_vignette and low_health_vignette.visible and not GameSettings.reduce_motion:
		# Soft breathing vignette: edges pulse, center stays clear.
		low_health_vignette.modulate.a = 0.38 + 0.34 * (0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006))
	var bg_speed := 0.0
	if drone:
		bg_speed = (MAX_BG_SPEED * (drone.position.y / max(1.0, vp.y)) + MIN_BG_SPEED) * delta
	else:
		bg_speed = MAX_BG_SPEED * delta
	if items:
		for c in items.get_children():
			if c is Fish:
				c.process(bg_speed, delta)
	var parallax := $"ParallaxBackground"
	if parallax:
		parallax.scroll_offset.y -= bg_speed
	depth += bg_speed / 10.0
	_check_depth_milestones()
	if timer:
		timer.wait_time = clampf(0.8 - depth / 3000.0, 0.32, 0.8)
	if drone:
		drone.position += drag_velocity * GameState.get_move_speed_multiplier()
		if not (60 < drone.position.x and drone.position.x < vp.x - 60):
			drone.position.x = clampf(drone.position.x, 60, vp.x - 60)
			drag_velocity.x *= -0.3
		if not (60 < drone.position.y and drone.position.y < vp.y - 60):
			drone.position.y = clampf(drone.position.y, 60, vp.y - 60)
			drag_velocity.y *= -0.3
	drag_velocity.x = move_toward(drag_velocity.x, 0, delta * absf(drag_velocity.x) * 0.8)
	drag_velocity.y = move_toward(drag_velocity.y, 0, delta * absf(drag_velocity.y) * 0.8)
	_update_edge_markers()
	_update_ui()

func _input(event: InputEvent) -> void:
	if not running:
		return
	if event is InputEventMouseButton:
		dragging = event.pressed
	elif event is InputEventMouseMotion and dragging:
		drag_velocity = (drag_velocity + event.relative) * 0.5
	elif event is InputEventScreenTouch:
		dragging = event.pressed
	elif event is InputEventScreenDrag:
		drag_velocity += (drag_velocity + event.relative) * 0.5

func _spawn_item() -> void:
	if items and items.get_child_count() >= 18:
		return
	var item: Fish = preload("res://scenes/rr_fish.tscn").instantiate()
	if items:
		items.add_child(item)
	item.add_to_group("items")
	item.modulate.a = 0.0
	item.scale = Vector2(0.6, 0.6)
	var tw := item.create_tween()
	tw.tween_property(item, "modulate:a", 1.0, 0.35)
	tw.parallel().tween_property(item, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if randfn(depth / 1000.0, 0.5) > 0.5:
		item.init_fish()
	else:
		item.init_garbage()

func _update_edge_markers() -> void:
	var vp := get_viewport_rect().size
	var targets: Array = []
	if items:
		for c in items.get_children():
			if c:
				targets.append(c)
	for child in targets:
		if not child:
			continue
		var next := child as Node2D
		if next == null or not next.is_inside_tree():
			continue
		var pos: Vector2 = next.global_position
		if pos.x >= 0 and pos.x <= vp.x and pos.y >= 0 and pos.y <= vp.y:
			if _edge_markers.has(next.get_instance_id()):
				_clear_marker(next.get_instance_id())
			continue
		var marker: Label
		var id := next.get_instance_id()
		if not _edge_markers.has(id):
			marker = _EDGE_MARKER_SCENE.instantiate()
			marker.set_direction(pos - vp * 0.5)
			add_child(marker)
			marker.set_kind(bool(next.get_meta("is_fish", false)))
			_edge_markers[id] = marker
		else:
			marker = _edge_markers[id]
		if not marker:
			continue
		marker.position = Vector2(
			clampf(pos.x, 12.0, vp.x - 12.0) - 6.0,
			clampf(pos.y, 12.0, vp.y - 12.0) - 12.0
		)
		marker.set_direction(pos - vp * 0.5)
		# Fish markers shimmer harder as they close on the drone, and the
		# effect deepens with depth — near-misses feel readable, not random.
		if bool(next.get_meta("is_fish", false)) and drone:
			var dist := pos.distance_to(drone.global_position)
			var proximity := clampf(1.0 - dist / 900.0, 0.0, 1.0)
			var depth_factor := clampf(depth / 800.0, 0.0, 1.0)
			var shimmer := clampf(proximity * 0.7 + depth_factor * 0.45, 0.0, 1.0)
			var wave := 0.5 + 0.5 * sin(Time.get_ticks_msec() * (0.006 + shimmer * 0.012))
			marker.pulse(shimmer * wave)
		else:
			marker.pulse(0.0)

func _clear_marker(id: int) -> void:
	if _edge_markers.has(id):
		var m: Label = _edge_markers[id]
		if m:
			m.queue_free()
		_edge_markers.erase(id)

func _clear_edge_markers() -> void:
	for id in _edge_markers.keys():
		_clear_marker(id)

func _update_ui() -> void:
	if garbage_label:
		garbage_label.text = "Collected %d kg of garbage" % garbage
	if fish_label:
		fish_label.text = "Fish bumps: %d / %d" % [fish, _fish_limit]
	if depth_label:
		depth_label.text = "%d m" % depth

## Fires a one-time toast per milestone per dive. Milestones line up with the
## achievement ladder (400 m = DEEP DIVE, 900 m = TO THE ABYSS) so crossing one
## feels like making progress rather than just reading a number go up.
func _check_depth_milestones() -> void:
	for milestone in DEPTH_MILESTONES:
		if depth >= float(milestone) and not _milestones_hit.has(milestone):
			_milestones_hit[milestone] = true
			var text := "%d m" % milestone
			var col := Color(0.66, 0.9, 1.0, 1.0)
			if milestone == 400:
				text = "400 m — DEEP DIVE"
				col = Color(0.8, 0.87, 1.0, 1.0)
			elif milestone == 900:
				text = "900 m — TO THE ABYSS"
				col = Color(1.0, 0.82, 0.4, 1.0)
			elif milestone >= 700:
				col = Color(0.75, 0.85, 1.0, 1.0)
			_toast_milestone(text, col)


## Big, centered, back-eased banner — readable at a glance mid-dive without
## covering the action at the edges (where the HUD labels live).
func _toast_milestone(text: String, col: Color) -> void:
	var lbl := _FLOATING_TEXT_SCENE.instantiate()
	lbl.z_index = 60
	lbl.rise_distance = 0.0
	lbl.hold_time = 1.6
	lbl.fade_out_time = 0.5
	lbl.punch_scale = 1.65
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size = Vector2(440.0, 0.0)
	lbl.size = Vector2(440.0, 40.0)
	var vp := get_viewport_rect().size
	lbl.position = Vector2(vp.x * 0.5 - 220.0, vp.y * 0.2)
	add_child(lbl)
	lbl.present(text, col, 30)
	AudioManager.play_sfx("quest_complete", 1.25)


## Combo label under the depth HUD. Visible from ×2 up; every time the
## multiplier steps (every 3 garbage inside the 2s window) it punches big and
## flares hot gold before settling, so an x3+ streak reads across the screen.
func _update_combo_label(multiplier: int) -> void:
	if not combo_label:
		return
	if multiplier <= 1:
		combo_label.visible = false
		return
	combo_label.visible = true
	combo_label.text = "COMBO ×%d" % multiplier
	var stepped := _garbage_combo % 3 == 0
	combo_label.pivot_offset = combo_label.size * 0.5
	combo_label.scale = Vector2(1.55, 1.55) if stepped else Vector2(1.2, 1.2)
	combo_label.modulate = Color(1.0, 0.92, 0.45, 1.0) if stepped else Color(1.0, 0.84, 0.35, 1.0)
	var tw := combo_label.create_tween()
	tw.tween_property(combo_label, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(combo_label, "modulate", Color(1.0, 0.84, 0.35, 1.0), 0.3)

## One bump left: the screen edges breathe red. Reduced motion holds a
## static dim vignette instead of a pulse — same warning, no flashing.
func _update_low_health() -> void:
	if not low_health_vignette:
		return
	var bumps_left := _fish_limit - fish
	low_health_vignette.visible = bumps_left == 1
	if not low_health_vignette.visible:
		low_health_vignette.modulate.a = 0.0
		return
	if GameSettings.reduce_motion:
		low_health_vignette.modulate.a = 0.55
	else:
		low_health_vignette.modulate.a = 0.45

func _popup(msg: String, col: Color) -> void:
	var lbl := _FLOATING_TEXT_SCENE.instantiate()
	lbl.position = (drone.global_position if drone else Vector2.ZERO) + Vector2(-20, -40)
	lbl.rise_distance = 42.0
	lbl.hold_time = 0.4
	if items:
		items.add_child(lbl)
	else:
		add_child(lbl)
	lbl.present(msg, col, 18)

func _sparkle(at: Vector2, col: Color) -> void:
	var p := load("res://scenes/ui/c_p_u_particles2_d.tscn").instantiate() as CPUParticles2D
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 16
	p.lifetime = 0.45
	p.global_position = at
	p.spread = 180.0
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 120.0
	p.gravity = Vector2(0.0, 120.0)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = col
	add_child(p)
	p.emitting = true
	var tw := create_tween()
	tw.tween_interval(p.lifetime + 0.1)
	tw.tween_callback(p.queue_free)

func _on_area_2d_body_entered(body: Node2D) -> void:
	var root := body.get_parent() if body else null
	if not root or not root.is_in_group("items"):
		return
	var pos := (root as Node2D).global_position
	var vp := get_viewport_rect().size
	if pos.x < 0 or pos.y < 0 or pos.x > vp.x or pos.y > vp.y:
		return
	if bool(root.get_meta("collected", false)):
		return
	root.set_meta("collected", true)
	_clear_marker(root.get_instance_id())
	var is_fish: bool = bool(root.get_meta("is_fish", false))
	if is_fish:
		fish += 1
		_update_ui()
		_update_low_health()
		AudioManager.play_sfx("sort_bad")
		_popup("-1 life", Color(1.0, 0.4, 0.4, 1.0))
		_sparkle(root.global_position, Color(1.0, 0.4, 0.4, 1.0))
		var ap := root.get_node("AnimationPlayer")
		if ap:
			ap.play("run")
		if fish >= _fish_limit:
			_game_over_summary("fish")
		return
	else:
		var weight := 1
		_garbage_combo += 1
		_combo_timer = 2.0
		var multiplier := 1 + int(_garbage_combo / 3)
		_update_combo_label(multiplier)
		garbage += 1.0
		GameState.upcycle_score += multiplier
		AudioManager.play_sfx("pickup", 1.0 + min(float(multiplier), 3.0) * 0.05)
		var t := "+%d kg" % weight if multiplier <= 1 else "+%d kg x%d" % [weight, multiplier]
		_popup(t, Color(0.95, 0.95, 0.35, 1.0))
		_sparkle(root.global_position, Color(0.95, 0.95, 0.35, 1.0))
		var ap2 := root.get_node("AnimationPlayer")
		if ap2:
			ap2.play("suck")
		if GameState.get_free_capacity() <= 0:
			_game_over_summary("inventory")
			return

func _game_over_summary(reason: String = "manual") -> void:
	if _leaving:
		return
	_leaving = true
	running = false
	_clear_edge_markers()
	var prev_best := GameState.best_reef_depth
	GameState.record_reef(garbage, fish, depth)
	var new_best := int(depth) > prev_best
	var debris_total := int(max(1.0, round(garbage)))
	if GameState.deep_cache:
		var bonus := 5 * GameState.deep_cache_tier + 3 * GameState.inventory_capacity_level
		debris_total += bonus
	var accepted := GameState.add_trash_type_weighted("Reef Debris", debris_total)
	
	var cause_msg := ""
	if reason == "fish" or fish >= _fish_limit:
		cause_msg = "Drone disabled! You bumped into sea life 3 times."
		if go_title:
			go_title.text = "Drone Damaged!"
	elif reason == "inventory" or GameState.get_free_capacity() <= 0:
		cause_msg = "Cargo full! You ran out of inventory space for more trash."
		if go_title:
			go_title.text = "Inventory Full!"
	else:
		cause_msg = "Dive ended early by operator return."
		if go_title:
			go_title.text = "Dive Summary"

	if accepted == 0 and drone:
		_popup("Inventory full - sell trash", Color(1.0, 0.4, 0.4, 1.0))
	
	_record_run_card(accepted)
	
	if go_body:
		var best_depth := GameState.best_reef_depth
		var milestone_line := "Depth milestones complete: TO THE ABYSS earned."
		if new_best:
			# The payoff line leads the card — a dive worth remembering.
			milestone_line = "★ NEW BEST DEPTH — %d m! ★" % int(depth)
		elif best_depth < 400:
			milestone_line = "Next depth milestone: DEEP DIVE at 400 m (best %d m)." % best_depth
		elif best_depth < 900:
			milestone_line = "DEEP DIVE earned · %d m to TO THE ABYSS (900 m)." % (900 - best_depth)
		go_body.text = "%s\n\nFish bumps: %d / %d\nGarbage collected: %d kg\nDepth reached: %d m\n%s\n\nReef debris earned: %d" % [
			cause_msg, fish, _fish_limit, int(garbage), int(depth), milestone_line, accepted
		]
		
	if game_over_canvas:
		game_over_canvas.layer = 110
		get_tree().paused = false
		game_over_canvas.visible = true
	_start_game_over_juice()
	if new_best:
		# A personal-best dive celebrates instead of stinging.
		AudioManager.play_sfx("achievement", 1.15)
	else:
		AudioManager.play_sfx("empty_inventory" if reason == "inventory" else "sort_bad")

func _leave_after_summary() -> void:
	get_tree().paused = false
	if game_over_canvas:
		game_over_canvas.visible = false
	AudioManager.play_sfx("return")
	SceneTransition.change_scene("res://scenes/world.tscn")


## Hand-off card for the world map: what this dive produced and where to go next.
func _record_run_card(accepted: int) -> void:
	var debris := int(GameState.trash_by_type.get("Reef Debris", 0))
	var lines: Array[String] = [
		"Collected %d kg · reached %d m" % [int(garbage), int(depth)],
		"Reef Debris +%d  (%d/%d kg carried)" % [
			accepted, GameState.get_inventory_weight(), GameState.get_inventory_capacity()
		],
	]
	if fish > 0:
		lines.append("Fish bumps %d/%d · best depth %d m" % [
			fish, _fish_limit, maxi(int(depth), GameState.best_reef_depth)
		])
	
	if GameState.best_reef_depth >= 400 and GameState.best_reef_depth < 900:
		lines.append("%d m to TO THE ABYSS (best %d m)" % [900 - GameState.best_reef_depth, GameState.best_reef_depth])

	var hint := ""
	if GameState.get_free_capacity() <= 0:
		hint = "Bag full - sell materials at the Shop."
	elif debris <= 0:
		hint = "Dive again to gather Reef Debris."
	else:
		hint = "Sort %d Reef Debris at the Upcycle bench." % debris
	
	GameState.record_run("reef", "Reef Rescue complete", lines, hint)

func _leave_to_map() -> void:
	_game_over_summary("manual")
	return

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and running:
		_leave_to_map()

func _start_game_over_juice() -> void:
	# Motion-sensitive players still get the summary panel, just no shake.
	if GameSettings.reduce_motion:
		return
	
	if shake_camera:
		shake_camera.position = get_viewport_rect().size * 0.5
		shake_camera.enabled = true
		shake_camera.make_current()
		var shake := create_tween()
		var base_offset := shake_camera.offset
		for i in range(14):
			shake.tween_property(shake_camera, "offset", base_offset + Vector2(randf_range(-14.0, 14.0), randf_range(-14.0, 14.0)), 0.04)
		shake.tween_property(shake_camera, "offset", base_offset, 0.1)
	var confetti := load("res://scenes/ui/c_p_u_particles2_d.tscn").instantiate() as CPUParticles2D
	confetti.one_shot = true
	confetti.explosiveness = 1.0
	confetti.amount = 96
	confetti.lifetime = 1.4
	confetti.global_position = get_viewport_rect().size * 0.5
	confetti.spread = 360.0
	confetti.initial_velocity_min = 120.0
	confetti.initial_velocity_max = 280.0
	confetti.gravity = Vector2(0.0, 260.0)
	confetti.scale_amount_min = 3.0
	confetti.scale_amount_max = 6.0
	confetti.color = Color(1.0, 0.85, 0.3, 1.0)
	add_child(confetti)
	confetti.emitting = true
	var tw := create_tween()
	tw.tween_interval(confetti.lifetime + 0.2)
	tw.tween_callback(confetti.queue_free)
