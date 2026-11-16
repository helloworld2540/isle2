class_name ReceiptStack extends CanvasLayer

## Sale/undo receipt stack + the short-lived stamp/punch effects for the shop.
## Receipts live in a stack anchored to the top-right corner. Each new entry
## slides in from the right; when one expires the survivors reflow upward, so
## the column never keeps gaps from a burst of quick sales. `punch` > 1.0
## plays a pop-in punch — bulk sales use it so the 25% bonus reads at a
## glance in a fast stack of receipts.
##
## Instantiate in the owning scene (shop_menu does this at _ready) and drive
## through `sale()` / `undo()` / `stamp()`; `punch`/`flash` are shared static
## helpers for the surrounding controls.

const FLOATING_TEXT_SCENE := preload("res://scenes/ui/floating_text.tscn")
const RECEIPT_WIDTH := 460.0

var _receipts: Array[Control] = []


## Right-aligned sale receipt entering the stack from the right edge.
func sale(text: String, col: Color, punch: float = 1.0) -> void:
	var lbl := FLOATING_TEXT_SCENE.instantiate() as Label
	lbl.z_index = 130
	lbl.rise_distance = 0.0
	lbl.hold_time = 1.4
	lbl.fade_out_time = 0.4
	lbl.punch_scale = punch
	add_child(lbl)
	_receipts.append(lbl)
	lbl.tree_exited.connect(func(): _retire_receipt(lbl))

	var vp := _vp_size()
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


func _reflow_receipts() -> void:
	var vp := _vp_size()
	for i in range(_receipts.size()):
		var lbl := _receipts[i]
		if not is_instance_valid(lbl):
			continue
		var target := Vector2(vp.x - RECEIPT_WIDTH - 24.0, _receipt_slot_y(i))
		var tw := lbl.create_tween()
		tw.tween_property(lbl, "position", target, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## Exiting receipt for an undo. Deliberately kept OUT of the `_receipts`
## stack: it owns slot 0 for a moment and leaves to the right, so it never
## disturbs the reflow of fresh sale receipts behind it.
func undo(text: String, col: Color) -> void:
	var lbl := FLOATING_TEXT_SCENE.instantiate() as Label
	lbl.z_index = 131
	lbl.rise_distance = 0.0
	lbl.hold_time = 0.9
	lbl.fade_out_time = 0.35
	lbl.punch_scale = 1.3
	add_child(lbl)
	var vp := _vp_size()
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


## One-shot "REVERSED"-style stamp: oversized, back-eased punch-in, short hold.
## Sells the rewind without touching layout anywhere else on screen.
func stamp(text: String, col: Color) -> void:
	var lbl := FLOATING_TEXT_SCENE.instantiate() as Label
	lbl.z_index = 132
	lbl.rise_distance = 0.0
	lbl.hold_time = 0.65
	lbl.fade_out_time = 0.3
	lbl.punch_scale = 2.1
	add_child(lbl)
	var vp := _vp_size()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size = Vector2(300.0, 0)
	lbl.size = Vector2(300.0, 44.0)
	lbl.present(text, col, 34)
	lbl.position = Vector2(vp.x * 0.5 - 150.0, vp.y * 0.3)


## Scale punch for any control: snaps up then settles with a back ease. Used
## for tactile feedback on undo without stealing layout space.
static func punch(ctrl: Control) -> void:
	if not ctrl:
		return
	var base := ctrl.scale
	ctrl.scale = base * 1.28
	var tw := ctrl.create_tween()
	tw.tween_property(ctrl, "scale", base, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Amber/red/green flash that kicks a control's modulate back to white.
static func flash(ctrl: Control, from_color: Color = Color(0.6, 1.0, 0.65, 1.0)) -> void:
	if not ctrl:
		return
	var tw := ctrl.create_tween()
	ctrl.modulate = from_color
	tw.tween_property(ctrl, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.45)


func _vp_size() -> Vector2:
	return get_tree().root.get_visible_rect().size
