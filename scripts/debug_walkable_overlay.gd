extends TileMapLayer

func _ready() -> void:
	await get_tree().process_frame
	_print_walkable_cells()

func _print_walkable_cells() -> void:
	var used := get_used_cells()
	for cell in used:
		var td := get_cell_tile_data(cell)
		var walkable: bool = td != null and td.get_custom_data("Walkable") == true
		if walkable:
			print("[walkable] ", cell)
			var rect := ColorRect.new()
			rect.color = Color(1.0, 0.0, 0.85, 0.502)
			rect.size = Vector2(tile_set.tile_size) if tile_set else Vector2(128, 128)
			rect.global_position = to_global(map_to_local(cell)) - rect.size * 0.5
			get_parent().add_child(rect)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		queue_free()
