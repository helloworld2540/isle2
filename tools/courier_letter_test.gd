extends SceneTree

## Regression harness for the courier's letter (the shop's $10 counter page).
## Isolated user data via XDG_DATA_HOME; refuses to run against real slots.
## Reads and restores GameState inline so a failing harness never strands
## the player's island either.

const SaveManagerScript := preload("res://scripts/save_manager.gd")

var _fails := 0

func _initialize() -> void:
	var slot_dir := ProjectSettings.globalize_path("user://slots")
	if DirAccess.dir_exists_absolute(slot_dir):
		print("SKIP: slots present at %s, not touching them" % slot_dir)
		quit(0)
		return

	var gs: Node = root.get_node("GameState")
	var money_before: int = gs.money
	var day_before: int = gs.tide_days_visited
	var letter_day_before: int = gs.courier_letter_day

	# Fresh purchase: spends exactly 10$, marks the day, refuses the re-buy.
	gs.money = 30
	gs.tide_days_visited = 5
	gs.courier_letter_day = -1
	_check(gs.purchase_courier_letter(), "purchase succeeds with 30$")
	_check(int(gs.money) == 20, "purchase deducts exactly 10$")
	_check(int(gs.courier_letter_day) == 5, "purchase marks the tide day")
	_check(gs.courier_letter_bought_today(), "bought_today reflects the purchase")
	_check(not gs.purchase_courier_letter(), "re-buy on the same tide day is refused")
	_check(int(gs.money) == 20, "refusal does not charge again")

	# Edge: not enough money — nothing happens.
	gs.money = 5
	gs.courier_letter_day = -1
	_check(not gs.purchase_courier_letter(), "cannot buy on 5$")
	_check(int(gs.money) == 5, "failed purchase spends nothing")

	# A new tide day unlocks the next page.
	gs.money = 50
	gs.tide_days_visited = 6
	_check(not gs.courier_letter_bought_today(), "new tide day re-opens the counter")
	_check(gs.purchase_courier_letter(), "new tide day purchase succeeds")
	_check(int(gs.money) == 40, "second-day purchase deducts exactly 10$")

	# Restore the in-memory state (and re-save nothing).
	gs.money = money_before
	gs.tide_days_visited = day_before
	gs.courier_letter_day = letter_day_before

	print("courier_letter_test: %d failure(s)" % _fails)
	quit(_fails)


func _check(ok: bool, what: String) -> void:
	print(("  ok  " if ok else "[FAIL] ") + what)
	if not ok:
		_fails += 1
