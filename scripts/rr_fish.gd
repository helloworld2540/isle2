extends Node2D
class_name Fish

const GARBAGE := {
	"trash_net.png": 35,
	"trash_bottle.png": 15,
	"trash_plasticblue.png": 40,
	"trash_plasticwhite.png": 35,
	"trash_straw.png": 17
}

var _sprite_cache: Dictionary = {}

func _sprite(path: String) -> Texture2D:
	var cached := _sprite_cache.get(path) as Texture2D
	if cached:
		return cached
	var tex := load("res://sprites/rr/" + path) as Texture2D
	if tex:
		_sprite_cache[path] = tex
	return tex

const FISH := {
	"fish_gold.png": 20,
	"fish_greyreefshark.png": 45,
	"fish_nemo.png": 25,
	"fish_crab.png": 15,
	"fish_silverfin.png": 18
}

## Relative spawn weights — tuned so the Grey Reef Shark is a spice, the Crab
## and Goldie are regulars, and the Silverfin is a deliberate, rare sighting.
## Eel Run calls the courier up: the silver flash rides the fast water.
const SPAWN_WEIGHTS := {
	"fish_gold.png": 20,
	"fish_greyreefshark.png": 14,
	"fish_nemo.png": 26,
	"fish_crab.png": 22,
	"fish_silverfin.png": 10,
}
## Silverfin spawn weight while the tide is Eel Run (fish are keyed up).
const EEL_RUN_SILVERFIN_WEIGHT := 20

@onready var sprite: Sprite2D = $CharacterBody2D/Sprite2D

var speed := Vector2.ZERO
var size := 1.0

const WAKE_SCENE := preload("res://scenes/rr_fish_wake.tscn")

## Weighted spawn pick. Reads the deterministic tide, so Eel Run days are the
## courier's day on the water — preview and payout never disagree about the odds.
static func _pick_fish_texture() -> String:
	var weights := SPAWN_WEIGHTS.duplicate()
	if TideReport.today_key() == "eel_run":
		weights["fish_silverfin.png"] = EEL_RUN_SILVERFIN_WEIGHT
	var total := 0.0
	for w in weights.values():
		total += float(w)
	var roll := randf() * total
	for key in weights:
		roll -= float(weights[key])
		if roll <= 0.0:
			return str(key)
	return "fish_nemo.png"


func init_fish() -> void:
	set_meta("is_fish", true)
	var wake := WAKE_SCENE.instantiate()
	var vp := get_viewport_rect().size
	if wake and get_parent():
		get_parent().add_child(wake)
		wake.global_position = Vector2(global_position.x, vp.y - 24.0)
	var texture := _pick_fish_texture()
	set_meta("species", texture.get_basename())
	# Rare golden Goldie: grazes are rewards, not penalties. Tinted bright gold.
	# The daily Night Drift tide doubles this roll.
	var golden_fish := randf() < 0.10 * TideReport.golden_chance_multiplier()
	if golden_fish:
		set_meta("golden_fish", true)
	var raw_size := randfn(float(FISH.get(texture, 10)), 10.0)
	var clamped := clampf(raw_size, 1.0, 99.0)
	size = log(clamped) / log(100.0)
	# Eel Run speeds the whole school up.
	speed = Vector2(randfn(0.0, 75.0), randfn(1.0, 0.4)) * TideReport.fish_speed_multiplier()
	if sprite:
		var tex := _sprite(texture)
		if tex:
			sprite.texture = tex
		if golden_fish:
			sprite.modulate = Color(1.18, 1.08, 0.5, 1.0)

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
	# Rare golden debris: worth a bonus point when vacuumed up. Night Drift
	# doubles the roll.
	if randf() < 0.12 * TideReport.golden_chance_multiplier():
		set_meta("golden", true)
		if sprite:
			sprite.modulate = Color(1.15, 1.05, 0.55, 1.0)
	if sprite:
		var tex := _sprite(texture)
		if tex:
			sprite.texture = tex
			if bool(get_meta("golden", false)):
				sprite.modulate = Color(1.15, 1.05, 0.55, 1.0)
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
