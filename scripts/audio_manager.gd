extends Node
# Audio manager autoload. Placeholder implementation ready for real SFX/BGM assets.

const MASTER_BUS := "Master"
var sound_path := "res://sound/"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func play_sfx(_name: String) -> void:
	# Placeholder: calls become audible once samples exist in res://sounds.
	pass

func set_master_volume(v: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MASTER_BUS), linear_to_db(v))

func get_master_volume() -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(MASTER_BUS)))
