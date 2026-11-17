extends SceneTree

func _initialize() -> void:
	var scene: Node = load("res://scenes/world.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var layer: TileMapLayer = scene.get_node_or_null("WorldMap") as TileMapLayer
	for y in range(-3, 2):
		var row := ""
		for x in range(8, 18):
			var td := layer.get_cell_tile_data(Vector2i(x, y)) as TileData
			var w: bool = td != null and td.get_custom_data("Walkable") == true
			row += (" W " if w else (" . " if td == null else "###"))
		print("row %d: %s" % [y, row])
	quit()
