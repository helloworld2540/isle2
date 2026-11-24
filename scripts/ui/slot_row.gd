extends PanelContainer
class_name SlotRow

## One row in the slot picker: an island's name, a one-line summary, its age,
## and three actions — load, rename, delete. The row owns its own highlight,
## so the picker only has to set `selected` before adding it to the tree.

signal picked(slot_id: String)
## Named `rename_requested` rather than `renamed`: PanelContainer already
## declares a native `renamed` signal, and shadowing it fails to parse.
signal rename_requested(slot_id: String, new_name: String)
signal delete_requested(slot_id: String)

const NAME_FIELD_SCENE := preload("res://scenes/ui/slot_name_field.tscn")

## Full parsed save for this slot (see SaveManager._read_slot_header). The
## picker sets this before add_child(); the row reads it in _ready.
var slot: Dictionary = {}

## Highlight the active island.
var selected: bool = false

@onready var name_label: Label = $HBox/VBox/NameRow/Name
@onready var meta_label: Label = $HBox/VBox/Meta
@onready var pick_btn: Button = $HBox/PickBtn

var _edit_field: LineEdit = null


func _ready() -> void:
	_apply_style()
	_refresh_text()


func _apply_style() -> void:
	var sel := StyleBoxFlat.new()
	sel.corner_radius_top_left = 10
	sel.corner_radius_top_right = 10
	sel.corner_radius_bottom_right = 10
	sel.corner_radius_bottom_left = 10
	sel.content_margin_left = 16.0
	sel.content_margin_top = 12.0
	sel.content_margin_right = 16.0
	sel.content_margin_bottom = 12.0
	if selected:
		sel.bg_color = Color(0.12, 0.22, 0.32, 0.95)
		sel.border_width_left = 2
		sel.border_width_top = 2
		sel.border_width_right = 2
		sel.border_width_bottom = 2
		sel.border_color = Color(0.55, 0.85, 1.0, 0.7)
		pick_btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		sel.bg_color = Color(0.08, 0.12, 0.18, 0.85)
		sel.border_width_left = 1
		sel.border_width_top = 1
		sel.border_width_right = 1
		sel.border_width_bottom = 1
		sel.border_color = Color(0.3, 0.55, 0.75, 0.4)
		pick_btn.modulate = Color(0.85, 0.9, 0.95, 1.0)
	add_theme_stylebox_override("panel", sel)


func _refresh_text() -> void:
	if slot.is_empty():
		return
	name_label.text = String(slot.get("name", "Island"))
	meta_label.text = "%s  ·  %s" % [
		SaveSlot.one_liner(slot),
		SaveSlot.age_label(int(slot.get("modified", 0))),
	]


func _on_pick() -> void:
	AudioManager.play_sfx("pickup")
	picked.emit(String(slot.get("id", "")))


func _on_edit() -> void:
	if _edit_field and is_instance_valid(_edit_field):
		_clear_edit_field()
		return
	AudioManager.play_sfx("open")
	_edit_field = NAME_FIELD_SCENE.instantiate() as LineEdit
	_edit_field.text = String(slot.get("name", "Island"))
	_edit_field.text_submitted.connect(_on_edit_submitted)
	$HBox/VBox.add_child(_edit_field)
	_edit_field.grab_focus()


func _clear_edit_field() -> void:
	if _edit_field and is_instance_valid(_edit_field):
		if _edit_field.get_parent():
			_edit_field.get_parent().remove_child(_edit_field)
		_edit_field.queue_free()
	_edit_field = null


func _on_edit_submitted(new_text: String) -> void:
	var name := new_text.strip_edges()
	if name.is_empty():
		return
	rename_requested.emit(String(slot.get("id", "")), name)
	_clear_edit_field()


func _on_delete() -> void:
	AudioManager.play_sfx("open")
	delete_requested.emit(String(slot.get("id", "")))