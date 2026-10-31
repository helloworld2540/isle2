extends Node
# Audio manager autoload. Placeholder implementation ready for real SFX/BGM assets.

const MASTER_BUS := "Master"
var sound_path := "res://sound/"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func play_sfx(_name: String) -> void:
	# Load and play a SFX sample from res://sound/ if present.
	var path := sound_path + _name
	if not ResourceLoader.exists(path):
		# Support variant extensions.
		for ext in [".wav", ".ogg", ".mp3"]:
			var alt := sound_path + _name.get_basename() + ext
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

func get_master_volume() -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(MASTER_BUS)))
