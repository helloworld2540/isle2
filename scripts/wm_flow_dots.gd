extends Node2D

## Glowing pulses that travel along the loop trail (Reef Rescue → Upcycle →
## Shop) to show the intended island-loop direction.
## Paints itself in _draw(); no child nodes are created at runtime.
##
## When the route advisor picks a next stop, the trail segment that leads into
## that stop brightens to gold, so the HUD line, the glowing portal pad and the
## dots all point at the same place. NPC errands (station == "npc") leave the
## dots neutral: the turn-in is marked by the gold star over the islander.

@export var source: NodePath = ^"../LoopPath"
## Must match the order of the portals on the loop path. The first N points of
## the Line2D are the portals; any return waypoints are appended after them.
@export var station_ids: PackedStringArray = PackedStringArray(["reef_rescue", "upcycle", "shop"])
@export var spacing := 56.0
@export var dot_radius := 4.2
@export var speed := 115.0
@export var dot_color := Color(0.72, 1.0, 1.0, 0.95)
@export var glow_color := Color(0.45, 0.9, 1.0, 0.22)
## Warmer, brighter treatment for the leg that leads to the advised stop.
@export var hint_color := Color(1.0, 0.88, 0.42, 1.0)
@export var hint_glow_color := Color(1.0, 0.72, 0.22, 0.36)
## Static direction chevrons spaced along the trail; unlike the dots they are
## always visible, so the loop's direction is legible at a glance.
@export var chevron_spacing := 150.0
@export var chevron_offset := 75.0
@export var chevron_length := 13.0
@export var chevron_half_width := 7.0
@export var chevron_width := 2.3
@export var chevron_color := Color(1.0, 1.0, 1.0, 0.55)

var _points: PackedVector2Array = []
var _lengths: PackedFloat32Array = []
var _total := 0.0
var _phase := 0.0
var _hint_station := ""
## Distances along the trail (start, end) for the highlighted leg.
var _hint_range := Vector2(-1.0, -1.0)
var _reduce_motion := false


func _ready() -> void:
	var line := get_node_or_null(source)
	if line is Line2D:
		_points = (line as Line2D).points
	_build_lengths()
	z_index = 2
	_reduce_motion = GameSettings.reduce_motion


## Called by the HUD whenever the route advice changes. The station is one of
## station_ids, or "" for "no leg to highlight" (e.g. an NPC errand).
func set_hint(station: String) -> void:
	if station == _hint_station:
		return
	_hint_station = station
	_hint_range = _range_for(station)
	queue_redraw()


func _build_lengths() -> void:
	_lengths = PackedFloat32Array()
	var acc := 0.0
	for i in range(_points.size()):
		if i > 0:
			acc += _points[i].distance_to(_points[i - 1])
		_lengths.append(acc)
	_total = acc


## The trail runs Reef → Upcycle → Shop, so the leg *into* a stop is the
## segment that ends at its point. Reef's approach is the closing return leg,
## which only exists once the loop has been learned (see wm_loop_path).
func _range_for(station: String) -> Vector2:
	if _lengths.is_empty() or station.is_empty():
		return Vector2(-1.0, -1.0)
	var idx := station_ids.find(station)
	if idx < 0 or idx >= _lengths.size():
		return Vector2(-1.0, -1.0)
	var portal_count := mini(station_ids.size(), _points.size())
	if idx >= portal_count:
		return Vector2(-1.0, -1.0)
	# Reef's approach is the return leg: last portal -> end of the polyline.
	if idx == 0:
		return Vector2(_lengths[portal_count - 1], _total)
	return Vector2(_lengths[idx - 1], _lengths[idx])


func _point_at(dist: float) -> Vector2:
	var d := fposmod(dist, _total)
	for i in range(1, _points.size()):
		if d <= _lengths[i]:
			var seg_start: float = _lengths[i - 1]
			var seg_len: float = _lengths[i] - seg_start
			var t := (d - seg_start) / seg_len if seg_len > 0.0 else 0.0
			return _points[i - 1].lerp(_points[i], t)
	return _points[_points.size() - 1]


func _process(delta: float) -> void:
	if _total <= 0.0:
		return
	if _reduce_motion:
		# Static guide: nothing changes, so nothing needs redrawing.
		return
	_phase = fposmod(_phase + speed * delta, spacing)
	queue_redraw()


## Unit direction of the trail at a given distance. Chevrons use it to point
## along the loop the same way a Line2D's joint_mode handles corners.
func _dir_at(dist: float) -> Vector2:
	var d := fposmod(dist, _total)
	for i in range(1, _points.size()):
		if d <= _lengths[i]:
			var seg := _points[i] - _points[i - 1]
			var length := seg.length()
			return seg / length if length > 0.0 else Vector2.RIGHT
	var last_seg := _points[_points.size() - 1] - _points[_points.size() - 2]
	return last_seg.normalized() if last_seg.length() > 0.0 else Vector2.RIGHT


func _draw() -> void:
	if _points.size() < 2 or _total <= 0.0:
		return
	
	_draw_chevrons()
	
	# Reduced motion keeps the static guide but not the travelling pulses.
	if _reduce_motion:
		return
	
	# Draw from a fixed grid offset by _phase so dots advance smoothly.
	var count := int(_total / spacing)
	var has_hint := _hint_range.y > _hint_range.x
	for i in range(count + 1):
		var d := fposmod(float(i) * spacing + _phase, _total)
		var p := _point_at(d)
		if has_hint and d >= _hint_range.x and d <= _hint_range.y:
			draw_circle(p, dot_radius * 2.6, hint_glow_color)
			draw_circle(p, dot_radius * 1.15, hint_color)
		else:
			draw_circle(p, dot_radius * 2.1, glow_color)
			draw_circle(p, dot_radius, dot_color)


## Small static arrows spaced along the trail. They show where the loop goes
## without needing any movement, which is why they still draw under reduced
## motion.
func _draw_chevrons() -> void:
	var count := int(_total / chevron_spacing)
	for i in range(count + 1):
		var d := fposmod(float(i) * chevron_spacing + chevron_offset, _total)
		if d >= _total:
			continue
		var p := _point_at(d)
		var dir := _dir_at(d)
		var perp := Vector2(-dir.y, dir.x)
		var tip := p + dir * (chevron_length * 0.5)
		var base := p - dir * (chevron_length * 0.5)
		var left := base + perp * chevron_half_width
		var right := base - perp * chevron_half_width
		draw_line(left, tip, chevron_color, chevron_width, true)
		draw_line(right, tip, chevron_color, chevron_width, true)