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

@onready var items: Node2D = get_node_or_null("Items")
@onready var drone: CharacterBody2D = get_node_or_null("Drone")
@onready var timer: Timer = get_node_or_null("SpawnTimer")
@onready var garbage_label: Label = get_node_or_null("UI/GarbageLabel")
@onready var fish_label: Label = get_node_or_null("UI/FishLabel")
@onready var depth_label: Label = get_node_or_null("UI/DepthLabel")
@onready var return_btn: Button = get_node_or_null("UI/ReturnToMapButton")

@onready var game_over_canvas: CanvasLayer = get_node_or_null("GameOverCanvas")
@onready var go_title: Label = get_node_or_null("GameOverCanvas/GameOverPanel/VBox/Title")
@onready var go_body: Label = get_node_or_null("GameOverCanvas/GameOverPanel/VBox/Body")
@onready var go_return_btn: Button = get_node_or_null("GameOverCanvas/GameOverPanel/VBox/ReturnButton")

var _edge_markers: Dictionary = {}
var _fish_limit := 3

const _POPUP_LABEL_SCENE := preload("res://scenes/ui/popup_label.tscn")

func _ready() -> void:
	if is_instance_valid(timer):
		timer.wait_time = SPAWN_INTERVAL
		if not timer.timeout.is_connected(_spawn_item):
			timer.timeout.connect(_spawn_item)
		timer.start()
	var collect_shape: CollisionShape2D = get_node_or_null("Drone/Area2D/CollisionShape2D")
	if is_instance_valid(collect_shape) and collect_shape.shape is CircleShape2D:
		(collect_shape.shape as CircleShape2D).radius = 66.27 + GameState.get_collection_radius_bonus()
	AudioManager.play_bgm("reef")
	if ResourceLoader.exists("res://scenes/minigame_intro.tscn"):
		var intro := load("res://scenes/minigame_intro.tscn").instantiate() as CanvasLayer
		add_child(intro)
		if intro.has_method("setup"):
			intro.setup("Reef Rescue", ["Move the drone and touch garbage/fish to collect them.", "Press Esc or Return to Map when ready."])
	_update_ui()
	if is_instance_valid(return_btn):
		return_btn.pressed.connect(_leave_to_map)
	if is_instance_valid(go_return_btn):
		go_return_btn.pressed.connect(_leave_after_summary)

func _process(delta: float) -> void:
	if not running:
		return
	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_garbage_combo = 0
	var vp := get_viewport_rect().size
	var bg_speed := 0.0
	if is_instance_valid(drone):
		bg_speed = (MAX_BG_SPEED * (drone.position.y / max(1.0, vp.y)) + MIN_BG_SPEED) * delta
	else:
		bg_speed = MAX_BG_SPEED * delta
	if is_instance_valid(items):
		for c in items.get_children():
			if c is Fish:
				c.process(bg_speed, delta)
	var parallax := get_node_or_null("ParallaxBackground")
	if is_instance_valid(parallax):
		parallax.scroll_offset.y -= bg_speed
	depth += bg_speed / 10.0
	if is_instance_valid(drone):
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
	var item: Fish = preload("res://scenes/rr_fish.tscn").instantiate()
	if is_instance_valid(items):
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
	if is_instance_valid(items):
		for c in items.get_children():
			if is_instance_valid(c):
				targets.append(c)
	for child in targets:
		if not is_instance_valid(child):
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
			marker = load("res://scenes/ui/label.tscn").instantiate() as Label
			marker.text = "!"
			marker.modulate = Color(1.0, 0.95, 0.35, 0.95)
			marker.add_theme_font_size_override("font_size", 22)
			add_child(marker)
			_edge_markers[id] = marker
		else:
			marker = _edge_markers[id]
		if not is_instance_valid(marker):
			continue
		var x := clampf(pos.x, 12.0, vp.x - 12.0)
		var y := clampf(pos.y, 12.0, vp.y - 12.0)
		marker.position = Vector2(x - 6.0, y - 12.0)
		if pos.x < 0:
			marker.text = "<"
		elif pos.x > vp.x:
			marker.text = ">"
		elif pos.y < 0:
			marker.text = "^"
		else:
			marker.text = "v"

func _clear_marker(id: int) -> void:
	if _edge_markers.has(id):
		var m: Label = _edge_markers[id]
		if is_instance_valid(m):
			m.queue_free()
		_edge_markers.erase(id)

func _clear_edge_markers() -> void:
	for id in _edge_markers.keys():
		_clear_marker(id)

func _update_ui() -> void:
	if is_instance_valid(garbage_label):
		garbage_label.text = "Collected %d kg of garbage" % garbage
	if is_instance_valid(fish_label):
		fish_label.text = "Fish bumps: %d / %d" % [fish, _fish_limit]
	if is_instance_valid(depth_label):
		depth_label.text = "%d m" % depth

func _popup(msg: String, col: Color) -> void:
	var lbl: Label = _POPUP_LABEL_SCENE.instantiate()
	if msg != "":
		lbl.text = msg
	lbl.modulate = col
	if is_instance_valid(items):
		items.add_child(lbl)
	else:
		add_child(lbl)
	lbl.position = (drone.global_position if is_instance_valid(drone) else Vector2.ZERO) + Vector2(-20, -40)
	var tw := lbl.create_tween()
	tw.tween_property(lbl, "position", lbl.position + Vector2(0, -42), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.7)
	tw.tween_callback(lbl.queue_free)

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
	var root := body.get_parent() if is_instance_valid(body) else null
	if not is_instance_valid(root) or not root.is_in_group("items"):
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
		AudioManager.play_sfx("sort_bad")
		_popup("-1 life", Color(1.0, 0.4, 0.4, 1.0))
		_sparkle(root.global_position, Color(1.0, 0.4, 0.4, 1.0))
		var ap := root.get_node_or_null("AnimationPlayer")
		if ap:
			ap.play("run")
		if fish >= _fish_limit:
			_game_over_summary()
		return
	else:
		var weight := 1
		_garbage_combo += 1
		_combo_timer = 2.0
		var multiplier := 1 + int(_garbage_combo / 3)
		# Each collected trash is exactly 1 kg; combo only earns a small score pop.
		garbage += 1.0
		GameState.upcycle_score += multiplier
		AudioManager.play_sfx("pickup")
		var t := "+%d kg" % weight if multiplier <= 1 else "+%d kg x%d" % [weight, multiplier]
		_popup(t, Color(0.95, 0.95, 0.35, 1.0))
		_sparkle(root.global_position, Color(0.95, 0.95, 0.35, 1.0))
		var ap2 := root.get_node_or_null("AnimationPlayer")
		if ap2:
			ap2.play("suck")
		if GameState.get_free_capacity() <= 0:
			_game_over_summary()
			return

func _game_over_summary() -> void:
	if _leaving:
		return
	_leaving = true
	running = false
	_clear_edge_markers()
	GameState.record_reef(garbage, fish)
	var debris_total := int(max(1.0, round(garbage)))
	if GameState.deep_cache:
		var bonus := 5 * GameState.deep_cache_tier + 3 * GameState.inventory_capacity_level
		debris_total += bonus
	var accepted := GameState.add_trash_type_weighted("Reef Debris", debris_total)
	if accepted == 0 and is_instance_valid(drone):
		_popup("Inventory full - sell trash", Color(1.0, 0.4, 0.4, 1.0))
	if is_instance_valid(go_body):
		go_body.text = "Bumped into %d fish\nGarbage collected: %d kg\nDepth: %d m\n\nReef debris earned: %d" % [fish, int(garbage), int(depth), accepted]
	if is_instance_valid(game_over_canvas):
		game_over_canvas.layer = 110
		get_tree().paused = false
		game_over_canvas.visible = true
	_start_game_over_juice()
	AudioManager.play_sfx("sort_bad")

func _leave_after_summary() -> void:
	get_tree().paused = false
	if is_instance_valid(game_over_canvas):
		game_over_canvas.visible = false
	AudioManager.play_sfx("return")
	SceneTransition.change_scene("res://scenes/world.tscn")

func _leave_to_map() -> void:
	if _leaving:
		return
	_leaving = true
	running = false
	_clear_edge_markers()
	GameState.record_reef(garbage, fish)
	var debris_total := int(max(1.0, round(garbage)))
	if GameState.deep_cache:
		var bonus := 5 * GameState.deep_cache_tier + 3 * GameState.inventory_capacity_level
		debris_total += bonus
		_popup("+%d Deep Cache debris" % bonus, Color(0.45, 0.85, 1.0, 1.0))
	var accepted := GameState.add_trash_type_weighted("Reef Debris", debris_total)
	if accepted < debris_total and is_instance_valid(drone):
		_popup("%d over capacity" % (debris_total - accepted), Color(0.95, 0.5, 0.35, 1.0))
	AudioManager.play_sfx("return")
	SceneTransition.change_scene("res://scenes/world.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and running:
		_leave_to_map()

func _start_game_over_juice() -> void:
	var cam := load("res://scenes/ui/camera2_d.tscn").instantiate() as Camera2D
	cam.name = "GameOverCamera"
	cam.position = get_viewport_rect().size * 0.5
	cam.make_current()
	add_child(cam)
	var shake := create_tween()
	var base_offset := cam.offset
	for i in range(14):
		shake.tween_property(cam, "offset", base_offset + Vector2(randf_range(-14.0, 14.0), randf_range(-14.0, 14.0)), 0.04)
	shake.tween_property(cam, "offset", base_offset, 0.1)
	shake.tween_callback(func(): if is_instance_valid(cam): cam.queue_free())
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
