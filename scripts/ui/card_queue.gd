extends RefCounted
class_name CardQueue

## One popup card at a time, island-wide.
##
## The world map can have several voices reach for the screen in the same
## breath: a bottle story, an NPC greeting, a milestone banner, the tide card,
## a tutorial hint. Each used to present itself the moment it was asked, so
## two or three could land together and read as a wall. This queue serialises
## them: a card asks for the screen, and either gets it now or waits until the
## card ahead of it is dismissed.
##
## Cards keep their authored content and presentation; the only contract is:
##   - call `CardQueue.request(self, priority)` once the card is built,
##   - implement `_card_activate()` — the moment it becomes the visible card,
##   - call `CardQueue.release(self)` when it closes,
##   - call `CardQueue.withdraw(self)` from `_exit_tree()` (scene changes).
##
## Modals (conversations, the welcome guide) jump ahead of ambient cards
## (hints, milestone banners) because the player is standing in them; ambient
## cards merely decorate a screen the player is already reading.
##
## Screens owned outside the queue (the pause menu, a minigame briefing, a
## confirm panel) register in the `ui_modal_card` group; the queue waits for
## those to close too, so no card ever slides underneath one.

const PRIORITY_MODAL := 0
const PRIORITY_AMBIENT := 10

static var _active: Node = null
static var _waiting: Array[Dictionary] = []
static var _pumping := false


## Ask for the screen. Returns nothing: if the queue is free the card is
## activated immediately (synchronously, before this call returns), otherwise
## `_card_activate()` fires once every card ahead of it has closed.
static func request(card: Node, priority: int = PRIORITY_AMBIENT) -> void:
	if card == null:
		return
	_prune()
	if _active == card:
		return
	for entry in _waiting:
		if entry.get("node") == card:
			return
	if _active == null and not _foreign_modal_open(card):
		_activate(card)
		return
	var entry := {"node": card, "priority": priority}
	# Stable insert: modals (0) ahead of ambient (10), FIFO within a band.
	var idx := _waiting.size()
	for i in range(_waiting.size()):
		if int(_waiting[i].get("priority", PRIORITY_AMBIENT)) > priority:
			idx = i
			break
	_waiting.insert(idx, entry)
	_pump(card.get_tree())


## The card closed and the screen is free again.
static func release(card: Node) -> void:
	if _active == card:
		_active = null
	else:
		_cancel(card)
	_drain()


## The card left the tree without closing (scene change, owner freed). It must
## not be activated later and must not hold the screen.
static func withdraw(card: Node) -> void:
	if _active == card:
		_active = null
	_cancel(card)
	_drain()


static func is_busy() -> bool:
	_prune()
	return _active != null or not _waiting.is_empty()


static func _cancel(card: Node) -> void:
	for i in range(_waiting.size() - 1, -1, -1):
		if _waiting[i].get("node") == card:
			_waiting.remove_at(i)


static func _activate(card: Node) -> void:
	_active = card
	if card.has_method("_card_activate"):
		card.call("_card_activate")


static func _drain() -> void:
	_prune()
	if _active != null:
		return
	while not _waiting.is_empty():
		var entry: Dictionary = _waiting.pop_front()
		# Untyped on purpose: a freed node cannot be assigned to a typed Node.
		var card: Variant = entry.get("node")
		if not is_instance_valid(card):
			continue
		if not (card as Node).is_inside_tree():
			continue
		if _foreign_modal_open(card as Node):
			# A pause menu / briefing / confirm panel owns the screen. Keep the
			# card parked at the head of the queue and try again next frame.
			_waiting.push_front(entry)
			return
		_activate(card as Node)
		return


## True when a dimming card from outside the queue is up. Queued cards do not
## join `ui_modal_card` until they are activated, so this only sees real ones.
static func _foreign_modal_open(card: Node) -> bool:
	var tree := card.get_tree()
	if tree == null:
		return true
	for modal in tree.get_nodes_in_group("ui_modal_card"):
		if modal != card and is_instance_valid(modal):
			return true
	return false


static func _prune() -> void:
	if _active != null and (not is_instance_valid(_active) or not _active.is_inside_tree()):
		_active = null
	for i in range(_waiting.size() - 1, -1, -1):
		var node: Variant = _waiting[i].get("node")
		# Test validity first: `is` / typed casts on a freed instance throw.
		if not is_instance_valid(node) or not (node as Node).is_inside_tree():
			_waiting.remove_at(i)


## Frames keep firing while the tree is paused, so a card parked behind a
## pausing guide still drains the moment the guide closes.
static func _pump(tree: SceneTree) -> void:
	if _pumping or tree == null:
		return
	_pumping = true
	_pump_loop(tree)


static func _pump_loop(tree: SceneTree) -> void:
	while not _waiting.is_empty() and is_instance_valid(tree):
		await tree.process_frame
		_drain()
	_pumping = false
