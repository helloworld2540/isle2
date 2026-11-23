extends SceneTree

## Headless smoke test: validate every scene under res://scenes.
##   1. Link check — every ext_resource path referenced by a scene (and by
##      .tres/.res files referenced from scenes) must exist on disk.
##      Catches missing scripts/art/audio even though Godot defers those
##      errors out of the import path.
##   2. Script check — every `script = ExtResource(...)` in a scene must
##      resolve to a script that actually loads AND parses (an empty/parse-
##      error script nulls the node's script while instantiate() still
##      succeeds, so check the declared scripts explicitly).
##   3. Instantiate check — instantiate each scene, add it to the tree (fires
##      _ready), and confirm it survives.
##
## Usage (from the project root):
##   godot --headless --path . -s tools/smoke_test.gd
## Exit code = number of failing checks (0 = clean), so CI/the loop can gate on it.
##
## Note: scenes whose _ready touches the save file or audio will still run here;
## back up user://save.json around the run if you care about its contents.

var _paths: Array[String] = []
var _checked_resources: Dictionary = {}
var _failures := 0
var _passes := 0
var _skipped := 0
var _start_time: int = 0

# ANSI color codes
const C_RESET := "\u001b[0m"
const C_BOLD := "\u001b[1m"
const C_RED := "\u001b[31m"
const C_GREEN := "\u001b[32m"
const C_YELLOW := "\u001b[33m"
const C_BLUE := "\u001b[34m"
const C_CYAN := "\u001b[36m"

func _initialize() -> void:
	_start_time = Time.get_ticks_msec()
	_print_header("Scene Smoke Tests")
	_collect("res://scenes")
	_paths.sort()
	for p in _paths:
		_link_check(p)
	for p in _paths:
		_script_check(p)
	for p in _paths:
		_instantiate_check(p)
	_print_summary()
	quit(_failures)

func _collect(dir: String) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	d.list_dir_begin()
	var name := d.get_next()
	while name != "":
		var path := dir + "/" + name
		if d.current_is_dir():
			if not name.begins_with("."):
				_collect(path)
		elif name.ends_with(".tscn"):
			_paths.append(path)
		name = d.get_next()
	d.list_dir_end()

func _link_check(path: String) -> void:
	if _checked_resources.has(path):
		return
	_checked_resources[path] = true
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		printerr(C_RED + "[FAIL] unreadable     " + path + C_RESET)
		_failures += 1
		return
	var re := RegEx.new()
	# ext_resource lines carry uid and path; we check the path form.
	re.compile('ext_resource[^]]*?path="([^"]+)"')
	for m in re.search_all(text):
		var ref := m.get_string(1)
		if ref.begins_with("res://"):
			if not FileAccess.file_exists(ref):
				printerr(C_RED + "[FAIL] missing      " + ref + " (referenced by " + path + ")" + C_RESET)
				_failures += 1
			elif ref.ends_with(".tres") or ref.ends_with(".res"):
				_link_check(ref)

## Every `script = ExtResource("id")` in the scene must resolve to a script
## that loads and compiles. A parse error silently nulls the node's script,
## yet instantiate() still "succeeds" — without this check a broken script
## sailed through as PASS.
func _script_check(p: String) -> void:
	var text := FileAccess.get_file_as_string(p)
	if text.is_empty():
		return
	# Map ext_resource ids to their paths (both attribute orders are legal).
	var id_to_path: Dictionary = {}
	var re_ext := RegEx.new()
	re_ext.compile('ext_resource[^]]*')
	for m in re_ext.search_all(text):
		var line: String = m.get_string(0)
		var re_path := RegEx.new()
		re_path.compile('path="([^"]+)"')
		var re_id := RegEx.new()
		re_id.compile('id="([^"]+)"')
		var pm := re_path.search(line)
		var im := re_id.search(line)
		if pm and im:
			id_to_path[im.get_string(1)] = pm.get_string(1)
	var re_use := RegEx.new()
	re_use.compile('script = ExtResource\\("([^"]+)"\\)')
	for m in re_use.search_all(text):
		var path: String = id_to_path.get(m.get_string(1), "")
		if path.is_empty() or not path.begins_with("res://"):
			continue
		# Bypass the .godot compile cache: a stale cached binary can mask an on-disk parse error.
		var script: Script = ResourceLoader.load(path, "Script", ResourceLoader.CACHE_MODE_IGNORE) as Script
		if script == null:
			printerr(C_RED + "[FAIL] script     " + path + " (referenced by " + p + ")" + C_RESET)
			_failures += 1

func _instantiate_check(p: String) -> void:
	var res = ResourceLoader.load(p, "", ResourceLoader.CACHE_MODE_IGNORE)
	if res == null:
		printerr(C_RED + "[FAIL] load       " + p + C_RESET)
		_failures += 1
		return
	var inst = res.instantiate()
	if inst == null:
		printerr(C_RED + "[FAIL] instantiate " + p + C_RESET)
		_failures += 1
		return
	root.add_child(inst)
	if not is_instance_valid(inst):
		printerr(C_RED + "[FAIL] ready      " + p + C_RESET)
		_failures += 1
		return
	# An inline `script =` on the [node ...] header line is silently dropped by
	# the scene deserializer (it must sit on its own property line), which
	# leaves a scriptless node. Catch that here: if the scene declares scripts,
	# the root node must carry one when the scene has a script assigned.
	var problems := _missing_scripts(p, inst)
	for missing in problems:
		printerr(C_RED + "[FAIL] script     " + missing + C_RESET)
		_failures += 1
	print(C_GREEN + "[PASS]" + C_RESET + " " + p)
	_passes += 1
	inst.free()


## Walk a scene's declared script assignments against the instantiated tree.
## Every `script =` line under a `[node ...]` section must resolve to a live
## script on the matching node — otherwise the node loads scriptless and any
## behaviour is missing with no error beyond a silent type mismatch at the
## call site, which is exactly how a refactor shipped broken guide rows.
func _missing_scripts(p: String, inst: Node) -> Array[String]:
	var missing: Array[String] = []
	var text := FileAccess.get_file_as_string(p)
	var id_to_path: Dictionary = {}
	var re_ext := RegEx.new()
	re_ext.compile('ext_resource[^]]*')
	for m in re_ext.search_all(text):
		var line: String = m.get_string(0)
		var re_path := RegEx.new()
		var re_id := RegEx.new()
		re_path.compile('path="([^"]+)"')
		re_id.compile('id="([^"]+)"')
		var pm := re_path.search(line)
		var im := re_id.search(line)
		if pm and im:
			id_to_path[im.get_string(1)] = pm.get_string(1)
	var node_scripts: Dictionary = {}   # tree path -> script path
	for raw in text.split("[node "):
		if raw.is_empty():
			continue
		var sec := "[node " + raw
		var nm := RegEx.new()
		nm.compile('name="([^"]+)"')
		var name_m := nm.search(sec)
		if name_m == null:
			continue
		var node_path := name_m.get_string(1)
		var re_script := RegEx.new()
		re_script.compile('script ?= ?ExtResource\\("([^"]+)"\\)')
		var script_m := re_script.search(sec)
		if script_m == null:
			continue
		var script_path: String = id_to_path.get(script_m.get_string(1), "")
		if script_path.is_empty():
			continue
		var full_path := _node_path_from_header(sec, node_path)
		node_scripts[full_path] = script_path
	for np in node_scripts:
		var node: Node = inst.get_node(np) if np != "." else inst
		if node == null:
			missing.append(p + ": missing node " + np)
			continue
		if node.get_script() == null:
			missing.append(p + ": " + np + " lost " + node_scripts[np])
	return missing


## Build the scene tree path for a `[node name="..." ... parent="..."]` section.
## The root has no parent attribute; `parent="."` is a direct child of root
## and its tree path is just its own name.
func _node_path_from_header(section: String, name: String) -> String:
	var re_parent := RegEx.new()
	re_parent.compile('parent="([^"]+)"')
	var pm := re_parent.search(section)
	if pm == null:
		return "."   # root
	var parent := pm.get_string(1)
	if parent == "." or parent.is_empty():
		return name
	return parent + "/" + name


func _print_header(title: String) -> void:
	var line := "═".repeat(title.length() + 4)
	print(C_CYAN + line + C_RESET)
	print(C_CYAN + "  " + title + "  " + C_RESET)
	print(C_CYAN + line + C_RESET)
	print("")


func _print_summary() -> void:
	var elapsed := (Time.get_ticks_msec() - _start_time) / 1000.0
	var total := _passes + _failures + _skipped
	var line := "─".repeat(50)
	print("")
	print(C_CYAN + line + C_RESET)
	print(C_BOLD + "RESULTS:" + C_RESET + " " + C_GREEN + str(_passes) + C_RESET + "  " + C_RED + "FAILED:" + C_RESET + " " + str(_failures) + "  " + C_YELLOW + "SKIPPED:" + C_RESET + " " + str(_skipped))
	var time_str := "%0.2f" % elapsed
	print(C_BOLD + "TOTAL:" + C_RESET + " " + str(total) + "  " + C_BLUE + "TIME:" + C_RESET + " " + time_str + "s")
	if _failures == 0:
		print(C_BOLD + "STATUS:" + C_RESET + " " + C_GREEN + "✓ ALL TESTS PASSED" + C_RESET)
	else:
		print(C_BOLD + "STATUS:" + C_RESET + " " + C_RED + "✗ " + str(_failures) + " TEST(S) FAILED" + C_RESET)
	print(C_CYAN + line + C_RESET)
