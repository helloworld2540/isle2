extends Node

# Shared cross-scene progress. Lives as an autoload (GameState).
var upcycle_score: int = 0
var reef_garbage: float = 0.0
var reef_fish: int = 0

func record_upcycle(score: int) -> void:
	upcycle_score = score
	_persist()

func record_reef(garbage: float, fish: int) -> void:
	reef_garbage = garbage
	reef_fish = fish
	_persist()

func _persist() -> void:
	var data := SaveManager.load_game()
	data["upcycle_score"] = upcycle_score
	data["reef_garbage"] = reef_garbage
	data["reef_fish"] = reef_fish
	SaveManager.save_game(data)

func restore() -> void:
	var data := SaveManager.load_game()
	upcycle_score = int(data.get("upcycle_score", 0))
	reef_garbage = float(data.get("reef_garbage", 0.0))
	reef_fish = int(data.get("reef_fish", 0))
