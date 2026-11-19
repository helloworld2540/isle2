extends Label
class_name GuideFooter

## The closing footer label in the stats-page guide overlay: "✦ Legends glow
## gold — the island's last words." Centered, gold-tinted, 20 px.
## Authored scene instead of Label.new().

func _ready() -> void:
	text = "✦ Legends glow gold — the island's last words."
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_font_size_override("font_size", 24)
	add_theme_color_override("font_color", Color(1.0, 0.86, 0.35, 0.7))
