extends Node2D

const NOTIFICATION_QUEUE := preload("res://scenes/ui/notification_queue.tscn")
const FLOATING_TEXT_SCENE := preload("res://scenes/ui/floating_text.tscn")

const ShopLedger := preload("res://scripts/shop_ledger.gd")

## Fixed width for receipt labels; text right-aligns inside it so receipts
## always hug the right margin and never clip off-screen.
const RECEIPT_WIDTH := 460.0

# Scene-unique names (the scene sets unique_name_in_owner) so this list no
# longer has to track the layout tree.
@onready var coins: Label = %Coins
@onready var inv: Label = %Inventory
@onready var preview: Label = %Preview
@onready var tip: Label = %Tip
@onready var capacity_status: Label = %CapacityStatus
@onready var transaction_log: Label = %TransactionLog

@onready var row_polyethylene: HBoxContainer = %Row_Polyethylene
@onready var row_polypropylene: HBoxContainer = %Row_Polypropylene
@onready var row_glass: HBoxContainer = %Row_Glass
@onready var row_nylon: HBoxContainer = %Row_Nylon
@onready var row_reef_debris: HBoxContainer = %Row_ReefDebris

@onready var buy_cap_button: Button = %BuyCapButton
@onready var buy_market_button: Button = %BuyMarketButton
@onready var buy_reef_button: Button = %BuyReefButton
@onready var buy_patron_button: Button = %BuyPatronButton
@onready var buy_tidekeeper_button: Button = %BuyTidekeeperButton
@onready var money_note: Label = %MoneyNote

@onready var back_button: Button = %BackButton
@onready var undo_button: Button = %UndoButton

var _rows: Dictionary = {}
var _last_sale: Dictionary = {}
var _undo_in_progress := false
var _tx_log_lines: Array = []
var _hud_queue = null
var _receipts: Array[Control] = []

func _ready() -> void:
	TutorialDirector.scene_started("shop")
	_wire_ui()
	_tx_log_lines.clear()
	_refresh()
	AudioManager.play_bgm("shop")

func _wire_ui() -> void:
	if not row_polyethylene:
		return
	_rows["Polyethylene"] = _wire_row(row_polyethylene, "Polyethylene", int(GameState.SALE_PRICES["Polyethylene"]))
	if row_polypropylene:
		_rows["Polypropylene"] = _wire_row(row_polypropylene, "Polypropylene", int(GameState.SALE_PRICES["Polypropylene"]))
	if row_glass:
		_rows["Glass"] = _wire_row(row_glass, "Glass", int(GameState.SALE_PRICES["Glass"]))
	if row_nylon:
		_rows["Nylon"] = _wire_row(row_nylon, "Nylon", int(GameState.SALE_PRICES["Nylon"]))
	if row_reef_debris:
		_rows["Reef Debris"] = _wire_row(row_reef_debris, "Reef Debris", int(GameState.SALE_PRICES["Reef Debris"]))

	if back_button:
		back_button.pressed.connect(func():
			AudioManager.play_sfx("return")
			SceneTransition.change_scene("res://scenes/world.tscn")
		)
	if undo_button:
		undo_button.pressed.connect(_undo_last_sale)
	if buy_cap_button:
		buy_cap_button.pressed.connect(_buy_capacity)
	if buy_market_button:
		buy_market_button.pressed.connect(_buy_market)
	if buy_reef_button:
		buy_reef_button.pressed.connect(_buy_reef_lives)
	if buy_patron_button:
		buy_patron_button.pressed.connect(_buy_patron)
	if buy_tidekeeper_button:
		buy_tidekeeper_button.pressed.connect(_buy_tidekeeper)

func _wire_row(row: HBoxContainer, mat: String, price: int) -> Dictionary:
	var name_lbl: Label = row.get_node("Name")
	var sell_one: Button = row.get_node("SellOne")
	var sell_five: Button = row.get_node("SellFive")
	var sell_all: Button = row.get_node("SellAll")
	var value_lbl: Label = row.get_node("Value")
	var count_lbl: Label = row.get_node("Count")
	if name_lbl:
		name_lbl.text = "%s · %d$" % [mat, price]
	if sell_one:
		sell_one.pressed.connect(func(): _sell_qty(mat, 1))
	if sell_five:
		sell_five.pressed.connect(func(): _sell_qty(mat, ShopLedger.BULK_THRESHOLD))
	if sell_all:
		sell_all.pressed.connect(func(): _sell_all(mat))
	return {"name": name_lbl, "sell_one": sell_one, "sell_five": sell_five, "sell_all": sell_all, "value": value_lbl, "count": count_lbl}

func _refresh() -> void:
	if coins:
		coins.text = "Money: %d$   ·   Upcycle score: %d" % [GameState.money, GameState.upcycle_score]
	if inv:
		inv.text = _inv_text()
	if preview:
		preview.text = _preview_text()
	_refresh_undo_button()
	_update_shop_tip()
	_update_capacity_status()
	_refresh_purchases()
	for mat in GameState.SALE_PRICES.keys():
		_refresh_row(mat)

## Undo is only meaningful while a sale is remembered; show what it would do.
func _refresh_undo_button() -> void:
	if not undo_button:
		return
	if _last_sale.is_empty():
		undo_button.text = "Undo last sale"
		undo_button.disabled = true
		return
	undo_button.text = "Undo %s x%d (+%d$)" % [
		String(_last_sale.get("mat", "")),
		int(_last_sale.get("qty", 0)),
		int(_last_sale.get("earnings", 0)),
	]
	undo_button.disabled = _undo_in_progress
	# Surface the all-or-nothing rule before the press: if the lot cannot
	# fit back in the bag, say so on the tooltip instead of after a denial.
	var _mat := String(_last_sale.get("mat", ""))
	var _need := int(_last_sale.get("qty", 0)) * int(GameState.TRASH_WEIGHTS.get(_mat, 1))
	var _free := GameState.get_inventory_capacity() - GameState.get_inventory_weight()
	undo_button.tooltip_text = "Take the sale back" if _need <= _free else "Bag can't fit the lot back (needs %d kg free)" % (_need - _free)


func _update_shop_tip() -> void:
	if not tip:
		return
	var cap := GameState.get_inventory_capacity()
	if GameState.get_inventory_weight() >= cap:
		tip.text = "Tip: inventory full — sell or upgrade cap before another run."
		tip.modulate = Color(1.0, 0.45, 0.45, 1.0)
	elif float(GameState.get_inventory_weight()) / float(max(1, cap)) >= 0.8:
		tip.text = "Tip: inventory heavy — consider selling bulk for bonus."
		tip.modulate = Color(1.0, 0.85, 0.35, 1.0)
	else:
		tip.text = "Tip: sort efficiently for combo bonuses."
		tip.modulate = Color(0.85, 1.0, 0.75, 1.0)

func _refresh_purchases() -> void:
	var cost := GameState.get_capacity_money_cost()
	if buy_cap_button:
		buy_cap_button.text = "Bag +10 kg — %d$" % cost
		buy_cap_button.tooltip_text = "Expand your hold by 10 kg."
		buy_cap_button.disabled = not GameState.can_afford(cost)

	var market_cost := GameState.get_market_cost()
	if buy_market_button:
		if GameState.market_level >= GameState.MARKET_MAX_LEVEL:
			buy_market_button.text = "Market MAX (+%d$/unit)" % GameState.get_market_bonus()
			buy_market_button.disabled = true
		else:
			buy_market_button.text = "Market +1$/unit — %d$" % market_cost
			buy_market_button.tooltip_text = "+1$ per unit on every sale."
			buy_market_button.disabled = not GameState.can_afford(market_cost)

	var reef_cost := GameState.get_reef_lives_cost()
	if buy_reef_button:
		if GameState.reef_bonus_lives >= GameState.REEF_LIVES_MAX_LEVEL:
			buy_reef_button.text = "Reef Charter MAX (+%d bumps)" % GameState.get_reef_bonus_lives()
			buy_reef_button.disabled = true
		else:
			buy_reef_button.text = "Reef Charter — %d$" % reef_cost
			buy_reef_button.tooltip_text = "Tolerate one more fish bump per dive."
			buy_reef_button.disabled = not GameState.can_afford(reef_cost)

	if money_note:
		money_note.text = "Bag %d kg  ·  +%d$/unit  ·  %d dive bumps" % [
			GameState.get_inventory_capacity(), GameState.get_market_bonus(),
			3 + GameState.get_reef_bonus_lives(),
		]

	if buy_patron_button:
		if GameState.island_patron:
			buy_patron_button.text = "Patron of the Isle — owned"
			buy_patron_button.disabled = true
		else:
			buy_patron_button.text = "Patron of the Isle — %d$" % GameState.ISLAND_PATRON_COST
			buy_patron_button.tooltip_text = "A one-time island benefactor gift."
			buy_patron_button.disabled = not GameState.can_afford(GameState.ISLAND_PATRON_COST)

	if buy_tidekeeper_button:
		if GameState.tidekeeper:
			buy_tidekeeper_button.text = "Tidekeeper's Pact — funded"
			buy_tidekeeper_button.disabled = true
		else:
			buy_tidekeeper_button.text = "Tidekeeper's Pact — %d$" % GameState.TIDEKEEPER_COST
			buy_tidekeeper_button.tooltip_text = "+10 kg bag, permanently."
			buy_tidekeeper_button.disabled = not GameState.can_afford(GameState.TIDEKEEPER_COST)


func _buy_market() -> void:
	var cost := GameState.get_market_cost()
	if not GameState.purchase_market():
		_play_denied("Need %d$ for market contacts" % cost, "")
		_shake_control(buy_market_button)
		return
	AudioManager.play_sfx("upgrade", 1.1)
	_spawn_receipt("MARKET CONTACT +1$/unit  -%d$" % cost, Color(1.0, 0.9, 0.5, 1.0))
	_log_sale("Market contacts up to +%d$ per unit for %d$" % [GameState.get_market_bonus(), cost])
	_refresh()


func _buy_tidekeeper() -> void:
	if not GameState.purchase_tidekeeper():
		_play_denied("Need %d$ for the Tidekeeper's Pact" % GameState.TIDEKEEPER_COST, "")
		_shake_control(buy_tidekeeper_button)
		return
	AudioManager.play_sfx("achievement")
	_spawn_receipt("TIDEKEEPER'S PACT  -%d$" % GameState.TIDEKEEPER_COST, Color(0.55, 0.95, 0.85, 1.0))
	_log_sale("Tidekeeper's Pact: +10 kg bag for good — the reef is yours to keep")
	_refresh()


func _buy_patron() -> void:
	if not GameState.purchase_island_patron():
		_play_denied("Need %d$ to become a patron" % GameState.ISLAND_PATRON_COST, "")
		_shake_control(buy_patron_button)
		return
	AudioManager.play_sfx("upgrade", 0.85)
	_spawn_receipt("PATRON OF THE ISLE  -%d$" % GameState.ISLAND_PATRON_COST, Color(1.0, 0.75, 0.35, 1.0))
	_log_sale("Became Patron of the Isle — 1500$ gift")
	_refresh()


func _buy_reef_lives() -> void:
	var cost := GameState.get_reef_lives_cost()
	if not GameState.purchase_reef_lives():
		_play_denied("Need %d$ for a reef charter" % cost, "")
		_shake_control(buy_reef_button)
		return
	AudioManager.play_sfx("upgrade", 0.95)
	_spawn_receipt("REEF CHARTER +1 bump  -%d$" % cost, Color(0.6, 0.9, 1.0, 1.0))
	_log_sale("Reef charter: %d fish bumps tolerated" % (3 + GameState.get_reef_bonus_lives()))
	_refresh()


func _buy_capacity() -> void:
	var cost := GameState.get_capacity_money_cost()
	if not GameState.purchase_capacity_with_money():
		_play_denied("Need %d$ for a bigger bag" % cost, "")
		_shake_control(buy_cap_button)
		return
	
	AudioManager.play_sfx("upgrade", 1.05)
	_spawn_receipt("BAG +10 kg  -%d$" % cost, Color(0.7, 0.95, 1.0, 1.0))
	_log_sale("Bag expanded to %d kg for %d$" % [GameState.get_inventory_capacity(), cost])
	_refresh()


func _update_capacity_status() -> void:
	if not capacity_status:
		return
	var cap := GameState.get_inventory_capacity()
	var used := GameState.get_inventory_weight()
	var ratio := float(used) / float(max(1, cap))
	var color := Color(0.8, 0.95, 1.0, 1.0)
	if ratio >= 1.0:
		color = Color(1.0, 0.45, 0.45, 1.0)
	elif ratio >= 0.8:
		color = Color(1.0, 0.85, 0.35, 1.0)
	capacity_status.text = "Capacity %d/%d kg (%d%%) · +10 kg: %d$ here, or trash on the map" % [used, cap, int(round(ratio * 100.0)), GameState.get_capacity_money_cost()]
	capacity_status.modulate = color

func _refresh_row(mat: String) -> void:
	var row_data: Dictionary = _rows.get(mat, {})
	if row_data.is_empty():
		return
	var price: int = int(GameState.SALE_PRICES.get(mat, 0))
	var count: int = int(GameState.trash_by_type.get(mat, 0))
	var unit_value: int = price + GameState.get_market_bonus()
	var value: int = count * unit_value
	var bulk: bool = count >= ShopLedger.BULK_THRESHOLD
	var name_lbl: Label = row_data.get("name", null)
	if name_lbl:
		name_lbl.text = "%s · %d$" % [mat, unit_value]
	var btn_all: Button = row_data.get("sell_all", null)
	if btn_all:
		btn_all.text = "Sell All" + (" +25%" if bulk else "")
		btn_all.disabled = count <= 0
	var btn_five: Button = row_data.get("sell_five", null)
	if btn_five:
		btn_five.text = "Sell 5" + (" +25%" if bulk else "")
		btn_five.disabled = count < ShopLedger.BULK_THRESHOLD
	var value_lbl: Label = row_data.get("value", null)
	if value_lbl:
		value_lbl.text = "+%d$" % value
	var count_lbl: Label = row_data.get("count", null)
	if count_lbl:
		count_lbl.text = "x%d" % count
		var rarity: String = str(GameState.TRASH_RARITY.get(mat, "common"))
		var base_color := Color(0.8, 1.0, 0.85, 1.0)
		match rarity:
			"rare":
				base_color = Color(1.0, 0.85, 0.45, 1.0)
			"uncommon":
				base_color = Color(0.75, 0.9, 1.0, 1.0)
			_:
				base_color = Color(0.8, 1.0, 0.85, 1.0)
		if count <= 0:
			base_color = Color(0.9, 0.5, 0.5, 1.0)
		count_lbl.modulate = base_color
	var btn_one: Button = row_data.get("sell_one", null)
	if btn_one:
		btn_one.disabled = count <= 0

func _inv_text() -> String:
	var parts: Array[String] = []
	for k in GameState.trash_by_type.keys():
		var count := int(GameState.trash_by_type.get(k, 0))
		if count > 0:
			parts.append("%s x%d" % [k, count])
	if parts.is_empty():
		return "Holding: nothing — go gather material"
	return "Holding: " + ", ".join(parts)


func _preview_text() -> String:
	var total := 0
	for mat in GameState.SALE_PRICES.keys():
		total += int(GameState.trash_by_type.get(mat, 0)) * (int(GameState.SALE_PRICES.get(mat, 0)) + GameState.get_market_bonus())
	return "If you sell it all: %d$" % total

func _sell_qty(mat: String, qty: int) -> void:
	if qty < 1:
		return
	var sale := ShopLedger.apply(mat, qty)
	if sale.is_empty():
		_play_denied("No %s left" % mat, mat)
		return
	
	var units := int(sale.get("units", 0))
	var earnings := int(sale.get("earnings", 0))
	var bulk := bool(sale.get("bulk", false))
	var tag := " (bulk +25%)" if bulk else ""
	_last_sale = {"mat": mat, "price": int(sale.get("price", 0)), "qty": units, "earnings": earnings, "bulk": bulk}
	_log_sale("%s x%d%s → %d$" % [mat, units, tag, earnings])
	AudioManager.play_sfx("sale", 1.03)
	_feedback("Sold %d %s%s +%d$" % [units, mat, tag, earnings])
	_spawn_receipt("SOLD %s x%d%s  +%d$" % [mat, units, tag, earnings], Color(1.0, 0.85, 0.35, 1.0) if bulk else Color(0.7, 1.0, 0.6, 1.0), 1.35 if bulk else 1.0)
	TutorialDirector.notify("sold")
	TutorialDirector.nudge("upgrade")
	GameState._persist()
	_refresh()


func _sell_all(mat: String) -> void:
	var available := int(GameState.trash_by_type.get(mat, 0))
	if available <= 0:
		_play_denied("No %s left" % mat, mat)
		return
	var sale := ShopLedger.apply(mat, available)
	if sale.is_empty():
		_play_denied("No %s left" % mat, mat)
		return
	
	var units := int(sale.get("units", 0))
	var earnings := int(sale.get("earnings", 0))
	var bulk := bool(sale.get("bulk", false))
	var tag := " (bulk +25%)" if bulk else ""
	_last_sale = {"mat": mat, "price": int(sale.get("price", 0)), "qty": units, "earnings": earnings, "bulk": bulk}
	_log_sale("%s x%d%s → %d$" % [mat, units, tag, earnings])
	AudioManager.play_sfx("sale", 1.03)
	_feedback("Sold %d %s%s for %d$" % [units, mat, tag, earnings])
	_spawn_receipt("SOLD %s x%d%s  +%d$" % [mat, units, tag, earnings], Color(1.0, 0.85, 0.35, 1.0) if bulk else Color(0.7, 1.0, 0.6, 1.0), 1.35 if bulk else 1.0)
	TutorialDirector.notify("sold")
	TutorialDirector.nudge("upgrade")
	GameState._persist()
	_refresh()


func _log_sale(text: String) -> void:
	_tx_log_lines.append(text)
	if _tx_log_lines.size() > 6:
		_tx_log_lines.pop_front()
	if transaction_log:
		transaction_log.text = "\n".join(_tx_log_lines)

func _undo_last_sale() -> void:
	if _undo_in_progress:
		return
	if _last_sale.is_empty():
		_feedback("Nothing to undo")
		return
	var mat := String(_last_sale.get("mat", ""))
	var qty := int(_last_sale.get("qty", 0))
	var earnings := int(_last_sale.get("earnings", 0))
	var was_bulk := bool(_last_sale.get("bulk", false))
	if mat == "" or qty <= 0:
		_feedback("Nothing to undo")
		return
	_undo_in_progress = true
	var cap: int = GameState.get_inventory_capacity()
	var used := GameState.get_inventory_weight()
	var weight_each := int(GameState.TRASH_WEIGHTS.get(mat, 1))
	var needed := qty * weight_each
	var free := cap - used
	# All-or-nothing: a partial restore would claw back the full earnings while
	# returning only some of the goods — a silent loss for the player. Deny the
	# undo until the bag can take the whole lot back.
	if needed > free:
		_undo_in_progress = false
		_feedback("Bag too full — free %d kg to undo" % (needed - free))
		_shake_control(undo_button)
		AudioManager.play_sfx("sort_bad", 0.9)
		return
	var actual_units := qty
	GameState.trash_by_type[mat] = int(GameState.trash_by_type.get(mat, 0)) + actual_units
	GameState.money = max(0, GameState.money - earnings)
	GameState.lifetime_earnings = max(0, GameState.lifetime_earnings - earnings)
	_last_sale.clear()
	GameState._recompute_inventory()
	GameState._persist()
	# Release the busy flag before refreshing so the button re-enables here
	# instead of staying locked until the next sale.
	_undo_in_progress = false
	_refresh()
	_feedback("Undo restored %d/%d %s" % [actual_units, qty, mat])
	_play_undo_animation(mat, actual_units, earnings, was_bulk)
	AudioManager.play_sfx("return", 0.95)

func _play_denied(feedback_text: String, mat: String) -> void:
	_feedback(feedback_text)
	var row_data: Dictionary = _rows.get(mat, {})
	var btn_all: Button = row_data.get("sell_all", null)
	var btn_one: Button = row_data.get("sell_one", null)
	var btn_five: Button = row_data.get("sell_five", null)
	if btn_all:
		_shake_control(btn_all)
	if btn_one:
		_shake_control(btn_one)
	if btn_five:
		_shake_control(btn_five)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		AudioManager.play_sfx("return")
		SceneTransition.change_scene("res://scenes/world.tscn")

func _shake_control(ctrl: Control) -> void:
	if not ctrl:
		return
	var base := ctrl.position
	var tw := ctrl.create_tween()
	tw.tween_property(ctrl, "position", base + Vector2(-6,0), 0.05)
	tw.tween_property(ctrl, "position", base + Vector2(6,0), 0.05)
	tw.tween_property(ctrl, "position", base, 0.05)

func _ensure_hud_queue() -> void:
	if _hud_queue == null:
		_hud_queue = NOTIFICATION_QUEUE.instantiate()
		var parent := $"CanvasLayer" if $"CanvasLayer" else self
		parent.add_child(_hud_queue)

func _feedback(text: String) -> void:
	_ensure_hud_queue()
	_hud_queue.push(text, Color(0.85, 1.0, 0.5, 1.0), 1.2)

## Receipts live in a stack anchored to the top-right corner. Each new entry
## slides in from the right; when one expires the survivors reflow upward, so
## the column never keeps gaps from a burst of quick sales. `punch` > 1.0 plays
## a pop-in punch — bulk sales use it so the 25% bonus reads at a glance in a
## fast stack of receipts.
func _spawn_receipt(text: String, col: Color, punch: float = 1.0) -> void:
	var parent: Node = $"CanvasLayer" if has_node("CanvasLayer") else self
	var lbl := FLOATING_TEXT_SCENE.instantiate()
	lbl.z_index = 130
	lbl.rise_distance = 0.0
	lbl.hold_time = 1.4
	lbl.fade_out_time = 0.4
	lbl.punch_scale = punch
	parent.add_child(lbl)
	_receipts.append(lbl)
	lbl.tree_exited.connect(func(): _retire_receipt(lbl))

	var vp := get_viewport_rect().size
	lbl.modulate.a = 0.0
	lbl.present(text, col, 18)
	# Right-aligned text hugging the right margin: fixed-width label with
	# HORIZONTAL_ALIGNMENT_RIGHT means no off-screen clipping regardless of
	# how long the bulk line gets, without measuring the font at runtime.
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.custom_minimum_size = Vector2(RECEIPT_WIDTH, 0)
	lbl.size = Vector2(RECEIPT_WIDTH, 24.0)
	var rest_x := vp.x - RECEIPT_WIDTH - 24.0
	var slot_y := _receipt_slot_y(_receipts.size() - 1)
	lbl.position = Vector2(vp.x + 20.0, slot_y)

	# present() fades alpha and (rise_distance 0) leaves position alone.
	var tw := lbl.create_tween()
	tw.tween_property(lbl, "position:x", rest_x, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _receipt_slot_y(index: int) -> float:
	return 88.0 + float(index) * 26.0


func _retire_receipt(lbl: Control) -> void:
	_receipts.erase(lbl)
	_reflow_receipts()


## Undo animation: the ledger rewinds in three beats — a red "REVERSED" stamp
## punches in over the screen, a dark receipt slides back out to the right
## (the mirror of a sale receipt entering the stack), and the chips that
## changed hands (undo button, coin line, row count) punch and flash red.
## Split from _undo_last_sale so the state change stays readable and the
## presentation stays swappable.
func _play_undo_animation(mat: String, restored_qty: int, earnings: int, was_bulk: bool) -> void:
	var bulk_tag := " (bulk +25%)" if was_bulk else ""
	_spawn_stamp("REVERSED", Color(1.0, 0.42, 0.38, 1.0))
	_spawn_undo_receipt("UNDO %s x%d%s  -%d$" % [mat, restored_qty, bulk_tag, earnings], Color(1.0, 0.55, 0.4, 1.0))
	_punch_control(undo_button)
	_flash_control(transaction_log, Color(1.0, 0.55, 0.45, 1.0))
	_flash_control(coins, Color(1.0, 0.5, 0.4, 1.0))
	var row_data: Dictionary = _rows.get(mat, {})
	_flash_control(row_data.get("count", null), Color(1.0, 0.6, 0.45, 1.0))
	_punch_control(row_data.get("count", null))


## Exiting receipt for an undo. Deliberately kept OUT of the _receipts stack:
## it owns slot 0 for a moment and leaves to the right, so it never disturbs
## the reflow of fresh sale receipts behind it.
func _spawn_undo_receipt(text: String, col: Color) -> void:
	var parent: Node = $"CanvasLayer" if has_node("CanvasLayer") else self
	var lbl := FLOATING_TEXT_SCENE.instantiate()
	lbl.z_index = 131
	lbl.rise_distance = 0.0
	lbl.hold_time = 0.9
	lbl.fade_out_time = 0.35
	lbl.punch_scale = 1.3
	parent.add_child(lbl)
	var vp := get_viewport_rect().size
	lbl.present(text, col, 18)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.custom_minimum_size = Vector2(RECEIPT_WIDTH, 0)
	lbl.size = Vector2(RECEIPT_WIDTH, 24.0)
	var rest_x := vp.x - RECEIPT_WIDTH - 24.0
	lbl.position = Vector2(rest_x, _receipt_slot_y(0))
	# present() only fades alpha (rise_distance == 0), so the exit slide is safe to own.
	var tw := lbl.create_tween()
	tw.tween_interval(0.35)
	tw.tween_property(lbl, "position:x", vp.x + 60.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


## One-shot "REVERSED" stamp: oversized, back-eased punch-in, short hold.
## Sells the rewind without touching layout anywhere else on screen.
func _spawn_stamp(text: String, col: Color) -> void:
	var parent: Node = $"CanvasLayer" if has_node("CanvasLayer") else self
	var lbl := FLOATING_TEXT_SCENE.instantiate()
	lbl.z_index = 132
	lbl.rise_distance = 0.0
	lbl.hold_time = 0.65
	lbl.fade_out_time = 0.3
	lbl.punch_scale = 2.1
	parent.add_child(lbl)
	var vp := get_viewport_rect().size
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size = Vector2(300.0, 0)
	lbl.size = Vector2(300.0, 44.0)
	lbl.present(text, col, 34)
	lbl.position = Vector2(vp.x * 0.5 - 150.0, vp.y * 0.3)


## Scale punch for any control: snaps up then settles with a back ease. Used
## for tactile feedback on undo without stealing layout space.
func _punch_control(ctrl: Control) -> void:
	if not ctrl:
		return
	var base := ctrl.scale
	ctrl.scale = base * 1.28
	var tw := ctrl.create_tween()
	tw.tween_property(ctrl, "scale", base, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _reflow_receipts() -> void:
	var vp := get_viewport_rect().size
	for i in range(_receipts.size()):
		var lbl := _receipts[i]
		if not is_instance_valid(lbl):
			continue
		var target := Vector2(vp.x - RECEIPT_WIDTH - 24.0, _receipt_slot_y(i))
		var tw := lbl.create_tween()
		tw.tween_property(lbl, "position", target, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _flash_control(ctrl: Control, from_color: Color = Color(0.6, 1.0, 0.65, 1.0)) -> void:
	if not ctrl:
		return
	var tw := ctrl.create_tween()
	ctrl.modulate = from_color
	tw.tween_property(ctrl, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.45)
