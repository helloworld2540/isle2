extends Node

## Emoji presentation: keeps the bundled Noto Color Emoji font in the fallback
## chain of the project UI fonts, so emoji render through it instead of falling
## back to whatever system emoji font the platform provides.

const EMOJI_FONT_RESOURCE := "res://fonts/NotoColorEmoji-Regular.ttf"

## Theme resources that supply fonts to the UI (project default + control theme).
const THEME_RESOURCES: Array[String] = [
	"res://resources/default.tres",
	"res://resources/control_theme.tres",
]

## Control types whose fonts should carry the emoji fallback.
const FONT_TYPES: Array[String] = [
	"Button",
	"Label",
	"RichTextLabel",
]

var _emoji_font: FontFile


func _ready() -> void:
	_apply_emoji_font()


func _apply_emoji_font() -> void:
	_emoji_font = load(EMOJI_FONT_RESOURCE) as FontFile
	if _emoji_font == null:
		push_warning("EmojiFont: bundled emoji font not found at %s" % EMOJI_FONT_RESOURCE)
		return
	for theme_resource in THEME_RESOURCES:
		var theme := load(theme_resource) as Theme
		if theme == null:
			continue
		_apply_fallback(theme.default_font)
		for control_type in FONT_TYPES:
			_apply_fallback(theme.get_font("font", control_type))


func _apply_fallback(font: Font) -> void:
	if not (font is FontFile):
		return
	var font_file := font as FontFile
	font_file.allow_system_fallback = true
	if not _has_emoji_fallback(font_file):
		font_file.fallbacks = [ _emoji_font ]


func _has_emoji_fallback(font_file: FontFile) -> bool:
	for fallback_font in font_file.fallbacks:
		if fallback_font == _emoji_font:
			return true
	return false
