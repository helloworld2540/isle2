extends Node

## Optional bridge for the godot-mcp addon (in-editor control of a running
## game for tools like input injection and exec). The addon itself lives in
## `addons/godot_mcp/` and is deliberately NOT tracked in the repository — it
## is an editor-side development affordance, never a shipping concern.
##
## Why the guard exists: a fresh clone of this repo has no `addons/` folder,
## and an autoload pointing at the addon's script makes every fresh boot log
## a scary (but non-fatal) "autoload can't load" error. This guard loads the
## real bridge only when the addon is present on disk, and stays a silent
## no-op otherwise. Behavior on the developer's machine is unchanged; fresh
## clones boot clean.


func _ready() -> void:
	# The optional bridge script self-registers with the MCP server when it
	# exists. When it does not, we do nothing — the game is fully sufficient
	# without it.
	if not FileAccess.file_exists("res://addons/godot_mcp/game_bridge/mcp_game_bridge.gd"):
		return
	var bridge := load("res://addons/godot_mcp/game_bridge/mcp_game_bridge.gd")
	if bridge is PackedScene:
		add_child((bridge as PackedScene).instantiate())
	elif bridge is GDScript:
		var instance: Node = bridge.new()
		if instance != null:
			add_child(instance)
