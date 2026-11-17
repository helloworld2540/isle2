extends CanvasLayer
class_name SlotPicker

## Pick which island the player loads. One row per owned slot, newest first,
## plus a "+ New island" button that opens a name field. The picker is a
## modal: it registers in `ui_modal_card` so the tutorial director and the
## achievement banner leave it alone, and it dims the world behind it.
##
## The picker node lives permanently in main_menu.tscn; it starts hidden and
## is shown/hidden rather than freed, because a freed child of the menu would
## have to be re-instanced on every open.

signal slot_picked(slot_id: String)
signal slot_created(slot_id: String)
signal closed

const SLOT_ROW_SCENE := preload("res://scenes/ui/slot_row.tscn")
const NAME_FIELD_SCENE := preload("res://scenes/ui/slot_name_field.tscn")

@onready var dimmer: ColorRect = $Dimmer
@onready var center: CenterContainer = $Center
@onready var panel: PanelContainer = $Center/Panel
@onready var title_label: Label = $Center/Panel/VBox/Header/Title
@onready var new_slot_btn: Button = $Center/Panel/VBox/Header/NewSlotBtn
@onready var slot_list: VBoxContainer = $Center/Panel/VBox/ListScroll/SlotList
@onready var empty_hint: Label = $Center/Panel/VBox/EmptyHint
@onready var close_btn: Button = $Center/Panel/VBox/Footer/CloseBtn

var _name_field: LineEdit = null


func _ready() -> void:
	# Start hidden; the menu calls present() when the player wants a slot.
	set_shown(false)


func set_shown(on: bool) -> void:
	if dimmer:
		dimmer.visible = on
	if center:
		center.visible = on


## Rebuild the row list from disk and show the card. Cheap: each slot's save
## is read once at menu-open time, never per frame.
func present() -> void:
	_refresh()
	set_shown(true)
	add_to_group("ui_modal_card")
	AudioManager.duck_music()
	if GameSettings.reduce_motion:
		panel.modulate.a = 1.0
		panel.scale = Vector2.ONE
	else:
		panel.modulate.a = 0.0
		panel.scale = Vector2(0.96, 0.96)
		var intro := create_tween().set_parallel(true)
		intro.tween_property(panel, "modulate:a", 1.0, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		intro.tween_property(panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _refresh() -> void:
	# Remove rows before queue_free so the layout rebuilds this frame while the
	# old rows wait for deletion at the end of it (no one-frame duplicate list).
	for child in slot_list.get_children():
		slot_list.remove_child(child)
		child.queue_free()
	_clear_name_field()
	new_slot_btn.text = "+ New island"

	var slots := SaveManager.list_slots()
	empty_hint.visible = slots.is_empty()
	if slots.is_empty():
		return

	for slot in slots:
		var row := SLOT_ROW_SCENE.instantiate() as SlotRow
		row.slot = slot
		row.selected = String(slot.get("id", "")) == SaveManager.current_slot
		row.picked.connect(_on_row_picked)
		row.rename_requested.connect(_on_row_renamed)
		row.delete_requested.connect(_on_row_deleted)
		slot_list.add_child(row)


func _on_row_picked(slot_id: String) -> void:
	# Close first (which also re-reads the summary), then hand the pick to the
	# menu — the menu switches slots, restores and leaves for the world.
	_close()
	slot_picked.emit(slot_id)


func _on_row_renamed(slot_id: String, new_name: String) -> void:
	# Rename the slot that was edited, not necessarily the active one: switch
	# temporarily, rename, then restore the active slot.
	var active := SaveManager.current_slot
	if SaveManager.switch_slot(slot_id):
		SaveManager.rename_slot(new_name)
		if not active.is_empty():
			SaveManager.switch_slot(active)
	_refresh()


func _on_row_deleted(slot_id: String) -> void:
	if slot_id.is_empty():
		return
	# Confirm before the irreversible wipe. ConfirmPanel ships at layer 95, but
	# the picker is 180 — lift the spawned card above it or it would open behind
	# the dimmer.
	var confirm: CanvasLayer = preload("res://scenes/ui/confirm_panel.tscn").instantiate()
	confirm.layer = 200
	add_child(confirm)
	confirm.confirmed.connect(func():
		var active := SaveManager.current_slot
		if SaveManager.switch_slot(slot_id):
			SaveManager.delete_slot()
			# Keep the player on the island they were on, unless that is the
			# one they just deleted.
			if slot_id != active and not active.is_empty():
				SaveManager.switch_slot(active)
		_refresh()
	)
	confirm.present("Delete this island?",
		"Every dive, sort, sale, quest and achievement on this island will be wiped for good.",
		"Delete island")


func _on_new_slot() -> void:
	# Toggle a name field rather than a second modal — the picker owns the
	# screen, so the player just types and presses enter.
	if _name_field and is_instance_valid(_name_field):
		_clear_name_field()
		new_slot_btn.text = "+ New island"
		return

	new_slot_btn.text = "Name your island…"
	_name_field = NAME_FIELD_SCENE.instantiate() as LineEdit
	_name_field.text_submitted.connect(_on_name_submitted)
	AudioManager.play_sfx("open")
	$Center/Panel/VBox.add_child(_name_field)
	_name_field.grab_focus()


## Remove the inline name field immediately (not just at frame end), so a
## rebuild never paints a stale field next to the new one.
func _clear_name_field() -> void:
	if _name_field and is_instance_valid(_name_field):
		if _name_field.get_parent():
			_name_field.get_parent().remove_child(_name_field)
		_name_field.queue_free()
	_name_field = null


func _on_name_submitted(new_text: String) -> void:
	var name := new_text.strip_edges()
	if name.is_empty():
		return
	var id := SaveManager.create_slot(name)
	if id.is_empty():
		return
	AudioManager.play_sfx("quest_complete")
	# Close before handing off, same as a row pick: the menu tears down the
	# menu scene as part of the scene change.
	_close()
	slot_created.emit(id)


func _on_close() -> void:
	_clear_name_field()
	new_slot_btn.text = "+ New island"
	remove_from_group("ui_modal_card")
	AudioManager.restore_music()
	set_shown(false)
	closed.emit()


func _close() -> void:
	_on_close()