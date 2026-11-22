extends Node2D
class_name NextStopArrow

## World-map pointer that hovers above the keeper and always points at the
## station the route advisor wants next, so the way through the loop is legible
## without the whole trail being drawn on the map.
##
## The target is derived from the same `RouteAdvisor.next_stop()` call the
## HUD uses, so the arrow and the "Next:" line can never disagree. The arrow
## hides when the player is already standing at the stop, and ducks out during
## anything that is not the open world (menus pause the tree, which pauses
## _process, so the arrow simply freezes in place there).
##
## Reduced motion: no bob, no sway — the arrow just points.

@export var y_offset: float = -140.0 ## fallback height above the player when motion is reduced
@export var orbit_radius: float = 110.0
@export var orbit_speed: float = 1.6 ## radians per second (one lap in ~4s)
@export var bob_amplitude: float = 4.0
@export var bob_time: float = 1.15
@export var arrival_radius: float = 150.0 ## hide the arrow once the keeper is basically at the stop

## Total pointer can hold one advice re-computation; cheap, but not free.
const ADVICE_TICK_SECONDS := 0.35
const RouteAdvisor := preload("res://scripts/route_advisor.gd")
## Station ids from RouteAdvisor map to top-level scene nodes of the world map.
const STATION_TO_NAME: Dictionary = {
	"reef_rescue": &"PortalReefRescue",
	"upcycle": &"PortalUpcycle",
	"shop": &"PortalShop",
}

@onready var bob: Node2D = $Bob

var _advice_tick: float = 0.0
var _station: String = ""
var _target: Node2D = null
var _orbit_angle: float = -PI * 0.5
var _reduce_motion: bool = false


func _ready() -> void:
	_reduce_motion = GameSettings.reduce_motion
	position = Vector2(0.0, y_offset)
	if not _reduce_motion:
		var tw := create_tween().set_loops()
		tw.tween_property(bob, "position:y", -bob_amplitude, bob_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(bob, "position:y", bob_amplitude, bob_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _process(delta: float) -> void:
	_advice_tick += delta
	if _advice_tick >= ADVICE_TICK_SECONDS:
		_advice_tick = 0.0
		_refresh_target()

	if _target == null or not is_instance_valid(_target):
		visible = false
		return

	var to_target := _target.global_position - global_position
	var distance := to_target.length()
	# Standing at the stop: nothing to point at.
	visible = distance > arrival_radius
	if not visible:
		return
	rotation = to_target.angle() + PI * 0.5


## Re-derive the advised station and cache the target node. The tree walk for
## an NPC errand only runs when the advice flips to a different station.
func _refresh_target() -> void:
	var advice := RouteAdvisor.next_stop(get_tree())
	var station := String(advice.get("station", ""))
	if station == _station and _target != null and is_instance_valid(_target):
		return

	_station = station
	_target = _find_target(station)


func _find_target(station: String) -> Node2D:
	var scene := get_tree().current_scene
	if scene == null:
		return null

	if station == "npc":
		# The advisor already picked an islander; point at the first one whose
		# quest is ready, matching RouteAdvisor._ready_quest exactly.
		for npc in get_tree().get_nodes_in_group("npc"):
			if not npc is Node2D:
				continue
			var quest: Dictionary = npc.get_active_quest() if npc.has_method("get_active_quest") else {}
			if not quest.is_empty() and bool(quest.get("ready", false)):
				return npc as Node2D
		return null

	var station_node := StringName(STATION_TO_NAME.get(station, ""))
	if String(station_node).is_empty():
		return null
	return scene.get_node_or_null(NodePath(station_node)) as Node2D
