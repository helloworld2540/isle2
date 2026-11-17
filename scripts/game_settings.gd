extends Node

## Player preferences that outlive a run but are not gameplay state.
## Volume settings live in AudioManager; this covers presentation options.

const KEY_REDUCE_MOTION := "reduce_motion"

## When true, shake effects, confetti bursts and pad pulses are skipped.
var reduce_motion: bool = false


func _ready() -> void:
	reduce_motion = bool(SaveManager.load_game().get(KEY_REDUCE_MOTION, false))
	# Desktop: pin the window to the designed resolution and never let it
	# shrink below it. The game lays out for 1152x648; smaller windows clip
	# single-line labels (the shop header used to shear at the right edge).
	# Mobile OSes own the window, so skip there.
	if OS.get_name() in ["Linux", "Windows", "macOS", "FreeBSD"]:
		var window := get_tree().root
		window.set_size(Vector2i(1152, 648))
		window.set_min_size(Vector2i(1152, 648))


func set_reduce_motion(enabled: bool) -> void:
	if reduce_motion == enabled:
		return
	
	reduce_motion = enabled
	SaveManager.update_game({KEY_REDUCE_MOTION: enabled})
