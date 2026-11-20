extends RefCounted

## Pure quest rules for WorldNPC. The node keeps the visuals, save flags and
## dialogue flow; everything that can be derived from its exported quest fields
## (which tier is active, what a turn-in costs, whether the reward fits) lives
## here so the HUD tracker, the dialogue panel and the turn-in handler read one
## implementation.
##
## `npc` is intentionally untyped: the callers pass a WorldNPC, and tests can
## pass any object exposing the same fields. Bag facts come from GameState, the
## same autoload the route advisor reads.


## The tier this NPC is currently offering, or 0 when the line is finished.
static func active_tier(npc) -> int:
	if npc == null or not npc._visited_flag:
		return 0
	if not npc._quest_done and npc.quest_amount > 0:
		return 1
	if npc._quest_done and not npc._quest2_done and npc.quest2_amount > 0:
		return 2
	return 0


## All data for one quest tier in a single shape, so callers stop repeating
## the same tier-1/tier-2 conditionals.
static func config(npc, tier: int) -> Dictionary:
	if npc == null:
		return {}
	match tier:
		1:
			return {
				"material": npc.quest_material,
				"amount": npc.quest_amount,
				"reward_material": npc.quest_reward_mat,
				"reward_amount": npc.quest_reward_amount,
			}
		2:
			return {
				"material": npc.quest2_material,
				"amount": npc.quest2_amount,
				"reward_material": npc.quest2_reward_mat,
				"reward_amount": npc.quest2_reward_amount,
			}
	return {}


static func has_items(npc, tier: int) -> bool:
	var data := config(npc, tier)
	if data.is_empty():
		return false
	var have := int(GameState.trash_by_type.get(data.get("material", ""), 0))
	return have >= int(data.get("amount", 0))


## Snapshot for the HUD quest tracker.
static func entry(npc) -> Dictionary:
	var tier := active_tier(npc)
	if tier == 0:
		return {}
	var data := config(npc, tier)
	var mat := String(data.get("material", ""))
	var amount := int(data.get("amount", 0))
	var have := int(GameState.trash_by_type.get(mat, 0))
	return {
		"npc": npc.npc_name,
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
static func gift_fits(mat: String, amount: int) -> bool:
	if amount <= 0:
		return true
	var unit_weight: int = max(1, int(GameState.TRASH_WEIGHTS.get(mat, 1)))
	return GameState.get_free_capacity() >= amount * unit_weight


## Everything the dialogue needs to decide whether the turn-in button is live:
## what is required, what is held, and whether the reward still fits after the
## quest items leave the bag.
static func turn_in(npc, tier: int) -> Dictionary:
	var data := config(npc, tier)
	if data.is_empty():
		return {}
	
	var mat := String(data.get("material", ""))
	var amount := int(data.get("amount", 0))
	var rw_mat := String(data.get("reward_material", ""))
	var rw_amt := int(data.get("reward_amount", 0))
	var have := int(GameState.trash_by_type.get(mat, 0))
	var freed_weight: int = amount * int(GameState.TRASH_WEIGHTS.get(mat, 1))
	var reward_weight: int = rw_amt * int(GameState.TRASH_WEIGHTS.get(rw_mat, 1))
	var room_after: int = GameState.get_free_capacity() + freed_weight
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