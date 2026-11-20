extends Node

## Player preferences that outlive a run but are not gameplay state.
## Volume settings live in AudioManager; this covers presentation options.

const KEY_REDUCE_MOTION := "reduce_motion"
const KEY_HIDE_TIDE := "hide_tide_hud"

## When true, shake effects, confetti bursts and pad pulses are skipped.
var reduce_motion: bool = false
## When true, the tide is not shown anywhere on the HUD. The game plays
## exactly the same underneath — keepers who want the sea to stay a mystery
## can read the water themselves.
var hide_tide: bool = false


func _ready() -> void:
	var data := SaveManager.load_game()
	reduce_motion = bool(data.get(KEY_REDUCE_MOTION, false))
	hide_tide = bool(data.get(KEY_HIDE_TIDE, false))
	# Keep the designed aspect on every screen. `window/stretch/aspect` in
	# project.godot is the authoritative setting, but the editor rewrites
	# project.godot from its in-memory settings on quit, silently dropping
	# keys it did not load — so the runtime re-asserts it here and the
	# exported build can never ship stretched. Idempotent and free.
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
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

func set_hide_tide(enabled: bool) -> void:
	if hide_tide == enabled:
		return
	hide_tide = enabled
	SaveManager.update_game({KEY_HIDE_TIDE: enabled})
