extends Node

## Audio manager autoload (authored scene: scenes/audio_manager.tscn).
## Owns a fixed BGM player plus a pool of SFX players so nothing has to create
## nodes at runtime, and debounces volume writes to the save file.

const MASTER_BUS := "Master"
const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"
const AMBIENCE_BUS := "Ambience"

const KEY_MASTER := "master_volume"
const KEY_MUSIC := "music_volume"
const KEY_SFX := "sfx_volume"
const KEY_AMBIENCE := "ambience_volume"

const SAVE_DEBOUNCE_SECONDS := 0.6

var sfx_path := "res://sound/sfx/"
var bgm_path := "res://sound/bgm/"
var sound_path := "res://sound/"

@onready var bgm_player: AudioStreamPlayer = $BgmPlayer
@onready var sfx_pool: Node = $SfxPool

var _stream_cache: Dictionary = {}
var _current_bgm_track := ""
var _bgm_fade_tween: Tween = null
var _duck_tween: Tween = null
var _music_volume_before_duck := -1.0

var _volumes := {
	KEY_MASTER: 1.0,
	KEY_MUSIC: 0.65,
	KEY_SFX: 1.0,
	KEY_AMBIENCE: 0.7,
}
var _dirty_volumes := {}
var _save_timer: SceneTreeTimer = null
var _next_sfx := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_bus(MUSIC_BUS)
	_setup_bus(SFX_BUS)
	_setup_bus(AMBIENCE_BUS)
	_load_volumes()
	
	_apply_bus_volume(MASTER_BUS, _volumes[KEY_MASTER])
	_apply_bus_volume(MUSIC_BUS, _volumes[KEY_MUSIC])
	_apply_bus_volume(SFX_BUS, _volumes[KEY_SFX])
	_apply_bus_volume(AMBIENCE_BUS, _volumes[KEY_AMBIENCE])
	_assign_player_buses()


func _assign_player_buses() -> void:
	if bgm_player:
		bgm_player.bus = MUSIC_BUS
	if sfx_pool:
		for player in sfx_pool.get_children():
			if player is AudioStreamPlayer:
				player.bus = SFX_BUS


# --- Buses ---

func _setup_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		AudioServer.add_bus(AudioServer.bus_count)
		AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
	
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx != -1 and bus_name != MASTER_BUS:
		AudioServer.set_bus_send(bus_idx, MASTER_BUS)


func _apply_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.0, 1.0)))


# --- SFX ---

func play_sfx(sound: String, pitch_scale: float = 1.0, bus_name: String = SFX_BUS) -> void:
	var stream := _resolve_sfx(sound)
	if stream == null or sfx_pool == null:
		return
	
	var player := _next_sfx_player()
	if player == null:
		return
	
	player.stream = stream
	player.bus = bus_name
	player.pitch_scale = clampf(pitch_scale * randf_range(0.96, 1.04), 0.5, 2.0)
	player.play()


func _resolve_sfx(sound: String) -> AudioStream:
	var base := sound.get_basename()
	var candidates := [
		sfx_path + sound,
		sound_path + sound,
		sfx_path + base + ".ogg",
		sfx_path + base + ".wav",
		sfx_path + base + ".mp3",
	]
	for candidate in candidates:
		var stream := _load_stream(candidate)
		if stream != null:
			return stream
	return null


# Round-robin over the authored pool; reusing a player cuts its previous sound.
func _next_sfx_player() -> AudioStreamPlayer:
	var players: Array[AudioStreamPlayer] = []
	for child in sfx_pool.get_children():
		if child is AudioStreamPlayer:
			players.append(child)
	if players.is_empty():
		return null
	
	var player := players[_next_sfx % players.size()]
	_next_sfx += 1
	return player


# --- BGM ---

func play_bgm(track: String) -> void:
	if bgm_player == null:
		return
	if track == "" or (track == _current_bgm_track and bgm_player.playing):
		return
	
	var resolved := _resolve_bgm(track)
	if resolved == "":
		stop_bgm()
		return
	
	if _bgm_fade_tween:
		_bgm_fade_tween.kill()
	
	var fade_time := 0.6
	if bgm_player.playing:
		_bgm_fade_tween = create_tween()
		_bgm_fade_tween.tween_property(bgm_player, "volume_db", -46.0, fade_time * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_bgm_fade_tween.tween_callback(func():
			var stream := _load_stream(resolved)
			if bgm_player and stream:
				bgm_player.stop()
				bgm_player.stream = stream
				bgm_player.volume_db = -6.0
				bgm_player.play()
		)
		_bgm_fade_tween.tween_property(bgm_player, "volume_db", -6.0, fade_time * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		var stream := _load_stream(resolved)
		if stream:
			bgm_player.stream = stream
			bgm_player.volume_db = -6.0
			bgm_player.play()
	
	_current_bgm_track = track


func _resolve_bgm(track: String) -> String:
	var base := track.get_basename()
	for candidate in [bgm_path + track, bgm_path + base + ".ogg", bgm_path + base + ".wav", bgm_path + base + ".mp3"]:
		if _load_stream(candidate) != null:
			return candidate
	return ""


func stop_bgm() -> void:
	if _bgm_fade_tween:
		_bgm_fade_tween.kill()
		_bgm_fade_tween = null
	if bgm_player:
		bgm_player.stop()
	_current_bgm_track = ""


func duck_music(target: float = 0.18, duration: float = 0.25) -> void:
	if _music_volume_before_duck < 0.0:
		_music_volume_before_duck = _volumes[KEY_MUSIC]
	if _duck_tween:
		_duck_tween.kill()
	
	var idx := AudioServer.get_bus_index(MUSIC_BUS)
	if idx == -1:
		return
	
	_duck_tween = create_tween()
	_duck_tween.tween_method(
		func(db): AudioServer.set_bus_volume_db(idx, db),
		AudioServer.get_bus_volume_db(idx),
		linear_to_db(clampf(target, 0.0, 1.0)),
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func restore_music(duration: float = 0.3) -> void:
	if _music_volume_before_duck < 0.0:
		return
	
	var target_lin := _music_volume_before_duck
	_music_volume_before_duck = -1.0
	
	var idx := AudioServer.get_bus_index(MUSIC_BUS)
	if idx == -1:
		return
	if _duck_tween:
		_duck_tween.kill()
	
	_duck_tween = create_tween()
	_duck_tween.tween_method(
		func(db): AudioServer.set_bus_volume_db(idx, db),
		AudioServer.get_bus_volume_db(idx),
		linear_to_db(clampf(target_lin, 0.001, 1.0)),
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# --- Volumes ---

func set_master_volume(value: float) -> void:
	_set_volume(KEY_MASTER, MASTER_BUS, value)

func get_master_volume() -> float:
	return _volumes[KEY_MASTER]

func set_music_volume(value: float) -> void:
	_set_volume(KEY_MUSIC, MUSIC_BUS, value)

func get_music_volume() -> float:
	return _volumes[KEY_MUSIC]

func set_sfx_volume(value: float) -> void:
	_set_volume(KEY_SFX, SFX_BUS, value)

func get_sfx_volume() -> float:
	return _volumes[KEY_SFX]

func set_ambience_volume(value: float) -> void:
	_set_volume(KEY_AMBIENCE, AMBIENCE_BUS, value)

func get_ambience_volume() -> float:
	return _volumes[KEY_AMBIENCE]


func _set_volume(key: String, bus_name: String, value: float) -> void:
	var clamped := clampf(value, 0.0, 1.0)
	_volumes[key] = clamped
	_apply_bus_volume(bus_name, clamped)
	_dirty_volumes[key] = clamped
	_schedule_volume_save()


# Slider drags fire dozens of changes per second; write once the dust settles.
func _schedule_volume_save() -> void:
	if _save_timer != null:
		return
	_save_timer = get_tree().create_timer(SAVE_DEBOUNCE_SECONDS)
	_save_timer.timeout.connect(_flush_volumes)


func _flush_volumes() -> void:
	_save_timer = null
	if _dirty_volumes.is_empty():
		return
	
	SaveManager.update_game(_dirty_volumes)
	_dirty_volumes.clear()


func _load_volumes() -> void:
	var data := SaveManager.load_game()
	for key in _volumes.keys():
		_volumes[key] = clampf(float(data.get(key, _volumes[key])), 0.0, 1.0)


# --- Streams ---

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
