extends Node

## Font fallback chain: keeps the bundled coverage fonts at the end of every UI
## font's fallback chain, so glyphs the primary fonts lack (arrows and marks
## like → ≈ ★ ✓ ✦, geometric shapes, emoji) render on every platform.
##
## This matters most in the web export: browsers expose no system fonts to
## Godot, so `allow_system_fallback` cannot fill the gaps the way it does on
## desktop. Every glyph the game uses must therefore come from a bundled font.
##
## The chain is ordered so a font never falls back to itself or, transitively,
## back to a font earlier in the list — that would form a fallback cycle.

## Bundled fonts that together cover every glyph the game uses, in priority
## order. The first is the body font (broad Latin and punctuation coverage);
## the rest add glyphs the body font lacks.
const COVERAGE_FONTS: Array[String] = [
	"res://fonts/CenturyGothic.ttf",
	"res://fonts/NotoSansSymbols2-Regular.ttf",
	"res://fonts/NotoColorEmoji-Regular.ttf",
]

## Theme resources that supply fonts to the UI (project default + control theme).
const THEME_RESOURCES: Array[String] = [
	"res://resources/default.tres",
	"res://resources/control_theme.tres",
]

## Control types whose fonts should carry the fallback chain.
const FONT_TYPES: Array[String] = [
	"Button",
	"Label",
	"RichTextLabel",
]

var _coverage: Array[Font] = []


func _ready() -> void:
	_coverage = _load_coverage()
	_apply_fallbacks()


func _load_coverage() -> Array[Font]:
	var result: Array[Font] = []
	for path in COVERAGE_FONTS:
		var font := load(path) as Font
		if font == null:
			push_warning("FontFallbacks: bundled font not found at %s" % path)
			continue
		result.append(font)
	return result


func _apply_fallbacks() -> void:
	if _coverage.is_empty():
		return
	for theme_resource in THEME_RESOURCES:
		var theme := load(theme_resource) as Theme
		if theme == null:
			continue
		_apply_chain(theme.default_font)
		for control_type in FONT_TYPES:
			_apply_chain(theme.get_font("font", control_type))
	# The project default font can be set independently of the project theme.
	var project_font: Variant = ProjectSettings.get_setting("gui/theme/custom_font")
	if project_font is String:
		project_font = load(project_font as String) if not (project_font as String).is_empty() else null
	_apply_chain(project_font as Font)


func _apply_chain(font: Font) -> void:
	if font == null:
		return
	# Rebuild from the font's own fallbacks so re-runs stay idempotent and any
	# fallbacks authored elsewhere (import settings, other scripts) survive.
	var merged: Array[Font] = []
	for existing in font.fallbacks:
		merged.append(existing)
	# Only append coverage fonts after this one in the list, so chains stay
	# acyclic; a font that is not itself a coverage font gets all of them.
	var first := _coverage.find(font) + 1
	for i in range(first, _coverage.size()):
		var fallback := _coverage[i]
		if not merged.has(fallback):
			merged.append(fallback)
	if merged.size() != font.fallbacks.size():
		font.fallbacks = merged
