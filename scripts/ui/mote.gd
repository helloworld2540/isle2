extends TextureRect
class_name AmbientMote

## A single tiny ambient mote: drifts upward slowly, sways side to side on a
## sine wave, and twinkles its alpha between [twinkle_min] and [twinkle_max].
## Used by the main-menu world preview postcard over the island vista.
## Honors GameSettings.reduce_motion by holding still (motes stay, static).

@export var rise_speed: float = 14.0   ## px per second, upward drift
@export var sway_amp: float = 6.0      ## px, horizontal sway amplitude
@export var sway_period: float = 3.4   ## seconds per full sway cycle
@export var twinkle_min: float = 0.12
@export var twinkle_max: float = 0.85
@export var twinkle_speed: float = 2.1 ## rad/s alpha oscillation

var _bounds: Vector2 = Vector2(200.0, 100.0)
var _t: float = 0.0
var _base_x: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Random phase so a batch of motes never pulses in unison.
	_t = randf() * TAU
	_base_x = position.x
	modulate.a = randf_range(twinkle_min, twinkle_max)


## Called by the spawner so the mote knows when to wrap back to the bottom.
func set_bounds(bounds: Vector2) -> void:
	_bounds = bounds


func _process(delta: float) -> void:
	if GameSettings.reduce_motion:
		return
	_t += delta
	position.y -= rise_speed * delta
	position.x = _base_x + sin(_t * TAU / sway_period) * sway_amp
	modulate.a = lerpf(twinkle_min, twinkle_max, 0.5 + 0.5 * sin(_t * twinkle_speed))
	if position.y < -size.y:
		_respawn()


func _respawn() -> void:
	position.y = _bounds.y + randf_range(2.0, 14.0)
	_base_x = randf_range(0.0, maxf(1.0, _bounds.x - size.x))
	position.x = _base_x
	modulate.a = twinkle_min
