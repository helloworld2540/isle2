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
var _edge_markers: Dictionary = {}

@onready var items: Node2D = $Items
@onready var drone: CharacterBody2D = $Drone
@onready var timer: Timer = $SpawnTimer
@onready var garbage_label: Label = $UI/GarbageLabel
@onready var fish_label: Label = $UI/FishLabel
@onready var depth_label: Label = $UI/DepthLabel

func _ready() -> void:
	timer.wait_time = SPAWN_INTERVAL
	_edge_markers = {}
	timer.timeout.connect(_spawn_item)
	timer.start()
	AudioManager.play_bgm("reef")
	if ResourceLoader.exists("res://scripts/minigame_intro.gd"):
		var intro: CanvasLayer = preload("res://scripts/minigame_intro.gd").new()
		add_child(intro)
		if intro.has_method("setup"):
			intro.setup("Reef Rescue", ["Move the drone and touch garbage/fish to collect them.", "Press Esc or Return to Map when ready."])
	_update_ui()
	# Return-to-map control for flow back into the world map.
	var return_btn := Button.new()
	return_btn.text = "Return to Map"
	return_btn.position = Vector2(16, 160)
	$UI.add_child(return_btn)
	return_btn.pressed.connect(func(): _clear_edge_markers(); GameState.record_reef(garbage, fish); GameState.add_trash_type("Reef Debris", int(max(1.0, round(garbage)))); AudioManager.play_sfx("return"); SceneTransition.change_scene("res://scenes/world.tscn"))

func _process(delta: float) -> void:
	if not running:
		return
		
	var vp := get_viewport_rect().size
	
	var bg_speed := (MAX_BG_SPEED * (drone.position.y / vp.y) + MIN_BG_SPEED) * delta
	for c: Fish in items.get_children():
		c.process(bg_speed, delta)
		
	$ParallaxBackground.scroll_offset.y -= bg_speed
	depth += bg_speed / 10.0
	
	drone.position += drag_velocity * GameState.get_move_speed_multiplier()
	
	if not (60 < drone.position.x and drone.position.x < vp.x - 60):
		drone.position.x = clampf(drone.position.x, 60, vp.x - 60)
		drag_velocity.x *= -0.3
		
	if not (60 < drone.position.y and drone.position.y < vp.y - 60):
		drone.position.y = clampf(drone.position.y, 60, vp.y - 60)
		drag_velocity.y *= -0.3
		
	drag_velocity.x = move_toward(drag_velocity.x, 0, delta * drag_velocity.x * 0.8)
	drag_velocity.y = move_toward(drag_velocity.y, 0, delta * drag_velocity.y * 0.8)
	_update_edge_markers()
	_update_ui()

func _input(event: InputEvent) -> void:
	if not running:
		return
	if event is InputEventMouseButton:
		if event.pressed:
			dragging = true
		else:
			dragging = false
	elif event is InputEventMouseMotion and dragging:
		drag_velocity = (drag_velocity + event.relative) / 2
	elif event is InputEventScreenTouch:
		if event.pressed:
			dragging = true
		else:
			dragging = false
	elif event is InputEventScreenDrag:
		drag_velocity += (drag_velocity + event.relative) / 2

func _spawn_item() -> void:
	var item: Fish = preload("res://scenes/rr_fish.tscn").instantiate()
	items.add_child(item)
	item.add_to_group("items")
	item.modulate.a = 0.0
	item.scale = Vector2(0.6, 0.6)
	var tw := item.create_tween()
	tw.tween_property(item, "modulate:a", 1.0, 0.35)
	tw.parallel().tween_property(item, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if randfn(depth / 1000.0, 0.5) > 0.5:
		# fish get more common deeper
		item.init_fish()
	else:
		item.init_garbage()
	

func _update_edge_markers() -> void:
	var vp := get_viewport_rect().size
	for child in items.get_children():
		if not is_instance_valid(child):
			continue
		var next := child as Node2D
		if next == null or not next.is_inside_tree():
			continue
		var pos: Vector2 = next.global_position
		var mid := pos
		if mid.x >= 0 and mid.x <= vp.x and mid.y >= 0 and mid.y <= vp.y:
			if _edge_markers.has(next.get_instance_id()):
				var m: Label = _edge_markers[next.get_instance_id()]
				if is_instance_valid(m): m.queue_free()
				_edge_markers.erase(next.get_instance_id())
			continue
		var marker: Label
		if not _edge_markers.has(next.get_instance_id()):
			marker = Label.new()
			marker.text = "!"
			marker.modulate = Color(1.0, 0.95, 0.35, 0.95)
			marker.add_theme_font_size_override("font_size", 22)
			add_child(marker)
			_edge_markers[next.get_instance_id()] = marker
		else:
			marker = _edge_markers[next.get_instance_id()]
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

func _clear_edge_markers() -> void:
	for m in _edge_markers.values():
		if is_instance_valid(m): m.queue_free()
	_edge_markers.clear()

func _update_ui() -> void:
	garbage_label.text = "Collected %d kg of garbage" % garbage
	fish_label.text = "Released %d fish" % fish
	depth_label.text = "%d m" % depth
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	var root := body.get_parent()
	if not is_instance_valid(root) or not root.is_in_group("items"): return
	if bool(root.get_meta("collected", false)): return
	root.set_meta("collected", true)
	if _edge_markers.has(root.get_instance_id()):
		var m2: Label = _edge_markers[root.get_instance_id()]
		if is_instance_valid(m2): m2.queue_free()
		_edge_markers.erase(root.get_instance_id())
	
	var is_fish: bool = root.get_meta("is_fish", false)
	
	if is_fish:
		fish += 1
		AudioManager.play_sfx("pickup")
		_spawn_popup(root.global_position, "+1 fish", Color(0.6, 0.9, 1.0, 1.0))
		root.get_node("AnimationPlayer").play("run")
	else:
		var weight := int(root.get_meta("weight", 0))
		garbage += weight
		AudioManager.play_sfx("pickup")
		_spawn_popup(root.global_position, "+%d kg" % weight, Color(0.95, 0.95, 0.35, 1.0))
		root.get_node("AnimationPlayer").play("suck")

func _spawn_popup(at: Vector2, text: String, col: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.modulate = col
	lbl.position = at + Vector2(-20, -40)
	$UI.add_child(lbl)
	var tw := lbl.create_tween()
	tw.tween_property(lbl, "position", lbl.position + Vector2(0, -42), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.7)
	tw.tween_callback(lbl.queue_free)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		AudioManager.play_sfx("return")
		_clear_edge_markers()
		SceneTransition.change_scene("res://scenes/world.tscn")
