extends SceneTree

## Regression harness for the courier's letter (the shop's $10 counter page).
## Isolated user data via XDG_DATA_HOME; refuses to run against real slots.
## Reads and restores GameState inline so a failing harness never strands
## the player's island either.

const SaveManagerScript := preload("res://scripts/save_manager.gd")

# ANSI color codes
const C_RESET := "\u001b[0m"
const C_BOLD := "\u001b[1m"
const C_RED := "\u001b[31m"
const C_GREEN := "\u001b[32m"
const C_YELLOW := "\u001b[33m"
const C_BLUE := "\u001b[34m"
const C_CYAN := "\u001b[36m"

var _fails := 0
var _passes := 0
var _skipped := 0
var _start_time: int = 0

func _initialize() -> void:
	_start_time = Time.get_ticks_msec()
	var slot_dir := ProjectSettings.globalize_path("user://slots")
	if DirAccess.dir_exists_absolute(slot_dir):
		print(C_YELLOW + "SKIP:" + C_RESET + " slots present at " + slot_dir + ", not touching them")
		quit(0)
		return
	_print_header("Courier Letter Tests")

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

	print("")
	_print_summary()
	quit(_fails)


func _check(ok: bool, what: String) -> void:
	if ok:
		_passes += 1
		print(C_GREEN + "✓" + C_RESET + " " + what)
	else:
		_fails += 1
		print(C_RED + "✗" + C_RESET + " " + what)


func _print_header(title: String) -> void:
	var line := "═".repeat(title.length() + 4)
	print(C_CYAN + line + C_RESET)
	print(C_CYAN + "  " + title + "  " + C_RESET)
	print(C_CYAN + line + C_RESET)
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
