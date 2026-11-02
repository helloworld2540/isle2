extends Node2D
class_name Upcycle

const MATERIALS := [
	"Polyethylene",
	"Glass",
	"Polypropylene",
	"Nylon"
]

var trash := [
	"trash_bottle.png",
	"trash_plasticblue.png",
	"trash_plasticwhite.png",
	"trash_net.png",
	"trash_straw.png"
]

const GRID := 160
const MIN_SWIPE_DISTANCE := 30.0

const MIN_GRID_X := 1
const MAX_GRID_X := 5
const MIN_GRID_Y := 0
const MAX_GRID_Y := 2

var score := 0
var sort_streak := 0
var _sorted_count := 0
var carried_item: Node2D = null
var spawn_timer := 0.0
var SPAWN_INTERVAL := 5.0
var belt_speed := 80.0
var _next_spawn_interval := 5.0

var _belt_banner_shown := false
var _leaving := false
var _hud_queue = null
var _recycled_total := 0
var _recycled_by_mat := {"Polyethylene":0,"Glass":0,"Polypropylene":0,"Nylon":0}
var drag_start_pos := Vector2.ZERO
var is_dragging := false
var move_tween: Tween = null
var _arrow_radius := 3 * GRID
var _arrow: Polygon2D = null

@onready var score_label: Label = get_node_or_null("UI/ScoreLabel")
@onready var streak_label: Label = get_node_or_null("UI/StreakLabel")
@onready var recycled_label: Label = get_node_or_null("UI/RecycledLabel")
@onready var belt_label: Label = get_node_or_null("UI/BeltLabel")
@onready var return_btn: Button = get_node_or_null("UI/ReturnToMapButton")
@onready var player: CharacterBody2D = get_node_or_null("Player")
@onready var conveyor: Path2D = get_node_or_null("Conveyor")
@onready var fire: Area2D = get_node_or_null("Fire")
@onready var bins: Node2D = get_node_or_null("Bins")
@onready var highlight_node: Node2D = get_node_or_null("highlight_node")

func _ready() -> void:
	var max_bins = min(bins.get_child_count(), MATERIALS.size()) if is_instance_valid(bins) else 0
	for i in range(max_bins):
		var bin := bins.get_child(i)
		if is_instance_valid(bin):
			bin.set_meta("material", MATERIALS[i])
			var lbl := load("res://scenes/ui/label.tscn").instantiate() as Label
			lbl.text = str(bin.name)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.anchor_left = 0.5
			lbl.anchor_right = 0.5
			lbl.anchor_top = 0.5
			lbl.anchor_bottom = 0.5
			lbl.offset_left = -70
			lbl.offset_right = 70
			lbl.offset_top = -22
			lbl.offset_bottom = 22
			lbl.custom_minimum_size = Vector2(140, 44)
			lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
			lbl.add_theme_font_size_override("font_size", 18)
			lbl.z_index = 30
			lbl.modulate = bin.modulate
			lbl.top_level = true
			bin.add_child(lbl)
			lbl.global_position = bin.global_position
			
	if is_instance_valid(player):
		player.global_position = _snap(player.global_position)

	_arrow = Polygon2D.new()
	_arrow.color = Color(1.0, 0.85, 0.3, 0.9)
	_arrow.polygon = PackedVector2Array([Vector2(0, -12), Vector2(6, 6), Vector2(-6, 6)])
	_arrow.z_index = 20
	_arrow.visible = false
	add_child(_arrow)
		
	var ui := get_node_or_null("UI")
	_update_ui()
	
	if ResourceLoader.exists("res://scenes/minigame_intro.tscn"):
		var intro := load("res://scenes/minigame_intro.tscn").instantiate() as CanvasLayer
		add_child(intro)
		if intro.has_method("setup"):
			intro.setup("Upcycle Sorting", ["Sort belt items into matching material bins.", "Carry one item at a time; place it in the right bin.", "Correct sorts build streak; burned/wrong sorts reset streak.", "Burned/incorrect trash earns nothing and adds no material.", "Each correct sort grants its material to inventory.", "Controls: tap to move, swipe item to carry, tap bin to drop.\nESC / Return to Map leaves."])
			
	AudioManager.play_bgm("upcycle")
	
	if is_instance_valid(return_btn):
		return_btn.pressed.connect(_leave_to_map)
		
	if is_instance_valid(fire) and not fire.body_entered.is_connected(_on_fire_body_entered):
		fire.body_entered.connect(_on_fire_body_entered)

func _process(delta: float) -> void:
	if is_instance_valid(conveyor):
		for follow in conveyor.get_children():
			if follow.get_child_count() == 0:
				follow.queue_free()
				continue
			var item := follow.get_child(0) as Node2D
			if item == null or not item.get_meta("on_belt", false):
				continue
			follow.progress += belt_speed * delta
			if follow.progress_ratio >= 1.0:
				item.set_meta("on_belt", false)
				burn_item(item)
				
	belt_speed = clampf(75.0 + float(score) * 0.3, 75.0, 180.0)
	spawn_timer += delta
	
	if _count_belt_items() < 5:
		_belt_banner_shown = false
		
	var spawn_interval := clampf(5.0 - float(score) * 0.03, 1.5, 5.0)
	spawn_interval = clampf(spawn_interval + randf_range(-0.25, 0.25), 1.0, 5.5)
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		if _count_belt_items() < 10:
			spawn_item()
			if _count_belt_items() >= 5 and not _belt_banner_shown:
				_belt_banner_shown = true
				_spawn_streak_banner()
				
	if is_instance_valid(carried_item):
		var deposit_bin := _find_deposit_bin(carried_item)
		carried_item.z_index = 30
		var bob := sin(Time.get_ticks_msec() * 0.005) * 2.0
		if is_instance_valid(deposit_bin):
			carried_item.global_position = deposit_bin.global_position + Vector2(0, -34 + bob)
		else:
			carried_item.global_position = (player.global_position if is_instance_valid(player) else carried_item.global_position) + Vector2(0, -22 + bob)
		_update_arrow(carried_item, deposit_bin)
	else:
		carried_item = null
		_hide_arrow()

	var target = _get_valid_interaction_target()
	if is_instance_valid(highlight_node):
		if target:
			highlight_node.visible = true
			highlight_node.global_position = _snap(target.global_position)
		else:
			highlight_node.visible = false
	_update_ui()

func _get_valid_interaction_target() -> Node2D:
	if not is_instance_valid(player):
		return null
	var player_grid := _snap(player.global_position)
	var nearest: Node2D = null
	var best_dist := INF
	
	if carried_item == null:
		if is_instance_valid(conveyor):
			for follow in conveyor.get_children():
				if follow.get_child_count() == 0:
					continue
				var item := follow.get_child(0) as Node2D
				if item == null or not item.get_meta("on_belt", false):
					continue
				var item_grid := _snap(item.global_position)
				var diff := (item_grid - player_grid).abs()
				if diff.x <= GRID and diff.y <= GRID:
					var d := item.global_position.distance_to(player.global_position)
					if d < best_dist:
						best_dist = d
						nearest = item
	else:
		if is_instance_valid(bins):
			for bin in bins.get_children():
				var bin_grid := _snap(bin.global_position)
				var diff := (bin_grid - player_grid).abs()
				if diff.x <= GRID and diff.y <= GRID:
					var d: float = bin.global_position.distance_to(player.global_position)
					if d < best_dist:
						best_dist = d
						nearest = bin
	return nearest

func _count_belt_items() -> int:
	var n := 0
	if is_instance_valid(conveyor):
		for follow in conveyor.get_children():
			if follow.get_child_count() > 0:
				n += 1
	return n

func spawn_item() -> void:
	var tex: String = str(trash.pick_random())
	var item: Node2D = preload("res://scenes/u_trash.tscn").instantiate()
	var follow := load("res://scenes/ui/path_follow2_d.tscn").instantiate() as PathFollow2D
	follow.loop = false
	follow.progress = 0.0
	if is_instance_valid(conveyor):
		conveyor.add_child(follow)
	follow.add_child(item)
	item.position = Vector2.ZERO
	item.set_meta("on_belt", true)
	if item.has_method("init"):
		item.init(tex)
	item.modulate.a = 0.0
	var spawn_tw := item.create_tween()
	spawn_tw.tween_property(item, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if not AudioManager.get_reduced_motion():
		var bob := item.create_tween().set_loops()
		bob.tween_property(item, "position:y", item.position.y - 6.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		bob.tween_property(item, "position:y", item.position.y + 6.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func burn_item(item: Node2D) -> void:
	# No score penalty on belt burn; streak reset only.
	sort_streak = 0
	AudioManager.play_sfx("sort_bad", 0.88)
	var ap := item.get_node_or_null("AnimationPlayer")
	if ap:
		ap.play("suck")
		if not ap.animation_finished.is_connected(item.queue_free):
			ap.animation_finished.connect(func(_anim_name): item.queue_free())
	else:
		item.queue_free()
	_update_ui()

func _update_ui() -> void:
	if is_instance_valid(score_label):
		score_label.text = "Score: %d" % score
	var sl = get_node_or_null("UI/StreakLabel")
	if sl:
		sl.text = "Streak: %d (best %d)" % [sort_streak, GameState.best_sort_streak]
	if is_instance_valid(recycled_label):
		var parts: Array[String] = []
		for m in MATERIALS:
			parts.append("%s:%d" % [m.substr(0,4), int(_recycled_by_mat.get(m,0))])
		recycled_label.text = "Recycled %d | %s" % [_recycled_total, " ".join(parts)]
	if is_instance_valid(belt_label):
		belt_label.text = "Belt: %d/10" % _count_belt_items()
	var mat_name = "none"
	if is_instance_valid(carried_item) and carried_item.has_meta("material"):
		mat_name = str(carried_item.get_meta("material"))

func _on_fire_body_entered(body: Node2D) -> void:
	var parent_item = body.get_parent() if is_instance_valid(body) else null
	if parent_item and parent_item.has_meta("on_belt"):
		burn_item(parent_item)

func _input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch or event is InputEventMouseButton):
		return
	if event.pressed:
		drag_start_pos = event.position
	else:
		var drag_vector: Vector2 = event.position - drag_start_pos
		if drag_vector.length() < MIN_SWIPE_DISTANCE:
			_interact()
		else:
			var dir := (
				(Vector2(-1, 0) if drag_vector.x < 0 else Vector2(1, 0))
				if abs(drag_vector.x) > abs(drag_vector.y)
				else (Vector2(0, -1) if drag_vector.y < 0 else Vector2(0, 1))
			)
			var target_pixel_pos := _snap(player.global_position + dir * GRID) if is_instance_valid(player) else Vector2.ZERO
			var target_grid_pos := Vector2(
				round((target_pixel_pos.x - GRID / 2.0) / GRID),
				round((target_pixel_pos.y - GRID / 2.0) / GRID)
			)
			if _is_valid_move(target_grid_pos):
				if move_tween and move_tween.is_valid():
					move_tween.kill()
				move_tween = create_tween()
				var move_time: float = max(0.05, 0.08 / max(0.5, GameState.get_move_speed_multiplier()))
				move_tween.tween_property(player, "global_position", target_pixel_pos, move_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _is_valid_move(grid_pos: Vector2) -> bool:
	var x = int(grid_pos.x)
	var y = int(grid_pos.y)
	if x < MIN_GRID_X or x > MAX_GRID_X or y < MIN_GRID_Y or y > MAX_GRID_Y:
		return false
	if y == 0 and x != 1:
		return false
	return true

func _interact() -> void:
	var target = _get_valid_interaction_target()
	if not is_instance_valid(target):
		return
	if carried_item == null:
		var parent := target.get_parent()
		if parent is PathFollow2D:
			var old_gpos = target.global_position
			target.reparent(self)
			target.global_position = old_gpos
			parent.queue_free()
		carried_item = target
		target.set_meta("on_belt", false)
		AudioManager.play_sfx("pickup")
	else:
		var mat: String = str(carried_item.get_meta("material"))
		var bin_mat: String = str(target.get_meta("material"))
		if mat == bin_mat:
			score += 1
			AudioManager.play_sfx("sort_ok", 1.0 + min(float(sort_streak), 15.0) * 0.03)
			sort_streak += 1
			_sorted_count += 1
			_recycled_total += 1
			if not _recycled_by_mat.has(mat):
				_recycled_by_mat[mat] = 0
			_recycled_by_mat[mat] += 1
			var gained := GameState.add_trash_type_weighted(mat, int(carried_item.get("size")))
			if gained < int(carried_item.get("size")):
				_notify_queue("%d over inventory cap" % (int(carried_item.get("size")) - gained), Color(0.95, 0.5, 0.35, 1.0), 1.4)
			if sort_streak % 5 == 0:
				score += 5
				_notify_queue("Combo +%d! (%dx5)" % [5, int(sort_streak / 5)], Color(1.0, 0.85, 0.3, 1.0), 1.2)
				_play_combo_feedback()
				var is_best := score > GameState.best_upcycle_score
				_notify_queue(("NEW BEST %d!" % score) if is_best else ("Combo milestone! +%d" % 5), Color(0.9, 0.95, 0.4, 1.0) if is_best else Color(0.7, 1.0, 0.6, 1.0), 1.4)
				if is_best:
					AudioManager.play_sfx("combo")
			_spawn_bin_sparkle(target.global_position)
			AudioManager.play_sfx("combo")
		else:
			AudioManager.play_sfx("sort_bad", 0.92)
			sort_streak = 0
			_shake_wrong_sort()
		carried_item.queue_free()
		carried_item = null

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		AudioManager.play_sfx("return")
		_leave_to_map()

func _play_combo_feedback() -> void:
	var tw := create_tween()
	if is_instance_valid(get_node_or_null("UI")):
		get_node("UI").modulate = Color(1.0, 1.0, 1.0, 1.0)
		tw.tween_property(get_node("UI"), "scale", Vector2(1.05, 1.05), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(get_node("UI"), "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _find_deposit_bin(item: Node2D) -> Node2D:
	var mat := str(item.get_meta("material"))
	if not is_instance_valid(bins) or not is_instance_valid(player):
		return null
	var nearest: Node2D = null
	var best_dist: float = INF
	for bin in bins.get_children():
		if str(bin.get_meta("material")) != mat:
			continue
		var d: float = (bin as Node2D).global_position.distance_to(player.global_position)
		if d <= _arrow_radius and d < best_dist:
			best_dist = d
			nearest = bin
	return nearest

func _update_arrow(item: Node2D, bin: Node2D) -> void:
	if not is_instance_valid(_arrow):
		return
	if not is_instance_valid(bin):
		_arrow.visible = false
		return
	_arrow.visible = true
	var pulse := 1.0 + 0.12 * (0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.008))
	_arrow.scale = Vector2(pulse, pulse)
	var from_pos: Vector2 = player.global_position if is_instance_valid(player) else (item.global_position if is_instance_valid(item) else Vector2.ZERO)
	var to_pos: Vector2 = bin.global_position
	_arrow.global_position = from_pos + (to_pos - from_pos).normalized() * min(GRID * 1.5, from_pos.distance_to(to_pos) * 0.6)
	var angle: float = (to_pos - from_pos).angle()
	_arrow.rotation = angle - PI / 2.0

func _hide_arrow() -> void:
	if is_instance_valid(_arrow):
		_arrow.visible = false

func _snap(pos: Vector2) -> Vector2:
	var offset := Vector2(GRID / 2.0, GRID / 2.0)
	return (pos - offset).snapped(Vector2(GRID, GRID)) + offset

func _spawn_streak_banner() -> void:
	var lbl := load("res://scenes/ui/label.tscn").instantiate() as Label
	lbl.text = "FIVE ON THE BELT!"
	lbl.position = Vector2(320, 14)
	lbl.modulate = Color(0.7, 0.95, 1.0, 1.0)
	lbl.add_theme_font_size_override("font_size", 28)
	var ui := get_node_or_null("UI")
	if is_instance_valid(ui):
		ui.add_child(lbl)
	var tw := lbl.create_tween()
	tw.tween_property(lbl, "scale", Vector2(1.25, 1.25), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.18)
	tw.tween_interval(0.6)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.5)
	tw.tween_callback(lbl.queue_free)

func _shake_wrong_sort() -> void:
	if AudioManager.get_reduced_motion():
		return
	var shake_target: Node = $"."
	var base_pos: Vector2 = shake_target.position
	var tw := create_tween()
	for i in range(6):
		tw.tween_property(shake_target, "position", base_pos + Vector2(randf_range(-8.0, 8.0), randf_range(-6.0, 6.0)), 0.03)
	tw.tween_property(shake_target, "position", base_pos, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _spawn_bin_sparkle(at: Vector2) -> void:
	var p := load("res://scenes/ui/c_p_u_particles2_d.tscn").instantiate() as CPUParticles2D
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 12 + min(10, sort_streak / 5)
	p.lifetime = 0.4
	p.global_position = at
	p.spread = 360.0
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 90.0
	p.gravity = Vector2(0.0, 60.0)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = Color(0.7, 1.0, 0.6, 1.0)
	add_child(p)
	p.emitting = true
	var tw := create_tween()
	tw.tween_interval(p.lifetime + 0.1)
	tw.tween_callback(p.queue_free)

func _leave_to_map() -> void:
	if _leaving:
		return
	_leaving = true
	GameState.record_sort_streak(sort_streak)
	GameState.record_upcycle(score)
	_show_return_summary()

func _show_return_summary() -> void:
	var lbl := load("res://scenes/ui/label.tscn").instantiate() as Label
	lbl.text = "Run complete: Score %d | Sorted %d items" % [score, _sorted_count]
	lbl.position = Vector2(240, 120)
	lbl.modulate = Color(0.85, 1.0, 0.6, 1.0)
	lbl.add_theme_font_size_override("font_size", 24)
	var ui := get_node_or_null("UI")
	if is_instance_valid(ui):
		ui.add_child(lbl)
	var tw := create_tween()
	tw.tween_interval(0.9)
	tw.tween_callback(func():
		AudioManager.play_sfx("return")
		SceneTransition.change_scene("res://scenes/world.tscn")
	)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.3)
	tw.tween_callback(lbl.queue_free)

func _ensure_hud_queue() -> void:
	if _hud_queue == null:
		_hud_queue = load("res://scripts/ui/notification_queue.gd").new()
		add_child(_hud_queue)

func _notify_queue(text: String, col: Color = Color(0.85, 1.0, 0.6, 1.0), duration := 1.2) -> void:
	_ensure_hud_queue()
	_hud_queue.push(text, col, duration)
