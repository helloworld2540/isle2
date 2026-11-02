extends Node2D

const RATES := {"Polyethylene":2,"Polypropylene":3,"Glass":5,"Nylon":4,"Reef Debris":1}
const BULK_THRESHOLD := 5
const BULK_MULTIPLIER := 1.25

@onready var coins: Label = get_node_or_null("CanvasLayer/VBoxContainer/Coins")
@onready var inv: Label = get_node_or_null("CanvasLayer/VBoxContainer/Inventory")
@onready var preview: Label = get_node_or_null("CanvasLayer/VBoxContainer/Preview")
@onready var tip: Label = get_node_or_null("CanvasLayer/VBoxContainer/Tip")

@onready var row_polyethylene: HBoxContainer = get_node_or_null("CanvasLayer/VBoxContainer/Rows/Row_Polyethylene")
@onready var row_polypropylene: HBoxContainer = get_node_or_null("CanvasLayer/VBoxContainer/Rows/Row_Polypropylene")
@onready var row_glass: HBoxContainer = get_node_or_null("CanvasLayer/VBoxContainer/Rows/Row_Glass")
@onready var row_nylon: HBoxContainer = get_node_or_null("CanvasLayer/VBoxContainer/Rows/Row_Nylon")
@onready var row_reef_debris: HBoxContainer = get_node_or_null("CanvasLayer/VBoxContainer/Rows/Row_Reef Debris")

@onready var back_button: Button = get_node_or_null("CanvasLayer/VBoxContainer/BackButton")
@onready var undo_button: Button = get_node_or_null("CanvasLayer/VBoxContainer/UndoButton")

var _rows: Dictionary = {}
var _last_sale: Dictionary = {}
var _undo_in_progress := false

func _ready() -> void:
	GameState.restore()
	_wire_ui()
	_refresh()
	AudioManager.play_bgm("shop")

func _wire_ui() -> void:
	if not is_instance_valid(row_polyethylene):
		return
	_rows["Polyethylene"] = _wire_row(row_polyethylene, "Polyethylene", 2)
	if is_instance_valid(row_polypropylene):
		_rows["Polypropylene"] = _wire_row(row_polypropylene, "Polypropylene", 3)
	if is_instance_valid(row_glass):
		_rows["Glass"] = _wire_row(row_glass, "Glass", 5)
	if is_instance_valid(row_nylon):
		_rows["Nylon"] = _wire_row(row_nylon, "Nylon", 4)
	if is_instance_valid(row_reef_debris):
		_rows["Reef Debris"] = _wire_row(row_reef_debris, "Reef Debris", 1)

	if is_instance_valid(back_button):
		back_button.pressed.connect(func():
			AudioManager.play_sfx("return")
			SceneTransition.change_scene("res://scenes/world.tscn")
		)
	if is_instance_valid(undo_button):
		undo_button.pressed.connect(_undo_last_sale)

func _wire_row(row: HBoxContainer, mat: String, price: int) -> Dictionary:
	var sell_one: Button = row.get_node_or_null("SellOne")
	var sell_all: Button = row.get_node_or_null("SellAll")
	var value_lbl: Label = row.get_node_or_null("Value")
	var count_lbl: Label = row.get_node_or_null("Count")
	if is_instance_valid(sell_one):
		sell_one.text = "Sell 1 %s (%d)" % [mat, price]
		sell_one.pressed.connect(func(): _sell_one(mat))
	if is_instance_valid(sell_all):
		sell_all.pressed.connect(func(): _sell_all(mat))
	return {"sell_one": sell_one, "sell_all": sell_all, "value": value_lbl, "count": count_lbl}

func _refresh() -> void:
	if is_instance_valid(coins):
		coins.text = "Score: %d" % GameState.upcycle_score
	if is_instance_valid(inv):
		inv.text = _inv_text()
	if is_instance_valid(preview):
		preview.text = _preview_text()
	_update_shop_tip()
	for mat in RATES.keys():
		_refresh_row(mat)

func _update_shop_tip() -> void:
	var cap := GameState.get_inventory_capacity()
	if not is_instance_valid(tip):
		return
	if GameState.trash_inventory >= cap:
		tip.text = "Tip: inventory full — sell or upgrade cap before another run."
		tip.modulate = Color(1.0, 0.45, 0.45, 1.0)
	elif float(GameState.trash_inventory) / float(max(1, cap)) >= 0.8:
		tip.text = "Tip: inventory heavy — consider selling bulk for bonus."
		tip.modulate = Color(1.0, 0.85, 0.35, 1.0)
	else:
		tip.text = "Tip: sort efficiently for combo bonuses."
		tip.modulate = Color(0.85, 1.0, 0.75, 1.0)

func _refresh_row(mat: String) -> void:
	var row_data: Dictionary = _rows.get(mat, {})
	if row_data.is_empty():
		return
	var price: int = int(RATES.get(mat, 0))
	var count: int = int(GameState.trash_by_type.get(mat, 0))
	var value: int = count * price
	var bulk: bool = count >= BULK_THRESHOLD
	var btn_all: Button = row_data.get("sell_all", null)
	if is_instance_valid(btn_all):
		if bulk:
			btn_all.text = "Sell All (+%d%%)" % int((BULK_MULTIPLIER - 1.0) * 100.0)
		else:
			btn_all.text = "Sell All"
	var value_lbl: Label = row_data.get("value", null)
	if is_instance_valid(value_lbl):
		value_lbl.text = "value %d" % value
	var count_lbl: Label = row_data.get("count", null)
	if is_instance_valid(count_lbl):
		count_lbl.text = "x%d" % count
		var rarity: String = str(GameState.TRASH_RARITY.get(mat, "common"))
		var base_color := Color(0.85, 0.95, 1.0, 1.0)
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
	if is_instance_valid(btn_one):
		btn_one.text = "Sell 1 %s (%d)" % [mat, price]

func _inv_text() -> String:
	var cap := GameState.get_inventory_capacity()
	var used := GameState.get_inventory_weight()
	var t := "Inventory (weight %d/%d): " % [used, cap]
	for k in GameState.trash_by_type.keys():
		var count: int = int(GameState.trash_by_type.get(k, 0))
		var weight: int = int(count) * int(GameState.TRASH_WEIGHTS.get(k, 1))
		var rarity: String = str(GameState.TRASH_RARITY.get(k, "common"))
		t += "%s[%s]=%d (w%d)  " % [k, rarity.substr(0, 1).to_upper(), count, weight]
	return t

func _preview_text() -> String:
	var total := 0
	for mat in RATES.keys():
		total += int(GameState.trash_by_type.get(mat, 0)) * int(RATES.get(mat, 0))
	return "Potential base earnings if sold all: %d score" % total

func _play_denied(feedback_text: String, mat: String) -> void:
	_feedback(feedback_text)
	var row_data: Dictionary = _rows.get(mat, {})
	var btn_all: Button = row_data.get("sell_all", null)
	var btn_one: Button = row_data.get("sell_one", null)
	if is_instance_valid(btn_all):
		_shake_control(btn_all)
	if is_instance_valid(btn_one):
		_shake_control(btn_one)

func _sell_one(mat: String) -> void:
	var price: int = int(RATES.get(mat, 0))
	var ok := GameState.consume_trash_type(mat, 1)
	if not ok:
		_play_denied("No %s left" % mat, mat)
		return
	GameState.upcycle_score += price
	AudioManager.play_sfx("sale", 1.03)
	GameState.add_earnings(price)
	_last_sale = {"mat": mat, "price": price, "qty": 1, "earnings": price, "bulk": false}
	_feedback("Sold %s +%d (score %d)" % [mat, price, GameState.upcycle_score])
	GameState._persist()
	_refresh()
	_spawn_receipt("SOLD %s" % mat)

func _spawn_receipt(text: String) -> void:
	var lbl := load("res://scenes/ui/label.tscn").instantiate() as Label
	lbl.text = text
	lbl.position = Vector2(20, 90)
	lbl.modulate = Color(0.85, 1.0, 0.55, 1.0)
	var parent := coins.get_parent() if is_instance_valid(coins) else null
	if is_instance_valid(parent):
		parent.add_child(lbl)
	else:
		add_child(lbl)
	var tw := lbl.create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 46.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.5)
	tw.tween_callback(lbl.queue_free)

func _sell_all(mat: String) -> void:
	var price: int = int(RATES.get(mat, 0))
	var avail := int(GameState.trash_by_type.get(mat, 0))
	if avail <= 0:
		_play_denied("No %s left" % mat, mat)
		return
	var multiplier: float = BULK_MULTIPLIER if avail >= BULK_THRESHOLD else 1.0
	var earnings := int(round(float(avail) * float(price) * multiplier))
	GameState.consume_trash_type(mat, avail)
	GameState.upcycle_score += earnings
	AudioManager.play_sfx("sale", 1.03)
	GameState.add_earnings(earnings)
	_last_sale = {"mat": mat, "price": price, "qty": avail, "earnings": earnings, "bulk": multiplier > 1.0}
	var tag := " (bulk)" if multiplier > 1.0 else ""
	_feedback("Sold %d %s%s +%d (score %d)" % [avail, mat, tag, earnings, GameState.upcycle_score])
	GameState._persist()
	_refresh()

func _undo_last_sale() -> void:
	if _undo_in_progress:
		return
	if _last_sale.is_empty():
		_feedback("Nothing to undo")
		return
	var mat := String(_last_sale.get("mat", ""))
	var qty := int(_last_sale.get("qty", 0))
	var earnings := int(_last_sale.get("earnings", 0))
	if mat == "" or qty <= 0:
		_feedback("Nothing to undo")
		return
	_undo_in_progress = true
	var cap := GameState.get_inventory_capacity()
	var current_total := GameState.trash_inventory
	var free: int = max(0, cap - current_total)
	var add_back: int = min(qty, free)
	if add_back < qty:
		_feedback("Only %d/%d restored (capacity)" % [add_back, qty])
	GameState.trash_by_type[mat] = int(GameState.trash_by_type.get(mat, 0)) + add_back
	GameState.upcycle_score = max(0, GameState.upcycle_score - earnings)
	GameState.lifetime_earnings = max(0, GameState.lifetime_earnings - earnings)
	_last_sale.clear()
	GameState._recompute_inventory() if GameState.has_method("_recompute_inventory") else null
	GameState._persist()
	_refresh()
	_undo_in_progress = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		AudioManager.play_sfx("return")
		SceneTransition.change_scene("res://scenes/world.tscn")

func _shake_control(ctrl: Control) -> void:
	if not is_instance_valid(ctrl):
		return
	var base := ctrl.position
	var tw := ctrl.create_tween()
	tw.tween_property(ctrl, "position", base + Vector2(-6,0), 0.05)
	tw.tween_property(ctrl, "position", base + Vector2(6,0), 0.05)
	tw.tween_property(ctrl, "position", base, 0.05)

func _feedback(text: String) -> void:
	var lbl := load("res://scenes/ui/label.tscn").instantiate() as Label
	lbl.text = text
	lbl.position = Vector2(20, 70)
	lbl.modulate = Color(0.85, 1.0, 0.5, 1.0)
	var parent := coins.get_parent() if is_instance_valid(coins) else null
	if is_instance_valid(parent):
		parent.add_child(lbl)
	var tw := lbl.create_tween()
	tw.tween_property(lbl, "position", lbl.position + Vector2(0, -30), 0.8)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.4)
	tw.tween_callback(lbl.queue_free)
