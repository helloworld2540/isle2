extends Sprite2D
class_name WorldCourier

## The Silverfin crosses the strait on Eel Run days only. A rare, fast,
## silvery streak along the water — pure ambience, no interaction. On any
## other day the node frees itself; the courier does not make appointments.
## Reduced motion skips the flyby entirely (like the gulls freeze).
##
## Once the keeper has read the whole courier's post (THE LAST LETTER), the
## courier keeps the keeper's company: it arrives sooner after each pass.
## Nothing is said about it — the sea just stops being a stranger.

const TEX := preload("res://sprites/rr/fish_silverfin.png")
const SWEEP_PIXELS := 1100.0    ## how far the streak travels, px
const SWEEP_SECONDS := 2.4      ## the whole crossing
const MIN_INTERVAL := 30.0      ## seconds between passes (min)
const MAX_INTERVAL := 65.0      ## seconds between passes (max)
## Intervals once THE LAST LETTER is read — the courier shows off a little.
const GRATITUDE_MIN_INTERVAL := 16.0
const GRATITUDE_MAX_INTERVAL := 34.0

## Debug/test hook: pretend the tide is this key (empty = real tide). Lets a
## harness exercise the eel-run path without changing the calendar.
@export var force_tide_key := ""
## Debug/test hook: force the gratitude interval without a save. Otherwise the
## scene reads THE LAST LETTER off the live GameState and stays quiet.
@export var force_gratitude := false

var _center: Vector2 = Vector2.ZERO
var _timer: float = 0.0
var _passing: bool = false
var _grateful := false


func _ready() -> void:
	var tide_key := force_tide_key if not force_tide_key.is_empty() else TideReport.today_key()
	if tide_key != "eel_run":
		# The courier keeps its own calendar — no card, no trace.
		queue_free()
		return
	# Runtime lookup, not the bare autoload identifier: tool harnesses
	# compile without autoloads as globals, but the /root node always
	# exists in a real run — and harnesses can add their own stand-in.
	var gs := get_tree().root.get_node("GameSettings")
	if gs != null and bool(gs.get("reduce_motion")):
		queue_free()
		return
	_grateful = _read_gratitude()
	texture = TEX
	centered = true
	scale = Vector2(0.5, 0.5)
	modulate.a = 0.0
	_center = position
	_timer = randf_range(4.0, 9.0) if _grateful else randf_range(8.0, 20.0)


## True once the keeper has read all fourteen pages. Everything is looked up at
## runtime so the harness (which has no save) simply defaults to false.
func _read_gratitude() -> bool:
	if force_gratitude:
		return true
	var state := get_tree().root.get_node("GameState")
	if state == null or not state.has_method("is_achievement_unlocked"):
		return false
	return bool(state.call("is_achievement_unlocked", "last_letter"))


func _process(delta: float) -> void:
	if _passing:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_pass()


## One crossing, left-to-right or right-to-left at random. The streak
## fades in, glints through, and fades out — never twice at once.
func _pass() -> void:
	_passing = true
	var from_left := randf() < 0.5
	var dir := 1.0 if from_left else -1.0
	var start := _center + Vector2(-SWEEP_PIXELS * dir, 0.0)
	var end := _center + Vector2(SWEEP_PIXELS * dir, 0.0)
	position = start
	scale = Vector2(0.5 * dir, 0.5)  # face the direction of travel
	var tw := create_tween()
	modulate.a = 0.0
	tw.tween_property(self, "modulate:a", 0.85, 0.25)
	# Runtime lookup: tool harnesses compile without autoload identifiers,
	# but /root/AudioManager always exists in a real run.
	var am := get_tree().root.get_node("AudioManager")
	if am != null:
		am.play_sfx("silverfin", 1.5)
	tw.parallel().tween_property(self, "position", end, SWEEP_SECONDS)
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_callback(_end_pass)


func _end_pass() -> void:
	_passing = false
	position = _center
	modulate.a = 0.0
	if _grateful:
		# The post is all read; the courier lingers a little nearer.
		_timer = randf_range(GRATITUDE_MIN_INTERVAL, GRATITUDE_MAX_INTERVAL)
	else:
		_timer = randf_range(MIN_INTERVAL, MAX_INTERVAL)
