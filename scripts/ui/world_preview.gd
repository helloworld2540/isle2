extends PanelContainer
class_name WorldPreviewPanel

## Decorative "postcard" of the island shown on the main menu: a framed vista
## of the world the player is about to set out into, sprinkled with tiny
## ambient motes drifting over the art. Purely presentational — no gameplay
## state lives here. Motes are instanced scenes (scene-first) and freeze
## entirely under reduce_motion.

const MOTE_SCENE := preload("res://scenes/ui/mote.tscn")
const MOTE_COUNT := 14
const MOTE_TINTS: Array[Color] = [
	Color(1.0, 0.95, 0.75, 1.0),  # warm sun speck
	Color(0.75, 0.92, 1.0, 1.0),  # sea-spray cyan
	Color(1.0, 1.0, 1.0, 1.0),    # plain white
]

@onready var _mote_layer: Control = $Margin/VBox/ImageFrame/MoteLayer

func _ready() -> void:
	_spawn_motes()


func _spawn_motes() -> void:
	if not _mote_layer:
		return
	# Layout may not have sorted this frame yet; measure next idle.
	await get_tree().process_frame
	var bounds := _mote_layer.size
	if bounds.x < 1.0 or bounds.y < 1.0:
		bounds = _mote_layer.custom_minimum_size
	for i in range(MOTE_COUNT):
		var mote := MOTE_SCENE.instantiate() as AmbientMote
		var s := randf_range(4.0, 9.0)
		mote.size = Vector2(s, s)
		mote.custom_minimum_size = Vector2(s, s)
		mote.position = Vector2(randf() * maxf(1.0, bounds.x - s), randf() * maxf(1.0, bounds.y - s))
		mote.modulate = MOTE_TINTS[i % MOTE_TINTS.size()]
		mote.set_bounds(bounds)
		_mote_layer.add_child(mote)
