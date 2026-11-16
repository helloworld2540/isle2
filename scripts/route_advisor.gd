extends RefCounted

## Suggests the next stop on the island loop from what is in the player's bag.
## Pure, read-only logic shared by the HUD line and the portal highlight, so
## the text in the corner and the glowing pad can never disagree.
##
## The scene tree is passed in rather than reached statically (a RefCounted has
## no get_tree()), and NPCs are only touched through their public
## get_active_quest(), keeping this decoupled from WorldNPC internals.
##
## Once the player maxes Market Contact (the last market upgrade) the loop's
## economics change: every unit sold pays peak price, so a bench trip is less
## urgent than simply diving deeper. The rules below re-weight for that state —
## haul treatment over sort treatment.

const STATION_LABELS: Dictionary = {
	"reef_rescue": "1 · Reef Rescue",
	"upcycle": "2 · Upcycle",
	"shop": "3 · Shop",
}

## Bag ratio that counts as "nearly full" and makes a selling trip worth it.
const HEAVY_RATIO := 0.85
## Bag ratio above which selling early beats another dive (mature market).
const MATURE_SELL_RATIO := 0.6

## True once Market Contact is maxed — the pricing ceiling is reached and the
## advice should stop optimising for $/unit and start optimising for depth.
static func _market_maxed() -> bool:
	return GameState.market_level >= GameState.MARKET_MAX_LEVEL

## Returns {station, label, reason}. station is "npc" for a turn-in errand,
## otherwise one of the CIRCUIT_STATIONS ids.
static func next_stop(tree: SceneTree) -> Dictionary:
	var capacity := maxi(1, GameState.get_inventory_capacity())
	var weight := GameState.get_inventory_weight()
	var debris := int(GameState.trash_by_type.get("Reef Debris", 0))
	
	# A full bag blocks every other activity, so selling wins outright.
	if weight >= capacity:
		return _station("shop", "bag full, sell the haul")
	
	var quest := _ready_quest(tree)
	if not quest.is_empty():
		return {
			"station": "npc",
			"label": String(quest.get("npc", "An islander")),
			"reason": "turn in %d %s" % [int(quest.get("amount", 0)), String(quest.get("material", ""))],
		}
	
	# Debris is dead weight until the bench turns it into material. A maxed-out
	# market blunts the urgency — with peak prices, one more dive beats a sort
	# trip unless the bag is already getting heavy.
	if debris > 0 and not _market_maxed():
		return _station("upcycle", "%d Reef Debris to sort" % debris)
	
	if _market_maxed() and float(weight) / float(capacity) >= MATURE_SELL_RATIO and weight > 0:
		return _station("shop", "prices maxed — cash in soon")
	
	if _market_maxed() and debris > 0:
		return _station("upcycle", "%d Reef Debris still to sort (prices maxed)" % debris)
	
	if float(weight) / float(capacity) >= HEAVY_RATIO:
		return _station("shop", "bag nearly full, sell soon")
	
	if _market_maxed():
		return _station("reef_rescue", "prices maxed — dive deeper")
	
	return _station("reef_rescue", "gather a fresh haul")


## Linked-list-free helper so the dictionary shape stays in one place.
static func _station(id: String, reason: String) -> Dictionary:
	return {
		"station": id,
		"label": String(STATION_LABELS.get(id, id)),
		"reason": reason,
	}


## First NPC whose active quest is already satisfied by the bag.
static func _ready_quest(tree: SceneTree) -> Dictionary:
	if tree == null:
		return {}
	for npc in tree.get_nodes_in_group("npc"):
		if not npc.has_method("get_active_quest"):
			continue
		var quest: Dictionary = npc.get_active_quest()
		if not quest.is_empty() and bool(quest.get("ready", false)):
			return quest
	return {}
