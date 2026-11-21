extends SceneTree

## Gift-fit gate for the world-map NPCs.
##
## THE HARBOR HERO's first-visit gift must never be swallowed by a full bag:
## the dialogue defers the gift and warns the player to sell at the shop
## instead (NpcQuests.gift_fits + the turn-in fit check in WorldNPC). The pure
## rules live here so the boundary — gift weight vs free bag capacity, and
## reward-vs-quest weight accounting at turn-in — stay pinned.
##
## Run with autoloads:
##   godot --headless --path . -s tools/npc_gift_test.gd
## Refuses to run if real player slots exist. Exits 0 on success, 1 otherwise.
## Wired into tools/all_audits.sh.

const NpcQuests := preload("res://scripts/npc_quests.gd")

var _fails := 0

func _initialize() -> void:
	await process_frame
	var slot_dir := ProjectSettings.globalize_path("user://slots")
	if DirAccess.dir_exists_absolute(slot_dir) and not DirAccess.get_files_at(slot_dir).is_empty():
		print("SKIP: player slots present at %s, not touching them" % slot_dir)
		quit(0)
		return

	## Access GameState for the test: create a minimal instance used by NpcQuests.
	## The NpcQuests functions access gs.trash_by_type, gs.TRASH_WEIGHTS, gs.get_free_capacity().
	var gs: Dictionary = {"trash_by_type": {}, "TRASH_WEIGHTS": {"Polyethylene": 1, "Polypropylene": 2, "Glass": 3, "Nylon": 2, "Reef Debris": 1}, "free_capacity": 10}

	# --- First-visit gift: fits when the bag has the weight, not when it has
	# the units. 5 PET = 5 kg against a fresh 10 kg bag -> fits.
	_check(NpcQuests.gift_fits("Polyethylene", 5, gs), "gift of 5 PET fits an empty 10 kg bag")

	# Six PET already held (6 kg) -> the 5-unit gift no longer fits.
	gs.trash_by_type = {"Polyethylene": 6}
	_check(not NpcQuests.gift_fits("Polyethylene", 5, gs), "gift of 5 PET deferred when bag holds 6 kg")

	# A zero reward never gates (finished or flavour-only visits).
	gs.trash_by_type = {}
	_check(NpcQuests.gift_fits("Polyethylene", 0), "zero-amount gift always fits")

	# --- Upgraded bag: the same gift must fit in a bigger capacity.
	gs.inventory_capacity_level = 1
	gs.trash_by_type = {"Polyethylene": 15}
	_check(NpcQuests.gift_fits("Polyethylene", 5, gs), "gift of 5 PET fits a 20 kg bag holding 15 kg")
	gs.trash_by_type = {"Polyethylene": 16}
	_check(not NpcQuests.gift_fits("Polyethylene", 5, gs), "gift of 5 PET deferred when upgraded bag holds 16 kg")

	# --- Turn-in: the hand-in frees the quest weight before the reward lands,
	# so a reward that only fits post-consumption is accepted.
	gs.trash_by_type = {"Nylon": 2}
	gs.trash_inventory = 4
	var ok_npc := _make_npc("npc_harbor", "Harbor Hero", "Nylon", 2, "Glass", 2)
	var ok_turn: Dictionary = NpcQuests.turn_in(ok_npc, 1, gs)
	_check(bool(ok_turn.get("fits", false)), "turn-in accepted: quest goods freed room for the reward")
	_check(int(ok_turn.get("have", 0)) >= int(ok_turn.get("amount", 0)), "turn-in snapshot sees the held units")

	# --- Turn-in: the reward still must fit afterwards. Quest goods weigh 10 kg
	# (Nylon x5); the reward is 4 Glass (12 kg) — no room left after the hand-in
	# with base 10 kg capacity.
	gs.inventory_capacity_level = 0
	gs.trash_by_type = {"Nylon": 5}
	gs.trash_inventory = 10
	var full_npc := _make_npc("npc_full", "Full Hand", "Nylon", 5, "Glass", 4)
	var full_turn: Dictionary = NpcQuests.turn_in(full_npc, 1, gs)
	_check(not bool(full_turn.get("fits", false)), "turn-in denied when reward cannot fit after consuming the quest")

	print("npc_gift_test: %s" % ("PASS" if _fails == 0 else "%d failure(s)" % _fails))
	quit(0 if _fails == 0 else 1)


func _make_npc(npc_id: String, npc_name: String, quest_mat: String, quest_amt: int, reward_mat: String, reward_amt: int) -> Dictionary:
	return {
		"_visited_flag": true,
		"_quest_done": false,
		"_quest2_done": false,
		"npc_id": npc_id,
		"npc_name": npc_name,
		"quest_material": quest_mat,
		"quest_amount": quest_amt,
		"quest_reward_mat": reward_mat,
		"quest_reward_amount": reward_amt,
		"quest2_material": "",
		"quest2_amount": 0,
		"quest2_reward_mat": "",
		"quest2_reward_amount": 0,
	}


func _check(condition: bool, label: String) -> void:
	if condition:
		print("ok  %s" % label)
	else:
		print("FAIL %s" % label)
		_fails += 1
