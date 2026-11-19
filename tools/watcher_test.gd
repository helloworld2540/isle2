extends SceneTree

## Temporary debug for the Far Point Watcher interaction.
## Run with a scratch XDG_DATA_HOME:
##   XDG_DATA_HOME=$(mktemp -d) godot --headless --path . -s tools/watcher_test.gd

func _initialize() -> void:
	var slot_dir := ProjectSettings.globalize_path("user://slots")
	if DirAccess.dir_exists_absolute(slot_dir):
		print("SKIP: slots present at %s, not touching them" % slot_dir)
		quit(1)
		return
	root.size = Vector2i(1152, 648)

	var packed: PackedScene = load("res://scenes/world.tscn")
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame

	var watcher: Node = scene.get_node_or_null("FarPointWatcher")
	var player: Node2D = scene.get_node("Player")
	print("watcher: ", watcher, " monitoring=", watcher.monitoring)
	print("player group player: ", player.is_in_group("player"))
	print("player pos: ", player.global_position, " watcher pos: ", watcher.global_position)

	player.global_position = watcher.global_position
	for i in range(4):
		await physics_frame
	print("after move, player pos: ", player.global_position)
	print("overlapping bodies: ", [watcher.get_overlapping_bodies()])
	print("monitoring: ", watcher.monitoring, " watcher_seen: ", root.get_node("GameState").watcher_seen)
	print("watcher node: ", watcher)
	quit(0)
