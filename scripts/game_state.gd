extends Node

# Shared cross-scene progress. Lives as an autoload (GameState).
const DEFAULT_TRASH_TYPES := ["Polyethylene", "Polypropylene", "Glass", "Nylon", "Reef Debris"]

var upcycle_score: int = 0
var reef_garbage: float = 0.0
var reef_fish: int = 0
var trash_inventory: int = 0
var trash_by_type: Dictionary = {}
var best_upcycle_score: int = 0
var best_sort_streak: int = 0
var best_reef_depth: int = 0
var best_reef_fish: int = 0
var sort_streak: int = 0
var deep_cache: bool = false

func _init() -> void:
	for t in DEFAULT_TRASH_TYPES:
		trash_by_type[t] = 0

func record_upcycle(score: int) -> void:
	upcycle_score = score
	if score > best_upcycle_score:
		best_upcycle_score = score
	_persist()

func record_reef(garbage: float, fish: int) -> void:
	reef_garbage = garbage
	reef_fish = fish
	if int(garbage) > best_reef_depth:
		best_reef_depth = int(garbage)
	if fish > best_reef_fish:
		best_reef_fish = fish
	_persist()

func add_trash_type(mat: String, amount: int) -> void:
	if amount <= 0:
		return
	if not trash_by_type.has(mat):
		trash_by_type[mat] = 0
	trash_by_type[mat] += amount
	trash_inventory += amount
	_persist()

func purchase_deep_cache() -> bool:
	if deep_cache:
		return false
	if upcycle_score < 30:
		return false
	upcycle_score -= 30
	deep_cache = true
	_persist()
	return true

func get_upgrade_level(key: String) -> int:
	var data := SaveManager.load_game()
	return int(data.get(key, 0))

func get_move_speed_multiplier() -> float:
	var lvl := get_upgrade_level("upgrade_move")
	return 1.0 + float(lvl) * 0.08

func get_collection_radius_bonus() -> float:
	var lvl := get_upgrade_level("upgrade_range")
	return float(lvl) * 12.0

func consume_trash_type(mat: String, amount: int) -> bool:
	if amount <= 0:
		return false
	if int(trash_by_type.get(mat, 0)) < amount:
		return false
	trash_by_type[mat] = int(trash_by_type.get(mat, 0)) - amount
	trash_inventory = max(0, trash_inventory - amount)
	_persist()
	return true

func record_sort_streak(streak: int) -> void:
	if streak > best_sort_streak:
		best_sort_streak = streak
		_persist()

func _persist() -> void:
	var data := SaveManager.load_game()
	data["upcycle_score"] = upcycle_score
	data["reef_garbage"] = reef_garbage
	data["reef_fish"] = reef_fish
	data["trash_inventory"] = trash_inventory
	data["trash_by_type"] = trash_by_type
	data["best_upcycle_score"] = best_upcycle_score
	data["best_sort_streak"] = best_sort_streak
	data["best_reef_depth"] = best_reef_depth
	data["best_reef_fish"] = best_reef_fish
	data["sort_streak"] = sort_streak
	data["deep_cache"] = deep_cache
	SaveManager.save_game(data)

func restore() -> void:
	var data := SaveManager.load_game()
	upcycle_score = int(data.get("upcycle_score", 0))
	reef_garbage = float(data.get("reef_garbage", 0.0))
	reef_fish = int(data.get("reef_fish", 0))
	trash_inventory = int(data.get("trash_inventory", 0))
	var tbt = data.get("trash_by_type", {})
	if tbt is Dictionary:
		trash_by_type = {}
		for t in DEFAULT_TRASH_TYPES:
			trash_by_type[t] = 0
		for k in (tbt as Dictionary).keys():
			trash_by_type[str(k)] = int((tbt as Dictionary)[k])
	best_upcycle_score = int(data.get("best_upcycle_score", 0))
	best_sort_streak = int(data.get("best_sort_streak", 0))
	best_reef_depth = int(data.get("best_reef_depth", 0))
	best_reef_fish = int(data.get("best_reef_fish", 0))
	sort_streak = int(data.get("sort_streak", 0))
	deep_cache = bool(data.get("deep_cache", false))