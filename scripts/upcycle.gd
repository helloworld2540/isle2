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

var score := 0
var carried_item: Node2D = null
var spawn_timer := 0.0
var SPAWN_INTERVAL := 1.0
var belt_speed := 120.0

@onready var score_label: Label = $UI/ScoreLabel
@onready var held_label: Label = $UI/HeldLabel
@onready var player: CharacterBody2D = $Player
@onready var conveyor: Node2D = $Conveyor
@onready var fire: Area2D = $Fire
@onready var bins: Node2D = $Bins

func _ready() -> void:
	for i in range(4):
		trash.append_array(trash.duplicate())
	for i in range(bins.get_child_count()):
		var bin := bins.get_child(i)
		bin.set_meta("material", MATERIALS[i])
		var body := bin.get_node_or_null("Body")
		if body:
			body.input_event.connect(_handle_bin.bind(bin))
	_update_ui()

func _random_path() -> Path2D:
	var paths := conveyor.get_children()
	if paths.is_empty():
		return null
	return paths[randi() % paths.size()] as Path2D

func _process(delta: float) -> void:
	for path in conveyor.get_children():
		if not (path is Path2D):
			continue
		for child in path.get_children():
			if not (child is PathFollow2D):
				continue
			var follow := child as PathFollow2D
			if follow.get_child_count() == 0:
				follow.queue_free()
				continue
			var item := follow.get_child(0) as Node2D
			if not is_instance_valid(item):
				continue
			if not item.get_meta("on_belt", false):
				continue
			follow.progress += belt_speed * delta
			if follow.progress_ratio >= 1.0:
				item.set_meta("on_belt", false)
				burn_item(item)
				follow.queue_free()
	spawn_timer += delta
	if spawn_timer >= SPAWN_INTERVAL:
		spawn_timer = 0.0
		spawn_item()
	if carried_item and is_instance_valid(carried_item):
		carried_item.global_position = player.global_position + Vector2(0, -20)
	_update_ui()

func spawn_item() -> void:
	var tex: String = trash.pick_random()
	var item: Node2D = preload("res://scenes/u_trash.tscn").instantiate()
	var path := _random_path()
	if path:
		var follow := PathFollow2D.new()
		follow.loop = false
		follow.progress = 0.0
		path.add_child(follow)
		follow.add_child(item)
		item.position = Vector2.ZERO
	else:
		conveyor.add_child(item)
	item.set_meta("on_belt", true)
	item.init(tex)
	var body := item.get_node_or_null("Body")
	if body:
		body.input_event.connect(_handle_item.bind(item))

func _handle_item(viewport: Viewport, event: InputEvent, shape_idx: int, item: Node2D) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		if not carried_item:
			var parent := item.get_parent()
			if parent is PathFollow2D:
				item.reparent(self)
				item.global_position = (parent as PathFollow2D).global_position
				parent.queue_free()
			carried_item = item
			item.set_meta("on_belt", false)

func _handle_bin(viewport: Viewport, event: InputEvent, shape_idx: int, bin: Node2D) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		if carried_item:
			var mat: String = str(carried_item.get_meta("material"))
			print("[rr] Put", mat, "into", bin.get_meta("material"))
			if mat == bin.get_meta("material"):
				score += 1
			else:
				score -= 1
			carried_item.queue_free()
			carried_item = null

func burn_item(item: Node2D) -> void:
	score -= 1
	var ap := item.get_node_or_null("AnimationPlayer")
	if ap:
		ap.play("suck")
	_update_ui()

func _update_ui() -> void:
	score_label.text = "Score: %d" % score
	held_label.text = "Held: %s" % (carried_item.get_meta("material") if carried_item else "none")

func _on_fire_body_entered(body: Node2D) -> void:
	burn_item(body)
