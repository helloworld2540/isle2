extends Node2D
class_name ShopMenu

const NOTIFICATION_QUEUE := preload("res://scenes/ui/notification_queue.tscn")
const RECEIPT_STACK_SCENE := preload("res://scenes/ui/receipt_stack.tscn")
const DIALOGUE_SCENE := preload("res://scenes/ui/npc_dialogue.tscn")

const ShopLedger := preload("res://scripts/shop_ledger.gd")
const CourierLetters := preload("res://scripts/courier_letters.gd")

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
@onready var buy_tide_tip_button: Button = %BuyTideTipButton
@onready var tide_tip_note: Label = %TideTipNote
@onready var buy_courier_letter_button: Button = %BuyCourierLetterButton
@onready var courier_letter_note: Label = %CourierLetterNote
@onready var tide_note: Label = %TideNote
@onready var money_note: Label = %MoneyNote

@onready var back_button: Button = %BackButton
@onready var undo_button: Button = %UndoButton

var _rows: Dictionary = {}
var _last_sale: Dictionary = {}
var _undo_in_progress := false
var _tx_log_lines: Array = []
var _hud_queue = null
var _stack: ReceiptStack = null

func _ready() -> void:
	TutorialDirector.scene_started("shop")
	# Flavor for the night shift: Night Drift nights smell different at the till.
	if TideReport.today_key() == "night_drift":
		_log_sale("The till smells of salt and moonlight tonight. Corl is humming something with too many verses.")
	# The island notices its keepers' centennials.
	if GameState.tide_days_visited == 100:
		_log_sale("The island marks its 100th tide today. Corl polishes the counter without being asked.")
	# The courier is done writing. Corl notices that too.
	if GameState.courier_letters_bought >= CourierLetters.count():
		_log_sale('Corl adds a note to the ledger: "The courier\'s post is done. Thank you."')
	# One-shot pointer to the dockhand's tip once the keeper can afford it.
	if GameState.money >= 100 and not GameState.harbor_tip_purchased():
		TutorialDirector.nudge("tip")
	_spawn_receipt_stack()
	_wire_ui()
	_tx_log_lines.clear()
	_refresh()
	AudioManager.play_bgm("shop")

func _spawn_receipt_stack() -> void:
	if _stack:
		return
	var stack := RECEIPT_STACK_SCENE.instantiate() as ReceiptStack
	var parent: Node = $"CanvasLayer" if has_node("CanvasLayer") else self
	parent.add_child(stack)
	_stack = stack

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
	if buy_tide_tip_button:
		buy_tide_tip_button.pressed.connect(_buy_tide_tip)
	if buy_courier_letter_button:
		buy_courier_letter_button.pressed.connect(_buy_courier_letter)

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

	if tide_note:
		if GameSettings.hide_tide:
			# The sea keeps its own counsel — and so does the counter. The order
			# still pays; it simply is not named (the row price shows the total).
			tide_note.text = "Today: the sea keeps its own counsel — and so do you."
		else:
			tide_note.text = "Today: %s  ·  standing order: %s +%d$" % [
				TideReport.summary(), ShopLedger.order_material(), ShopLedger.TIDE_ORDER_BONUS]

	if buy_courier_letter_button:
		var letter_i: int = GameState.courier_letters_bought
		var drawer_empty := letter_i >= CourierLetters.count()
		# Once the drawer is empty there's nothing left to buy — hide the
		# button instead of greying it, so the counter lists only what can
		# still happen.
		buy_courier_letter_button.visible = not drawer_empty
		if drawer_empty:
			pass
		elif GameState.courier_letter_bought_today():
			buy_courier_letter_button.text = "Courier's letter %d of %d — read for today" % [letter_i + 1, CourierLetters.count()]
			buy_courier_letter_button.tooltip_text = "One page a tide day. Come back on the next tide."
			buy_courier_letter_button.disabled = true
		else:
			buy_courier_letter_button.text = "Courier's letter %d of %d — %d$" % [letter_i + 1, CourierLetters.count(), GameState.COURIER_LETTER_COST]
			buy_courier_letter_button.tooltip_text = "One page a tide day, from the fin that passes by."
			buy_courier_letter_button.disabled = not GameState.can_afford(GameState.COURIER_LETTER_COST)
	if courier_letter_note:
		var letter_i: int = GameState.courier_letters_bought
		if letter_i >= CourierLetters.count():
			courier_letter_note.text = "The drawer is empty. Every page was read at this counter — the courier still crosses the strait for you."
		elif GameState.courier_letter_bought_today():
			courier_letter_note.text = "You read today's page at the counter. It did not keep."
		else:
			var remaining: int = CourierLetters.count() - GameState.courier_letters_bought
			courier_letter_note.text = "%d page%s left in the counter's stash. The counter keeps them for %d$." % [
				remaining, "s" if remaining != 1 else "", GameState.COURIER_LETTER_COST]

	if buy_tide_tip_button:
		var quiet := GameSettings.hide_tide
		if GameState.harbor_tip_purchased():
			buy_tide_tip_button.text = "Dockhand's secret — taken today" if quiet else "Dockhand's tip — bought today"
			buy_tide_tip_button.disabled = true
		else:
			buy_tide_tip_button.text = "Dockhand's quiet — %d$" % GameState.tip_cost() if quiet else "Dockhand's tide tip — %d$" % GameState.tip_cost()
			buy_tide_tip_button.tooltip_text = "Corl tells you tomorrow's tide without naming it aloud." if quiet else "Pay a dockhand to read tomorrow's tide to you."
			buy_tide_tip_button.disabled = not GameState.can_afford(GameState.tip_cost())
	if tide_tip_note and GameSettings.hide_tide:
		tide_tip_note.text = "Tomorrow's a secret, keeper. Corl's ledger: %d/7 whispers." % mini(GameState.harbor_tips_bought, 7) if not GameState.harbor_tip_purchased() else "Tomorrow's a secret. Corl's ledger: %d/7 whispers." % mini(GameState.harbor_tips_bought, 7)
	elif tide_tip_note:
		if GameState.harbor_tip_purchased():
			tide_tip_note.text = "Tomorrow: %s — plan the dive and the belt accordingly. His ledger: %d/7 whispers." % [GameState.tomorrow_tide_title(), mini(GameState.harbor_tips_bought, 7)]
		else:
			var streak_hint := " Regulars (3-day streak) pay $15." if GameState.tide_streak < GameState.HARBOR_TIP_DISCOUNT_STREAK else " You are a regular — $15 today."
			tide_tip_note.text = "A dockhand can tell you tomorrow's tide — for a price. His ledger: %d/7 whispers.%s" % [mini(GameState.harbor_tips_bought, 7), streak_hint]


func _buy_courier_letter() -> void:
	if GameState.courier_letters_bought >= CourierLetters.count():
		_stack.sale("COURIER'S LETTER\nThe drawer is empty.", Color(0.7, 0.85, 0.95, 1.0))
		_log_sale("The counter's letter drawer is empty. All %d pages read." % CourierLetters.count())
		return
	if not GameState.purchase_courier_letter():
		_play_denied("Need %d$ for the courier's letter" % GameState.COURIER_LETTER_COST, "")
		_shake_control(buy_courier_letter_button)
		return
	AudioManager.play_sfx("pickup", 1.5)
	var letter := CourierLetters.letter_at(GameState.courier_letter_index())
	_stack.sale("COURIER'S LETTER  -%d$\nA page, kept." % GameState.COURIER_LETTER_COST, Color(0.72, 0.94, 1.0, 1.0))
	_log_sale("A page from the courier, read at the counter.")
	# Corl keeps his own counsel — but he counts the letters.
	if GameState.courier_letters_bought == 1:
		_log_sale('Corl nods at the page: "From the courier? I do not ask about that one."')
	elif GameState.courier_letters_bought == 10:
		_log_sale('Corl taps the ledger: "Ten pages. You pay for paper like it is gospel."')
	if DIALOGUE_SCENE:
		var dialogue = DIALOGUE_SCENE.instantiate()
		get_tree().current_scene.add_child(dialogue)
		dialogue.present("The Courier's Letter", [letter])
	# One gentle pointer at the reef, once per save — after the letter, the
	# keeper should know the courier is a fish they can bump into.
	TutorialDirector.nudge("courier")
	_refresh()


func _buy_tide_tip() -> void:
	if not GameState.purchase_harbor_tip():
		_play_denied("Need %d$ for the dockhand's tip" % GameState.tip_cost(), "")
		_shake_control(buy_tide_tip_button)
		return
	AudioManager.play_sfx("upgrade", 1.15)
	if GameSettings.hide_tide:
		# No spoilers: the keeper pays a dockhand for a tide they cannot see.
		# The receipt gives them the fare and hands over nothing.
		_stack.sale("DOCKHAND'S QUIET  -%d$\nA secret, kept." % GameState.tip_cost(), Color(0.6, 0.85, 0.95, 1.0))
	else:
		var tip_text := "Tomorrow: %s" % GameState.tomorrow_tide_title()
		_stack.sale("DOCKHAND'S TIP  -%d$\n%s" % [GameState.tip_cost(), tip_text], Color(0.6, 0.9, 1.0, 1.0))
	_log_sale(_corl_line())
	# Corl marks the keeper's milestones — he counts days, and he counts you.
	var day := GameState.tide_days_visited
	match day:
		10:
			_log_sale('Corl taps the ledger once: "Ten days. You are not a customer anymore."')
		30:
			_log_sale('Corl slides an empty receipt: "Thirty days. Same time tomorrow."')
		50:
			_log_sale('Corl says nothing for a long time: "Fifty days. I stopped asking questions around the fortieth."')
	_refresh()


## Corl is never seen; he exists as lines in the log. He notices regulars.
## One line per lifetime purchase, rotating at the end — the cheapest
## characterisation in the game, and the most expensive per word.
func _corl_line() -> String:
	var n := GameState.harbor_tips_bought
	var tomorrow := GameState.tomorrow_tide_title()
	match n:
		1:
			return "Corl slides a folded paper across the counter: %s tomorrow. \"First one's on the house. It isn't.\"" % tomorrow
		2:
			return "Corl nods once: %s tomorrow. \"Small talk costs extra. The weather doesn't.\"" % tomorrow
		3:
			return "Corl taps the ledger: %s tomorrow. \"You keep coming back. The tide talks, I listen, everybody eats.\"" % tomorrow
		4:
			return "Corl without looking up: %s tomorrow. \"You're drinking tomorrow's weather like it's fresh fish. It is.\"" % tomorrow
		5:
			return "Corl, pencil behind his ear: %s tomorrow. \"Five mornings I sold you. You've never once asked my name.\"" % tomorrow
		6:
			return "Corl exhales at the ledger: %s tomorrow. \"Six. You're buying what I charge for the wind. Partly.\"" % tomorrow
		7:
			return "Corl finally looks at you: %s tomorrow. \"Seven days of tomorrow. You're the most patient fool I know. Tomorrow's free — 25$ anyway.\"" % tomorrow
		_:
			return "Corl folds the day away without a word: %s tomorrow." % tomorrow


func _buy_market() -> void:
	var cost := GameState.get_market_cost()
	if not GameState.purchase_market():
		_play_denied("Need %d$ for market contacts" % cost, "")
		_shake_control(buy_market_button)
		return
	AudioManager.play_sfx("upgrade", 1.1)
	_stack.sale("MARKET CONTACT +1$/unit  -%d$" % cost, Color(1.0, 0.9, 0.5, 1.0))
	_log_sale("Market contacts up to +%d$ per unit for %d$" % [GameState.get_market_bonus(), cost])
	_refresh()


func _buy_tidekeeper() -> void:
	if not GameState.purchase_tidekeeper():
		_play_denied("Need %d$ for the Tidekeeper's Pact" % GameState.TIDEKEEPER_COST, "")
		_shake_control(buy_tidekeeper_button)
		return
	AudioManager.play_sfx("achievement")
	# The pact is the island's biggest beat — ring the harbor bell over the
	# chord so it lands like a tide coming in, not a receipt.
	AudioManager.play_sfx("harbor_bell", 0.8)
	_stack.sale("TIDEKEEPER'S PACT  -%d$" % GameState.TIDEKEEPER_COST, Color(0.55, 0.95, 0.85, 1.0))
	_log_sale("Tidekeeper's Pact: +10 kg bag for good — the reef is yours to keep")
	_refresh()


func _buy_patron() -> void:
	if not GameState.purchase_island_patron():
		_play_denied("Need %d$ to become a patron" % GameState.ISLAND_PATRON_COST, "")
		_shake_control(buy_patron_button)
		return
	AudioManager.play_sfx("upgrade", 0.85)
	_stack.sale("PATRON OF THE ISLE  -%d$" % GameState.ISLAND_PATRON_COST, Color(1.0, 0.75, 0.35, 1.0))
	_log_sale("Became Patron of the Isle — 1500$ gift")
	_refresh()


func _buy_reef_lives() -> void:
	var cost := GameState.get_reef_lives_cost()
	if not GameState.purchase_reef_lives():
		_play_denied("Need %d$ for a reef charter" % cost, "")
		_shake_control(buy_reef_button)
		return
	AudioManager.play_sfx("upgrade", 0.95)
	_stack.sale("REEF CHARTER +1 bump  -%d$" % cost, Color(0.6, 0.9, 1.0, 1.0))
	_log_sale("Reef charter: %d fish bumps tolerated" % (3 + GameState.get_reef_bonus_lives()))
	_refresh()


func _buy_capacity() -> void:
	var cost := GameState.get_capacity_money_cost()
	if not GameState.purchase_capacity_with_money():
		_play_denied("Need %d$ for a bigger bag" % cost, "")
		_shake_control(buy_cap_button)
		return
	
	AudioManager.play_sfx("upgrade", 1.05)
	_stack.sale("BAG +10 kg  -%d$" % cost, Color(0.7, 0.95, 1.0, 1.0))
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
	var unit_value: int = price + GameState.get_market_bonus() + ShopLedger.order_bonus(mat)
	var value: int = count * unit_value
	var bulk: bool = count >= ShopLedger.BULK_THRESHOLD
	var name_lbl: Label = row_data.get("name", null)
	if name_lbl:
		name_lbl.text = "%s · %d$" % [mat, unit_value]
	var btn_all: Button = row_data.get("sell_all", null)
	if btn_all:
		btn_all.text = "Sell All" + (" " + ShopLedger.bulk_label() if bulk else "")
		btn_all.disabled = count <= 0
	var btn_five: Button = row_data.get("sell_five", null)
	if btn_five:
		btn_five.text = "Sell 5" + (" " + ShopLedger.bulk_label() if bulk else "")
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
		total += int(GameState.trash_by_type.get(mat, 0)) * (int(GameState.SALE_PRICES.get(mat, 0)) + GameState.get_market_bonus() + ShopLedger.order_bonus(mat))
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
	var tag := " (bulk %s)" % ShopLedger.bulk_label() if bulk else ""
	_last_sale = {"mat": mat, "price": int(sale.get("price", 0)), "qty": units, "earnings": earnings, "bulk": bulk}
	_log_sale("%s x%d%s → %d$" % [mat, units, tag, earnings])
	AudioManager.play_sfx("sale", 1.03)
	_feedback("Sold %d %s%s +%d$" % [units, mat, tag, earnings])

	_stack.sale("SOLD %s x%d%s  +%d$" % [mat, units, tag, earnings], Color(1.0, 0.85, 0.35, 1.0) if bulk else Color(0.7, 1.0, 0.6, 1.0), 1.35 if bulk else 1.0)
	TutorialDirector.notify("sold")
	TutorialDirector.nudge("upgrade")
	if bulk:
		TutorialDirector.nudge("undo")
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
	var tag := " (bulk %s)" % ShopLedger.bulk_label() if bulk else ""
	_last_sale = {"mat": mat, "price": int(sale.get("price", 0)), "qty": units, "earnings": earnings, "bulk": bulk}
	_log_sale("%s x%d%s → %d$" % [mat, units, tag, earnings])
	AudioManager.play_sfx("sale", 1.03)
	_feedback("Sold %d %s%s for %d$" % [units, mat, tag, earnings])
	_stack.sale("SOLD %s x%d%s  +%d$" % [mat, units, tag, earnings], Color(1.0, 0.85, 0.35, 1.0) if bulk else Color(0.7, 1.0, 0.6, 1.0), 1.35 if bulk else 1.0)
	TutorialDirector.notify("sold")
	TutorialDirector.nudge("upgrade")
	if bulk:
		TutorialDirector.nudge("undo")
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

## Sale receipts, undo receipts, the REVERSED stamp and the punch/flash
## effects live in scenes/ui/receipt_stack.tscn (ReceiptStack) — instantiated
## once in _ready and reused for every sale and undo.
func _play_undo_animation(mat: String, restored_qty: int, earnings: int, was_bulk: bool) -> void:
	var bulk_tag := " (bulk %s)" % ShopLedger.bulk_label() if was_bulk else ""
	_stack.stamp("REVERSED", Color(1.0, 0.42, 0.38, 1.0))
	_stack.undo("UNDO %s x%d%s  -%d$" % [mat, restored_qty, bulk_tag, earnings], Color(1.0, 0.55, 0.4, 1.0))
	ReceiptStack.punch(undo_button)
	ReceiptStack.flash(transaction_log, Color(1.0, 0.55, 0.45, 1.0))
	ReceiptStack.flash(coins, Color(1.0, 0.5, 0.4, 1.0))
	var row_data: Dictionary = _rows.get(mat, {})
	ReceiptStack.flash(row_data.get("count", null), Color(1.0, 0.6, 0.45, 1.0))
	ReceiptStack.punch(row_data.get("count", null))
