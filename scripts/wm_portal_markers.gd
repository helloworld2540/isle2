extends CanvasLayer
# Off-screen edge cues for world portals and NPCs to aid navigation.
@export var portals_path := "."
var _markers: Dictionary = {}

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	var vp := get_viewport_rect().size
	var root := get_tree().current_scene
	if root == null:
		return
	for node in root.get_children():
		if not (node is Node2D):
			continue
		var pos: Vector2 = node.global_position
		var is_portal := node is Area2D and node.has_signal("body_entered")
		var is_npc := node.is_in_group("npc")
		if not (is_portal or is_npc):
			continue
		if pos.x >= 0 and pos.x <= vp.x and pos.y >= 0 and pos.y <= vp.y:
			if _markers.has(node.get_instance_id()):
				var m: Label = _markers[node.get_instance_id()]
				if is_instance_valid(m): m.queue_free()
				_markers.erase(node.get_instance_id())
			continue
		var marker: Label
		if not _markers.has(node.get_instance_id()):
			marker = Label.new()
			marker.text = "►"
			marker.modulate = Color(0.2, 1.0, 0.4, 0.9)
			marker.add_theme_font_size_override("font_size", 22)
			add_child(marker)
			_markers[node.get_instance_id()] = marker
		else:
			marker = _markers[node.get_instance_id()]
		if is_instance_valid(marker):
			var arrow := "►"
			if pos.x < 0:
				arrow = "◄"
			elif pos.y < 0:
				arrow = "▲"
			elif pos.y > vp.y:
				arrow = "▼"
			if is_npc:
				arrow += "!"
			marker.text = arrow
			marker.position = Vector2(clampf(pos.x, 8, vp.x-22), clampf(pos.y, 8, vp.y-22))
