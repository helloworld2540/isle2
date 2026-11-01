extends Node2D

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

# Grid boundaries
const MIN_GRID_X := 1
const MAX_GRID_X := 5
const MIN_GRID_Y := 0
const MAX_GRID_Y := 2

var score := 0
var sort_streak := 0
var carried_item: Node2D = null
var spawn_timer := 0.0
var SPAWN_INTERVAL := 1.0
var belt_speed := 120.0

var drag_start_pos := Vector2.ZERO
var is_dragging := false
var move_tween: Tween = null

@onready var score_label: Label = $UI/ScoreLabel
@onready var held_label: Label = $UI/HeldLabel
@onready var player: CharacterBody2D = $Player
@onready var conveyor: Path2D = $Conveyor
@onready var fire: Area2D = $Fire
@onready var bins: Node2D = $Bins
@onready var highlight_node: Node2D = $highlight_node

func _ready() -> void:
	var max_bins = min(bins.get_child_count(), MATERIALS.size())
	for i in range(max_bins):
		var bin := bins.get_child(i)
		bin.set_meta("material", MATERIALS[i])
		
	player.global_position = _snap(player.global_position)
	var streak_label := Label.new()
	streak_label.name = "StreakLabel"
	streak_label.position = Vector2(20, 60)
	$UI.add_child(streak_label)
	_update_ui()
	if ResourceLoader.exists("res://scripts/minigame_intro.gd"):
		var intro: CanvasLayer = preload("res://scripts/minigame_intro.gd").new()
		add_child(intro)
		if intro.has_method("setup"):
			intro.setup("Upcycle Sorting", ["Sort trash into matching material bins.", "Press Esc to quit or Return to Map when finished."])
# BGM
	AudioManager.play_bgm("upcycle")
	# Return-to-map control for flow back into the world map.
	var return_btn := Button.new()
	return_btn.text = "Return to Map"
	return_btn.position = Vector2(820, 20)
	$UI.add_child(return_btn)
	return_btn.pressed.connect(func(): GameState.record_sort_streak(sort_streak); GameState.record_upcycle(score); AudioManager.play_sfx("return"); SceneTransition.change_scene("res://scenes/world.tscn"))
	# visual feedback is applied in _update_ui
	# ESC also returns, for consistency with world menu.
	# (handled via Button; ESC reserved for future pause menu)

func _spawn_combo_popup() -> void:
	var lbl := Label.new()
	lbl.text = "Combo +%d! (%dx5)" % [5, int(sort_streak / 5)]
	lbl.modulate = Color(1.0, 0.85, 0.3, 1.0)
	lbl.position = Vector2(300, 40)
	$UI.add_child(lbl)
	var tw := lbl.create_tween()
	tw.tween_property(lbl, "position", lbl.position + Vector2(0, -60), 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.9)
	tw.tween_callback(lbl.queue_free)

func _snap(pos: Vector2) -> Vector2:
	var offset := Vector2(GRID / 2.0, GRID / 2.0)
	return (pos - offset).snapped(Vector2(GRID, GRID)) + offset

func _process(delta: float) -> void:
	for follow in conveyor.get_children():
		if follow.get_child_count() == 0:
			follow.queue_free()
			continue
			
		var item := follow.get_child(0) as Node2D
		if not item.get_meta("on_belt", false): continue
			
		follow.progress += belt_speed * delta
		
		if follow.progress_ratio >= 1.0:
			item.set_meta("on_belt", false)
			burn_item(item)
			
	spawn_timer += delta
	if spawn_timer >= SPAWN_INTERVAL:
		spawn_timer = 0.0
		spawn_item()
		
	if carried_item and is_instance_valid(carried_item):
		carried_item.global_position = player.global_position + Vector2(0, -20)
		
	var target = _get_valid_interaction_target()
	if target:
		highlight_node.visible = true
		highlight_node.global_position = _snap(target.global_position)
	else:
		highlight_node.visible = false
		
	_update_ui()

func _get_valid_interaction_target() -> Node2D:
	var player_grid := _snap(player.global_position)
	var nearest: Node2D = null
	var best_dist := INF
	
	if not carried_item:
		for follow in conveyor.get_children():
			if follow.get_child_count() == 0: continue
			var item := follow.get_child(0) as Node2D
			if not item.get_meta("on_belt", false): continue
			
			var item_grid := _snap(item.global_position)
			var diff := (item_grid - player_grid).abs()
			
			if diff.x <= GRID and diff.y <= GRID:
				var d := item.global_position.distance_to(player.global_position)
				if d < best_dist:
					best_dist = d
					nearest = item
	else:
		for bin in bins.get_children():
			var bin_grid := _snap(bin.global_position)
			var diff := (bin_grid - player_grid).abs()
			if diff.x <= GRID and diff.y <= GRID:
				var d: float = bin.global_position.distance_to(player.global_position)
				if d < best_dist:
					best_dist = d
					nearest = bin
	return nearest

func spawn_item() -> void:
	var tex: String = trash.pick_random()
	var item: Node2D = preload("res://scenes/u_trash.tscn").instantiate()

	var follow := PathFollow2D.new()
	follow.loop = false
	follow.progress = 0.0
	conveyor.add_child(follow)
	follow.add_child(item)
	item.position = Vector2.ZERO

	item.set_meta("on_belt", true)
	item.init(tex)

func burn_item(item: Node2D) -> void:
	score -= 1
	sort_streak = 0
	var ap := item.get_node("AnimationPlayer")
	if ap:
		ap.play("suck")
		if not ap.animation_finished.is_connected(item.queue_free):
			ap.animation_finished.connect(func(_anim_name): item.queue_free())
	else:
		item.queue_free()
	_update_ui()

func _update_ui() -> void:
	score_label.text = "Score: %d" % score
	var sl := $UI.get_node_or_null("StreakLabel")
	if sl:
		sl.text = "Streak: %d (best %d)" % [sort_streak, GameState.best_sort_streak]
	
	var mat_name = "none"
	if carried_item and carried_item.has_meta("material"):
		mat_name = carried_item.get_meta("material")
	held_label.text = "Holding %s" % mat_name

func _on_fire_body_entered(body: Node2D) -> void:
	var parent_item = body.get_parent() 
	if parent_item and parent_item.has_meta("on_belt"):
		burn_item(parent_item)

func _input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch or event is  InputEventMouseButton):
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
			print("[u] input: ", drag_vector)
			print("[u] output:", dir)
			var target_pixel_pos = _snap(player.global_position + dir * GRID)
				
			var target_grid_pos = Vector2(
				round((target_pixel_pos.x - GRID / 2.0) / GRID),
				round((target_pixel_pos.y - GRID / 2.0) / GRID)
			)
				
			if _is_valid_move(target_grid_pos):
				if move_tween and move_tween.is_valid():
					move_tween.kill()
				move_tween = create_tween()
				move_tween.tween_property(player, "global_position", target_pixel_pos, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _is_valid_move(grid_pos: Vector2) -> bool:
	var x = int(grid_pos.x)
	var y = int(grid_pos.y)
	
	if x < MIN_GRID_X or x > MAX_GRID_X or y < MIN_GRID_Y or y > MAX_GRID_Y:
		return false
		
	if y == 0 and x != 1: return false
	return true

func _interact() -> void:
	var target = _get_valid_interaction_target()
	
	if not target:
		return
		
	if not carried_item:
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
			AudioManager.play_sfx("sort_ok")
			sort_streak += 1
			GameState.add_trash_type(mat, int(carried_item.get("size")))
			if sort_streak % 5 == 0:
				score += 5
				_spawn_combo_popup()
				AudioManager.play_sfx("combo")
		else:
			score -= 1
			AudioManager.play_sfx("sort_bad")
			sort_streak = 0
			
		carried_item.queue_free()
		carried_item = null
