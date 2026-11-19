extends ScrollContainer
class_name DragScrollContainer

## Adds mouse drag-to-scroll on top of the built-in touch/gesture scrolling,
## so desktop players can fling lists the same way phone players do.
##
## How it behaves:
##  - A press and short travel counts as a click (children still get it).
##  - Once the pointer travels past `drag_threshold` pixels vertically, the
##    gesture converts into a scroll drag and clicks under the finger are
##    eaten for the rest of that press.
##  - Inertial-ish feel: `drag_speed` scales finger speed to scroll speed.
##  - Honors the project-wide `reduce_motion` flag: no easing is used either
##    way, but the flag is respected by snapping drags 1:1 (no multiplier).
##
## Input is handled in `_input` (before GUI), not `_gui_input`, because the
## deepest child under the pointer (a Label with the default MOUSE_FILTER_STOP)
## would otherwise swallow the event and the scroll container would never see
## it — dragging worked only over the empty background, not the content.
##
## Node-first: instanced by scenes (shop, guide overlay). No runtime node
## construction anywhere.

@export var drag_threshold: float = 8.0 ## px of travel before a press becomes a drag
@export var drag_speed: float = 1.0      ## 1.0 = finger-speed; >1 flings faster

var _dragging := false
var _drag_distance := 0.0
var _press_y := 0.0
var _start_scroll := 0


func _ready() -> void:
	# Chunky scrollbars: a bigger grabber target for fingers and small
	# windows. The width has to come from the bar's theme minimum (its
	# "scroll" stylebox), not `custom_minimum_size`: ScrollContainer reserves
	# the gutter from `get_minimum_size()`, so a custom minimum left the bar
	# drawn *over* the content by the extra width. A transparent stylebox
	# with 13 px content margins reserves a real 26 px gutter instead.
	_fatten_bar(get_v_scroll_bar(), true)
	_fatten_bar(get_h_scroll_bar(), false)


func _fatten_bar(bar: ScrollBar, vertical: bool) -> void:
	if bar == null:
		return
	var pad := StyleBoxEmpty.new()
	if vertical:
		pad.content_margin_left = 13
		pad.content_margin_right = 13
	else:
		pad.content_margin_top = 13
		pad.content_margin_bottom = 13
	bar.add_theme_stylebox_override("scroll", pad)


func _input(event: InputEvent) -> void:
	# Never steal input from something drawn over us (modal overlays, menus).
	if not is_visible_in_tree():
		return
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		if event.pressed:
			var hovered := get_viewport().gui_get_hovered_control()
			if Rect2(global_position, size).has_point(event.position) and _can_drag_from(hovered):
				_begin_press(event.position.y)
		elif _dragging:
			if _end_press():
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _dragging:
		_drag_to(event)
		if _is_scrolling():
			get_viewport().set_input_as_handled()


## Start a drag unless the press landed on something that needs the gesture
## for itself. Labels/panels are fine; sliders and text editing need drags.
func _can_drag_from(control: Control) -> bool:
	if control == null:
		# No hover info (press exactly at once): trust the rect check.
		return true
	if control is Range:
		return false
	if control is LineEdit or control is TextEdit or control is OptionButton:
		return false
	# Something outside our subtree — only allow it if we have no better
	# target (e.g. the empty background of the container itself).
	return not (hovered_is_foreign(control))


func hovered_is_foreign(control: Control) -> bool:
	# True when the hovered control is neither us nor a descendant — i.e. an
	# overlay or sibling painted above us. Dragging must scroll only when the
	# pointer is over our own content (or its empty background).
	if control == self:
		return false
	return not is_ancestor_of(control)


func _begin_press(y: float) -> void:
	_dragging = true
	_drag_distance = 0.0
	_press_y = y
	_start_scroll = scroll_vertical


func _drag_to(event: InputEventMouseMotion) -> void:
	if not _dragging:
		return
	var offset := event.position.y - _press_y
	_drag_distance = maxf(_drag_distance, absf(offset))
	if _drag_distance >= drag_threshold:
		var mult := 1.0 if GameSettings.reduce_motion else drag_speed
		scroll_vertical = int(round(float(_start_scroll) - offset * mult))


func _is_scrolling() -> bool:
	return _drag_distance >= drag_threshold


## Returns true when the release should be eaten (it ended a scroll drag).
func _end_press() -> bool:
	var was_scrolling := _is_scrolling()
	_dragging = false
	_drag_distance = 0.0
	return was_scrolling
