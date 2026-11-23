extends Node2D

## Glowing pulses that travel along the loop trail (Reef Rescue → Upcycle →
## Shop) to show the intended island-loop direction. Paints itself in _draw();
## no child nodes are created at runtime.
##
## Only legs the keeper has completed are drawn at all — before that, the map
## shows nothing but the NextStopArrow above the keeper. This reads the same
## revealed segments the LoopPath Line2D legs use, so the dots, the chevrons
## and the dashed lines never disagree about what is known.
##
## When the route advisor picks a next stop, the leg that leads into
## that stop brightens to gold, so the HUD line, the glowing portal pad and the
## dots all point at the same place. NPC errands (station == "npc") leave the
## dots neutral: the turn-in is marked by the gold star over the islander.

const REEF := 0
const UPCYCLE := 1
const RETURN := 2

@export var source: NodePath = ^"../LoopPath"
@export var spacing := 56.0
@export var dot_radius := 4.2
@export var speed := 115.0
@export var dot_color := Color(0.72, 1.0, 1.0, 0.8)
@export var glow_color := Color(0.45, 0.9, 1.0, 0.12)
## Warmer, brighter treatment for the leg that leads to the advised stop.
@export var hint_color := Color(1.0, 0.88, 0.42, 1.0)
@export var hint_glow_color := Color(1.0, 0.72, 0.22, 0.22)
## Static direction chevrons spaced along the trail; unlike the dots they are
## always visible, so the loop's direction is legible at a glance.
@export var chevron_spacing := 150.0
@export var chevron_offset := 75.0
@export var chevron_length := 13.0
@export var chevron_half_width := 7.0
@export var chevron_width := 2.3
@export var chevron_color := Color(1.0, 1.0, 1.0, 0.38)

var _segments: Array[PackedVector2Array] = []
var _seg_lengths: Array[float] = []
var _phase := 0.0
var _hint_station := ""
var _reduce_motion := false


func _ready() -> void:
	z_index = 2
	_reduce_motion = GameSettings.reduce_motion
	# The trail reveals itself as the loop is learned; rebuild whenever the
	# saved progress moves underneath us.
	GameState.circuit_progress_changed.connect(_rebuild_segments)
	GameState.island_circuit_completed.connect(_rebuild_segments)
	_rebuild_segments()


## Fetch the revealed legs from the LoopPath and recompute cumlength tables.
func _rebuild_segments(_visited: Variant = null) -> void:
	var loop := get_node(source)
	var segments: Array[PackedVector2Array] = []
	if loop != null and loop.has_method("revealed_segments"):
		segments = loop.revealed_segments()

	_segments = segments
	_seg_lengths = []
	for seg: PackedVector2Array in _segments:
		_seg_lengths.append(_segment_length(seg))
	queue_redraw()


func _segment_length(seg: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, seg.size()):
		total += seg[i].distance_to(seg[i - 1])
	return total


## Leg indices are stable: 0 = Reef→Upcycle, 1 = Upcycle→Shop, 2 = Shop→Reef.
## The leg into a stop is the one whose end station is that stop.
func _hint_segment() -> int:
	match _hint_station:
		"upcycle":
			return REEF
		"shop":
			return UPCYCLE
		"reef_rescue":
			return RETURN
		_:
			return -1


## Called by the HUD whenever the route advice changes. The station is one of
## station ids, or "" for "no leg to highlight" (e.g. an NPC errand).
func set_hint(station: String) -> void:
	if station == _hint_station:
		return
	_hint_station = station
	queue_redraw()


func _process(delta: float) -> void:
	# No revealed legs: nothing moves, nothing redraws.
	if _seg_lengths.is_empty():
		return
	if _reduce_motion:
		return
	_phase = fposmod(_phase + speed * delta, spacing)
	queue_redraw()


func _point_at(seg: PackedVector2Array, seg_total: float, dist: float) -> Vector2:
	var d := fposmod(dist, seg_total)
	var acc := 0.0
	for i in range(1, seg.size()):
		var seg_len := seg[i].distance_to(seg[i - 1])
		if d <= acc + seg_len:
			var t := (d - acc) / seg_len if seg_len > 0.0 else 0.0
			return seg[i - 1].lerp(seg[i], t)
		acc += seg_len
	return seg[seg.size() - 1]


func _dir_at(seg: PackedVector2Array, seg_total: float, dist: float) -> Vector2:
	var d := fposmod(dist, seg_total)
	var acc := 0.0
	for i in range(1, seg.size()):
		var seg_len := seg[i].distance_to(seg[i - 1])
		if d <= acc + seg_len:
			var seg_vec := seg[i] - seg[i - 1]
			return seg_vec / seg_len if seg_len > 0.0 else Vector2.RIGHT
		acc += seg_len
	var last_seg := seg[seg.size() - 1] - seg[seg.size() - 2]
	return last_seg.normalized() if last_seg.length() > 0.0 else Vector2.RIGHT


func _draw() -> void:
	if _segments.is_empty():
		return

	var hint := _hint_segment()
	for seg_index in range(_segments.size()):
		var seg: PackedVector2Array = _segments[seg_index]
		var seg_total: float = _seg_lengths[seg_index]
		if seg.size() < 2 or seg_total <= 0.0:
			continue
		var hinted := seg_index == hint
		_draw_chevrons(seg, seg_total)
		if _reduce_motion:
			continue # Static guide: still no travelling dots.
		# Draw dots offset by the shared phase so they march along the walk.
		var count := int(seg_total / spacing)
		for i in range(count + 1):
			var d := fposmod(float(i) * spacing + _phase, seg_total)
			var p := _point_at(seg, seg_total, d)
			if hinted:
				draw_circle(p, dot_radius * 2.6, hint_glow_color)
				draw_circle(p, dot_radius * 1.15, hint_color)
			else:
				draw_circle(p, dot_radius * 2.1, glow_color)
				draw_circle(p, dot_radius, dot_color)


## Small static arrows spaced along the trail. They show where the loop goes
## without needing any movement, which is why they still draw under reduced
## motion.
func _draw_chevrons(seg: PackedVector2Array, seg_total: float) -> void:
	var count := int(seg_total / chevron_spacing)
	for i in range(count + 1):
		var d := fposmod(float(i) * chevron_spacing + chevron_offset, seg_total)
		if d >= seg_total:
			continue
		var p := _point_at(seg, seg_total, d)
		var dir := _dir_at(seg, seg_total, d)
		var perp := Vector2(-dir.y, dir.x)
		var tip := p + dir * (chevron_length * 0.5)
		var base := p - dir * (chevron_length * 0.5)
		var left := base + perp * chevron_half_width
		var right := base - perp * chevron_half_width
		draw_line(left, tip, chevron_color, chevron_width, true)
		draw_line(right, tip, chevron_color, chevron_width, true)
