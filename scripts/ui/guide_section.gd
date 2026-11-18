extends VBoxContainer
class_name GuideSection

## One station section in the stats-page guide: a gold-trim header followed
## by two columns of achievement rows (even entries left, odd entries right).
## Instanced per section; rows are added via add_row().

@onready var _header = $Header
@onready var _columns = $Columns
@onready var _col0: VBoxContainer = $Columns/Col0
@onready var _col1: VBoxContainer = $Columns/Col1

## Set up the header. `count_text` may be empty.
func configure(title_text: String, count_text: String) -> void:
	_header.configure(title_text, count_text)

## Add a pre-built row to column 0 (even index) or column 1 (odd index).
func add_row(row: Control, parity: int) -> void:
	var target := _col0 if parity % 2 == 0 else _col1
	target.add_child(row)
