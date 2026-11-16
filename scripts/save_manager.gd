extends Node

const SAVE_PATH := "user://save.json"

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func new_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)

func save_game(data: Dictionary) -> void:
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
	if not has_save():
		return {"money": 0}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {"money": 0}
	var text := file.get_as_text()
	file.close()
	var result = JSON.parse_string(text)
	if result is Dictionary:
		if not result.has("money"):
			result["money"] = 0
		return result
	return {"money": 0}

# --- Player position ---
# Stored as [x, y] so the world map can drop the player back where they left.

func save_player_position(pos: Vector2) -> void:
	update_game({"player_position": [pos.x, pos.y]})

# Returns the saved position, or null when the save has none.
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
