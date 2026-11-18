extends SceneTree

## Harness for the island-wide CardQueue (scripts/ui/card_queue.gd).
##
## The queue is the single handshake every popup card uses: a card asks for
## the screen, is either activated immediately or parked until the cards
## ahead of it close. This harness walks the contract with tiny probe cards
## (inline scripts, no game scenes) so it needs none of the autoload globals:
##
##   1. a lone card activates at once;
##   2. a second card waits, and activates only when the first releases;
##   3. a modal jumps ahead of an ambient card already waiting;
##   4. `withdraw` drops a waiting card that leaves the tree;
##   5. a modal owned outside the queue (the `ui_modal_card` group) blocks
##      activation until it closes, then the parked card drains;
##   6. re-requesting the same card is a no-op, and `release` of a card that
##      is not active only cancels its own wait slot.
##
## Run with --path . (a project run is fine; no saves are touched):
##   godot --headless --path . -s tools/card_queue_test.gd

## Inline probe card: a CanvasLayer that records how many times the queue
## granted it the screen and turns visible when it does.
const PROBE_SOURCE := """
extends CanvasLayer
var activations: int = 0
func _card_activate() -> void:
	activations += 1
	visible = true
"""

var _fails := 0
var _probe_script: GDScript


func _initialize() -> void:
	_probe_script = GDScript.new()
	_probe_script.source_code = PROBE_SOURCE
	_probe_script.reload()
	await _run()
	print("card_queue_test: %d failure(s)" % _fails)
	quit(_fails)


func _run() -> void:
	_check(not CardQueue.is_busy(), "queue starts idle")

	# --- 1. A lone card activates immediately.
	var a := await _probe()
	CardQueue.request(a, CardQueue.PRIORITY_AMBIENT)
	_check(a.visible and _activations(a) == 1, "first card activates at once")
	_check(CardQueue.is_busy(), "queue reports busy while a card is up")

	# --- 2. A second card waits behind the first.
	var b := await _probe()
	CardQueue.request(b, CardQueue.PRIORITY_AMBIENT)
	_check(not b.visible and _activations(b) == 0, "second card waits, not shown")
	_dismiss(a)
	await process_frame
	await process_frame
	_check(b.visible and _activations(b) == 1, "second card activates once the first closes")

	# --- 3. A modal jumps ahead of a waiting ambient card.
	var c := await _probe()
	var d := await _probe()
	CardQueue.request(c, CardQueue.PRIORITY_AMBIENT)
	CardQueue.request(d, CardQueue.PRIORITY_MODAL)
	_check(not c.visible and not d.visible, "ambient C and modal D both wait behind B")
	_dismiss(b)
	await process_frame
	await process_frame
	_check(d.visible and _activations(d) == 1, "modal D jumps ahead of ambient C")
	_check(not c.visible, "ambient C still waits after the modal took the lane")

	# --- 4. Dismissing the modal drains the ambient card behind it.
	_dismiss(d)
	await process_frame
	await process_frame
	_check(c.visible and _activations(c) == 1, "ambient C drains after the modal closes")

	# --- 5. A waiting card that leaves the tree is withdrawn, never shown.
	var e := await _probe()
	CardQueue.request(e, CardQueue.PRIORITY_AMBIENT)
	_check(not e.visible, "card E waits behind C")
	var e_activated: bool = _activations(e) > 0
	e.free()
	await process_frame
	_dismiss(c)
	await process_frame
	await process_frame
	_check(not e_activated, "withdrawn card never activates")
	_check(not CardQueue.is_busy(), "withdrawn card leaves nothing in the queue")

	# --- 6. A foreign modal (ui_modal_card group) blocks a parked card.
	var foreign := CanvasLayer.new()
	foreign.add_to_group("ui_modal_card")
	root.add_child(foreign)
	var g := await _probe()
	CardQueue.request(g, CardQueue.PRIORITY_AMBIENT)
	_check(not g.visible, "card G holds while a foreign modal is open")
	foreign.remove_from_group("ui_modal_card")
	await process_frame
	await process_frame
	await process_frame
	_check(g.visible and _activations(g) == 1, "card G drains once the foreign modal closes")

	# --- 7. Re-requesting an active card is a no-op; releasing a waiter cancels it.
	CardQueue.request(g, CardQueue.PRIORITY_AMBIENT)
	_check(_activations(g) == 1, "re-requesting the active card is a no-op")
	var h := await _probe()
	CardQueue.request(h, CardQueue.PRIORITY_AMBIENT)
	CardQueue.release(h)
	_check(not h.visible and _activations(h) == 0, "releasing a waiter cancels it")
	_dismiss(g)
	await process_frame
	await process_frame
	_check(not CardQueue.is_busy(), "queue idle after the last card closes")

	foreign.queue_free()
	# a/b/c/d/g were freed by _dismiss(); only h is still alive.
	if is_instance_valid(h):
		h.queue_free()
	await process_frame
	await process_frame


## A probe card added to the tree, ready to request the lane.
func _probe() -> CanvasLayer:
	var node := CanvasLayer.new()
	node.set_script(_probe_script)
	# A fresh CanvasLayer is visible by default; a queued card must start hidden
	# so "not visible" means "not activated".
	node.visible = false
	root.add_child(node)
	# In a --path harness a node enters the tree on the next frame, so the
	# card must not request the lane before that.
	await process_frame
	return node


## Hand the lane back and free the card, as a real card's dismiss does.
func _dismiss(card: CanvasLayer) -> void:
	CardQueue.release(card)
	card.queue_free()


func _activations(card: CanvasLayer) -> int:
	return int(card.get("activations"))


func _check(ok: bool, what: String) -> void:
	print(("  ok  " if ok else "[FAIL] ") + what)
	if not ok:
		_fails += 1
