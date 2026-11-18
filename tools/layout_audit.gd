extends SceneTree

## Permanent mobile-layout gate: no visible Control may extend past the
## 1152×648 design window once a scene is laid out.
##
## Nodes that are supposed to live outside the screen are skipped:
##   - anything under a ScrollContainer (its content scrolls by design),
##   - world-space nodes (scene roots that are Node2D/CanvasLayer trees: the
##     world map's portal labels sit on a tile map, not on the screen).
## Only screen-space UI is measured — a Control root scene, or Controls under
## a CanvasLayer.
##
## Run with --path . so autoloads resolve (scenes look up GameState etc.):
##   godot --headless --path . -s tools/layout_audit.gd
## Exit code is the number of overflowing Controls (0 = clean).

const DESIGN_SIZE := Vector2i(1152, 648)

const SCENES := [
	"res://scenes/main_menu.tscn",
	"res://scenes/world.tscn",
	"res://scenes/upcycle.tscn",
	"res://scenes/reef_rescue.tscn",
	"res://scenes/shop.tscn",
	"res://scenes/stats_menu.tscn",
	"res://scenes/tutorial.tscn",
	"res://scenes/minigame_intro.tscn",
	"res://scenes/ui/about.tscn",
	"res://scenes/ui/confirm_panel.tscn",
	"res://scenes/ui/run_recap.tscn",
	"res://scenes/ui/tutorial_hint.tscn",
	"res://scenes/ui/npc_dialogue.tscn",
	"res://scenes/ui/settings_panel.tscn",
]

## Hidden overlays are where a long label most often overflows (the guide,
## ledger, registry and almanac are only laid out once opened). For the scene
## below, open each overlay, measure, then close it again.
const OVERLAY_PASSES := [
	["_open_guide", "_close_guide"],
	["_open_ledger", "_close_ledger"],
	["_open_registry", "_close_registry"],
	["_open_almanac", "_close_almanac"],
]
const OVERLAY_SCENE := "res://scenes/stats_menu.tscn"

var _fails := 0


func _initialize() -> void:
	# House rule: never run against real player slots (scenes restore saves).
	var slot_dir := ProjectSettings.globalize_path("user://slots")
	if DirAccess.dir_exists_absolute(slot_dir):
		print("SKIP: slots present at %s, not touching them" % slot_dir)
		quit(0)
		return
	root.size = DESIGN_SIZE
	var viewport := Rect2(Vector2.ZERO, Vector2(DESIGN_SIZE))
	for path in SCENES:
		var packed: PackedScene = load(path)
		if packed == null:
			print("[FAIL] %s did not load" % path)
			_fails += 1
			continue
		var scene: Node = packed.instantiate()
		root.add_child(scene)
		# Containers need a couple of layout passes (autowrap labels, flow rows)
		# before their rects are meaningful; three frames has proven stable.
		await process_frame
		await process_frame
		await process_frame
		_report(path, _measure(scene, viewport))
		# The stats page's overlays are hidden at boot; open each one and
		# measure the laid-out card too.
		if path == OVERLAY_SCENE:
			for pair in OVERLAY_PASSES:
				var opener: String = pair[0]
				var closer: String = pair[1]
				if not scene.has_method(opener):
					continue
				scene.call(opener)
				await process_frame
				await process_frame
				await process_frame
				_report("%s (%s)" % [path, opener.trim_prefix("_open_")], _measure(scene, viewport))
				if scene.has_method(closer):
					scene.call(closer)
				await process_frame
		scene.queue_free()
		await process_frame
	print("layout_audit: %d failure(s)" % _fails)
	quit(_fails)


## Screen-space: a Control scene root, or a Control whose ancestry includes a
## CanvasLayer (HUD/overlays). World-space labels (on the tile map) are skipped.
func _screen_space(control: Control, scene: Node) -> bool:
	if scene is Control:
		return true
	var p := control.get_parent()
	while p != null:
		if p is CanvasLayer:
			return true
		if p == scene:
			return false
		p = p.get_parent()
	return false


## Content inside a ScrollContainer scrolls by design; never count it.
func _under_scroll(control: Control, scene: Node) -> bool:
	var p := control.get_parent()
	while p != null and p != scene:
		if p is ScrollContainer:
			return true
		p = p.get_parent()
	return false


## Every visible, screen-space Control past the viewport.
func _measure(scene: Node, viewport: Rect2) -> Array[String]:
	var bad: Array[String] = []
	for control in scene.find_children("*", "Control", true, false):
		if not control.is_visible_in_tree():
			continue
		if not _screen_space(control, scene):
			continue
		if _under_scroll(control, scene):
			continue
		var rect: Rect2 = control.get_global_rect()
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
		if rect.position.x < -1.0 or rect.position.y < -1.0 \
				or rect.end.x > viewport.size.x + 1.0 \
				or rect.end.y > viewport.size.y + 1.0:
			bad.append("%s %s" % [control.get_path(), rect])
	return bad


## Print one pass's verdict and count its failures.
func _report(label: String, bad: Array[String]) -> void:
	if bad.is_empty():
		print("  ok  %s fits" % label)
	else:
		print("[FAIL] %s — %d control(s) past the screen" % [label, bad.size()])
		for entry in bad.slice(0, 8):
			print("        %s" % entry)
		_fails += bad.size()
