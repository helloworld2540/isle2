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
	# Web exports need Stream playback; Sample/Default fall silent there
	# (godotengine forum: "No audio in web export").
	playback_type = 1
	
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
##
## Godot's WAV mixer (4.7 and earlier) decodes through `loop_end` *inclusive*,
## so a whole-buffer loop reads one frame past the PCM data at every wrap
## (godotengine/godot#119778). On desktop that lands in adjacent heap — one
## garbage sample per 12 s cycle, inaudible. On mobile the over-read
## intermittently faults in the audio thread and the app is killed with no
## error. Give the over-read a safe landing: append a copy of the first
## frame as a guard, so the wrap still reads in-bounds and the loop stays
## seamless. Compressed formats (data is not raw PCM) fall back to wrapping
## one frame early — an inaudible skip for slow ambience washes.
func _force_loop() -> void:
	if not (stream is AudioStreamWAV):
		return
	var wav := stream as AudioStreamWAV
	# `load()` caches resources, so re-entering a scene hands back the same
	# AudioStreamWAV we already guarded. Remember the pre-guard frame count so
	# repeated entries neither stack guard frames nor shift the loop point.
	var total_frames: int
	if wav.has_meta("_ambience_loop_frames"):
		total_frames = int(wav.get_meta("_ambience_loop_frames"))
	else:
		total_frames = int(round(wav.get_length() * float(wav.mix_rate)))
		if total_frames <= 0:
			return
		wav.set_meta("_ambience_loop_frames", total_frames)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	if wav.has_meta("_ambience_loop_guarded"):
		wav.loop_end = total_frames
		return
	if _append_guard_frame(wav):
		wav.set_meta("_ambience_loop_guarded", true)
		wav.loop_end = total_frames
	else:
		wav.loop_end = total_frames - 1


## Append one frame (a copy of the first frame) past the loop point so the
## mixer's one-frame over-read at each wrap stays inside `data`. Uncompressed
## PCM only; returns true on success.
func _append_guard_frame(wav: AudioStreamWAV) -> bool:
	var bytes_per_sample := 0
	match wav.format:
		AudioStreamWAV.FORMAT_16_BITS:
			bytes_per_sample = 2
		AudioStreamWAV.FORMAT_8_BITS:
			bytes_per_sample = 1
		_:
			return false
	var channels := 2 if wav.stereo else 1
	var frame_bytes := bytes_per_sample * channels
	# The importer hands back `data` as bare PCM (the RIFF header is stripped),
	# so the first frame starts at byte 0.
	if wav.data.size() < frame_bytes:
		return false
	var guard := wav.data.slice(0, frame_bytes)
	if guard.size() != frame_bytes:
		return false
	# Copy, mutate, write back: property access returns a copy of a packed
	# array, so appending through `wav.data` directly would be lost.
	var data := wav.data
	data.append_array(guard)
	wav.data = data
	return true
