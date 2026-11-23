extends Node2D
class_name Fish

## One drifting spawn in Reef Rescue — garbage or a fish — with its
## sprite, weight and drift speed; owns its off-screen edge marker.

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

## Bump hit radius per spawn texture, in sprite pixels, measured off the art's
## ink bounds so each species — and each trash — gets a hitbox that fits its
## picture instead of one hard-coded circle every spawn shared. Cached per
## texture path; each owning instance still applies its own drift scale.
var _hit_radius_cache: Dictionary = {}

## Half the diagonal of the sprite's ink bounding box — a circle broad enough to
## never miss a bump the player could not see and never stop short of one they
## could. Scaled by the instance's drift size upstream (the shape is parented
## under the size-driven body).
func _hit_radius(texture_path: String) -> float:
	var cached: float = _hit_radius_cache.get(texture_path, 0.0) as float
	if cached > 0.0:
		return cached
	var radius := 0.0
	var tex := _sprite(texture_path)
	if tex:
		var img := tex.get_image()
		var tex_w := img.get_width()
		var tex_h := img.get_height()
		var min_x := tex_w
		var min_y := tex_h
		var max_x := -1
		var max_y := -1
		for py in range(tex_h):
			for px in range(tex_w):
				if img.get_pixel(px, py).a > 0.0:
					if px < min_x:
						min_x = px
					if px > max_x:
						max_x = px
					if py < min_y:
						min_y = py
					if py > max_y:
						max_y = py
		if max_x >= 0:
			var ink_size := Vector2(max_x - min_x + 1, max_y - min_y + 1)
			radius = 0.5 * ink_size.length()
	_hit_radius_cache[texture_path] = radius
	return radius

## Points the spawn's bump hitbox at the freshly assigned sprite. Falls back to
## the authored shape when no ink could be measured for the texture.
func _apply_hitbox(texture_path: String) -> void:
	if collision_shape and collision_shape.shape is CircleShape2D:
		var radius := _hit_radius(texture_path)
		if radius > 0.0:
			(collision_shape.shape as CircleShape2D).radius = radius

const FISH := {
	"fish_gold.png": 20,
	"fish_greyreefshark.png": 45,
	"fish_nemo.png": 25,
	"fish_crab.png": 15,
	"fish_silverfin.png": 18,
	"fish_star.png": 15
}

## Relative spawn weights — tuned so the Grey Reef Shark is a spice, the Crab
## and Goldie are regulars, and the Silverfin is a deliberate, rare sighting.
## Eel Run calls the courier up: the silver flash rides the fast water. The
## Starfish is a slow reef-floor dweller, uncommon but easy to spot.
const SPAWN_WEIGHTS := {
	"fish_gold.png": 20,
	"fish_greyreefshark.png": 14,
	"fish_nemo.png": 26,
	"fish_crab.png": 22,
	"fish_silverfin.png": 10,
	"fish_star.png": 14,
}
## Silverfin spawn weight while the tide is Eel Run (fish are keyed up).
const EEL_RUN_SILVERFIN_WEIGHT := 20
## Speed scale per species. The Starfish is a patient reef-floor dweller: it
## drifts at a fraction of a fish's pace, so its lane can be read early and
## stepped around — flavour and a fair hazard at once.
const DRIFT_SPEED_SCALE := {
	"fish_star.png": 0.42,
}

@onready var sprite: Sprite2D = $CharacterBody2D/Sprite2D
@onready var collision_shape: CollisionShape2D = $CharacterBody2D/CollisionShape2D

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
	var texture := _pick_fish_texture()
	set_meta("species", texture.get_basename())
	# The Starfish does not swim up from below — it is simply there on the
	# reef floor. No red wake telegraph: its slow drift is its own warning.
	if texture == "fish_star.png" and get_parent():
		var vp := get_viewport_rect().size
		global_position = Vector2(vp.x * randf_range(0.06, 0.94), vp.y * randf_range(0.25, 0.75))
	else:
		var wake := WAKE_SCENE.instantiate()
		var vp := get_viewport_rect().size
		if wake and get_parent():
			get_parent().add_child(wake)
			wake.global_position = Vector2(global_position.x, vp.y - 24.0)
	# Rare golden Goldie: grazes are rewards, not penalties. Tinted bright gold.
	# The daily Night Drift tide doubles this roll.
	var golden_fish := randf() < 0.10 * TideReport.golden_chance_multiplier()
	if golden_fish:
		set_meta("golden_fish", true)
	var raw_size := randfn(float(FISH.get(texture, 10)), 10.0)
	var clamped := clampf(raw_size, 1.0, 99.0)
	size = log(clamped) / log(100.0)
	# Eel Run speeds the whole school up; the Starfish keeps its own slow pace.
	speed = Vector2(randfn(0.0, 75.0), randfn(1.0, 0.4)) \
		* TideReport.fish_speed_multiplier() \
		* float(DRIFT_SPEED_SCALE.get(texture, 1.0))
	if sprite:
		var tex := _sprite(texture)
		if tex:
			sprite.texture = tex
		if golden_fish:
			sprite.modulate = Color(1.18, 1.08, 0.5, 1.0)
		_apply_hitbox(texture)

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
	_apply_hitbox(texture)
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
