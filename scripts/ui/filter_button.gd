extends Button
class_name FilterButton

## One station filter chip in the stats-page guide: a toggle-mode button
## (All / Reef / Bench / Shop / Folk / Island / Hidden / Tide). Instanced per
## filter instead of built with Button.new().

signal pressed_filter(String)

## Set the label and toggle state. `key` is the filter key; `label` is the
## compact display text; `active` selects the pressed look.
func configure(key: String, label: String, active: bool) -> void:
	text = label
	toggle_mode = true
	button_pressed = active
	custom_minimum_size = Vector2(0, 44)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_font_size_override("font_size", 24)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pressed.connect(func(): pressed_filter.emit(key))
