extends SceneTree

## Temporary UI regression harness for the slot picker. Seeds two slots, boots
## the real main menu, and drives the picker's row list + rename flow.
const SaveManagerScript := preload("res://scripts/save_manager.gd")

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
	if DirAccess.dir_exists_absolute(SaveManagerScript.SLOT_DIR):
		print(C_YELLOW + "SKIP:" + C_RESET + " player data present")
		quit(0)
		return
	_print_header("Slot Picker UI Tests")
	var sm: Node = SaveManagerScript.new()
	root.add_child(sm)
	sm.create_slot("Alpha")
	sm.ensure_bound()
	sm.create_slot("Beta")

	var menu: Control = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	await process_frame

	var picker = menu.get_node("SlotPicker")
	_check(not picker.get_node("Dimmer").visible, "picker starts hidden")
	picker.present()
	await process_frame
	_check(picker.get_node("Dimmer").visible, "dimmer shown")
	_check(picker.get_node("Center").visible, "panel shown")
	var rows := picker.get_node("Center/Panel/VBox/ListScroll/SlotList").get_children()
	_check(rows.size() == 2, "two rows (%d)" % rows.size())
	var names: Array[String] = []
	for r in rows:
		names.append(r.get_node("HBox/VBox/NameRow/Name").text)
	_check(names.has("Alpha") and names.has("Beta"), "row names %s" % [names])

	# Rename the inactive slot from its row; the picker must temp-switch and
	# restore the active slot afterwards.
	var target = null
	for r in rows:
		if r.get_node("HBox/VBox/NameRow/Name").text == "Alpha":
			target = r
	if target:
		target._on_edit_submitted("Alpine")
		await process_frame
	_check(sm.list_slots().filter(func(s): return String(s.get("name")) == "Alpine").size() == 1, "rename persisted")
	_check(sm.has_save(), "active slot intact after rename")

	# Delete the inactive island through the picker's confirm card: the spawned
	# CanvasLayer must sit above the picker's own layer or it opens invisibly.
	var active_before: String = sm.current_slot
	picker._on_row_deleted("alpha")
	await process_frame
	var confirm: CanvasLayer = picker.get_child(picker.get_child_count() - 1)
	_check(confirm.layer > picker.layer, "confirm above picker (%d > %d)" % [confirm.layer, picker.layer])
	confirm._on_confirm()
	await process_frame
	_check(sm.list_slots().size() == 1, "delete removes row")
	_check(sm.current_slot == active_before, "delete keeps active island")

	# Close hides both layers again.
	picker._on_close()
	await process_frame
	_check(not picker.get_node("Dimmer").visible, "dimmer hidden after close")
	_check(not picker.get_node("Center").visible, "panel hidden after close")

	menu.queue_free()
	await process_frame
	_wipe_slots()
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

func _wipe_slots() -> void:
	var root_dir := DirAccess.open(SaveManagerScript.SLOT_DIR)
	if root_dir:
		for sub in root_dir.get_directories():
			var path := "%s/%s" % [SaveManagerScript.SLOT_DIR, sub]
			var d := DirAccess.open(path)
			if d:
				for f in d.get_files():
					DirAccess.remove_absolute("%s/%s" % [path, f])
			DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(SaveManagerScript.SLOT_DIR)
