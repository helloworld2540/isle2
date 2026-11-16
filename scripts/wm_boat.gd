extends Sprite2D
class_name WorldBoat

## Distant fishing sailboat drifting along the eastern horizon. One-way
## drift from `x_start` to `x_end`, then it quietly loops after fading out
## past the far point and fading back in at the near end. Bobs on an easy
## swell and heels slightly with the wind. No interaction; purely ambience.
## Frozen in place under reduced motion.

@export var x_start: float = 500.0   ## near (harbor-side) point, world px
@export var x_end: float = 1750.0    ## far (open sea) point, world px
@export var base_y: float = 620.0    ## horizon line y, world px
@export var drift_speed: float = 14.0  ## px per second, eastbound
@export var bob_amp: float = 5.0     ## px of vertical swell
@export var bob_period: float = 4.6  ## seconds per swell

var _t: float = 0.0
var _fade: float = 1.0  ## 1 = fully visible, 0 = gone
var _hidden: bool = false
## Rare, far-off foghorn so the sailboat reads as a working boat, not a
## drifting prop. Fires 45–85 s apart, only while the boat is actually up.
var _horn_timer: float = 30.0

func _ready() -> void:
	texture = preload("res://sprites/boat.png")
	centered = true
	position = Vector2(x_start, base_y)
	_t = randf() * TAU

func _process(delta: float) -> void:
	_t += delta
	if not GameSettings.reduce_motion:
		position.x += drift_speed * delta
		# Fade out near the far edge, fade back in at the near edge.
		var span := maxf(1.0, x_end - x_start)
		var u := clampf((position.x - x_start) / span, 0.0, 1.0)
		var edge_fade := 1.0
		if u < 0.06:
			edge_fade = u / 0.06
		elif u > 0.88:
			edge_fade = maxf(0.0, 1.0 - (u - 0.88) / 0.12)
		modulate.a = edge_fade
		if position.x >= x_end:
			position.x = x_start
		# Swell: sine bob with a hint of heel (rotation) on the same phase.
		position.y = base_y + sin(_t * TAU / bob_period) * bob_amp
		rotation = sin(_t * TAU / bob_period + 0.7) * 0.045
	# Foghorn is audio ambience, not motion — it sounds even under reduced
	# motion; the boat is only heard while it is genuinely on the horizon.
	_horn_timer -= delta
	if _horn_timer <= 0.0:
		_horn_timer = randf_range(45.0, 85.0)
		if modulate.a > 0.45:
			AudioManager.play_sfx("foghorn", randf_range(0.9, 1.08))
