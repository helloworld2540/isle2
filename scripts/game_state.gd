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

const TRASH_SHORT: Dictionary = {
	"Polyethylene": "PET",
	"Polypropylene": "PP",
	"Glass": "GL",
	"Nylon": "NY",
	"Reef Debris": "Debris",
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

## Turn-ins needed for the island's mastery title, and the one-time reward
## it grants (one extra capacity level = +10 kg of bag space).
const HARBOR_HERO_TURNS: int = 8
const HARBOR_HERO_CAPACITY_BONUS: int = 1

## Emitted once, the moment the Harbor Hero milestone is earned. The world HUD
## banner listens for it so the reward is felt, not just written to the save.
signal harbor_hero_unlocked

## Emitted when an NPC's final quest tier is turned in. Separate from the
## Harbor Hero signal so the banner can celebrate both without coupling the
## banner to WorldNPC.
signal npc_quest_line_completed(npc_name: String)

# --- Game State Variables ---
var upcycle_score: int = 0
var money: int = 0
var lifetime_earnings: int = 0
var quests_completed: int = 0
var harbor_hero_granted: bool = false

var reef_garbage: float = 0.0
var reef_fish: int = 0

# Inventory
var trash_inventory: int = 0
var trash_by_type: Dictionary = {}
var inventory_capacity_level: int = 0

# Upgrades
var deep_cache: bool = false
var deep_cache_tier: int = 1
var upgrade_move: int = 0
var upgrade_range: int = 0

# Most recent minigame run, handed to the world map for its recap card.
# Shape: { "kind": String, "title": String, "lines": Array[String], "hint": String }
var last_run: Dictionary = {}

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
	
	# Heaviest material first, then fall back to a bounded search: picking the
	# biggest denominations first avoids the old greedy failure where a cheap
	# 1 kg item was taken and the remaining weight could not be matched.
	var keys: Array = trash_by_type.keys()
	keys.sort_custom(func(a, b): return int(TRASH_WEIGHTS.get(a, 1)) > int(TRASH_WEIGHTS.get(b, 1)))
	
	var plan: Dictionary = {}
	if not _plan_spend(keys, 0, amount, plan):
		return false
	
	for key in plan.keys():
		trash_by_type[key] -= int(plan[key])
	
	_recompute_inventory()
	_persist()
	return true


func _plan_spend(keys: Array, index: int, remaining: int, plan: Dictionary) -> bool:
	if remaining == 0:
		return true
	if index >= keys.size():
		return false
	
	var key: String = keys[index]
	var weight: int = max(1, int(TRASH_WEIGHTS.get(key, 1)))
	var available: int = int(trash_by_type.get(key, 0))
	var max_units: int = min(available, remaining / weight)
	
	for units in range(max_units, -1, -1):
		if units > 0:
			plan[key] = units
		if _plan_spend(keys, index + 1, remaining - units * weight, plan):
			return true
		plan.erase(key)
	
	return false


# --- Upgrades ---

func purchase_inventory_capacity() -> bool:
	var cost: int = 6 + (inventory_capacity_level * 3)
	if not spend_trash(cost):
		return false
		
	inventory_capacity_level += 1
	_persist()
	return true

# --- Money ---

func get_money() -> int:
	return money

func can_afford(amount: int) -> bool:
	return money >= amount

func spend_money(amount: int) -> bool:
	if amount <= 0:
		return true
	if money < amount:
		return false
	
	money -= amount
	_persist()
	return true

func get_capacity_money_cost() -> int:
	return 60 + inventory_capacity_level * 25

# Shop-side alternative to the trash-priced bag upgrade.
func purchase_capacity_with_money() -> bool:
	if not spend_money(get_capacity_money_cost()):
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
	match key:
		"upgrade_move":
			return upgrade_move
		"upgrade_range":
			return upgrade_range
	return 0

func get_move_speed_multiplier() -> float:
	return 1.0 + (float(upgrade_move) * 0.08)

func get_collection_radius_bonus() -> float:
	return float(upgrade_range) * 12.0

func get_move_speed_cost() -> int:
	return 8 + upgrade_move * 4

func get_range_cost() -> int:
	return 12 + upgrade_range * 6

func purchase_move_speed() -> bool:
	if not spend_trash(get_move_speed_cost()):
		return false
	
	upgrade_move += 1
	_persist()
	return true

func purchase_range() -> bool:
	if not spend_trash(get_range_cost()):
		return false
	
	upgrade_range += 1
	_persist()
	return true

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

# --- Minigame Hand-off ---
# Minigames call this on their summary screen so the world map can show what
# just happened the moment the player walks back out of the portal.

## Lifetime count of NPC quests turned in (shown on the stats page).
## Returns true only on the turn-in that earns the Harbor Hero milestone, so
## the caller can celebrate exactly once. The capacity bonus is applied here
## and guarded by `harbor_hero_granted`, which is saved with the rest of the
## state; reset() clears the flag along with the capacity level.
func record_quest_turn_in() -> bool:
	quests_completed += 1
	
	var unlocked := not harbor_hero_granted and quests_completed >= HARBOR_HERO_TURNS
	if unlocked:
		harbor_hero_granted = true
		inventory_capacity_level += HARBOR_HERO_CAPACITY_BONUS
	
	_persist()
	if unlocked:
		harbor_hero_unlocked.emit()
	return unlocked


## True once every quest tier on the island has been cleared.
func is_harbor_hero() -> bool:
	return harbor_hero_granted


## Presentation hook used by WorldNPC after the final tier of its quest line.
## Kept on GameState so the world HUD can listen without knowing about NPCs.
func notify_npc_quest_line_completed(npc_name: String) -> void:
	npc_quest_line_completed.emit(npc_name)


func record_run(kind: String, title: String, lines: Array, hint: String = "") -> void:
	last_run = {
		"kind": kind,
		"title": title,
		"lines": lines.duplicate(),
		"hint": hint,
	}
	_persist()

# Returns the pending run once, then clears it so the card never replays.
func consume_last_run() -> Dictionary:
	if last_run.is_empty():
		return {}
	
	var pending := last_run.duplicate(true)
	last_run = {}
	_persist()
	return pending

# --- Save & Load ---

## Writes are coalesced: sorting and diving change state many times per second
## and each write rewrites the whole save file.
const SAVE_DEBOUNCE_SECONDS := 0.4

var _save_scheduled := false


func _persist() -> void:
	if _save_scheduled:
		return
	_save_scheduled = true
	get_tree().create_timer(SAVE_DEBOUNCE_SECONDS).timeout.connect(_on_save_timer)


func _on_save_timer() -> void:
	_save_scheduled = false
	_write_save()


## Force the pending write out now (used before scene changes and on quit).
func flush_save() -> void:
	if not _save_scheduled:
		return
	_save_scheduled = false
	_write_save()


func _write_save() -> void:
	SaveManager.update_game({
		"upcycle_score": upcycle_score,
		"reef_garbage": reef_garbage,
		"reef_fish": reef_fish,
		"trash_inventory": trash_inventory,
		"trash_by_type": trash_by_type,
		"best_upcycle_score": best_upcycle_score,
		"best_sort_streak": best_sort_streak,
		"best_reef_depth": best_reef_depth,
		"best_reef_fish": best_reef_fish,
		"lifetime_earnings": lifetime_earnings,
		"sort_streak": sort_streak,
		"deep_cache": deep_cache,
		"deep_cache_tier": deep_cache_tier,
		"upgrade_move": upgrade_move,
		"upgrade_range": upgrade_range,
		"last_run": last_run,
		"inventory_capacity_level": inventory_capacity_level,
		"money": money,
		"quests_completed": quests_completed,
		"harbor_hero_granted": harbor_hero_granted,
	})

func restore() -> void:
	var data: Dictionary = SaveManager.load_game()
	
	upcycle_score = int(data.get("upcycle_score", 0))
	reef_garbage = float(data.get("reef_garbage", 0.0))
	reef_fish = int(data.get("reef_fish", 0))
	trash_inventory = int(data.get("trash_inventory", 0))
	money = int(data.get("money", 0))
	lifetime_earnings = int(data.get("lifetime_earnings", 0))
	quests_completed = int(data.get("quests_completed", 0))
	
	best_upcycle_score = int(data.get("best_upcycle_score", 0))
	best_sort_streak = int(data.get("best_sort_streak", 0))
	best_reef_depth = int(data.get("best_reef_depth", 0))
	best_reef_fish = int(data.get("best_reef_fish", 0))
	sort_streak = int(data.get("sort_streak", 0))
	
	deep_cache = bool(data.get("deep_cache", false))
	deep_cache_tier = int(data.get("deep_cache_tier", 1))
	upgrade_move = int(data.get("upgrade_move", 0))
	upgrade_range = int(data.get("upgrade_range", 0))
	last_run = data.get("last_run", {}) if data.get("last_run", {}) is Dictionary else {}
	inventory_capacity_level = int(data.get("inventory_capacity_level", 0))
	harbor_hero_granted = bool(data.get("harbor_hero_granted", false))
	
	# Legacy saves that already cleared every quest tier predate the title
	# reward: grant it once here and write immediately, so repeated restore()
	# calls cannot stack the bonus.
	if not harbor_hero_granted and quests_completed >= HARBOR_HERO_TURNS:
		harbor_hero_granted = true
		inventory_capacity_level += HARBOR_HERO_CAPACITY_BONUS
		_write_save()
	
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
	quests_completed = 0
	
	best_upcycle_score = 0
	best_sort_streak = 0
	best_reef_depth = 0
	best_reef_fish = 0
	sort_streak = 0
	
	deep_cache = false
	deep_cache_tier = 1
	upgrade_move = 0
	upgrade_range = 0
	last_run = {}
	inventory_capacity_level = 0
	harbor_hero_granted = false
	
	trash_by_type.clear()
	for t in DEFAULT_TRASH_TYPES:
		trash_by_type[t] = 0
		
	_recompute_inventory()
