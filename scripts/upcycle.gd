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
var conveyor_points: Array[Vector2] = []
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
	trash.append_array(trash)
	trash.append_array(trash)
	trash.append_array(trash)
	trash.append_array(trash)
	
	var vp := get_viewport_rect().size
	conveyor_points = [
		Vector2(40, 60), # top left
		Vector2(vp.x - 40, 60), # top right
		Vector2(vp.x - 40, vp.y * 0.4), # middle right
		Vector2(40, vp.y * 0.4), # middle left
		Vector2(40, vp.y - 80), # bottom left
	]
	for i in range(bins.get_child_count()):
		var bin := bins.get_child(i)
		bin.set_meta("material", MATERIALS[i])
		bin.get_node("Body").input_event.connect(_handle_bin.bind(bin))
	_update_ui()

func _process(delta: float) -> void:
	for item in conveyor.get_children():
		if item.get_meta("on_belt", false):
			var idx: int = int(item.get_meta("seg", 0))
			var t: float = float(item.get_meta("t", 0.0))
			
			# Safety check to prevent out-of-bounds crash
			if idx >= conveyor_points.size() - 1:
				item.set_meta("on_belt", false)
				burn_item(item)
				continue
				
			t += belt_speed * delta / max(1.0, conveyor_points[idx].distance_to(conveyor_points[idx + 1]))
			if t >= 1.0:
				t -= 1.0
				idx += 1
				if idx >= conveyor_points.size() - 1:
					item.set_meta("on_belt", false)
					burn_item(item)
					continue
					
			item.set_meta("seg", idx)
			item.set_meta("t", t)
			item.global_position = conveyor_points[idx].lerp(conveyor_points[idx + 1], t)
			
	spawn_timer += delta
	if spawn_timer >= SPAWN_INTERVAL:
		spawn_timer = 0.0
		spawn_item()
		
	if carried_item and is_instance_valid(carried_item):
		carried_item.global_position = player.global_position + Vector2(0, -20)
	_update_ui()
	
func spawn_item() -> void:
	var item: Trash = preload("res://scenes/u_trash.tscn").instantiate()
	conveyor.add_child(item)
	var mat = trash[0]
	trash.remove_at(0)
	item.init(mat)
	item.set_meta("on_belt", true)
	item.get_node("Body").input_event.connect(_handle_item.bind(item))
	item.global_position = conveyor_points[0]

func _handle_item(viewport: Viewport, event: InputEvent, shape_idx: int, item: Node2D) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		if not carried_item:
			carried_item = item
	
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
	item.get_node("AnimationPlayer").play("suck")
	_update_ui()

func _update_ui() -> void:
	score_label.text = "Score: %d" % score
	held_label.text = "Held: %s" % (carried_item.get_meta("material") if carried_item else "none")
