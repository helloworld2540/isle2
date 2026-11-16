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

func _initialize() -> void:
	_collect("res://scenes")
	_paths.sort()
	for p in _paths:
		_link_check(p)
	for p in _paths:
		_script_check(p)
	for p in _paths:
		_instantiate_check(p)
	print("smoke: %d scene(s), %d failure(s)" % [_paths.size(), _failures])
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
		printerr("[FAIL] unreadable     ", path)
		_failures += 1
		return
	var re := RegEx.new()
	# ext_resource lines carry uid and path; we check the path form.
	re.compile('ext_resource[^]]*?path="([^"]+)"')
	for m in re.search_all(text):
		var ref := m.get_string(1)
		if ref.begins_with("res://"):
			if not FileAccess.file_exists(ref):
				printerr("[FAIL] missing      ", ref, " (referenced by ", path, ")")
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
			printerr("[FAIL] script     ", path, " (referenced by ", p, ")")
			_failures += 1

func _instantiate_check(p: String) -> void:
	var res = ResourceLoader.load(p, "", ResourceLoader.CACHE_MODE_IGNORE)
	if res == null:
		printerr("[FAIL] load       ", p)
		_failures += 1
		return
	var inst = res.instantiate()
	if inst == null:
		printerr("[FAIL] instantiate ", p)
		_failures += 1
		return
	root.add_child(inst)
	if not is_instance_valid(inst):
		printerr("[FAIL] ready      ", p)
		_failures += 1
		return
	print("[PASS] ", p)
	inst.free()
