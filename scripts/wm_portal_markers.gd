extends CanvasLayer

## Edge-of-screen pointers for off-map portals and NPCs. Targets are collected
## once (portals and NPCs are static), so the per-frame cost is just clamping
## and positioning the few markers that are currently off screen.

const MARKER_SCENE := preload("res://scenes/ui/label.tscn")

var _markers: Dictionary = {}
var _targets: Array[Node2D] = []


func _ready() -> void:
	# Deferred so the scene's own nodes exist before we walk the tree.
	call_deferred("_collect_targets")


func _collect_targets() -> void:
	_targets.clear()
	# Fall back to our own parent (the world root) when the scene launches
	# directly and current_scene is not assigned yet.
	var root_node := get_tree().current_scene
	if root_node == null:
		root_node = get_parent()
	if root_node:
		_collect_from(root_node)


func _collect_from(node: Node) -> void:
	for child in node.get_children():
		if child is Node2D and _is_pointer_target(child):
			_targets.append(child as Node2D)
		if child.get_child_count() > 0:
			_collect_from(child)


func _is_pointer_target(node: Node) -> bool:
	var is_npc := node.is_in_group("npc")
	var is_portal := node is Area2D and node.has_signal("body_entered")
	return is_npc or is_portal


func _process(_delta: float) -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var canvas_transform: Transform2D = get_viewport().get_canvas_transform()
	var active_ids := {}
	
	for target in _targets:
		if not is_instance_valid(target) or not target.is_inside_tree():
			continue
		
		var instance_id := target.get_instance_id()
		active_ids[instance_id] = true
		
		var screen_pos: Vector2 = canvas_transform * target.global_position
		var on_screen := screen_pos.x >= 0.0 and screen_pos.x <= vp.x and screen_pos.y >= 0.0 and screen_pos.y <= vp.y
		
		if on_screen:
			_drop_marker(instance_id)
			continue
		
		var marker: Label = _markers.get(instance_id, null)
		if marker == null:
			marker = MARKER_SCENE.instantiate()
			marker.add_theme_font_size_override("font_size", 24)
			marker.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
			marker.add_theme_constant_override("outline_size", 6)
			marker.modulate = Color(0.2, 1.0, 0.4, 0.9)
			add_child(marker)
			_markers[instance_id] = marker
		
		_update_marker(marker, target, screen_pos, vp)
	
	# Drop markers whose target left the scene.
	for id in _markers.keys():
		if not active_ids.has(id):
			_drop_marker(id)


func _update_marker(marker: Label, target: Node2D, screen_pos: Vector2, vp: Vector2) -> void:
	var arrow := _arrow_for(screen_pos, vp)
	if target.is_in_group("npc"):
		arrow += "!"
	
	var dist_text := ""
	if not target.is_in_group("npc"):
		var player := get_tree().get_first_node_in_group("player")
		if player:
			dist_text = " %dm" % int(round(target.global_position.distance_to(player.global_position) / 100.0))
	
	marker.text = arrow
	if dist_text != "":
		marker.text = dist_text.strip_edges() + " " + arrow
	# Clamp the whole label inside the screen, not just its origin: a "42m ►"
	# text is ~80 px wide, and clamping only the origin pushed the right edge
	# (and the bottom edge on the distance line) past the window.
	var text_size: Vector2 = marker.get_combined_minimum_size()
	marker.position = Vector2(
		clampf(screen_pos.x, 8.0, maxf(8.0, vp.x - text_size.x - 8.0)),
		clampf(screen_pos.y, 8.0, maxf(8.0, vp.y - text_size.y - 8.0))
	)


func _arrow_for(screen_pos: Vector2, vp: Vector2) -> String:
	var dx_left := -screen_pos.x
	var dx_right := screen_pos.x - vp.x
	var dy_top := -screen_pos.y
	var dy_bottom := screen_pos.y - vp.y
	
	if maxf(dx_left, dx_right) >= maxf(dy_top, dy_bottom):
		return "◄" if dx_left >= dx_right else "►"
	return "▲" if dy_top >= dy_bottom else "▼"


func _drop_marker(id: int) -> void:
	var marker: Label = _markers.get(id, null)
	if marker:
		marker.queue_free()
	_markers.erase(id)
