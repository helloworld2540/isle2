extends Node2D
class_name WorldLoopPath

## The island's one loop, drawn piece by piece as the keeper learns it.
## Points come from the portals themselves, so the lines always follow the scene.
##
## Legs are revealed as the loop is completed, not drawn from the start:
##  - Reef -> Upcycle appears once the keeper has been to the bench (Upcycle visit)
##  - Upcycle -> Shop appears once the keeper has traded at the shop (Shop visit)
##  - Shop -> Reef (the return leg) appears once the circuit closes; closing all
##    three stops opens the full ring from then on.
## Until the first leg is learned, the map shows nothing on the route at all —
## the NextStopArrow above the keeper points at the next stop instead.

@export var portal_paths: Array[NodePath] = []
## Authored points for the return leg, inserted between the last portal and the
## first one. Keep them in the order the player would walk.
@export var return_waypoints: PackedVector2Array = []
## Circuits needed before the whole ring is shown permanently.
@export var close_loop_after_circuits: int = 1
@export var pulse_time := 1.8

@onready var leg_reef_upcycle: Line2D = $LegReefUpcycle
@onready var leg_upcycle_shop: Line2D = $LegUpcycleShop
@onready var leg_return: Line2D = $LegReturn


func _ready() -> void:
	_layout_legs()
	_refresh_visibility()
	# Keep the ring state honest mid-run: stations are ticked off as scenes load,
	# and the celebration fires the frame the circuit closes.
	GameState.circuit_progress_changed.connect(_on_progress_changed)
	GameState.island_circuit_completed.connect(_on_progress_changed.unbind(1))

	_start_pulse()


func _layout_legs() -> void:
	var portals: PackedVector2Array = []
	for path: NodePath in portal_paths:
		var portal := get_node_or_null(path)
		if portal is Node2D:
			portals.append((portal as Node2D).global_position)
	if portals.size() < 3:
		push_warning("LoopPath: expected 3 portals, got %d — legs will stay hidden" % portals.size())
		_hide_all()
		return

	leg_reef_upcycle.points = PackedVector2Array([portals[0], portals[1]])
	leg_upcycle_shop.points = PackedVector2Array([portals[1], portals[2]])
	var return_leg: PackedVector2Array = PackedVector2Array([portals[2]])
	return_leg.append_array(return_waypoints)
	return_leg.append(portals[0])
	leg_return.points = return_leg


func _hide_all() -> void:
	leg_reef_upcycle.visible = false
	leg_upcycle_shop.visible = false
	leg_return.visible = false


## Which legs the keeper has actually earned control over. A single circuit
## closes all three; until then each leg appears as its stations are visited.
func _legs_complete() -> Array[bool]:
	var done := GameState.circuits_completed >= close_loop_after_circuits
	var visits := GameState.circuit_visits
	var been_to_upcycle := visits.has("upcycle") or done
	var been_to_shop := visits.has("shop") or done
	return [been_to_upcycle, been_to_upcycle and been_to_shop, done]


func _refresh_visibility() -> void:
	if leg_reef_upcycle == null:
		return # layout never happened (missing portals)
	var legs := _legs_complete()
	leg_reef_upcycle.visible = legs[0]
	leg_upcycle_shop.visible = legs[1]
	leg_return.visible = legs[2]


func _on_progress_changed(_visited: Array = []) -> void:
	_refresh_visibility()


func _start_pulse() -> void:
	if GameSettings.reduce_motion:
		# A steady ring reads just as clearly as a breathing one.
		modulate.a = 0.75
		return
	var pulse := create_tween().set_loops()
	pulse.tween_property(self, "modulate:a", 0.45, pulse_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(self, "modulate:a", 0.9, pulse_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## The revealed legs as polylines, in the order the keeper walks them.
## FlowDots reads this instead of a single Line2D's points.
func revealed_segments() -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for leg: Line2D in [leg_reef_upcycle, leg_upcycle_shop, leg_return]:
		if leg.visible and leg.points.size() >= 2:
			out.append(leg.points)
	return out
