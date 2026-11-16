extends Sprite2D
class_name WorldGull

## Ambient seagull for the world map. Follows a lazy lissajous patrol around
## wherever it was placed in the scene, swaps between the two wing frames,
## and banks gently with the vertical bob. Pure ambience — no interaction,
## no physics, no saves. Under reduced motion it holds still with wings up.

const FRAMES: Array[Texture2D] = [
	preload("res://sprites/gull_1.png"),
	preload("res://sprites/gull_2.png"),
]
const FLAP_SECONDS := 0.24
const BOB_FREQUENCY := 1.6   ## vertical sine speed relative to the patrol base frequency
const BOB_AMPLITUDE := 0.5   ## fraction of ry used by the bob term

@export var rx: float = 110.0     ## horizontal patrol radius, px
@export var ry: float = 44.0      ## vertical patrol radius, px
@export var period: float = 11.0  ## seconds per full patrol loop
@export var bank_amount: float = 0.16  ## max roll (radians) when turning
@export var cry_min_interval: float = 25.0  ## min seconds between cries
@export var cry_max_interval: float = 60.0  ## max seconds between cries

var _t: float = 0.0
var _center: Vector2 = Vector2.ZERO
var _cry_timer: float = 0.0


func _ready() -> void:
	texture = FRAMES[0]
	centered = true
	_center = position
	if GameSettings.reduce_motion:
		set_process(false)
		return
	_t = randf() * TAU  # desync a flock spawned together
	# Offset the first cry so a fresh world doesn't yelp immediately.
	_cry_timer = randf_range(cry_min_interval * 0.5, cry_max_interval * 0.8)


func _process(delta: float) -> void:
	_t += delta * TAU / period
	var x := cos(_t) * rx
	var y := sin(_t * BOB_FREQUENCY) * ry * BOB_AMPLITUDE + sin(_t) * ry * (1.0 - BOB_AMPLITUDE)
	position = _center + Vector2(x, y)
	# Bank into the direction of travel (derivative sign of y).
	rotation = clampf(cos(_t) * 0.9, -1.0, 1.0) * bank_amount
	texture = FRAMES[int(Time.get_ticks_msec() / int(FLAP_SECONDS * 1000.0)) % FRAMES.size()]
	_cry_timer -= delta
	if _cry_timer <= 0.0:
		AudioManager.play_sfx("gull", randf_range(0.85, 1.15), AudioManager.AMBIENCE_BUS)
		_cry_timer = randf_range(cry_min_interval, cry_max_interval)
