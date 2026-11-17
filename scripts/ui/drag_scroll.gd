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
	# windows. Height matters little — the bar fills the container — so the
	# width/height is what we fatten up.
	var bar := get_v_scroll_bar()
	if bar:
		bar.custom_minimum_size.x = 26
	var hbar := get_h_scroll_bar()
	if hbar:
		hbar.custom_minimum_size.y = 26


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_begin_press(event.position.y)
			else:
				_end_press(event)
			return
	elif event is InputEventMouseMotion and _dragging:
		_drag_to(event)


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
		accept_event()


func _end_press(event: InputEventMouseButton) -> void:
	if _drag_distance >= drag_threshold:
		# Eat the release so the widget under the finger does not also click.
		accept_event()
	_dragging = false
