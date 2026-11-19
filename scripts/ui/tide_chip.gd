extends PanelContainer
class_name TideChip

## One tide-condition chip in the stats-page guide's TIDE section: a title
## (with a "· today" suffix when it is the current tide) and a blurb, inside
## a styled panel. Instanced per tide condition instead of built with .new().

func _title_node() -> Label:
	return get_node("VBox/Title")
func _blurb_node() -> Label:
	return get_node("VBox/Blurb")

## Configure the chip from a tide condition dict. `is_today` adds the "·
## today" suffix and swaps to the selected panel stylebox (sea-foam edge).
func configure(condition: Dictionary, is_today: bool) -> void:
	var key := String(condition.get("key", ""))
	var title := String(condition.get("title", key))
	if is_today:
		title = "%s · today" % title
	var blurb := String(condition.get("summary", condition.get("blurb", "")))
	_title_node().text = title
	_blurb_node().text = blurb
	_title_node().add_theme_font_size_override("font_size", 24)
	_title_node().add_theme_color_override("font_color", Color(0.68, 0.95, 0.88, 1.0))
	_blurb_node().add_theme_font_size_override("font_size", 24)
	_blurb_node().add_theme_color_override("font_color", Color(0.6, 0.72, 0.86, 0.85))
	_title_node().autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_blurb_node().autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var box := StyleBoxFlat.new()
	box.content_margin_left = 10.0
	box.content_margin_right = 10.0
	box.content_margin_top = 8.0
	box.content_margin_bottom = 8.0
	box.set_corner_radius_all(10)
	box.set_border_width_all(2)
	if is_today:
		box.bg_color = Color(0.10, 0.12, 0.14, 1.0)
		box.border_color = Color(1.0, 0.84, 0.35, 0.85)
	else:
		box.bg_color = Color(0.06, 0.10, 0.16, 0.95)
		box.border_color = Color(0.4, 0.7, 0.9, 0.3)
	add_theme_stylebox_override("panel", box)
