extends VBoxContainer
class_name TideSection

## The TIDE section of the stats-page guide: a header ("THE TIDE"), four
## tide-condition chips in a row, and a closing note. Authored scene — the
## section, header and chips container are nodes; only the chips are instanced
## per condition via add_chip().

func _header_node() -> Node:
	return get_node("Header")
func _chips_node() -> HBoxContainer:
	return get_node("Chips")
func _note_node() -> Label:
	return get_node("Note")

## Set up the header and the closing note.
func configure() -> void:
	var header := _header_node()
	header.configure("THE TIDE", "")
	var note := _note_node()
	note.text = "Four days, one rotation. The HUD reads today — a dockhand sells tomorrow."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 24)
	note.add_theme_color_override("font_color", Color(0.62, 0.72, 0.85, 0.8))

## Add a pre-built tide chip to the row. The panel stylebox (today vs
## ordinary) is applied by TideChip.configure() itself.
func add_chip(chip) -> void:
	_chips_node().add_child(chip)
