extends TileMapLayer

## Debug-only overlay that prints the walkable TileMap cells for the
## BFS pathfinder — not shown in normal play.

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
			var rect := load("res://scenes/ui/color_rect.tscn").instantiate() as ColorRect
			rect.color = Color(1.0, 0.0, 0.85, 0.502)
			var ts := Vector2(128.0, 128.0)
			if tile_set:
				ts = Vector2(tile_set.tile_size)
			rect.size = ts
			rect.global_position = to_global(map_to_local(cell)) - rect.size * 0.5
			if get_parent():
				get_parent().add_child(rect)

func _input(event: InputEvent) -> void:
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
	if event.is_action_pressed("ui_cancel"):
		queue_free()
		queue_free()
