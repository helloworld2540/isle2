extends Node2D
class_name Fish

const GARBAGE := {
	"trash_net.png": 35,
	"trash_bottle.png": 15,
	"trash_plasticblue.png": 40,
	"trash_plasticwhite.png": 35,
	"trash_straw.png": 17
}

const FISH := {
	"fish_gold.png": 20,
	"fish_greyreefshark.png": 45,
	"fish_nemo.png": 25,
	"fish_crab.png": 15
}

@onready var sprite: Sprite2D = $CharacterBody2D/Sprite2D

var speed := Vector2.ZERO
var size := 1.0

const WAKE_SCENE := preload("res://scenes/rr_fish_wake.tscn")

func init_fish() -> void:
	set_meta("is_fish", true)
	var wake := WAKE_SCENE.instantiate()
	var vp := get_viewport_rect().size
	if wake and get_parent():
		get_parent().add_child(wake)
		wake.global_position = Vector2(global_position.x, vp.y - 24.0)
	var texture_keys := FISH.keys()
	if texture_keys.is_empty():
		return
	var texture: String = str(texture_keys.pick_random())
	set_meta("species", texture.get_basename())
	var raw_size := randfn(float(FISH.get(texture, 10)), 10.0)
	var clamped := clampf(raw_size, 1.0, 99.0)
	size = log(clamped) / log(100.0)
	speed = Vector2(randfn(0.0, 75.0), randfn(1.0, 0.4))
	if sprite:
		var tex := load("res://sprites/rr/" + texture)
		if tex is Texture2D:
			sprite.texture = tex

func init_garbage() -> void:
	set_meta("is_fish", false)
	var texture_keys := GARBAGE.keys()
	if texture_keys.is_empty():
		return
	var texture: String = str(texture_keys.pick_random())
	var raw_size := randfn(float(GARBAGE.get(texture, 10)), 10.0)
	var clamped := clampf(raw_size, 1.0, 99.0)
	size = log(clamped) / log(100.0)
	speed = Vector2(randfn(0.0, 25.0), randfn(1.0, 0.2))
	if sprite:
		var tex := load("res://sprites/rr/" + texture)
		if tex is Texture2D:
			sprite.texture = tex
	rotation_degrees = randi_range(0, 360)
	if sprite:
		sprite.flip_h = randf() > 0.5
	if texture == "trash_straw.png" and sprite:
		sprite.modulate = Color.from_hsv(randf(), 1.0, 1.0)

func _ready() -> void:
	var vp := get_viewport_rect().size
	global_position = Vector2(vp.x * randf_range(0.0, 0.8), vp.y * 1.5)
	add_to_group("items")
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func process(bg_speed: float, delta: float) -> void:
	position.y -= bg_speed * speed.y
	position.x += speed.x * delta
	var sx := absf(size)
	if speed.x < 0:
		scale.x = -sx
	else:
		scale.x = sx
	scale.y = absf(size)
	if position.y < -100:
		queue_free()
