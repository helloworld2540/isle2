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

func _load_stream(path: String) -> AudioStream:
	if _stream_cache.has(path):
		return _stream_cache[path]
	if not ResourceLoader.exists(path):
		return null
	var stream := load(path)
	if stream != null:
		_stream_cache[path] = stream
	return stream

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_bus(MUSIC_BUS)
	set_master_volume(get_master_volume())
	set_music_volume(get_music_volume())
	_create_bgm_player()

func _setup_bus(bus_name: String) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		AudioServer.add_bus(-1)
		AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)

func _create_bgm_player() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = MUSIC_BUS
	_bgm_player.volume_db = -6.0
	add_child(_bgm_player)

func play_sfx(name: String) -> void:
	var base := name.get_basename()
	var candidates := [sfx_path + name, sound_path + name, sfx_path + base + ".ogg", sfx_path + base + ".wav", sfx_path + base + ".mp3"]
	for c in candidates:
		var stream := _load_stream(c)
		if stream != null:
			var player := AudioStreamPlayer.new()
			player.stream = stream
			player.bus = MASTER_BUS
			add_child(player)
			player.finished.connect(player.queue_free)
			player.play()
			return

func play_bgm(track: String) -> void:
	var base := track.get_basename()
	var candidates := [bgm_path + track, bgm_path + base + ".ogg", bgm_path + base + ".wav", bgm_path + base + ".mp3"]
	for c in candidates:
		var stream := _load_stream(c)
		if stream != null:
			_bgm_player.stream = stream
			_bgm_player.play()
			return
	_bgm_player.stop()

func stop_bgm() -> void:
	if _bgm_player:
		_bgm_player.stop()

func set_master_volume(v: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MASTER_BUS), linear_to_db(v))
	_persist_volume("master_volume", v)

func get_master_volume() -> float:
	return float(_load_key("master_volume", 1.0))

func set_music_volume(v: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MUSIC_BUS), linear_to_db(v))
	_persist_volume("music_volume", v)

func get_music_volume() -> float:
	return float(_load_key("music_volume", 0.65))

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
