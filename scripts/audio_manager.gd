extends Node

# Audio manager autoload. Loads/plays SFX from res://sound/ with extension fallback.
const MASTER_BUS := "Master"
var sound_path := "res://sound/"
var _reduced_motion := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var vol := get_master_volume()
	set_master_volume(vol)

func play_sfx(name: String) -> void:
	var path := sound_path + name
	if not ResourceLoader.exists(path):
		for ext in [".wav", ".ogg", ".mp3"]:
			var alt: String = sound_path + name.get_basename() + ext
			if ResourceLoader.exists(alt):
				path = alt
				break
	if not ResourceLoader.exists(path):
		return
	var stream := load(path)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = MASTER_BUS
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func set_master_volume(v: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MASTER_BUS), linear_to_db(v))
	var data := SaveManager.load_game()
	data["master_volume"] = v
	SaveManager.save_game(data)

func get_master_volume() -> float:
	var data := SaveManager.load_game()
	return float(data.get("master_volume", 1.0))

func set_reduced_motion(v: bool) -> void:
	_reduced_motion = v
	var data := SaveManager.load_game()
	data["reduced_motion"] = v
	SaveManager.save_game(data)

func get_reduced_motion() -> bool:
	var data := SaveManager.load_game()
	return bool(data.get("reduced_motion", false))