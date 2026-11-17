extends Node

## Read/write the save file, with three safety nets:
##  1. Before every write the current save is rotated into save.json.bak and
##     the previous backup into save.json.bak2, so a torn write can never be
##     the only surviving copy.
##  2. load_game falls back to the backup (and then the second-generation
##     backup) when the primary is missing or unreadable, and reports that
##     it recovered so callers can log.
##  3. A schema version gate (`_check_version`) upgrades older saves on load.
##
## Slots. The island can live in more than one named slot — a main island, a
## scratch island for trying a new route without risking the first — and every
## slot keeps its own save.json + .bak + .bak2, so a torn write in one slot
## can never touch another. `current_slot` is the one the autoloads are
## currently reading/writing; the main menu switches it when the player picks
## a row. Backups are per-slot, so a slot's recovery never crosses into
## another player's file.
const SAVE_PATH := "user://save.json"
const BACKUP_PATH := "user://save.json.bak"
## Second-generation backup: every write parks the current save in .bak and
## rotates the previous .bak into .bak2, so a torn write is never the only
## surviving copy — and a torn write of the backup itself still leaves .bak2.
const BACKUP2_PATH := "user://save.json.bak2"
const SAVE_VERSION := 1

## Slot metadata helpers (slugify, summaries, age labels) live in the globally
## registered `SaveSlot` class (scripts/save_slot.gd).

## Directory holding one folder per slot. Each folder is named by its slug.
const SLOT_DIR := "user://slots"

## The slot currently bound to the autoloads. Empty until the main menu
## picks one; the game will not save or load until it has been set.
var current_slot: String = ""


## Path helpers for the current slot. Falls back to the legacy single file
## when no slot is active, so a pre-slot save still loads.
func _slot_dir() -> String:
	if current_slot.is_empty():
		return ""
	return "%s/%s" % [SLOT_DIR, current_slot]


func _slot_paths() -> Array:
	var d := _slot_dir()
	if d.is_empty():
		return [SAVE_PATH, BACKUP_PATH, BACKUP2_PATH]
	return ["%s/save.json" % d, "%s/save.json.bak" % d, "%s/save.json.bak2" % d]


## --- Slot directory ---

## Bind the autoloads to the slot they should use. Idempotent and safe to
## call from anywhere: it only does work the first time. On first boot it
## migrates a legacy single-file save into the default slot, picks the most
## recently played slot, or binds a fresh default id when the player has never
## saved at all.
##
## Called from has_save/load/save so the binding is correct even if a scene
## touches SaveManager before the main menu exists.
func ensure_bound() -> void:
	if not current_slot.is_empty():
		return
	if _legacy_save_exists():
		current_slot = "island"
		_migrate_legacy_save()
		return
	var existing := list_slots()
	if not existing.is_empty():
		current_slot = String(existing[0].get("id", "island"))
		return
	# Fresh install with no save at all: bind the default id. No file is
	# written until the player actually starts an island.
	current_slot = "island"


func _legacy_save_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH) and not _file_empty(SAVE_PATH)


## Move a pre-slot save (and its backups) into the default slot so a returning
## player keeps their island. Best-effort: if any copy fails the original is
## left in place and the game still boots from the legacy path.
func _migrate_legacy_save() -> void:
	var dir := "%s/island" % SLOT_DIR
	DirAccess.make_dir_recursive_absolute(dir)
	var moved := true
	for pair in [[SAVE_PATH, "%s/save.json" % dir], [BACKUP_PATH, "%s/save.json.bak" % dir], [BACKUP2_PATH, "%s/save.json.bak2" % dir]]:
		var src := String(pair[0])
		var dst := String(pair[1])
		if not FileAccess.file_exists(src):
			continue
		if DirAccess.copy_absolute(src, dst) != OK:
			moved = false
	if moved:
		for path in [SAVE_PATH, BACKUP_PATH, BACKUP2_PATH]:
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
	# Stamp the slot identity on the migrated file so its row self-describes.
	var data := _read_json("%s/save.json" % dir)
	if not data.is_empty():
		data["slot_id"] = "island"
		if not data.has("slot_name"):
			data["slot_name"] = "Island"
		data["save_version"] = SAVE_VERSION
		var file := FileAccess.open("%s/save.json" % dir, FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(data, "\t"))
			file.close()


## Every slot the player owns, newest first. Pure directory scan — the legacy
## migration is handled once in ensure_bound(), so this never recurses.
func list_slots() -> Array:
	var out: Array = []
	if not DirAccess.dir_exists_absolute(SLOT_DIR):
		return out
	var dir := DirAccess.open(SLOT_DIR)
	if dir == null:
		return out
	for name in dir.get_directories():
		if name.begins_with("."):
			continue
		var sub := "%s/%s" % [SLOT_DIR, name]
		if not DirAccess.dir_exists_absolute(sub):
			continue
		var file := "%s/save.json" % sub
		if not FileAccess.file_exists(file):
			continue
		var header := _read_slot_header(file, name, name)
		if not header.is_empty():
			out.append(header)
	out.sort_custom(func(a, b): return int(a.get("modified", 0)) > int(b.get("modified", 0)))
	return out


## Parses a slot file and normalizes its identity fields. The full dict is
## returned (the picker shows money/score/preview in one line), so listing is
## one read per slot, only when the menu opens.
func _read_slot_header(path: String, fallback_id: String, fallback_name: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var result = JSON.parse_string(text)
	if not (result is Dictionary):
		return {}
	var out: Dictionary = result
	out["id"] = String(result.get("slot_id", fallback_id))
	out["name"] = String(result.get("slot_name", fallback_name))
	out["created"] = int(result.get("slot_created", 0))
	out["modified"] = int(result.get("slot_modified", 0))
	if int(out["modified"]) <= 0:
		# Fall back to the file's mtime when the save predates the timestamp.
		out["modified"] = FileAccess.get_modified_time(path)
	return out


## Create a brand-new slot from `name`, bind the autoloads to it, and write a
## fresh island. Returns the slot id, or "" on failure (e.g. the name is
## blank or the slot already exists).
func create_slot(name: String) -> String:
	var cleaned := name.strip_edges()
	if cleaned.is_empty():
		return ""
	var existing := list_slots()
	var slug := SaveSlot.slugify(cleaned)
	slug = SaveSlot.unique_slug(slug, existing)
	if slug.is_empty():
		slug = "island"
	var dir := "%s/%s" % [SLOT_DIR, slug]
	var mk := DirAccess.make_dir_recursive_absolute(dir)
	if mk != OK and not DirAccess.dir_exists_absolute(dir):
		push_error("SaveManager: could not create slot directory %s" % dir)
		return ""
	current_slot = slug
	# GameState has not been restored for this slot yet — write a blank island
	# through the schema so the file is structurally valid from the first byte.
	var fresh := _fresh_slot_data(slug, cleaned)
	save_game(fresh)
	return slug


## Rename the current slot. The directory keeps its slug; only the in-file
## label changes, so existing backups and paths stay valid.
func rename_slot(name: String) -> bool:
	if current_slot.is_empty():
		return false
	var cleaned := name.strip_edges()
	if cleaned.is_empty():
		return false
	var data := load_game()
	data["slot_name"] = cleaned
	save_game(data)
	return true


## Delete the current slot and its backups, then bind the autoloads to another
## slot (or the default id) so the game still has somewhere to write.
func delete_slot() -> bool:
	if current_slot.is_empty():
		return false
	var paths := _slot_paths()
	for path in paths:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	var dir := _slot_dir()
	if not dir.is_empty() and DirAccess.dir_exists_absolute(dir):
		DirAccess.remove_absolute(dir)
	# Re-bind: the most recent surviving slot, or the fresh default id.
	current_slot = ""
	ensure_bound()
	return true


## Switch the autoloads to `slot_id`. Returns true on success; the caller is
## responsible for GameState.restore() afterwards.
func switch_slot(slot_id: String) -> bool:
	if slot_id.is_empty():
		return false
	# Once bound, switching to an existing slot is a plain assignment. A slot
	# id created this frame (create_slot) is already bound, so allow that too.
	if slot_id == current_slot:
		return true
	for e in list_slots():
		if String(e.get("id", "")) == slot_id:
			current_slot = slot_id
			return true
	return false


## Build a structurally-valid fresh island for a new slot, carrying only its
## identity. GameState.restore() will overwrite the scalar fields from this
## same dict on load, so the file is a correct v1 save the moment it is written.
func _fresh_slot_data(slug: String, name: String) -> Dictionary:
	var now := int(Time.get_unix_time_from_system())
	var out := {"money": 0, "save_version": SAVE_VERSION}
	out["slot_id"] = slug
	out["slot_name"] = name
	out["slot_created"] = now
	out["slot_modified"] = now
	return out

func has_save() -> bool:
	ensure_bound()
	return FileAccess.file_exists(_slot_paths()[0])

## Player position is persisted through here as well, so deleting all progress
## removes the backup too; a fresh "New save" must never see it.
func new_save() -> void:
	ensure_bound()
	for path in _slot_paths():
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

func has_backup() -> bool:
	ensure_bound()
	return FileAccess.file_exists(_slot_paths()[1])


## Compact summary of what the backup holds, for a restore button's preview
## text — never mutates anything. Empty dictionary when no backup exists or
## the file is unreadable.
func backup_summary() -> Dictionary:
	ensure_bound()
	var paths := _slot_paths()
	if not FileAccess.file_exists(paths[1]):
		return {}
	var text := FileAccess.get_file_as_string(paths[1])
	if text.is_empty():
		return {}
	var parsed = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return {}
	return {
		"money": int(parsed.get("money", 0)),
		"score": int(parsed.get("upcycle_score", 0)),
		"circuits": int(parsed.get("circuits_completed", 0)),
		"mtime": FileAccess.get_modified_time(paths[1]),
	}


## Overwrite the current save with the first backup. The pre-restore state is
## rotated into save.json.bak2 first, so no data is silently lost. Returns
## false when no backup exists. Callers refresh state themselves after a
## truthy return.
func restore_backup() -> bool:
	ensure_bound()
	var paths := _slot_paths()
	if not FileAccess.file_exists(paths[1]):
		return false
	if FileAccess.file_exists(paths[0]):
		DirAccess.copy_absolute(paths[0], paths[2])
	DirAccess.copy_absolute(paths[1], paths[0])
	return true

## When the save was last written, in unix seconds — 0 if unknown. Useful for
## stats pages that want to tell the player "this is from yesterday".
func get_save_mtime() -> int:
	ensure_bound()
	return FileAccess.get_modified_time(_slot_paths()[0])

func save_game(data: Dictionary) -> void:
	ensure_bound()
	# Make sure the slot directory exists before the first write to a fresh id.
	var dir := _slot_dir()
	if not dir.is_empty():
		DirAccess.make_dir_recursive_absolute(dir)
	# Park the previous save before overwriting it. Rotate generations so a
	# torn write of either file still leaves a readable copy behind.
	var paths := _slot_paths()
	if FileAccess.file_exists(paths[0]):
		if FileAccess.file_exists(paths[1]):
			DirAccess.copy_absolute(paths[1], paths[2])
		var existing := FileAccess.open(paths[0], FileAccess.READ)
		if existing:
			var content := existing.get_as_text()
			existing.close()
			var backup := FileAccess.open(paths[1], FileAccess.WRITE)
			if backup:
				backup.store_string(content)
				backup.close()

	data["save_version"] = SAVE_VERSION
	# Every write carries the slot's identity, so a file moved between slots
	# can never silently claim the wrong name.
	if not data.has("slot_id"):
		data["slot_id"] = current_slot
	var file := FileAccess.open(paths[0], FileAccess.WRITE)
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
	ensure_bound()
	var paths := _slot_paths()
	var data := _read_json(paths[0])
	if data.is_empty() and not _file_empty(paths[0]):
		push_warning("SaveManager: primary save unreadable, trying backup")
		data = _read_json(paths[1])
	if data.is_empty() and not _file_empty(paths[1]):
		push_warning("SaveManager: backup save unreadable, trying second-generation backup")
		data = _read_json(paths[2])
	if data.is_empty():
		data = {"money": 0}
	if not data.has("money"):
		data["money"] = 0
	data = _check_version(data)
	return data


## Schema gate for saves. `save_version` is written by every save_game(); this
## reads it back and either upgrades an older layout or warns when the file
## came from a newer build. Migrations are pure dict transforms chained in
## version order — each step only needs to produce the next version's shape.
## v0 (pre-versioning) → v1: nothing structural to fix; the key codec layer
## in GameState already tolerates missing keys via defaults, so the bump is
## purely declarative.
func _check_version(data: Dictionary) -> Dictionary:
	var version := int(data.get("save_version", 0))
	if version > SAVE_VERSION:
		push_warning("SaveManager: save_version %d is newer than this build (%d); loading as-is" % [version, SAVE_VERSION])
		return data
	while version < SAVE_VERSION:
		match version:
			0:
				# v0 → v1: mark the file as current; no key renames needed.
				version = 1
				data["save_version"] = version
			_:
				push_warning("SaveManager: no migration from save_version %d; stopping" % version)
				break
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
