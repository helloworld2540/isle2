extends Line2D

## Dashed guide line that links the numbered world-map portals into one loop.
## Points are taken from the portals themselves so the line follows the scene.
##
## The first Shop -> Reef return leg only appears once the player has closed an
## island circuit (see GameState.circuits_completed): the map opens as an arrow
## through the three stops and becomes a closed ring after the loop is learned.
## Return waypoints are authored, not derived, so the leg can hug the coast
## instead of cutting straight through the town.

@export var portal_paths: Array[NodePath] = []
## Authored points for the return leg, inserted between the last portal and the
## first one. Keep them in the order the player would walk.
@export var return_waypoints: PackedVector2Array = []
@export var close_loop: bool = true
## Circuits needed before the return leg is shown.
@export var close_loop_after_circuits: int = 1
@export var pulse_time := 1.8


func _ready() -> void:
	points = _collect_points()
	if points.size() < 2:
		return
	
	if GameSettings.reduce_motion:
		# A steady ring reads just as clearly as a breathing one.
		modulate.a = 0.75
		return
	
	var pulse := create_tween().set_loops()
	pulse.tween_property(self, "modulate:a", 0.45, pulse_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(self, "modulate:a", 0.9, pulse_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _collect_points() -> PackedVector2Array:
	var collected: PackedVector2Array = []
	for path in portal_paths:
		var portal := get_node_or_null(path)
		if portal is Node2D:
			collected.append((portal as Node2D).global_position)
	
	if _should_close_loop() and collected.size() >= 2:
		collected.append_array(return_waypoints)
		collected.append(collected[0])
	
	return collected


## The ring is a reward for completing the route once; a fresh save still
## reads as a directed path so the first visit is not overwhelming.
func _should_close_loop() -> bool:
	return close_loop and GameState.circuits_completed >= close_loop_after_circuits
