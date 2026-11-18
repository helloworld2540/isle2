extends HBoxContainer
class_name GuideHeader

## One section header in the stats-page guide: an upper-cased title (gold
## trim) and an earned/total count (sea-blue). Instanced per section instead
## of built with .new().

@onready var _title: Label = $Title
@onready var _count: Label = $Count

## Configure the header. `count_text` may be empty to hide the count label.
func configure(title_text: String, count_text: String) -> void:
	_title.text = title_text
	_title.add_theme_font_size_override("font_size", 20)
	_title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.35, 1.0))
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if count_text.is_empty():
		_count.visible = false
		return
	_count.text = count_text
	_count.add_theme_font_size_override("font_size", 20)
	_count.add_theme_color_override("font_color", Color(0.62, 0.86, 1.0, 0.8))
