extends AudioStreamPlayer
class_name AmbienceLoop

## A seamless, scene-local ambience bed on the Ambience bus. Each scene authors
## its own instance with a `stream_path` and `target_db`, so the world surf, the
## bench hum and the reef current all share one fade/loop implementation.
##
## Uses a dedicated player (never the round-robin SFX pool, which would cut it
## off mid-swell) and defaults to PROCESS_MODE_ALWAYS so pausing the tree — the
## world menu, a minigame briefing or a game-over card — never silences it.

@export var stream_path: String = ""
@export var target_db: float = -22.0
@export var fade_in_seconds: float = 3.0
@export var bus_name: StringName = &"Ambience"
@export var keep_playing_when_paused: bool = true


func _ready() -> void:
	if keep_playing_when_paused:
		process_mode = Node.PROCESS_MODE_ALWAYS
	bus = bus_name
	
	if stream_path.is_empty():
		push_warning("AmbienceLoop (%s): no stream_path set" % name)
		return
	stream = load(stream_path)
	if stream == null:
		push_warning("AmbienceLoop (%s): missing %s" % [name, stream_path])
		return
	
	_force_loop()
	volume_db = -60.0
	play()
	
	var fade := create_tween()
	fade.tween_property(self, "volume_db", target_db, fade_in_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## Imported loops may not carry a loop chunk, so wrap the whole buffer here.
## The frame count is derived from playback length, not the raw buffer, because
## the importer can hand back a compressed stream whose `data` is not PCM frames.
func _force_loop() -> void:
	if not (stream is AudioStreamWAV):
		return
	var wav := stream as AudioStreamWAV
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = int(round(wav.get_length() * float(wav.mix_rate)))
