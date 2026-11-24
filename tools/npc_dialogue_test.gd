extends SceneTree

## NPC dialogue card behaviour harness.
##
## Drives the real conversation card (scenes/ui/npc_dialogue.tscn) through its
## pacing contract with the island-wide CardQueue:
##   1. reduced motion -> the typewriter completes immediately on present;
##   2. the OK button arms "Next" mid-conversation and reads "OK" on the final
##      line, via advance();
##   3. the final advance dismisses: the closed signal fires, the card frees,
##      and the card queue goes idle;
##   4. full motion -> the typewriter starts on present and advance() completes
##      the current line before moving to the next one.
##
## Run with autoloads:
##   XDG_DATA_HOME=/tmp/isle2_audit_<n> godot --headless --path . -s tools/npc_dialogue_test.gd
## Wired into tools/all_audits.sh.

const DIALOGUE_SCENE := "res://scenes/ui/npc_dialogue.tscn"
const CONVO_LINES := ["First line of the keeper's greeting.", "Second line, and now the farewell."]

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
var _closed_count := 0


func _initialize() -> void:
	_start_time = Time.get_ticks_msec()
	await process_frame
	_print_header("NPC Dialogue Tests")
	await _run()
	_print_summary()
	quit(_fails)


func _run() -> void:
	var settings := root.get_node("GameSettings")
	_check(not CardQueue.is_busy(), "card queue starts idle")

	# --- Phase 1: reduced motion -> the typewriter completes instantly.
	settings.set("reduce_motion", true)
	var d1 := await _open_dialogue("Keeper", CONVO_LINES)
	var ok1 := d1.get_node("Center/Panel/VBox/OkButton") as Button
	_check(d1.get_node("Center/Panel/VBox/QuestBox/TurnIn") != null, "quest box TurnIn button is wired")
	_check(d1.has_signal("turn_in_requested"), "turn_in_requested signal declared")
	await process_frame
	_check(not bool(d1.get("_typing")), "reduce_motion: typewriter completes immediately")
	_check(ok1.text == "Next", "reduce_motion: first line arms the OK button (Next)")
	d1.call("advance")
	_check(ok1.text == "OK", "reduce_motion: advance moves to the final line")
	d1.call("advance")
	await process_frame
	await process_frame
	_check(_closed_count > 0, "reduce_motion: final advance dismisses the card")
	_check(not is_instance_valid(d1), "reduce_motion: card freed after dismiss")
	_check(not CardQueue.is_busy(), "reduce_motion: card queue idle after dismiss")


	# --- Phase 2: full motion -> the typewriter crawls, advance finishes a line.
	settings.set("reduce_motion", false)
	var d2 := await _open_dialogue("Keeper", CONVO_LINES)
	var ok2 := d2.get_node("Center/Panel/VBox/OkButton") as Button
	await process_frame
	_check(bool(d2.get("_typing")), "full motion: typewriter starts on the first line")
	_check(ok2.text == "Next", "full motion: first line arms the OK button (Next)")
	d2.call("advance")
	_check(bool(d2.get("_typing")), "full motion: advance completes the line and starts the next")
	_check(ok2.text == "OK", "full motion: second line is the final line")
	d2.call("advance")
	await process_frame
	await process_frame
	_check(_closed_count > 0, "full motion: final advance dismisses the card")
	_check(not is_instance_valid(d2), "full motion: card freed after dismiss")
	_check(not CardQueue.is_busy(), "full motion: card queue idle after dismiss")


## Instantiate the real dialogue card, add it to the root, wait a frame for the
## shared card queue to grant the screen, then present the conversation.
func _open_dialogue(npc_title: String, lines: Array) -> Node:
	var scene := load("res://scenes/ui/npc_dialogue.tscn") as PackedScene
	var dialogue := scene.instantiate()
	root.add_child(dialogue)
	await process_frame
	dialogue.call("present", npc_title, lines)
	dialogue.connect("closed", _on_closed)
	await process_frame
	return dialogue


func _on_closed() -> void:
	_closed_count += 1


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
