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

var _fails := 0
var ShopLedger: GDScript

func _initialize() -> void:
	await process_frame
	var slot_dir := ProjectSettings.globalize_path("user://slots")
	if DirAccess.dir_exists_absolute(slot_dir) and not DirAccess.get_files_at(slot_dir).is_empty():
		print("SKIP: player slots present at %s, not touching them" % slot_dir)
		quit(0)
		return

	## Access GameState autoload (registered in project.godot [autoload]).
	## In -s mode, use Engine.get_singleton() if the name isn't auto-resolved.
	var gs = Engine.get_singleton("GameState")
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

	print("shop_sale_test: %s" % ("PASS" if _fails == 0 else "%d failure(s)" % _fails))
	# Let the receipt/undo animations finish and retire before the tree exits;
	# quitting mid-reflow makes the stack's own cleanup noisy.
	await create_timer(2.0).timeout
	shop.queue_free()
	await process_frame
	quit(0 if _fails == 0 else 1)

func _check(condition: bool, label: String) -> void:
	if condition:
		print("ok  %s" % label)
	else:
		print("FAIL %s" % label)
		_fails += 1
