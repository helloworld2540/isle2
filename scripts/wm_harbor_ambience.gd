extends Node
class_name HarborAmbience

## The dock's own voice. The gull flock (`wm_gull.gd`) is animation-bound: under
## reduced motion the birds freeze and their cries stop, which used to leave the
## world map silent for anyone playing with the setting on. This node owns a
## sparse, *distant* harbor cry on its own cadence so resting at the dock always
## sounds alive — it carries no visuals, so there is nothing for reduced motion
## to freeze and it keeps playing. Pitch sits below the flock's so the two read
## as different birds rather than an echo. Rendered through the Ambience bus by
## AudioManager, so the player's ambience volume setting applies.

## Sparse by design: 40–75 s between calls. The flock fills the gaps.
@export var min_interval: float = 40.0
@export var max_interval: float = 75.0
## Quiet stretch after the world loads before the first cry, so entering a
## scene never yelps on frame one.
@export var first_delay: float = 16.0

## Fraction of calls that draw an answer a moment later — lone birds read as
## less alive than two talking across the water.
@export var echo_chance: float = 0.35
@export var echo_delay_min: float = 0.9
@export var echo_delay_max: float = 2.2

var _timer: float = 0.0
var _echo_timer: float = 0.0
var _echo_pitch: float = 1.0


func _ready() -> void:
	# Jitter the first delay so two worlds loading together don't sync up.
	_timer = randf_range(first_delay * 0.6, first_delay * 1.4)


func _process(delta: float) -> void:
	if _echo_timer > 0.0:
		_echo_timer -= delta
		if _echo_timer <= 0.0:
			AudioManager.play_sfx("gull", _echo_pitch, AudioManager.AMBIENCE_BUS)
	
	_timer -= delta
	if _timer > 0.0:
		return
	
	_cry()
	_timer = randf_range(min_interval, max_interval)


func _cry() -> void:
	# Night Drift: a lone foghorn low on the water, once per cycle instead of
	# half the time — the sea is doing tricks tonight.
	if TideReport.today_key() == "night_drift" and randf() < 0.5:
		AudioManager.play_sfx("foghorn", randf_range(0.8, 0.92), AudioManager.AMBIENCE_BUS)
		return
	# Lower and a touch slower than the flock — this is the bird on the far jetty.
	var pitch := randf_range(0.78, 0.94)
	if TideReport.today_key() == "eel_run":
		# Eel Run: the birds are keyed up for the hunt — pitch reads hotter.
		pitch = randf_range(0.95, 1.08)
	AudioManager.play_sfx("gull", pitch, AudioManager.AMBIENCE_BUS)
	
	if _echo_timer > 0.0:
		return
	# Tide tempers the chorus: Glass Calm's gulls are mobbed to the water,
	# Slack Water's never answer — nothing pushes, nothing hurries.
	var echo := echo_chance
	match TideReport.today_key():
		"glass_calm":
			echo = 0.7
		"slack_water":
			echo = 0.0
	if randf() < echo:
		# The reply sits slightly higher, as if closer.
		_echo_pitch = clampf(pitch + randf_range(0.05, 0.14), 0.5, 2.0)
		_echo_timer = randf_range(echo_delay_min, echo_delay_max)
