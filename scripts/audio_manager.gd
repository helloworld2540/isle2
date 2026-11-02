extends Node

# Audio manager autoload. Loads/plays SFX and BGM placeholders from res://sound/.

const MASTER_BUS := "Master"
const MUSIC_BUS := "Music"
var sound_path := "res://sound/"
var sfx_path := "res://sound/sfx/"
var bgm_path := "res://sound/bgm/"
var _reduced_motion := false
var _bgm_player: AudioStreamPlayer
var _stream_cache: Dictionary = {}
var _current_bgm_track := ""
var _bgm_fade_tween: Tween = null

func _load_stream(path: String) -> AudioStream:
	if _stream_cache.has(path):
		return _stream_cache[path]
	if not ResourceLoader.exists(path):
		return null
	var stream := load(path)
	if stream is AudioStream:
		_stream_cache[path] = stream
		return stream
	return null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_bus(MUSIC_BUS)
	set_master_volume(get_master_volume())
	set_music_volume(get_music_volume())
	_create_bgm_player()

func _setup_bus(bus_name: String) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		var new_idx := AudioServer.bus_count
		AudioServer.add_bus(new_idx)
		if AudioServer.get_bus_index(bus_name) == -1:
			# Fallback: append at end if named slot unavailable.
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
		else:
			AudioServer.set_bus_name(AudioServer.get_bus_index(bus_name), bus_name)

func _create_bgm_player() -> void:
	_bgm_player = load("res://scenes/ui/audio_stream_player.tscn").instantiate() as AudioStreamPlayer
	_bgm_player.bus = MUSIC_BUS
	_bgm_player.volume_db = -6.0
	add_child(_bgm_player)

func _ensure_bgm_player() -> void:
	if not is_instance_valid(_bgm_player):
		_create_bgm_player()

func play_sfx(name: String, pitch_scale: float = 1.0) -> void:
	var base := name.get_basename()
	var candidates := [sfx_path + name, sound_path + name, sfx_path + base + ".ogg", sfx_path + base + ".wav", sfx_path + base + ".mp3"]
	for c in candidates:
		var stream := _load_stream(c)
		if stream != null:
			var player := load("res://scenes/ui/audio_stream_player.tscn").instantiate() as AudioStreamPlayer
			player.stream = stream
			player.bus = MASTER_BUS
			player.pitch_scale = clampf(pitch_scale * randf_range(0.96, 1.04), 0.5, 2.0)
			add_child(player)
			player.finished.connect(player.queue_free)
			player.play()
			return

func play_bgm(track: String) -> void:
	_ensure_bgm_player()
	if track == "" or (track == _current_bgm_track and is_instance_valid(_bgm_player) and _bgm_player.playing):
		return
	var base := track.get_basename()
	var candidates := [bgm_path + track, bgm_path + base + ".ogg", bgm_path + base + ".wav", bgm_path + base + ".mp3"]
	var resolved_path := ""
	for c in candidates:
		if ResourceLoader.exists(c) and _load_stream(c) != null:
			resolved_path = c
			break
	if resolved_path == "":
		stop_bgm()
		_current_bgm_track = ""
		return
	if is_instance_valid(_bgm_fade_tween):
		_bgm_fade_tween.kill()
	var reduced := _reduced_motion or get_reduced_motion()
	var fade_time := 0.09 if reduced else 0.22
	if is_instance_valid(_bgm_player) and _bgm_player.playing:
		_bgm_fade_tween = create_tween()
		_bgm_fade_tween.tween_property(_bgm_player, "volume_db", -46.0, fade_time * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_bgm_fade_tween.tween_callback(func():
			if not is_instance_valid(_bgm_player):
				return
			_bgm_player.stop()
			var stream := _load_stream(resolved_path)
			if stream != null:
				_bgm_player.stream = stream
				_bgm_player.volume_db = -6.0
				_bgm_player.play()
		)
		if not reduced and fade_time > 0.0:
			_bgm_fade_tween.tween_property(_bgm_player, "volume_db", -6.0, fade_time * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		var stream := _load_stream(resolved_path)
		if stream != null:
			_bgm_player.stream = stream
			_bgm_player.volume_db = -6.0
			_bgm_player.play()
	_current_bgm_track = track

func stop_bgm() -> void:
	if is_instance_valid(_bgm_fade_tween):
		_bgm_fade_tween.kill()
		_bgm_fade_tween = null
	if is_instance_valid(_bgm_player):
		_bgm_player.stop()
	_current_bgm_track = ""

func set_master_volume(v: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MASTER_BUS), linear_to_db(clampf(v, 0.0, 1.0)))
	_persist_volume("master_volume", clampf(v, 0.0, 1.0))

func get_master_volume() -> float:
	return clampf(float(_load_key("master_volume", 1.0)), 0.0, 1.0)

func set_music_volume(v: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MUSIC_BUS), linear_to_db(clampf(v, 0.0, 1.0)))
	_persist_volume("music_volume", clampf(v, 0.0, 1.0))

func get_music_volume() -> float:
	return clampf(float(_load_key("music_volume", 0.65)), 0.0, 1.0)

func set_reduced_motion(v: bool) -> void:
	_reduced_motion = v
	_persist_volume("reduced_motion", v)

func get_reduced_motion() -> bool:
	return bool(_load_key("reduced_motion", _reduced_motion))

func _persist_volume(key: String, value) -> void:
	var data := SaveManager.load_game()
	data[key] = value
	SaveManager.save_game(data)

func _load_key(key: String, fallback):
	var data := SaveManager.load_game()
	return data.get(key, fallback)
