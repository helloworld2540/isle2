extends Node

# Shared cross-scene progress. Lives as an autoload (GameState).
const DEFAULT_TRASH_TYPES: Array[String] = ["Polyethylene", "Polypropylene", "Glass", "Nylon", "Reef Debris"]

# Typed-item metadata for richer inventory and capacity logic.
const TRASH_WEIGHTS: Dictionary = {
	"Polyethylene": 1,
	"Polypropylene": 2,
	"Glass": 3,
	"Nylon": 2,
	"Reef Debris": 1,
}

const TRASH_RARITY: Dictionary = {
	"Polyethylene": "common",
	"Polypropylene": "common",
	"Glass": "uncommon",
	"Nylon": "uncommon",
	"Reef Debris": "rare",
}

const MONEY_RATES: Dictionary = {
	"Polyethylene": 3,
	"Polypropylene": 4,
	"Glass": 6,
	"Nylon": 5
}

# --- Game State Variables ---
var upcycle_score: int = 0
var money: int = 0
var lifetime_earnings: int = 0

var reef_garbage: float = 0.0
var reef_fish: int = 0

# Inventory
var trash_inventory: int = 0
var trash_by_type: Dictionary = {}
var inventory_capacity_level: int = 0

# Upgrades
var deep_cache: bool = false
var deep_cache_tier: int = 1

# Statistics & High Scores
var sort_streak: int = 0
var best_upcycle_score: int = 0
var best_sort_streak: int = 0
var best_reef_depth: int = 0
var best_reef_fish: int = 0


func _init() -> void:
	for t in DEFAULT_TRASH_TYPES:
		trash_by_type[t] = 0

# --- Inventory & Capacity ---

# Return the weighted (space) used by current inventory, used by capacity logic.
func get_inventory_weight() -> int:
	var total: int = 0
	for k in trash_by_type.keys():
		total += int(trash_by_type[k]) * int(TRASH_WEIGHTS.get(k, 1))
	return total

func get_inventory_capacity() -> int:
	return 10 + (inventory_capacity_level * 10)

# Free cap now considers weight, not raw count.
func get_free_capacity() -> int:
	return max(0, get_inventory_capacity() - get_inventory_weight())

# Total current weighted inventory, but reported as the effective count.
func get_effective_inventory_count() -> int:
	return get_inventory_weight()

func _recompute_inventory() -> void:
	var total: int = 0
	for amount in trash_by_type.values():
		total += int(amount)
	trash_inventory = total

# Add trash accounting for weight when accepting.
func add_trash_type_weighted(mat: String, amount: int) -> int:
	var weight: int = max(1, int(TRASH_WEIGHTS.get(mat, 1)))
	
	if amount <= 0:
		return 0
		
	var free_weight: int = get_free_capacity()
	var max_acceptable: int = free_weight / weight
	var accepted: int = min(amount, max_acceptable)
	
	if accepted <= 0:
		return 0
		
	trash_by_type[mat] = int(trash_by_type.get(mat, 0)) + accepted
	
	_recompute_inventory()
	_persist()
	return accepted

func add_trash_type(mat: String, amount: int) -> int:
	# Aliased to the weighted function to prevent duplicated logic
	return add_trash_type_weighted(mat, amount)

func consume_trash_type(mat: String, amount: int) -> bool:
	if amount <= 0:
		return false
		
	var current_amount: int = int(trash_by_type.get(mat, 0))
	if current_amount < amount:
		return false
		
	trash_by_type[mat] = current_amount - amount
	_recompute_inventory()
	_persist()
	return true

func spend_trash(amount: int) -> bool:
	if amount <= 0:
		return true
		
	if get_inventory_weight() < amount:
		return false
		
	var remaining: int = amount
	var pending_deductions: Dictionary = {}
	
	for k in trash_by_type.keys():
		if remaining <= 0:
			break
			
		var item_weight: int = int(TRASH_WEIGHTS.get(k, 1))
		var available_units: int = int(trash_by_type.get(k, 0))
		
		if available_units <= 0:
			continue
			
		var take_units: int = min(available_units, remaining / item_weight)
		if take_units <= 0:
			continue
			
		pending_deductions[k] = take_units
		remaining -= take_units * item_weight
		
	# If we couldn't cleanly match the amount due to denomination constraints, fail the transaction.
	if remaining > 0:
		return false
		
	# Apply deductions safely
	for k in pending_deductions.keys():
		trash_by_type[k] -= pending_deductions[k]
		
	_recompute_inventory()
	_persist()
	return true

# --- Upgrades ---

func purchase_inventory_capacity() -> bool:
	var cost: int = 6 + (inventory_capacity_level * 3)
	if not spend_trash(cost):
		return false
		
	inventory_capacity_level += 1
	_persist()
	return true

func purchase_deep_cache() -> bool:
	if deep_cache or upcycle_score < 30:
		return false
		
	upcycle_score -= 30
	deep_cache = true
	deep_cache_tier = 1
	_persist()
	return true

func upgrade_deep_cache() -> bool:
	if not deep_cache:
		return false
		
	var cost: int = 15 * deep_cache_tier
	if upcycle_score < cost:
		return false
		
	upcycle_score -= cost
	deep_cache_tier += 1
	_persist()
	return true

func get_upgrade_level(key: String) -> int:
	var data: Dictionary = SaveManager.load_game()
	return int(data.get(key, 0))

func get_move_speed_multiplier() -> float:
	return 1.0 + (float(get_upgrade_level("upgrade_move")) * 0.08)

func get_collection_radius_bonus() -> float:
	return float(get_upgrade_level("upgrade_range")) * 12.0

# --- Tracking & Statistics ---

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

func add_earnings(amount: int) -> void:
	if amount <= 0:
		return
	lifetime_earnings += amount
	money += amount
	_persist()

func record_sort_streak(streak: int) -> void:
	if streak > best_sort_streak:
		best_sort_streak = streak
		_persist()

# --- Save & Load ---

func _persist() -> void:
	var data: Dictionary = SaveManager.load_game()
	data["upcycle_score"] = upcycle_score
	data["reef_garbage"] = reef_garbage
	data["reef_fish"] = reef_fish
	data["trash_inventory"] = trash_inventory
	data["trash_by_type"] = trash_by_type
	data["best_upcycle_score"] = best_upcycle_score
	data["best_sort_streak"] = best_sort_streak
	data["best_reef_depth"] = best_reef_depth
	data["best_reef_fish"] = best_reef_fish
	data["lifetime_earnings"] = lifetime_earnings
	data["sort_streak"] = sort_streak
	data["deep_cache"] = deep_cache
	data["deep_cache_tier"] = deep_cache_tier
	data["inventory_capacity_level"] = inventory_capacity_level
	data["money"] = money
	SaveManager.save_game(data)

func restore() -> void:
	var data: Dictionary = SaveManager.load_game()
	
	upcycle_score = int(data.get("upcycle_score", 0))
	reef_garbage = float(data.get("reef_garbage", 0.0))
	reef_fish = int(data.get("reef_fish", 0))
	trash_inventory = int(data.get("trash_inventory", 0))
	money = int(data.get("money", 0))
	lifetime_earnings = int(data.get("lifetime_earnings", 0))
	
	best_upcycle_score = int(data.get("best_upcycle_score", 0))
	best_sort_streak = int(data.get("best_sort_streak", 0))
	best_reef_depth = int(data.get("best_reef_depth", 0))
	best_reef_fish = int(data.get("best_reef_fish", 0))
	sort_streak = int(data.get("sort_streak", 0))
	
	deep_cache = bool(data.get("deep_cache", false))
	deep_cache_tier = int(data.get("deep_cache_tier", 1))
	inventory_capacity_level = int(data.get("inventory_capacity_level", 0))
	
	trash_by_type.clear()
	for t in DEFAULT_TRASH_TYPES:
		trash_by_type[t] = 0
		
	var loaded_trash: Dictionary = data.get("trash_by_type", {})
	for k in loaded_trash.keys():
		trash_by_type[str(k)] = int(loaded_trash[k])
		
	_recompute_inventory()

func reset() -> void:
	upcycle_score = 0
	reef_garbage = 0.0
	reef_fish = 0
	money = 0
	lifetime_earnings = 0
	
	best_upcycle_score = 0
	best_sort_streak = 0
	best_reef_depth = 0
	best_reef_fish = 0
	sort_streak = 0
	
	deep_cache = false
	deep_cache_tier = 1
	inventory_capacity_level = 0
	
	trash_by_type.clear()
	for t in DEFAULT_TRASH_TYPES:
		trash_by_type[t] = 0
		
	_recompute_inventory()
