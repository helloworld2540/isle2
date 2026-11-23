extends Node

## Single source of truth for world-map text size.
##
## The world map is drawn through a zoomed camera (Camera2D.zoom = 0.45 in
## scenes/world.tscn), so a Label's font_size is not its on-screen size — it
## renders at 45% of it. Rather than scatter hand-tuned local sizes across the
## world scenes, every world label is described by a *role* and this manager
## turns one on-screen size, base_px, into the local font_size that role needs.
##
## Set base_px (it re-stamps the live tree) and the portal titles, NPC
## names/status, warnings, the ready marker and the collectible callouts all
## resize together.
##
## A Label opts in by joining a role group — in its scene or from code:
##   world_text_title  — portal titles, NPC names, the ready marker
##   world_text_body   — NPC quest/ambient lines, portal warnings
##   world_text_popup  — one-shot pickup callouts
## Runtime-created text (pickup popups) asks for a size with font_size(role).

## The knob: on-screen size, in pixels, of the largest world-map text (the
## "title" role). The other roles scale down from it (see ROLE_SCALE). Assigning
## re-stamps the live tree, so it can be tuned at runtime.
var base_px: float = 24.0:
	set(value):
		base_px = value
		if is_inside_tree():
			refresh()

## On-screen size per role, as a fraction of base_px.
const ROLE_SCALE := {
	"title": 1.0,
	"body": 0.85,
	"popup": 0.75,
}

## Mirror of Camera2D.zoom in scenes/world.tscn. Local size = on-screen / zoom.
const CAMERA_ZOOM := 0.45

## Group-name prefix; the suffix after it is the role.
const GROUP_PREFIX := "world_text_"

## Role used when a label joins an unknown role group.
const FALLBACK_ROLE := "body"


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node is Label:
		var role := role_of(node)
		if not role.is_empty():
			apply(node as Label, role)


## The role `node` opts into via its groups, or "" when it is not world text.
func role_of(node: Node) -> String:
	for group in node.get_groups():
		var name := String(group)
		if name.begins_with(GROUP_PREFIX):
			var role := name.substr(GROUP_PREFIX.length())
			return role if ROLE_SCALE.has(role) else FALLBACK_ROLE
	return ""


## The local font_size, in pixels, that renders `role` at base_px on screen.
func font_size(role: String) -> int:
	return maxi(1, roundi(base_px * float(ROLE_SCALE.get(role, 1.0)) / CAMERA_ZOOM))


## Stamp `label` with the local size for `role`.
func apply(label: Label, role: String) -> void:
	label.add_theme_font_size_override("font_size", font_size(role))


## Re-stamp every world text label under `root` (the whole tree by default).
## Useful when base_px is tuned at runtime.
func refresh(root: Node = null) -> void:
	_walk(root if root != null else get_tree().root)


func _walk(node: Node) -> void:
	if node is Label:
		var role := role_of(node)
		if not role.is_empty():
			apply(node as Label, role)
	for child in node.get_children():
		_walk(child)
