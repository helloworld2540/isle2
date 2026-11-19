extends HBoxContainer
class_name GuideHeader

## One section header in the stats-page guide: an upper-cased title (gold
## trim) and an earned/total count (sea-blue). Instanced per section instead
## of built with .new().

func _title_node() -> Label:
	return get_node("Title")
func _count_node() -> Label:
	return get_node("Count")

## Configure the header. `count_text` may be empty to hide the count label.
func configure(title_text: String, count_text: String) -> void:
	var title := _title_node()
	var count := _count_node()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.35, 1.0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if count_text.is_empty():
		count.visible = false
		return
	count.text = count_text
	count.add_theme_font_size_override("font_size", 24)
	count.add_theme_color_override("font_color", Color(0.62, 0.86, 1.0, 0.8))
