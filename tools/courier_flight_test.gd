extends SceneTree

## Harness for the courier's Eel Run flyby (scenes/wm_courier.tscn +
## scripts/wm_courier.gd). Asserts the node survives on Eel Run, frees
## itself on every other tide, and that one pass re-arms the timer.
## Uses the exported force_tide_key debug hook and a stand-in GameSettings
## node — no calendar changes, no saves, no slots.

const CourierScene := preload("res://scenes/wm_courier.tscn")

var _fails := 0
var _gs: Node = null

func _initialize() -> void:
	# The GameSettings autoload loads with --path . — grab the real one
	# (fresh XDG profile) and toggle in memory only; never persisted.
	_gs = get_root().get_node_or_null("GameSettings")
	if _gs == null:
		print("courier_flight_test: GameSettings autoload not found — skipping reduced-motion case")
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
	_check(timer0 > 0.0 and timer0 <= 20.0, "first pass arrives within 20 s")

	# 3) One pass: becomes passing, fades in, sweeps, re-arms.
	live.call("_pass")
	_check(bool(live.get("_passing")), "pass marks the courier busy")
	await process_frame
	_check(live.modulate.a > 0.0, "pass fades the courier in")
	live.call("_end_pass")
	_check(not bool(live.get("_passing")), "pass completes")
	_check(live.modulate.a == 0.0, "pass cleans up the alpha")
	var timer1: float = live.get("_timer")
	_check(timer1 >= 30.0 and timer1 <= 65.0, "pass re-arms on the long timer (%.1f)" % timer1)

	# 4) Reduced motion skips the flyby entirely.
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
	_check(first >= 4.0 and first <= 9.0, "grateful courier arrives sooner (%.1f)" % first)
	gifted.call("_pass")
	gifted.call("_end_pass")
	var short_timer := float(gifted.get("_timer"))
	_check(short_timer >= 16.0 and short_timer <= 34.0,
		"grateful courier re-arms on the short interval (%.1f)" % short_timer)

	print("courier_flight_test: %d failure(s)" % _fails)
	quit(_fails)


func _check(ok: bool, what: String) -> void:
	print(("  ok  " if ok else "[FAIL] ") + what)
	if not ok:
		_fails += 1
