extends VBoxContainer
class_name GuideSection

## One station section in the stats-page guide: a gold-trim header followed
## by two columns of achievement rows (even entries left, odd entries right).
## Instanced per section; rows are added via add_row().

## Child nodes exist as soon as the scene is instanced; resolve them lazily so
## configure()/add_row() work before the section is added to the tree (the
## stats page configures rows, then reparents the section into the scroll).
func _header_node() -> Node:
	return get_node("Header")
func _column(index: int) -> VBoxContainer:
	return get_node("Columns/Col%d" % index)

## Set up the header. `count_text` may be empty.
func configure(title_text: String, count_text: String) -> void:
	_header_node().configure(title_text, count_text)

## Add a pre-built row to column 0 (even index) or column 1 (odd index).
func add_row(row: Control, parity: int) -> void:
	var target := _column(0) if parity % 2 == 0 else _column(1)
	target.add_child(row)
