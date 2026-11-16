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

## Canonical sale prices. The shop UI, the preview line and any future vendor
## read this one table; there used to be three copies (one dead, one stale).
const SALE_PRICES: Dictionary = {
	"Polyethylene": 2,
	"Polypropylene": 3,
	"Glass": 5,
	"Nylon": 4,
	"Reef Debris": 1,
}

## Turn-ins needed for the island's mastery title, and the one-time reward
## it grants (one extra capacity level = +10 kg of bag space).
const HARBOR_HERO_TURNS: int = 8
const HARBOR_HERO_CAPACITY_BONUS: int = 1

## The three world-map stops, in the order the trail suggests. Visiting all of
## them closes an island circuit, which pays a flat bonus so the loop the
## minigames form is worth running end to end.
const CIRCUIT_STATIONS: Array[String] = ["reef_rescue", "upcycle", "shop"]
const CIRCUIT_BONUS_MONEY: int = 15

## Catalogue lives in its own pure module; GameState only keeps the unlocked
## ids, the pending-card queue and the signal.
const AchievementCatalog := preload("res://scripts/achievement_catalog.gd")
## Capacity rules live in their own pure module; GameState delegates.
const Inventory := preload("res://scripts/inventory.gd")

## Emitted once, the moment the Harbor Hero milestone is earned. The world HUD
## banner listens for it so the reward is felt, not just written to the save.
signal harbor_hero_unlocked

## Emitted when an NPC's final quest tier is turned in. Separate from the
## Harbor Hero signal so the banner can celebrate both without coupling the
## banner to WorldNPC.
signal npc_quest_line_completed(npc_name: String)

## Emitted whenever the set of stations visited this circuit changes, so any
## HUD showing route progress can redraw without polling.
signal circuit_progress_changed(visited: Array)

## Emitted when a circuit closes. The celebration itself is deferred (see
## consume_circuit_celebrations) because the closing visit is one scene
## transition away from the world map the card belongs on.
signal island_circuit_completed(total: int)

## Emitted the moment a new one-time achievement is earned. The world banner
## listens to this single signal instead of every subsystem, so adding a
## milestone only means adding an entry to achievement_catalog.gd.
signal achievement_unlocked(id: String, title: String, subtitle: String)

## Emitted when a bottle is read. HUD can redraw the bottles-found roll.
signal bottle_read(count: int)

# --- Game State Variables ---
var upcycle_score: int = 0
var money: int = 0
var lifetime_earnings: int = 0
var quests_completed: int = 0
var harbor_hero_granted: bool = false

## Stations entered since the last completed circuit. Transient by design: a
## save that ends mid-route simply starts the next circuit from scratch, so no
## half-finished route can be farmed by reloading.
var circuit_visits: Array[String] = []
## Lifetime circuit count (shown on the stats page).
var circuits_completed: int = 0
## Circuits waiting for their banner card. Consumed by the world HUD, which is
## the only scene that owns a celebration banner.
var _pending_circuit_celebrations: int = 0

## Ids of earned achievements, in unlock order (saved).
var unlocked_achievements: Array[String] = []
## Achievements earned while no celebration banner existed (a shop sale, a
## minigame run). The world banner drains this on load so no card is lost.
var _pending_achievement_ids: Array[String] = []

var reef_garbage: float = 0.0
var reef_fish: int = 0
## Lifetime kg recovered at the reef, for the stats page.
var lifetime_garbage_kg: int = 0

# Inventory
var trash_inventory: int = 0
var trash_by_type: Dictionary = {}
var inventory_capacity_level: int = 0

# Upgrades
var deep_cache: bool = false
var deep_cache_tier: int = 1
var upgrade_move: int = 0
var upgrade_range: int = 0

## Money-priced shop conveniences. Kept separate from the trash-priced world
## upgrades so each currency has its own clear purpose: trash buys performance,
## money buys comfort (bag, market contacts, dive charter).
var market_level: int = 0
var reef_bonus_lives: int = 0
## Ids of "messages in a bottle" already read (saved, so they never respawn).
var bottles_read: Array[String] = []
## The one-time reward for finding all three bottles (saved).
var tide_gift_granted: bool = false
const TIDE_GIFT_MONEY := 25
## Prestige purchase: a one-time island benefactor gift. No stat effect, only
## bragging rights — the island's answer to late-game money.
var island_patron: bool = false

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


## Autoloads are ready before the first scene, so loading the save here means
## every scene (HUD, shop, stats, loop path) can read state in its own _ready
## without each of them re-reading the file. main_menu still calls restore()
## explicitly for "New save" and "Load save".
func _ready() -> void:
	restore()

# --- Inventory & Capacity ---
# Capacity maths and stock movement live in inventory.gd; the wrappers below
# keep the public API stable for HUD/minigame/NPC readers.

func get_inventory_weight() -> int:
	return Inventory.weight(self)

func get_inventory_capacity() -> int:
	return Inventory.capacity(self)

func get_free_capacity() -> int:
	return Inventory.free_space(self)

func get_effective_inventory_count() -> int:
	return get_inventory_weight()

func _recompute_inventory() -> void:
	var total: int = 0
	for amount in trash_by_type.values():
		total += int(amount)
	trash_inventory = total

func add_trash_type_weighted(mat: String, amount: int) -> int:
	var accepted := Inventory.add_weighted(self, mat, amount)
	if accepted > 0:
		_recompute_inventory()
		_persist()
	return accepted

func add_trash_type(mat: String, amount: int) -> int:
	return add_trash_type_weighted(mat, amount)

func consume_trash_type(mat: String, amount: int) -> bool:
	if not Inventory.consume(self, mat, amount):
		return false
	_recompute_inventory()
	_persist()
	return true

func spend_trash(amount: int) -> bool:
	if not Inventory.spend(self, amount):
		return false
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

# --- Shop conveniences (money sinks) ---

const MARKET_MAX_LEVEL := 3
const REEF_LIVES_MAX_LEVEL := 2

## Market Contact: each level adds +1$ to every unit sold, no matter the type.
func get_market_bonus() -> int:
	return market_level

func get_market_cost() -> int:
	return 80 + market_level * 60

func purchase_market() -> bool:
	if market_level >= MARKET_MAX_LEVEL:
		return false
	var cost := get_market_cost()
	if money < cost:
		return false
	money -= cost
	market_level += 1
	_persist()
	return true

## Reef Charter: one extra fish bump tolerated per dive.
func get_reef_bonus_lives() -> int:
	return reef_bonus_lives

func get_reef_lives_cost() -> int:
	return 100 + reef_bonus_lives * 80

func purchase_reef_lives() -> bool:
	if reef_bonus_lives >= REEF_LIVES_MAX_LEVEL:
		return false
	var cost := get_reef_lives_cost()
	if money < cost:
		return false
	money -= cost
	reef_bonus_lives += 1
	_persist()
	return true

## One-time 1500$ gift. Pure prestige: the title is earned, not rented.
const ISLAND_PATRON_COST := 1500

func purchase_island_patron() -> bool:
	if island_patron:
		return false
	if money < ISLAND_PATRON_COST:
		return false
	money -= ISLAND_PATRON_COST
	island_patron = true
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

## record_reef is called at the end of a dive. Depth is a separate argument
## because it grows with vertical reach, not with garbage; the old code stored
## garbage into best_reef_depth, so the "best depth" it showed was a kg count.
func record_reef(garbage: float, fish: int, depth: float = 0.0) -> void:
	reef_garbage = garbage
	reef_fish = fish
	lifetime_garbage_kg += int(round(garbage))
	if int(depth) > best_reef_depth:
		best_reef_depth = int(depth)
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

# --- Stories: messages in a bottle ---

func is_story_read(id: String) -> bool:
	return bottles_read.has(id)


## Marks a bottle read and persists. Achievement evaluation happens inside
## _persist, so the Tide Keeper card fires on its own once all are found.
func mark_story_read(id: String) -> void:
	if id.is_empty() or bottles_read.has(id):
		return
	bottles_read.append(id)
	bottle_read.emit(bottles_read.size())
	_persist()

## One-time gift for completing the set. Callers (the world banner) drain
## this on load so the reward plays as a card, not as silent money.
func try_grant_tide_gift() -> Dictionary:
	if tide_gift_granted:
		return {}
	if bottles_read.size() < 3:
		return {}
	tide_gift_granted = true
	add_earnings(TIDE_GIFT_MONEY)
	return {
		"title": "TIDE'S GIFT",
		"subtitle": "The island thanks its keeper. +$%d" % TIDE_GIFT_MONEY,
	}


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


# --- Island Circuit ---

## Records that the player entered a station. Repeating a station inside the
## same circuit is ignored, so the bonus cannot be farmed by bouncing on one
## pad. The third distinct stop closes the circuit.
## Returns true on the visit that completed it.
func record_station_visit(station_id: String) -> bool:
	if station_id.is_empty() or circuit_visits.has(station_id):
		return false
	
	circuit_visits.append(station_id)
	circuit_progress_changed.emit(circuit_visits.duplicate())
	
	if circuit_visits.size() < CIRCUIT_STATIONS.size():
		_persist()
		return false
	
	circuit_visits.clear()
	circuits_completed += 1
	_pending_circuit_celebrations += 1
	add_earnings(CIRCUIT_BONUS_MONEY)
	
	circuit_progress_changed.emit([])
	island_circuit_completed.emit(circuits_completed)
	return true


## Hands the world HUD the celebrations it owes the player, then forgets them
## so the card plays exactly once per completed circuit.
func consume_circuit_celebrations() -> int:
	var owed := _pending_circuit_celebrations
	_pending_circuit_celebrations = 0
	return owed


## True when this station is already ticked off in the current circuit.
func has_visited_station(station_id: String) -> bool:
	return circuit_visits.has(station_id)


# --- Achievements ---
# One evaluation point: _persist() already runs after every state change, so
# achievements need no call sites. Conditions read the same public fields the
# rest of the game writes; the unlock itself only appends an id and emits.

func is_achievement_unlocked(id: String) -> bool:
	return unlocked_achievements.has(id)


func achievement_count() -> int:
	return unlocked_achievements.size()


func achievement_total() -> int:
	return AchievementCatalog.total()


## Catalogue copy for the stats page (never mutated).
func achievement_definitions() -> Array[Dictionary]:
	return AchievementCatalog.definitions()


## Marks every achievement whose condition is already met. `silent` is used by
## restore(): a legacy save must not fire a burst of cards for milestones the
## player earned before this system existed.
func _evaluate_achievements(silent: bool = false) -> void:
	for def in AchievementCatalog.definitions():
		var id := String(def.get("id", ""))
		if id.is_empty() or unlocked_achievements.has(id):
			continue
		if not AchievementCatalog.is_met(id, self):
			continue
		
		unlocked_achievements.append(id)
		if not silent:
			_pending_achievement_ids.append(id)
			achievement_unlocked.emit(id, String(def.get("title", id)), String(def.get("subtitle", "")))


## Drains card-ready copies of achievements earned while the banner was not
## loaded. Safe to call every frame: it returns [] once the queue is empty.
func consume_pending_achievements() -> Array[Dictionary]:
	if _pending_achievement_ids.is_empty():
		return []
	
	var ready: Array[Dictionary] = []
	for id in _pending_achievement_ids:
		var def := AchievementCatalog.find(id)
		if not def.is_empty():
			ready.append(def.duplicate())
	_pending_achievement_ids.clear()
	return ready


## Puts a card back when the map unloads before it could be seen (the player
## steps into a portal right after earning it).
func requeue_achievement_card(id: String) -> void:
	if id.is_empty() or _pending_achievement_ids.has(id):
		return
	_pending_achievement_ids.append(id)


## Same, for a circuit card that was still queued at unload.
func requeue_circuit_celebration() -> void:
	_pending_circuit_celebrations += 1


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
	_evaluate_achievements()
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
		"market_level": market_level,
		"reef_bonus_lives": reef_bonus_lives,
		"island_patron": island_patron,
		"bottles_read": bottles_read,
		"tide_gift_granted": tide_gift_granted,
		"quests_completed": quests_completed,
		"lifetime_garbage_kg": lifetime_garbage_kg,
		"harbor_hero_granted": harbor_hero_granted,
		"circuits_completed": circuits_completed,
		"achievements": unlocked_achievements,
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
	lifetime_garbage_kg = int(data.get("lifetime_garbage_kg", 0))
	
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
	market_level = int(data.get("market_level", 0))
	reef_bonus_lives = int(data.get("reef_bonus_lives", 0))
	island_patron = bool(data.get("island_patron", false))
	bottles_read.clear()
	for id in data.get("bottles_read", []):
		bottles_read.append(str(id))
	tide_gift_granted = bool(data.get("tide_gift_granted", false))
	harbor_hero_granted = bool(data.get("harbor_hero_granted", false))
	circuits_completed = int(data.get("circuits_completed", 0))
	
	unlocked_achievements.clear()
	for id in data.get("achievements", []):
		unlocked_achievements.append(str(id))
	# Old saves predate achievements: bank whatever they already earned
	# without firing cards, then persist the backfill with the rest of the
	# save (callers write after restore anyway).
	_evaluate_achievements(true)
	
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
	lifetime_garbage_kg = 0
	
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
	market_level = 0
	reef_bonus_lives = 0
	island_patron = false
	bottles_read.clear()
	tide_gift_granted = false
	harbor_hero_granted = false
	circuits_completed = 0
	circuit_visits.clear()
	_pending_circuit_celebrations = 0
	unlocked_achievements.clear()
	_pending_achievement_ids.clear()
	
	trash_by_type.clear()
	for t in DEFAULT_TRASH_TYPES:
		trash_by_type[t] = 0
		
	_recompute_inventory()
