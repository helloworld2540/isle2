extends Node2D
class_name Fish

const GARBAGE := {
	"res://sprites/rr/trash_net.png": 35,
	"res://sprites/rr/trash_bottle.png": 15,
	"res://sprites/rr/trash_plasticblue.png": 40,
	"res://sprites/rr/trash_plasticwhite.png": 35,
}

const FISH := {
	"res://sprites/rr/fish_gold.png": 20, 
	"res://sprites/rr/fish_greyreefshark.png": 45, 
	"res://sprites/rr/fish_nemo.png": 25,
	"res://sprites/rr/fish_crab.png": 15
}

@onready var sprite: Sprite2D = $CharacterBody2D/Sprite2D
var speed := Vector2.ZERO
var size := 1.0

func init_fish() -> void:
	set_meta("is_fish", true)
	var texture = FISH.keys().pick_random()
	sprite.texture = load(texture)
	
	speed = Vector2(randfn(0, 75), randfn(1, 0.4))
	size = log(randfn(FISH[texture], 10)) / log(100)
	
func init_garbage() -> void:
	set_meta("is_fish", false)
	var texture = GARBAGE.keys().pick_random()
	sprite.texture = load(texture)
	
	speed = Vector2(randfn(0, 25), randfn(1, 0.2))
	size = log(randfn(GARBAGE[texture], 10)) / log(100)
	set_meta("weight", int(randfn(10, 10)))

func _ready() -> void:
	var vp = get_viewport_rect().size
	position.x = vp.x * randf_range(0, 0.8)
	position.y = vp.y * 1.5
	add_to_group("items")

func process(bg_speed: float, delta: float) -> void:
	position.y -= bg_speed * speed.y
	position.x += speed.x * delta
	scale.x = abs(size) * (-1 if speed.x < 0 else 1)
	scale.y = size
	if position.y < -100:
		queue_free()
