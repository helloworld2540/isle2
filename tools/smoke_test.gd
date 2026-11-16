extends SceneTree

## Headless smoke test: validate every scene under res://scenes.
##   1. Link check — every ext_resource path referenced by a scene (and by
##      .tres/.res files referenced from scenes) must exist on disk.
##      Catches missing scripts/art/audio even though Godot defers those
##      errors out of the import path.
##   2. Instantiate check — instantiate each scene, add it to the tree (fires
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

func _instantiate_check(p: String) -> void:
	var res = ResourceLoader.load(p)
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
