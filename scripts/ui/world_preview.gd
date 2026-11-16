extends PanelContainer
class_name WorldPreviewPanel

## Decorative "postcard" of the island shown on the main menu: a framed vista
## of the world the player is about to set out into, sprinkled with tiny
## ambient motes drifting over the art. Purely presentational — no gameplay
## state lives here. Motes are instanced scenes (scene-first) and freeze
## entirely under reduce_motion.

const MOTE_SCENE := preload("res://scenes/ui/mote.tscn")
const SHIMMER_FLAG := "postcard_shimmer_played"
const MOTE_COUNT := 14
const MOTE_TINTS: Array[Color] = [
	Color(1.0, 0.95, 0.75, 1.0),  # warm sun speck
	Color(0.75, 0.92, 1.0, 1.0),  # sea-spray cyan
	Color(1.0, 1.0, 1.0, 1.0),    # plain white
]

@onready var _mote_layer: Control = $Margin/VBox/ImageFrame/MoteLayer
@onready var _vista: TextureRect = $Margin/VBox/ImageFrame/PreviewImage
@onready var _shimmer: TextureRect = $Margin/VBox/ImageFrame/Shimmer
@onready var _header: Label = $Margin/VBox/Header

func _ready() -> void:
	_spawn_motes()
	_maybe_shimmer()


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


## One-time celebration tied to progression: the first time the player has
## closed an island circuit, the postcard sweeps a golden shimmer across the
## vista (once ever per save). Under reduced motion it is a brief warm flash.
func _maybe_shimmer() -> void:
	if GameState.circuits_completed < 1:
		return
	if bool(SaveManager.load_game().get(SHIMMER_FLAG, false)):
		return
	SaveManager.update_game({SHIMMER_FLAG: true})
	# Defer past first layout so sizes are real; the card is the point of the beat.
	call_deferred("_play_shimmer")


func _play_shimmer() -> void:
	if not _vista:
		return
	if GameSettings.reduce_motion:
		_vista.modulate = Color(1.35, 1.22, 0.75, 1.0)
		var flash := create_tween()
		flash.tween_property(_vista, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.9).set_trans(Tween.TRANS_SINE)
		_pulse_header()
		return
	if not _shimmer:
		return
	var frame := _shimmer.get_parent() as Control
	var w := maxf(64.0, frame.size.x if frame else 164.0)
	_shimmer.visible = true
	_shimmer.modulate.a = 0.0
	_shimmer.position = Vector2(-w * 0.6, 0.0)
	_shimmer.size = Vector2(w * 0.6, frame.size.y if frame else 97.0)
	var tw := create_tween()
	tw.tween_property(_shimmer, "modulate:a", 0.9, 0.18).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_shimmer, "position:x", w + 8.0, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_shimmer, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void: _shimmer.visible = false)
	_pulse_header()


## Header catches the light a half-beat after the sweep.
func _pulse_header() -> void:
	if not _header:
		return
	var tw := create_tween()
	tw.tween_interval(0.45)
	tw.tween_property(_header, "modulate", Color(1.5, 1.3, 0.55, 1.0), 0.16).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_header, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5).set_trans(Tween.TRANS_SINE)
