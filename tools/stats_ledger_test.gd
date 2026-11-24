extends SceneTree

## Stats Tide Ledger runtime harness.
##
## Opens the real stats page's Tide Ledger overlay and walks the per-bottle
## read/unread wiring: a marked-read note shows the "✓  " mark and stays
## tappable, an unmarked note shows the "still out there" hint and locks. Closes
## through the real `_close_ledger()` handler and proves the overlay hides again.
##
## Run with autoloads:
##   XDG_DATA_HOME=/tmp/isle2_audit_<n> godot --headless --path . -s tools/stats_ledger_test.gd
## Wired into tools/all_audits.sh.

var StatsMenuScript: GDScript

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


func _initialize() -> void:
	_start_time = Time.get_ticks_msec()
	await process_frame
	_print_header("Stats Tide Ledger Tests")
	await _run()
	_print_summary()
	quit(_fails)


func _run() -> void:
	StatsMenuScript = load("res://scripts/stats_menu.gd") as GDScript
	var StatsScene: PackedScene = load("res://scenes/stats_menu.tscn") as PackedScene
	var stats := StatsScene.instantiate()
	root.add_child(stats)
	await process_frame
	var overlay := stats.get_node("LedgerOverlay") as Control
	_check(overlay != null, "stats scene carries a LedgerOverlay")
	var gs := root.get_node("GameState")
	_check(gs != null, "GameState autoload present")
	if gs == null:
		return
	var ledger_ids: Array = StatsMenuScript.LEDGER_IDS
	var ledger_buttons: Array = StatsMenuScript.LEDGER_BUTTONS
	_check(ledger_ids.size() == 8, "tide ledger lists eight bottles (%d)" % ledger_ids.size())
	_check(ledger_buttons.size() == ledger_ids.size(), "ledger buttons align 1:1 with ledger ids by index (%d/%d)" % [ledger_buttons.size(), ledger_ids.size()])

	# Mark two bottles read (in-memory only; the isolated profile keeps this off
	# any real save), leave the rest unmarked.
	gs.call("mark_story_read", "bottle_tide")
	gs.call("mark_story_read", "bottle_gull")
	await process_frame
	stats.call("_open_ledger")
	await process_frame
	_check(overlay.visible, "ledger overlay opens visible")
	for i in ledger_ids.size():
		var id := String(ledger_ids[i])
		var button := stats.get_node("LedgerOverlay/Panel/VBox/" + String(ledger_buttons[i])) as Button
		_check(button != null, "ledger scene has button %s" % String(ledger_buttons[i]))
		var read: bool = bool(gs.call("is_story_read", id))
		if read:
			_check(String(button.text).begins_with("✓  "), "read bottle %s shows the mark (%s)" % [id, String(button.text)])
			_check(not button.disabled, "read bottle %s stays tappable" % id)
		else:
			_check(String(button.text).contains("still out there"), "unread bottle %s hints it is out there (%s)" % [id, String(button.text)])
			_check(button.disabled, "unread bottle %s is disabled" % id)
	stats.call("_close_ledger")
	await process_frame
	_check(not overlay.visible, "ledger overlay closes on _close_ledger")
	stats.queue_free()
	await process_frame
	_check(not CardQueue.is_busy(), "card queue idle after the ledger harness")


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
	print(C_CYAN + "  " + title + C_RESET)
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
