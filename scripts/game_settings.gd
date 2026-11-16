extends Node

## Player preferences that outlive a run but are not gameplay state.
## Volume settings live in AudioManager; this covers presentation options.

const KEY_REDUCE_MOTION := "reduce_motion"

## When true, shake effects, confetti bursts and pad pulses are skipped.
var reduce_motion: bool = false


func _ready() -> void:
	reduce_motion = bool(SaveManager.load_game().get(KEY_REDUCE_MOTION, false))


func set_reduce_motion(enabled: bool) -> void:
	if reduce_motion == enabled:
		return
	
	reduce_motion = enabled
	SaveManager.update_game({KEY_REDUCE_MOTION: enabled})
