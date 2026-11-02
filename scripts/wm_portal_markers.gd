extends CanvasLayer

# Optional path container for portals/NPCs, or defaults to current scene root.
@export var search_node_path := "."
var _markers: Dictionary = {}

func _ready() -> void:
	set_process(true)

func _process(_delta: float) -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var canvas_transform: Transform2D = get_viewport().get_canvas_transform()
	var root := get_tree().current_scene
	if root == null:
		return
	
	# Track active nodes found this frame to clean up stale markers later
	var active_node_ids := {}
	
	# Recursively find and process valid nodes
	_process_nodes(root, canvas_transform, vp, active_node_ids)
	
	# Prune stale markers for nodes that were deleted or removed from the scene
	for instance_id in _markers.keys():
		if not active_node_ids.has(instance_id):
			var m: Label = _markers[instance_id]
			if is_instance_valid(m):
				m.queue_free()
			_markers.erase(instance_id)

func _process_nodes(parent: Node, canvas_transform: Transform2D, vp: Vector2, active_node_ids: Dictionary) -> void:
	for node in parent.get_children():
		if node is Node2D:
			var is_portal := node is Area2D and node.has_signal("body_entered")
			var is_npc := node.is_in_group("npc")
			
			if is_portal or is_npc:
				var instance_id = node.get_instance_id()
				active_node_ids[instance_id] = true
				
				# Convert world position to screen/canvas space
				var screen_pos: Vector2 = canvas_transform * node.global_position
				
				# If on screen, remove any existing off-screen marker
				if screen_pos.x >= 0 and screen_pos.x <= vp.x and screen_pos.y >= 0 and screen_pos.y <= vp.y:
					if _markers.has(instance_id):
						var m: Label = _markers[instance_id]
						if is_instance_valid(m):
							m.queue_free()
						_markers.erase(instance_id)
				else:
					# Off-screen: create or update marker
					var marker: Label
					if not _markers.has(instance_id):
						marker = load("res://scenes/ui/label.tscn").instantiate()
						marker.text = "►"
						marker.modulate = Color(0.2, 1.0, 0.4, 0.9)
						marker.add_theme_font_size_override("font_size", 24)
						marker.add_theme_color_override("font_outline_color", Color(0,0,0,1))
						marker.add_theme_constant_override("outline_size", 6)
						add_child(marker)
						_markers[instance_id] = marker
					else:
						marker = _markers[instance_id]
						
					if is_instance_valid(marker):
						var dx_left := -screen_pos.x
						var dx_right := screen_pos.x - vp.x
						var dy_top := -screen_pos.y
						var dy_bottom := screen_pos.y - vp.y
						var arrow := "►"
						var max_x := maxf(dx_left, dx_right)
						var max_y := maxf(dy_top, dy_bottom)
						if max_x >= max_y:
							if dx_left >= dx_right:
								arrow = "◄"
							else:
								arrow = "►"
						else:
							if dy_top >= dy_bottom:
								arrow = "▲"
							else:
								arrow = "▼"
						if is_npc:
							arrow += "!"
						var dist_text := ""
						if is_portal:
							var player := get_tree().get_first_node_in_group("player")
							if is_instance_valid(player):
								var d := int(round(node.global_position.distance_to(player.global_position) / 100.0))
								dist_text = " " + str(d) + "m"
						if dist_text.strip_edges() != "":
							marker.text = dist_text.strip_edges() + " " + arrow
						else:
							marker.text = arrow
						marker.position = Vector2(
							clampf(screen_pos.x, 8, vp.x - 22), 
							clampf(screen_pos.y, 8, vp.y - 22)
						)
		
		# Recursively search child nodes
		if node.get_child_count() > 0:
			_process_nodes(node, canvas_transform, vp, active_node_ids)
