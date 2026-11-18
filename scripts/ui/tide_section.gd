extends VBoxContainer
class_name TideSection

## The TIDE section of the stats-page guide: a header ("THE TIDE"), four
## tide-condition chips in a row, and a closing note. Authored scene — the
## section, header and chips container are nodes; only the chips are instanced
## per condition via add_chip().

@onready var _header = $Header
@onready var _chips = $Chips
@onready var _note = $Note

## Set up the header and the closing note.
func configure() -> void:
	_header.configure("THE TIDE", "")
	_note.text = "Four days, one rotation. The HUD reads today — a dockhand sells tomorrow."
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.add_theme_font_size_override("font_size", 20)
	_note.add_theme_color_override("font_color", Color(0.62, 0.72, 0.85, 0.8))

## Add a pre-built tide chip to the row. The panel stylebox (today vs
## ordinary) is applied by TideChip.configure() itself.
func add_chip(chip) -> void:
	_chips.add_child(chip)
