extends Node2D

## Glowing pulses that travel along the loop trail (Reef Rescue → Upcycle →
## Shop) to show the intended island-loop direction.
## Paints itself in _draw(); no child nodes are created at runtime.

@export var source: NodePath = ^"../LoopPath"
@export var spacing := 56.0
@export var dot_radius := 4.2
@export var speed := 115.0
@export var dot_color := Color(0.72, 1.0, 1.0, 0.95)
@export var glow_color := Color(0.45, 0.9, 1.0, 0.22)

var _points: PackedVector2Array = []
var _lengths: PackedFloat32Array = []
var _total := 0.0
var _phase := 0.0


func _ready() -> void:
	var line := get_node_or_null(source)
	if line is Line2D:
		_points = (line as Line2D).points
	_build_lengths()
	z_index = 2
	if GameSettings.reduce_motion:
		visible = false


func _build_lengths() -> void:
	_lengths = PackedFloat32Array()
	var acc := 0.0
	for i in range(_points.size()):
		if i > 0:
			acc += _points[i].distance_to(_points[i - 1])
		_lengths.append(acc)
	_total = acc


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
	_phase = fposmod(_phase + speed * delta, spacing)
	queue_redraw()


func _draw() -> void:
	if _points.size() < 2 or _total <= 0.0:
		return
	
	# Draw from a fixed grid offset by _phase so dots advance smoothly.
	var count := int(_total / spacing)
	for i in range(count + 1):
		var d := fposmod(float(i) * spacing + _phase, _total)
		var p := _point_at(d)
		draw_circle(p, dot_radius * 2.1, glow_color)
		draw_circle(p, dot_radius, dot_color)
