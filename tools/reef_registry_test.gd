extends SceneTree

## Reef Registry consistency harness.
##
## The registry is a four-way agreement: FishCatalog (names/blurbs), the Fish
## spawn tables in rr_fish.gd (textures + weights), the stats page's registry
## rows (REGISTRY_IDS / REGISTRY_BUTTONS), and the REEF REGISTRY achievement
## predicate. Every species must appear in all four or the page silently shows
## a locked row for a fish that cannot spawn (or vice versa). This harness
## walks the agreement so adding a species is one edit per table, not a hunt.
##
## Run: godot --headless --script tools/reef_registry_test.gd

const FishCatalogScript := preload("res://scripts/fish_catalog.gd")
const AchievementCatalogScript := preload("res://scripts/achievement_catalog.gd")

# Loaded at runtime, not preload: in a `--script` main loop, scripts (or scenes
# they preload) that read autoload singletons (SaveManager, GameSettings,
# AudioManager) fail to compile while the main script is still being parsed.
# Once the tree has booted the autoload globals resolve, so defer these loads.
var FishScript: GDScript
var StatsMenuScript: GDScript
var StatsScene: PackedScene

# ANSI color codes
const C_RESET := "\u001b[0m"
const C_BOLD := "\u001b[1m"
const C_RED := "\u001b[31m"
const C_GREEN := "\u001b[32m"
const C_YELLOW := "\u001b[33m"
const C_BLUE := "\u001b[34m"
const C_CYAN := "\u001b[36m"

var _fails := 0
var _passes := 0
var _skipped := 0
var _start_time: int = 0


func _initialize() -> void:
	_start_time = Time.get_ticks_msec()
	_print_header("Reef Registry Tests")
	await process_frame
	FishScript = load("res://scripts/rr_fish.gd")
	StatsMenuScript = load("res://scripts/stats_menu.gd")
	StatsScene = load("res://scenes/stats_menu.tscn")
	var catalog := FishCatalogScript.ENTRIES
	_check(catalog.size() >= 6, "catalogue carries at least six species (%d)" % catalog.size())

	# Every catalogue id is unique, named, and blurbbed — the registry renders
	# all three, so an empty string is a blank row on a shipped page.
	var ids: Array[String] = []
	for entry in catalog:
		var id := String(entry.get("id", ""))
		_check(not id.is_empty(), "catalogue entry has an id")
		_check(not ids.has(id), "catalogue id unique: %s" % id)
		ids.append(id)
		_check(not String(entry.get("name", "")).is_empty(), "%s has a name" % id)
		_check(String(entry.get("blurb", "")).length() > 30, "%s has a substantial blurb" % id)

	# Spawn tables: every catalogue species has a texture and a weight; every
	# texture the reef can spawn is in the catalogue (no unloggable fish).
	var fish_textures: Dictionary = FishScript.FISH
	var spawn_weights: Dictionary = FishScript.SPAWN_WEIGHTS
	_check(fish_textures.size() == ids.size(), "FISH has one texture per species (%d/%d)" % [fish_textures.size(), ids.size()])
	for id in ids:
		var texture := id + ".png"
		_check(fish_textures.has(texture), "%s has a FISH size row" % id)
		_check(spawn_weights.has(texture), "%s has a spawn weight" % id)
		_check(float(spawn_weights.get(texture, 0.0)) > 0.0, "%s spawns at all" % id)
	for texture in spawn_weights.keys():
		var id := String(texture).get_basename()
		_check(ids.has(id), "spawned texture %s is catalogued" % texture)
	for texture in fish_textures.keys():
		var id := String(texture).get_basename()
		_check(ids.has(id), "sized texture %s is catalogued" % texture)

	# The Starfish's signature: it drifts slower than a fish. A missing or
	# too-fast row would make the new species indistinguishable on the reef.
	var drift: Dictionary = FishScript.DRIFT_SPEED_SCALE
	_check(drift.has("fish_star.png"), "Starfish has a drift-speed row")
	_check(float(drift.get("fish_star.png", 1.0)) < 1.0, "Starfish drifts slower than a fish")

	# Every weighted species must actually be reachable: run the real picker a
	# few thousand times and confirm each texture comes up. A species with a
	# zero (or unreachable) weight is a row nobody can ever unlock.
	seed(20261118)
	var seen_spawns: Dictionary = {}
	for _i in range(3000):
		var picked := String(FishScript._pick_fish_texture())
		seen_spawns[picked] = int(seen_spawns.get(picked, 0)) + 1
	for id in ids:
		_check(int(seen_spawns.get(id + ".png", 0)) > 0, "%s is reachable in 3000 spawns" % id)

	# Stats page rows: ids and scene buttons must match the catalogue 1:1.
	var registry_ids: Array = StatsMenuScript.REGISTRY_IDS
	var registry_buttons: Array = StatsMenuScript.REGISTRY_BUTTONS
	_check(registry_ids.size() == ids.size(), "registry lists every species (%d/%d)" % [registry_ids.size(), ids.size()])
	_check(registry_buttons.size() == registry_ids.size(), "registry button/id counts agree")
	for id in ids:
		_check(registry_ids.has(id), "%s has a registry row" % id)

	var stats := StatsScene.instantiate()
	root.add_child(stats)
	for button_name in registry_buttons:
		var path := "RegistryOverlay/Panel/VBox/%s" % String(button_name)
		_check(stats.get_node(path) != null, "scene has %s" % button_name)
	# The locked/found text builder must have a hint for every species, or a
	# locked row falls back to the generic "? ? ?" line.
	var known_hints := 0
	for id in registry_ids:
		var button := stats.get_node("RegistryOverlay/Panel/VBox/%s" % String(registry_buttons[registry_ids.find(id)])) as Button
		if button and (not button.text.is_empty()):
			known_hints += 1
	_check(known_hints == registry_ids.size(), "every registry row carries a hint label (%d/%d)" % [known_hints, registry_ids.size()])
	stats.queue_free()

	# The achievement predicate must demand the whole catalogue, not a stale
	# five-of-six constant. Seed GameState directly and restore afterwards.
	var gs = root.get_node("GameState")
	_check(gs != null, "GameState autoload present")
	if gs:
		var saved: Array = gs.fish_met.duplicate()
		gs.fish_met.clear()
		var partial: Array = ids.duplicate()
		partial.pop_back()
		gs.fish_met.assign(partial)
		_check(not AchievementCatalogScript.is_met("reef_registry", gs), "REEF REGISTRY refuses %d/%d species" % [partial.size(), ids.size()])
		gs.fish_met.assign(ids)
		_check(AchievementCatalogScript.is_met("reef_registry", gs), "REEF REGISTRY accepts %d/%d species" % [ids.size(), ids.size()])
		gs.fish_met.assign(saved)

	_print_summary()
	quit(_fails)


func _check(ok: bool, what: String) -> void:
	if ok:
		_passes += 1
		print(C_GREEN + "✓" + C_RESET + " " + what)
	else:
		_fails += 1
		print(C_RED + "✗" + C_RESET + " " + what)


func _print_header(title: String) -> void:
	var line := "═".repeat(title.length() + 4)
	print(C_CYAN + line + C_RESET)
	print(C_CYAN + "  " + title + "  " + C_RESET)
	print(C_CYAN + line + C_RESET)
	print("")


func _print_summary() -> void:
	var elapsed := (Time.get_ticks_msec() - _start_time) / 1000.0
	var total := _passes + _fails + _skipped
	var line := "─".repeat(50)
	print("")
	print(C_CYAN + line + C_RESET)
	print(C_BOLD + "RESULTS:" + C_RESET + " " + C_GREEN + str(_passes) + C_RESET + "  " + C_RED + "FAILED:" + C_RESET + " " + str(_fails) + "  " + C_YELLOW + "SKIPPED:" + C_RESET + " " + str(_skipped))
	var time_str := "%0.2f" % elapsed
	print(C_BOLD + "TOTAL:" + C_RESET + " " + str(total) + "  " + C_BLUE + "TIME:" + C_RESET + " " + time_str + "s")
	if _fails == 0:
		print(C_BOLD + "STATUS:" + C_RESET + " " + C_GREEN + "✓ ALL TESTS PASSED" + C_RESET)
	else:
		print(C_BOLD + "STATUS:" + C_RESET + " " + C_RED + "✗ " + str(_fails) + " TEST(S) FAILED" + C_RESET)
	print(C_CYAN + line + C_RESET)
