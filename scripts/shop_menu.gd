extends Node2D

const RATES := {"Polyethylene":2,"Polypropylene":3,"Glass":5,"Nylon":4}
const BULK_THRESHOLD := 5
const BULK_MULTIPLIER := 1.25

var _coins: Label
var _inv: Label
var _preview: Label
var _rows: Dictionary = {}
var _last_sale: Dictionary = {}

func _ready() -> void:
	GameState.restore()
	_create_ui()

func _create_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.14, 0.2, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg)

	var title := Label.new()
	title.text = "Shop (sell trash)"
	title.position = Vector2(20, 16)
	canvas.add_child(title)

	_coins = Label.new()
	_coins.position = Vector2(20, 48)
	canvas.add_child(_coins)

	_inv = Label.new()
	_inv.position = Vector2(20, 600)
	canvas.add_child(_inv)

	_preview = Label.new()
	_preview.name = "PreviewLabel"
	_preview.position = Vector2(20, 640)
	canvas.add_child(_preview)

	var y := 90
	for mat in RATES.keys():
		var row := HBoxContainer.new()
		row.position = Vector2(20, y)
		row.custom_minimum_size = Vector2(520, 0)
		canvas.add_child(row)

		var btn := Button.new()
		btn.text = "Sell 1 %s (%d)" % [mat, RATES[mat]]
		btn.custom_minimum_size = Vector2(210, 0)
		row.add_child(btn)
		btn.pressed.connect(func(): _sell_one(mat))

		var btn_all := Button.new()
		btn_all.custom_minimum_size = Vector2(135, 0)
		row.add_child(btn_all)
		btn_all.pressed.connect(func(): _sell_all(mat))

		var value_lbl := Label.new()
		value_lbl.custom_minimum_size = Vector2(115, 0)
		row.add_child(value_lbl)

		var count_lbl := Label.new()
		count_lbl.custom_minimum_size = Vector2(70, 0)
		row.add_child(count_lbl)

		_rows[mat] = {"sell_one": btn, "sell_all": btn_all, "value": value_lbl, "count": count_lbl}
		row.set_meta("material", mat)
		y += 48

	var back := Button.new()
	back.text = "Return to World"
	back.position = Vector2(20, y + 8)
	canvas.add_child(back)
	back.pressed.connect(func():
		AudioManager.play_sfx("return")
		SceneTransition.change_scene("res://scenes/world.tscn")
	)

	var undo := Button.new()
	undo.text = "Undo Last Sale"
	undo.position = Vector2(20, y + 52)
	canvas.add_child(undo)
	undo.pressed.connect(_undo_last_sale)

	_refresh()

func _refresh() -> void:
	_coins.text = "Score: %d" % GameState.upcycle_score
	_inv.text = _inv_text()
	_preview.text = _preview_text()
	for mat in RATES.keys():
		_refresh_row(mat)

func _refresh_row(mat: String) -> void:
	var row_data: Dictionary = _rows.get(mat, {})
	if row_data.is_empty():
		return
	var price: int = int(RATES.get(mat, 0))
	var count: int = int(GameState.trash_by_type.get(mat, 0))
	var value: int = count * price
	var bulk: bool = count >= BULK_THRESHOLD
	var btn_all: Button = row_data.get("sell_all", null)
	if btn_all:
		if bulk:
			btn_all.text = "Sell All (+%d%%)" % int((BULK_MULTIPLIER - 1.0) * 100.0)
		else:
			btn_all.text = "Sell All"
	var value_lbl: Label = row_data.get("value", null)
	if value_lbl:
		value_lbl.text = "value %d" % value
	var count_lbl: Label = row_data.get("count", null)
	if count_lbl:
		count_lbl.text = "x%d" % count
		count_lbl.modulate = Color(0.8, 1.0, 0.85, 1.0) if count > 0 else Color(0.9, 0.5, 0.5, 1.0)

func _inv_text() -> String:
	var t := "Inventory: "
	for k in GameState.trash_by_type.keys():
		t += "%s=%d  " % [k, GameState.trash_by_type[k]]
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
	if btn_all:
		_shake_control(btn_all)
	if btn_one:
		_shake_control(btn_one)

func _sell_one(mat: String) -> void:
	var price: int = int(RATES.get(mat, 0))
	var ok := GameState.consume_trash_type(mat, 1)
	if not ok:
		_play_denied("No %s left" % mat, mat)
		return
	GameState.upcycle_score += price
	_last_sale = {"mat": mat, "price": price, "qty": 1, "earnings": price, "bulk": false}
	_feedback("Sold %s +%d (score %d)" % [mat, price, GameState.upcycle_score])
	GameState._persist()
	_refresh()

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
	_last_sale = {"mat": mat, "price": price, "qty": avail, "earnings": earnings, "bulk": multiplier > 1.0}
	var tag := " (bulk)" if multiplier > 1.0 else ""
	_feedback("Sold %d %s%s +%d (score %d)" % [avail, mat, tag, earnings, GameState.upcycle_score])
	GameState._persist()
	_refresh()

func _undo_last_sale() -> void:
	if _last_sale.is_empty():
		_feedback("Nothing to undo")
		return
	var mat := String(_last_sale.get("mat", ""))
	var qty := int(_last_sale.get("qty", 0))
	var earnings := int(_last_sale.get("earnings", 0))
	if mat == "" or qty <= 0:
		_feedback("Nothing to undo")
		return
	GameState.trash_by_type[mat] = int(GameState.trash_by_type.get(mat, 0)) + qty
	GameState.trash_inventory += qty
	GameState.upcycle_score = max(0, GameState.upcycle_score - earnings)
	_last_sale.clear()
	_feedback("Undid %d %s" % [qty, mat])
	GameState._persist()
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		AudioManager.play_sfx("return")
		SceneTransition.change_scene("res://scenes/world.tscn")

func _shake_control(ctrl: Control) -> void:
	if not ctrl: return
	var base := ctrl.position
	var tw := ctrl.create_tween()
	tw.tween_property(ctrl, "position", base + Vector2(-6,0), 0.05)
	tw.tween_property(ctrl, "position", base + Vector2(6,0), 0.05)
	tw.tween_property(ctrl, "position", base, 0.05)

func _feedback(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = Vector2(20, 70)
	lbl.modulate = Color(0.85, 1.0, 0.5, 1.0)
	var parent := _coins.get_parent()
	if parent:
		parent.add_child(lbl)
	var tw := lbl.create_tween()
	tw.tween_property(lbl, "position", lbl.position + Vector2(0, -30), 0.8)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.4)
	tw.tween_callback(lbl.queue_free)
