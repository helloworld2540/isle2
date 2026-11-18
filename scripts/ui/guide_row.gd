extends PanelContainer
class_name GuideRow

## One achievement row in the stats-page guide overlay: a glyph (earned /
## not earned), a title, and a subtitle, wrapped in a styled panel.
## Instanced once per achievement instead of building nodes with .new().

@onready var _glyph: Label = $HBox/Glyph
@onready var _title: Label = $HBox/TextColumn/Title
@onready var _subtitle: Label = $HBox/TextColumn/Subtitle

## Fill the row from an achievement definition dict plus its earned state.
## `legendary` selects the gold banner dress used for the island's last words.
## The panel stylebox (bg, border, shadow) matches the earned / legendary
## combination exactly as the old code-built rows did.
func configure(def: Dictionary, earned: bool, legendary: bool) -> void:
	var id := String(def.get("id", ""))
	var title := String(def.get("title", id))
	var subtitle := String(def.get("subtitle", ""))
	_glyph.text = "✓" if earned else "○"
	_title.text = title
	_subtitle.text = subtitle
	# Colours: earned rows read bright, legendary ones glow gold, locked
	# legendary rows keep a muted bronze so they still whisper "not yet".
	var title_col: Color
	var sub_col: Color
	var glyph_col: Color
	var bg: Color
	var border: Color
	var shadow: Color
	var shadow_size: float
	if legendary and earned:
		title_col = Color(1.0, 0.93, 0.6, 1.0)
		sub_col = Color(0.92, 0.82, 0.58, 0.9)
		glyph_col = Color(1.0, 0.86, 0.35, 1.0)
		bg = Color(0.13, 0.09, 0.02, 0.96)
		border = Color(1.0, 0.88, 0.42, 1.0)
		shadow = Color(1.0, 0.82, 0.3, 0.2)
		shadow_size = 8
	elif earned:
		title_col = Color(0.7, 0.92, 1.0, 1.0)
		sub_col = Color(0.62, 0.75, 0.9, 0.9)
		glyph_col = Color(1.0, 0.86, 0.35, 1.0)
		bg = Color(0.07, 0.10, 0.15, 0.95)
		border = Color(1.0, 0.84, 0.35, 0.75)
		shadow = Color(0, 0, 0, 0)
		shadow_size = 0
	elif legendary:
		title_col = Color(0.75, 0.68, 0.48, 0.85)
		sub_col = Color(0.6, 0.53, 0.38, 0.55)
		glyph_col = Color(0.5, 0.62, 0.8, 0.55)
		bg = Color(0.09, 0.07, 0.04, 0.8)
		border = Color(0.9, 0.78, 0.4, 0.35)
		shadow = Color(0, 0, 0, 0)
		shadow_size = 0
	else:
		title_col = Color(0.58, 0.68, 0.84, 0.85)
		sub_col = Color(0.5, 0.6, 0.75, 0.5)
		glyph_col = Color(0.5, 0.62, 0.8, 0.55)
		bg = Color(0.05, 0.08, 0.13, 0.75)
		border = Color(0.4, 0.7, 0.9, 0.2)
		shadow = Color(0, 0, 0, 0)
		shadow_size = 0
	_title.add_theme_color_override("font_color", title_col)
	_subtitle.add_theme_color_override("font_color", sub_col)
	_glyph.add_theme_color_override("font_color", glyph_col)
	var box := StyleBoxFlat.new()
	box.content_margin_left = 12.0
	box.content_margin_right = 12.0
	box.content_margin_top = 8.0
	box.content_margin_bottom = 8.0
	box.set_corner_radius_all(10)
	box.set_border_width_all(2)
	box.bg_color = bg
	box.border_color = border
	box.shadow_color = shadow
	box.shadow_size = shadow_size
	add_theme_stylebox_override("panel", box)
