extends SceneTree

## Harness for the courier's Eel Run flyby (scenes/wm_courier.tscn +
## scripts/wm_courier.gd). Asserts the node survives on Eel Run, frees
## itself on every other tide, and that one pass re-arms the timer.
## Uses the exported force_tide_key debug hook and a stand-in GameSettings
## node — no calendar changes, no saves, no slots.

const CourierScene := preload("res://scenes/wm_courier.tscn")
const WorldCourierScript := preload("res://scripts/wm_courier.gd")

# ANSI color codes
const C_RESET := "\u001b[0m"
const C_BOLD := "\u001b[1m"
const C_RED := "\u001b[31m"
const C_GREEN := "\u001b[32m"
const C_YELLOW := "\u001b[33m"
const C_BLUE := "\u001b[34m"
const C_CYAN := "\u001b[36m"

var _fails := 0
var _passes := 0
var _skipped := 0
var _start_time: int = 0
var _gs: Node = null

func _initialize() -> void:
	_start_time = Time.get_ticks_msec()
	_print_header("Courier Flight Tests")

	# The GameSettings autoload loads with --path . — grab the real one
	# (fresh XDG profile) and toggle in memory only; never persisted.
	_gs = get_root().get_node("GameSettings")
	if _gs == null:
		print(C_YELLOW + "SKIP:" + C_RESET + " GameSettings autoload not found — skipping reduced-motion case")
		_skipped += 1
	elif _gs.get("reduce_motion") == true:
		_gs.set("reduce_motion", false)

	# 1) Wrong tide: frees itself, no trace.
	var wrong := CourierScene.instantiate()
	wrong.set("force_tide_key", "night_drift")
	get_root().add_child(wrong)
	await process_frame
	_check(not is_instance_valid(wrong), "courier frees itself on Night Drift")

	# 2) Eel Run: survives and starts untouched, first pass scheduled.
	var live := CourierScene.instantiate()
	live.set("force_tide_key", "eel_run")
	live.position = Vector2(300, 1050)
	get_root().add_child(live)
	await process_frame
	_check(not live.is_queued_for_deletion(), "courier survives on Eel Run")
	_check(live.modulate.a == 0.0, "courier starts hidden")
	var timer0: float = live.get("_timer")
	_check(timer0 > 0.0 and timer0 <= WorldCourierScript.FIRST_PASS_MAX_INTERVAL, "first pass arrives within %.0f s" % WorldCourierScript.FIRST_PASS_MAX_INTERVAL)

	# 3) One pass: becomes passing, fades in, sweeps, re-arms.
	live.call("_pass")
	_check(bool(live.get("_passing")), "pass marks the courier busy")
	await process_frame
	_check(live.modulate.a > 0.0, "pass fades the courier in")
	live.call("_end_pass")
	_check(not bool(live.get("_passing")), "pass completes")
	_check(live.modulate.a == 0.0, "pass cleans up the alpha")
	var timer1: float = live.get("_timer")
	_check(timer1 >= WorldCourierScript.MIN_INTERVAL and timer1 <= WorldCourierScript.MAX_INTERVAL, "pass re-arms on the long timer (%.1f)" % timer1)

	# 4) Reduced motion skips the flyby entirely.
	if _gs != null:
		_gs.set("reduce_motion", true)
		var still := CourierScene.instantiate()
		still.set("force_tide_key", "eel_run")
		get_root().add_child(still)
		await process_frame
		_check(not is_instance_valid(still), "courier frees itself under reduced motion")
		_gs.set("reduce_motion", false)

	# 5) Gratitude: once the whole post is read, the courier comes nearer.
	var gifted := CourierScene.instantiate()
	gifted.set("force_tide_key", "eel_run")
	gifted.set("force_gratitude", true)
	gifted.position = Vector2(300, 1050)
	get_root().add_child(gifted)
	await process_frame
	_check(not gifted.is_queued_for_deletion(), "grateful courier survives on Eel Run")
	var first := float(gifted.get("_timer"))
	_check(first >= WorldCourierScript.GRATEFUL_FIRST_MIN_INTERVAL and first <= WorldCourierScript.GRATEFUL_FIRST_MAX_INTERVAL, "grateful courier arrives sooner (%.1f)" % first)
	gifted.call("_pass")
	gifted.call("_end_pass")
	var short_timer := float(gifted.get("_timer"))
	_check(short_timer >= WorldCourierScript.GRATITUDE_MIN_INTERVAL and short_timer <= WorldCourierScript.GRATITUDE_MAX_INTERVAL,
		"grateful courier re-arms on the short interval (%.1f)" % short_timer)

	_print_summary()
	quit(_fails)


func _check(ok: bool, what: String) -> void:
	if ok:
		_passes += 1
		print(C_GREEN + "✓" + C_RESET + " " + what)
	else:
		_fails += 1
		print(C_RED + "✗" + C_RESET + " " + what)

func _print_header(title: String) -> void:
	var line := "═".repeat(title.length() + 4)
	print(C_CYAN + line + C_RESET)
	print(C_CYAN + "  " + title + "  " + C_RESET)
	print(C_CYAN + line + C_RESET)
	print("")

func _print_summary() -> void:
	var elapsed := (Time.get_ticks_msec() - _start_time) / 1000.0
	var total := _passes + _fails + _skipped
	var line := "─".repeat(50)
	
	print("")
	print(C_CYAN + line + C_RESET)
	print(C_BOLD + "RESULTS:" + C_RESET + " " + C_GREEN + str(_passes) + C_RESET + "  " + C_RED + "FAILED:" + C_RESET + " " + str(_fails) + "  " + C_YELLOW + "SKIPPED:" + C_RESET + " " + str(_skipped))
	var time_str := "%0.2f" % elapsed
	print(C_BOLD + "TOTAL:" + C_RESET + " " + str(total) + "  " + C_BLUE + "TIME:" + C_RESET + " " + time_str + "s")
	if _fails == 0:
		print(C_BOLD + "STATUS:" + C_RESET + " " + C_GREEN + "✓ ALL TESTS PASSED" + C_RESET)
	else:
		print(C_BOLD + "STATUS:" + C_RESET + " " + C_RED + "✗ " + str(_fails) + " TEST(S) FAILED" + C_RESET)
	print(C_CYAN + line + C_RESET)
