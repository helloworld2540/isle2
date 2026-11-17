extends SceneTree

## Temporary UI regression harness for the slot picker. Seeds two slots, boots
## the real main menu, and drives the picker's row list + rename flow.
const SaveManagerScript := preload("res://scripts/save_manager.gd")

var _fails := 0

func _initialize() -> void:
	if DirAccess.dir_exists_absolute(SaveManagerScript.SLOT_DIR):
		print("SKIP: player data present")
		quit(0)
		return
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
	print("slot_ui_test: %d failure(s)" % _fails)
	quit(_fails)

func _check(ok: bool, what: String) -> void:
	print(("  ok  " if ok else "[FAIL] ") + what)
	if not ok:
		_fails += 1

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
