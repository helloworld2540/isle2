extends RefCounted

## Pure quest rules for WorldNPC. The node keeps the visuals, save flags and
## dialogue flow; everything that can be derived from its exported quest fields
## (which tier is active, what a turn-in costs, whether the reward fits) lives
## here so the HUD tracker, the dialogue panel and the turn-in handler read one
## implementation.
##
## `npc` is intentionally untyped: the callers pass a WorldNPC, and tests can
## pass any object exposing the same fields. Bag facts come from GameState,
## accessed via the `state` parameter when provided, or from the scene tree
## root when running in a full game context.
##
## When running as a tool script (-s), callers should pass the GameState
## instance via the `state` parameter, e.g.: NpcQuests.gift_fits(state, "Polyethylene", 5)


const Inventory := preload("res://scripts/inventory.gd")


## The tier this NPC is currently offering, or 0 when the line is finished.
static func active_tier(npc) -> int:
	if npc == null or not npc.get("_visited_flag"):
		return 0
	var qd := bool(npc.get("_quest_done") or false)
	if not qd and int(npc.get("quest_amount") or 0) > 0:
		return 1
	var qd2 := bool(npc.get("_quest2_done") or false)
	if qd and not qd2 and int(npc.get("quest2_amount") or 0) > 0:
		return 2
	return 0


## All data for one quest tier in a single shape, so callers stop repeating
## the same tier-1/tier-2 conditionals.
static func config(npc, tier: int) -> Dictionary:
	if npc == null:
		return {}
	match tier:
		1:
			var mat = npc.get("quest_material")
			if mat == null:
				mat = ""
			var amt = npc.get("quest_amount")
			if amt == null:
				amt = 0
			var rw_mat = npc.get("quest_reward_mat")
			if rw_mat == null:
				rw_mat = ""
			var rw_amt = npc.get("quest_reward_amount")
			if rw_amt == null:
				rw_amt = 0
			return {
				"material": mat,
				"amount": int(amt),
				"reward_material": rw_mat,
				"reward_amount": int(rw_amt),
			}
		2:
			var mat = npc.get("quest2_material")
			if mat == null:
				mat = ""
			var amt = npc.get("quest2_amount")
			if amt == null:
				amt = 0
			var rw_mat = npc.get("quest2_reward_mat")
			if rw_mat == null:
				rw_mat = ""
			var rw_amt = npc.get("quest2_reward_amount")
			if rw_amt == null:
				rw_amt = 0
			return {
				"material": mat,
				"amount": int(amt),
				"reward_material": rw_mat,
				"reward_amount": int(rw_amt),
			}
	return {}


static func has_items(npc, tier: int, state = null) -> bool:
	var data := config(npc, tier)
	if data.is_empty():
		return false
	
	var gs = state
	if gs == null:
		gs = Engine.get_main_loop().root.get_node_or_null("GameState")
	
	if gs == null:
		return false
		
	var mat = data.get("material")
	var amount = data.get("amount")
	
	var trash = {}
	if gs is Dictionary:
		trash = gs.get("trash_by_type", {})
	elif gs.has_method("get_trash_by_type"):
		trash = gs.get_trash_by_type()
	else:
		trash = gs.get("trash_by_type")
		
	var have := int(trash.get(mat, 0))
	return have >= amount


## Snapshot for the HUD quest tracker.
static func entry(npc, state = null) -> Dictionary:
	var tier := active_tier(npc)
	if tier == 0:
		return {}
	var data := config(npc, tier)
	var mat = data.get("material")
	var amount = data.get("amount")
	
	var gs = state
	if gs == null:
		gs = Engine.get_main_loop().root.get_node_or_null("GameState")
	
	if gs == null:
		return {}
		
	var trash = {}
	if gs is Dictionary:
		trash = gs.get("trash_by_type", {})
	elif gs.has_method("get_trash_by_type"):
		trash = gs.get_trash_by_type()
	else:
		trash = gs.get("trash_by_type")
		
	var have := int(trash.get(mat, 0))
	
	return {
		"npc": npc.get("npc_name"),
		"tier": tier,
		"material": mat,
		"amount": amount,
		"have": mini(have, amount),
		"ready": have >= amount,
	}


## Whether the NPC's first-visit gift of `amount` units of `mat` still fits in
## the bag right now. A full bag means the gift is not given this visit; the
## player is warned to sell at the shop instead, and the visit stays pending so
## the gift can be offered again once the bag has room.
static func gift_fits(mat: String, amount: int, state = null) -> bool:
	if amount <= 0:
		return true
	
	var gs = state
	if gs == null:
		gs = Engine.get_main_loop().root.get_node_or_null("GameState")
	
	if gs == null:
		return true
		
	var weights = {}
	if gs is Dictionary:
		weights = gs.get("TRASH_WEIGHTS", {})
	elif gs.has_method("get_trash_weights"):
		weights = gs.get_trash_weights()
	else:
		weights = gs.get("TRASH_WEIGHTS")
		
	var unit_weight: int = max(1, int(weights.get(mat, 1)))
	var free := Inventory.free_space(gs)
		
	return free >= amount * unit_weight


## Everything the dialogue needs to decide whether the turn-in button is live:
## what is required, what is held, and whether the reward still fits after the
## quest items leave the bag.
static func turn_in(npc, tier: int, state = null) -> Dictionary:
	var data := config(npc, tier)
	if data.is_empty():
		return {}
	
	var gs = state
	if gs == null:
		gs = Engine.get_main_loop().root.get_node_or_null("GameState")
	
	if gs == null:
		return {}
	
	var mat = data.get("material")
	var amount = data.get("amount")
	var rw_mat = data.get("reward_material")
	var rw_amt = data.get("reward_amount")
	
	var weights = {}
	if gs is Dictionary:
		weights = gs.get("TRASH_WEIGHTS", {})
	elif gs.has_method("get_trash_weights"):
		weights = gs.get_trash_weights()
	else:
		weights = gs.get("TRASH_WEIGHTS")
		
	var trash = {}
	if gs is Dictionary:
		trash = gs.get("trash_by_type", {})
	elif gs.has_method("get_trash_by_type"):
		trash = gs.get_trash_by_type()
	else:
		trash = gs.get("trash_by_type")
		
	var have := int(trash.get(mat, 0))
	var freed_weight: int = amount * int(weights.get(mat, 1))
	var reward_weight: int = rw_amt * int(weights.get(rw_mat, 1))
	var free := Inventory.free_space(gs)
	
	var room_after: int = free + freed_weight
	
	return {
		"material": mat,
		"amount": amount,
		"reward_material": rw_mat,
		"reward_amount": rw_amt,
		"have": have,
		"fits": rw_amt <= 0 or room_after >= reward_weight,
	}


## Per-islander flavour line that rotates with the visit count. Kept as data so
## adding an NPC needs no dialogue code.
static func banter(npc_id: String) -> Array:
	match npc_id:
		"npc_mara":
			return ["The garden looks greener when you recycle.", "I swept the beach twice this morning!", "Ever notice glass sparkles in the tide?"]
		"npc_tom":
			return ["The sea is calm — perfect diving weather.", "Don't let the fish stare you down!", "Nylon and coffee keep me going."]
		"npc_nina":
			return ["Shop's freshly stocked today!", "Bulk sales mean bonus days.", "I love the clink of glass rewards."]
		"npc_kai":
			return ["Shelves empty; bring me Glass!", "A clean shop is a happy shop.", "Polypropylene pays the rent around here."]
		_:
			return []