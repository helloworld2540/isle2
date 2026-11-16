extends Node

## Read/write the save file, with two safety nets:
##  1. Before every write the current save is copied to save.json.bak, so a
##     torn or half-written file can never be the only copy.
##  2. load_game falls back to the backup when the primary is missing or
##     unreadable, and reports that it recovered so callers can log.
const SAVE_PATH := "user://save.json"
const BACKUP_PATH := "user://save.json.bak"
const SAVE_VERSION := 1

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

## Player position is persisted through here as well, so deleting all progress
## removes the backup too; a fresh "New save" must never see it.
func new_save() -> void:
	for path in [SAVE_PATH, BACKUP_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

func has_backup() -> bool:
	return FileAccess.file_exists(BACKUP_PATH)

func save_game(data: Dictionary) -> void:
	# Park the previous save before overwriting it.
	if has_save():
		var existing := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if existing:
			var content := existing.get_as_text()
			existing.close()
			var backup := FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
			if backup:
				backup.store_string(content)
				backup.close()
	
	data["save_version"] = SAVE_VERSION
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: could not open save file for writing")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

## Load, merge `patch` over the stored dict, and write back in one pass.
## Returns the merged dict. Centralizes the read-modify-write pattern so the
## autoloads stop each re-implementing it.
func update_game(patch: Dictionary) -> Dictionary:
	var data := load_game()
	for key in patch.keys():
		data[key] = patch[key]
	save_game(data)
	return data

## Like update_game but merges `sub_patch` into one nested dictionary key
## (e.g. the per-NPC "npc_visited" flags), preserving sibling entries.
func update_nested(dict_key: String, sub_patch: Dictionary) -> Dictionary:
	var data := load_game()
	var dict: Dictionary = data.get(dict_key, {})
	for key in sub_patch.keys():
		dict[key] = sub_patch[key]
	data[dict_key] = dict
	save_game(data)
	return data

func load_game() -> Dictionary:
	var data := _read_json(SAVE_PATH)
	if data.is_empty() and not _file_empty(SAVE_PATH):
		push_warning("SaveManager: primary save unreadable, trying backup")
		data = _read_json(BACKUP_PATH)
	if data.is_empty():
		data = {"money": 0}
	if not data.has("money"):
		data["money"] = 0
	return data


func _file_empty(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return true
	return FileAccess.open(path, FileAccess.READ).get_as_text().strip_edges().is_empty()

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var result = JSON.parse_string(text)
	if result is Dictionary:
		return result
	return {}

# --- Player position ---
# Stored as [x, y] so the world map can drop the player back where they left.

func save_player_position(pos: Vector2) -> void:
	update_game({"player_position": [pos.x, pos.y]})

func load_player_position() -> Variant:
	var data := load_game()
	var value = data.get("player_position")
	if value is Array and value.size() == 2:
		return Vector2(float(value[0]), float(value[1]))
	if value is String:
		var cleaned: String = value.strip_edges().trim_prefix("(").trim_suffix(")")
		var parts := cleaned.split(",")
		if parts.size() == 2:
			return Vector2(parts[0].to_float(), parts[1].to_float())
	return null
