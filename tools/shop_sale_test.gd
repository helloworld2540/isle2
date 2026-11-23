extends SceneTree

## Shop sale runtime gate.
##
## `economy_audit.py` checks the price constants; this drives the real shop
## scene's handlers so the wiring cannot drift: Sell All must pay exactly the
## ledger quote, bank lifetime earnings, empty the stock, and Undo must return
## both the goods and the money with no residual profit. Both the bulk and the
## sub-threshold path is exercised, and the sale must survive a save/restore
## round trip (the stock is gone from disk too).
##
## Run with autoloads:
##   XDG_DATA_HOME=/tmp/isle2_verify godot --headless --path . -s tools/shop_sale_test.gd
## Refuses to run if real player slots exist. Exits 0 on success, 1 otherwise.
## Wired into tools/all_audits.sh.

## Loaded at runtime: autoload globals (GameState, TideReport, …) are not
## resolvable at compile time inside a `-s` main-loop script, so preloading a
## scene or script that reads them fails the harness build.
## However, we can instantiate them manually for the test context.
const SHOP_SCENE_PATH := "res://scenes/shop.tscn"
const LEDGER_PATH := "res://scripts/shop_ledger.gd"

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
var ShopLedger: GDScript

func _initialize() -> void:
	_start_time = Time.get_ticks_msec()
	await process_frame
	var slot_dir := ProjectSettings.globalize_path("user://slots")
	if DirAccess.dir_exists_absolute(slot_dir) and not DirAccess.get_files_at(slot_dir).is_empty():
		print(C_YELLOW + "SKIP:" + C_RESET + " player slots present at " + slot_dir + ", not touching them")
		quit(0)
		return
	_print_header("Shop Sale Tests")

	## Access the GameState autoload. Autoloads are root Node children, not
	## engine singletons, so Engine.get_singleton() never finds them here.
	var gs: Node = root.get_node("GameState")
	if gs == null:
		# Fallback: build one from the script if the autoload did not register.
		gs = (load("res://scripts/game_state.gd") as GDScript).new()
		gs.name = "GameState"
		root.add_child(gs)
	ShopLedger = load(LEDGER_PATH)
	gs.call("reset")
	gs.set("money", 0)
	gs.set("lifetime_earnings", 0)

	# Six Polyethylene (1 kg each): one unit over the five-unit bulk threshold,
	# and light enough that the 10 kg starting bag can take an undo back.
	var bag: Dictionary = gs.get("trash_by_type")
	bag.clear()
	for mat in ["Polyethylene", "Polypropylene", "Glass", "Nylon", "Reef Debris"]:
		bag[mat] = 0
	bag["Polyethylene"] = 6
	gs.call("_recompute_inventory")
	var weight_before := int(gs.call("get_inventory_weight"))

	var shop: Node = (load(SHOP_SCENE_PATH) as PackedScene).instantiate()
	root.add_child(shop)
	await process_frame

	# --- Bulk sale through the real handler.
	var quote_bulk: Dictionary = ShopLedger.quote("Polyethylene", 6)
	_check(not quote_bulk.is_empty(), "ledger quotes a 6-unit sale")
	_check(bool(quote_bulk.get("bulk", false)), "6 units earns the bulk rate")
	var expected_bulk := int(quote_bulk.get("earnings", 0))
	var unit_quote: Dictionary = ShopLedger.quote("Polyethylene", 1)
	var unit_price := int(unit_quote.get("earnings", 0))
	_check(expected_bulk > 6 * unit_price, "bulk payout beats unit price (%d$)" % expected_bulk)
	shop.call("_sell_qty", "Polyethylene", 6)
	_check(int(gs.get("money")) == expected_bulk, "Sell paid the ledger quote exactly (%d$)" % expected_bulk)
	_check(int(gs.get("lifetime_earnings")) == expected_bulk, "lifetime earnings banked the same amount")
	_check(int((gs.get("trash_by_type") as Dictionary).get("Polyethylene", -1)) == 0, "stock emptied")
	_check(int(gs.call("get_inventory_weight")) == weight_before - 6, "bag weight dropped by 6 kg")

	# --- Undo through the real handler: money and goods both come back.
	shop.call("_undo_last_sale")
	_check(int(gs.get("money")) == 0, "undo clawed the money back (0$)")
	_check(int(gs.get("lifetime_earnings")) == 0, "undo clawed lifetime earnings back")
	_check(int((gs.get("trash_by_type") as Dictionary).get("Polyethylene", -1)) == 6, "undo restored all 6 units")
	_check(int(gs.call("get_inventory_weight")) == weight_before, "undo restored bag weight")

	# --- A second, sub-threshold sale pays the plain unit price.
	var quote_small: Dictionary = ShopLedger.quote("Polyethylene", 3)
	_check(not bool(quote_small.get("bulk", true)), "3 units does not earn bulk")
	var expected_small := int(quote_small.get("earnings", 0))
	shop.call("_sell_qty", "Polyethylene", 3)
	_check(int(gs.get("money")) == expected_small, "small sale paid the plain quote (%d$)" % expected_small)
	_check(int((gs.get("trash_by_type") as Dictionary).get("Polyethylene", -1)) == 3, "small sale left 3 units")

	# --- The sale is durable: a reload from disk sees the sold stock and cash.
	gs.call("_write_save")
	gs.set("money", -1)
	(gs.get("trash_by_type") as Dictionary)["Polyethylene"] = 99
	gs.call("restore")
	_check(int(gs.get("money")) == expected_small, "sale survives a save/restore round trip (money)")
	_check(int((gs.get("trash_by_type") as Dictionary).get("Polyethylene", -1)) == 3, "sale survives a save/restore round trip (stock)")

	_print_summary()
	# Let the receipt/undo animations finish and retire before the tree exits;
	# quitting mid-reflow makes the stack's own cleanup noisy.
	await create_timer(2.0).timeout
	shop.queue_free()
	await process_frame
	quit(0 if _fails == 0 else 1)

func _check(condition: bool, label: String) -> void:
	if condition:
		_passes += 1
		print(C_GREEN + "✓" + C_RESET + " " + label)
	else:
		_fails += 1
		print(C_RED + "✗" + C_RESET + " " + label)


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
