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

@onready var items: Node2D = $Items
@onready var drone: CharacterBody2D = $Drone
@onready var timer: Timer = $SpawnTimer
@onready var garbage_label: Label = $UI/GarbageLabel
@onready var fish_label: Label = $UI/FishLabel
@onready var depth_label: Label = $UI/DepthLabel

func _ready() -> void:
	timer.wait_time = SPAWN_INTERVAL
	timer.timeout.connect(_spawn_item)
	timer.start()
	_update_ui()

func _process(delta: float) -> void:
	if not running:
		return
		
	var vp := get_viewport_rect().size
	
	var bg_speed := (MAX_BG_SPEED * (drone.position.y / vp.y) + MIN_BG_SPEED) * delta
	for c: Fish in items.get_children():
		c.process(bg_speed, delta)
		
	$ParallaxBackground.scroll_offset.y -= bg_speed
	depth += bg_speed / 10.0
	
	drone.position += drag_velocity
	
	if not (60 < drone.position.x and drone.position.x < vp.x - 60):
		drone.position.x = clampf(drone.position.x, 60, vp.x - 60)
		drag_velocity.x *= -0.3
		
	if not (60 < drone.position.y and drone.position.y < vp.y - 60):
		drone.position.y = clampf(drone.position.y, 60, vp.y - 60)
		drag_velocity.y *= -0.3
		
	drag_velocity.x = move_toward(drag_velocity.x, 0, delta * drag_velocity.x * 0.8)
	drag_velocity.y = move_toward(drag_velocity.y, 0, delta * drag_velocity.y * 0.8)
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
	var item: Fish = preload("res://scenes/fish.tscn").instantiate()
	items.add_child(item)
	item.add_to_group("items")
	if randfn(depth / 1000.0, 0.5) > 0.5:
		# fish get more common deeper
		item.init_fish()
	else:
		item.init_garbage()
	
func _update_ui() -> void:
	garbage_label.text = "Collected %d kg of garbage" % garbage
	fish_label.text = "Released %d fish" % fish
	depth_label.text = "%d m" % depth
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	var root := body.get_parent()
	if not root.is_in_group("items"): return
	
	var is_fish: bool = root.get_meta("is_fish", false)
	
	if is_fish:
		fish += 1
		root.get_node("AnimationPlayer").play("run")
	else:
		garbage += int(root.get_meta("weight", 0))
		root.get_node("AnimationPlayer").play("suck")
