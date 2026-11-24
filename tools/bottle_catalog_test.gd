extends SceneTree

## Bottle catalogue consistency harness.
##
## The island's eight "messages in a bottle" must agree with themselves: the
## catalogue entries are well-formed, the known story ids resolve through
## find/title_of/lines_of, every story-arc bottle id exists in the catalogue,
## and the Tide Ledger tables on the stats page line up with it.
##
## Static invocation — no autoload singletons touched:
##   godot --headless --script tools/bottle_catalog_test.gd

const BottleCatalogScript := preload("res://scripts/bottle_catalog.gd")
var StatsMenuScript: GDScript
var WM_BottleScript: GDScript

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
	await process_frame
	_print_header("Bottle Catalog Tests")
	await _run()
	_print_summary()
	quit(_fails)


func _run() -> void:
	var catalog: Array = BottleCatalogScript.ENTRIES
	_check(catalog.size() >= 8, "bottle catalogue carries at least eight notes (%d)" % catalog.size())

	# Every entry is named once, titled once, and carries a real letter.
	var ids: Array[String] = []
	var titles: Array[String] = []
	for entry in catalog:
		var id := String(entry.get("id", ""))
		_check(not id.is_empty(), "bottle entry has a name: '%s'" % id)
		_check(not ids.has(id), "bottle id unique: %s" % id)
		ids.append(id)
		var title := String(entry.get("title", ""))
		_check(not title.strip_edges().is_empty(), "%s has a title" % id)
		titles.append(title)
		var lines: Array = entry.get("lines", [])
		_check(lines.size() >= 3, "%s carries %d lines" % [id, lines.size()])
		for line in lines:
			_check(String(line).strip_edges().length() > 0, "%s has a substantial line" % id)
	for i in range(titles.size()):
		for j in range(i + 1, titles.size()):
			_check(not titles[i].is_empty() and titles[i] != titles[j], "bottle titles unique (%s)" % titles[i])

	# The eight known story ids must all resolve through the catalogue.
	var known_ids: Array[String] = [
		"bottle_tide", "bottle_gull", "bottle_light", "bottle_pact",
		"bottle_keeper", "bottle_corl", "bottle_watcher", "bottle_far_point",
	]
	for id in known_ids:
		var entry: Dictionary = BottleCatalogScript.find(id)
		_check(not String(entry.get("id", "")).is_empty(), "find(%s) resolves to a bottle" % id)
		_check(not String(BottleCatalogScript.title_of(id)).is_empty(), "title_of(%s) resolves" % id)
		var found_lines: Array = BottleCatalogScript.lines_of(id)
		_check(found_lines.size() >= 3, "lines_of(%s) carries the note" % id)

	# Every story-arc bottle id the world can hand the player must be catalogued.
	WM_BottleScript = load("res://scripts/wm_bottle.gd") as GDScript
	var arc_ids: Array[String] = []
	for arc_id in WM_BottleScript.BASE_BOTTLE_IDS:
		arc_ids.append(String(arc_id))
	for arc_id in [
		WM_BottleScript.PACT_BOTTLE_ID,
		WM_BottleScript.KEEPER_BOTTLE_ID,
		WM_BottleScript.CORL_BOTTLE_ID,
		WM_BottleScript.WATCHER_BOTTLE_ID,
		WM_BottleScript.FAR_POINT_BOTTLE_ID,
	]:
		arc_ids.append(String(arc_id))
	for arc_id in arc_ids:
		_check(ids.has(arc_id), "story arc bottle %s is catalogued" % arc_id)

	# Stats cross-check: the Tide Ledger tables must name the catalogue's set.
	StatsMenuScript = load("res://scripts/stats_menu.gd") as GDScript
	var ledger_ids: Array = StatsMenuScript.LEDGER_IDS
	var ledger_buttons: Array = StatsMenuScript.LEDGER_BUTTONS
	_check(ledger_ids.size() == 8, "tide ledger lists eight bottles (%d)" % ledger_ids.size())
	_check(ledger_buttons.size() == ledger_ids.size(), "ledger buttons align 1:1 with ledger ids by index (%d/%d)" % [ledger_buttons.size(), ledger_ids.size()])
	var ledger_set := {}
	for ledger_id in ledger_ids:
		ledger_set[String(ledger_id)] = true
	var uncatalogued := 0
	for id in ids:
		if not ledger_set.has(id):
			_check(false, "catalogue bottle %s missing from the tide ledger" % id)
			uncatalogued += 1
	_check(uncatalogued == 0, "every catalogue bottle has a tide ledger row")


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
	print(C_CYAN + "  " + title + C_RESET)
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
