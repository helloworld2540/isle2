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
var GameStateScript: GDScript

# ANSI color codes
const C_RESET := "\u001b[0m"
const C_BOLD := "\u001b[1m"
const C_DIM := "\u001b[2m"
const C_RED := "\u001b[31m"
const C_GREEN := "\u001b[32m"
const C_YELLOW := "\u001b[33m"
const C_BLUE := "\u001b[34m"
const C_MAGENTA := "\u001b[35m"
const C_CYAN := "\u001b[36m"
const C_WHITE := "\u001b[37m"

var _fails := 0
var _passes := 0
var _skipped := 0
var _start_time: int = 0

func _initialize() -> void:
	_start_time = Time.get_ticks_msec()
	await process_frame
	GameStateScript = load("res://scripts/game_state.gd") as GDScript
	var slot_dir := ProjectSettings.globalize_path("user://slots")
	if DirAccess.dir_exists_absolute(slot_dir) and not DirAccess.get_files_at(slot_dir).is_empty():
		print("%sSKIP:%s player slots present at %s, not touching them" % [C_YELLOW, C_RESET, slot_dir])
		quit(0)
		return

	_print_header("NPC Gift & Turn-in Tests")

	## Access GameState for the test: create a minimal instance used by NpcQuests.
	## The NpcQuests functions read the Inventory state off this mock through the
	## same fields GameState carries: trash_by_type plus the production TRASH_WEIGHTS
	## table and the inventory capacity level (the bag is 10 kg at level 0).
	var gs: Dictionary = {
		"trash_by_type": {},
		"TRASH_WEIGHTS": GameStateScript.TRASH_WEIGHTS,
		"inventory_capacity_level": 0,
	}

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
	var ok_npc := _make_npc("npc_harbor", "Harbor Hero", "Nylon", 2, "Glass", 2)
	var ok_turn: Dictionary = NpcQuests.turn_in(ok_npc, 1, gs)
	_check(bool(ok_turn.get("fits", false)), "turn-in accepted: quest goods freed room for the reward")
	_check(int(ok_turn.get("have", 0)) >= int(ok_turn.get("amount", 0)), "turn-in snapshot sees the held units")

	# --- Turn-in: the reward still must fit afterwards. Quest goods weigh 10 kg
	# (Nylon x5); the reward is 4 Glass (12 kg) — no room left after the hand-in
	# with base 10 kg capacity.
	gs.inventory_capacity_level = 0
	gs.trash_by_type = {"Nylon": 5}
	var full_npc := _make_npc("npc_full", "Full Hand", "Nylon", 5, "Glass", 4)
	var full_turn: Dictionary = NpcQuests.turn_in(full_npc, 1, gs)
	_check(not bool(full_turn.get("fits", false)), "turn-in denied when reward cannot fit after consuming the quest")

	_print_summary()
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
		_passes += 1
		print("%s✓%s %s" % [C_GREEN, C_RESET, label])
	else:
		_fails += 1
		print("%s✗%s %s" % [C_RED, C_RESET, label])


func _print_header(title: String) -> void:
	var line := "═".repeat(title.length() + 4)
	print("%s%s%s" % [C_CYAN, line, C_RESET])
	print("%s  %s  %s" % [C_CYAN, title, C_RESET])
	print("%s%s%s" % [C_CYAN, line, C_RESET])
	print("")


func _print_summary() -> void:
	var elapsed := (Time.get_ticks_msec() - _start_time) / 1000.0
	var total := _passes + _fails + _skipped
	var line := "─".repeat(50)
	
	print("")
	print(C_CYAN + line + C_RESET)
	print(C_BOLD + "RESULTS:" + C_RESET + " " + C_GREEN + str(_passes) + C_RESET + "  " + C_RED + "FAILED:" + C_RESET + " " + str(_fails) + "  " + C_YELLOW + "SKIPPED:" + C_RESET + " " + str(_skipped))
	var time_str := "%0.2f" % elapsed
	print(C_BOLD + "TOTAL:" + C_RESET + " " + str(total) + "  " + C_BLUE + "TIME:" + C_RESET + " " + time_str + "s")
	if _fails == 0:
		print(C_BOLD + "STATUS:" + C_RESET + " " + C_GREEN + "✓ ALL TESTS PASSED" + C_RESET)
	else:
		print(C_BOLD + "STATUS:" + C_RESET + " " + C_RED + "✗ " + str(_fails) + " TEST(S) FAILED" + C_RESET)
	print(C_CYAN + line + C_RESET)
