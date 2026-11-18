extends Control
class_name StatsMenu

const SCENE_MAIN_MENU: String = "res://scenes/main_menu.tscn"
const DIALOGUE_SCENE: PackedScene = preload("res://scenes/ui/npc_dialogue.tscn")
const BottleCatalog := preload("res://scripts/bottle_catalog.gd")
const FishCatalog := preload("res://scripts/fish_catalog.gd")
## Display order of the Tide Ledger buttons, matched to the scene's button nodes.
const LEDGER_BUTTONS: Array[String] = ["BottleTideButton", "BottleGullButton", "BottleLightButton", "BottlePactButton", "BottleKeeperButton", "BottleCorlButton", "BottleWatcherButton", "BottleFarPointButton"]
const LEDGER_IDS: Array[String] = ["bottle_tide", "bottle_gull", "bottle_light", "bottle_pact", "bottle_keeper", "bottle_corl", "bottle_watcher", "bottle_far_point"]
## Reef Registry rows, matched to the scene's button nodes and FishCatalog.
const REGISTRY_BUTTONS: Array[String] = ["FishGoldButton", "FishGreyreefsharkButton", "FishNemoButton", "FishCrabButton", "FishSilverfinButton"]
const REGISTRY_IDS: Array[String] = ["fish_gold", "fish_greyreefshark", "fish_nemo", "fish_crab", "fish_silverfin"]
## Display order of the guide's station sections. Entries carry a "where" tag.
const GUIDE_GROUPS: Array[String] = ["Reef Rescue", "Upcycle", "Shop", "Islanders", "Island", "Hidden"]

@onready var _journal_label: Label = $"Margin/VBox/StatsScroll/Content/JournalBanner/JournalLabel"
@onready var _saved_label: Label = $"Margin/VBox/Header/SavedLabel"
@onready var _bench_body: Label = $"Margin/VBox/StatsScroll/Content/SectionGrid/BenchPanel/BenchBox/BenchBody"
@onready var _till_body: Label = $"Margin/VBox/StatsScroll/Content/SectionGrid/TillPanel/TillBox/TillBody"
@onready var _reef_body: Label = $"Margin/VBox/StatsScroll/Content/SectionGrid/ReefPanel/ReefBox/ReefBody"
@onready var _bag_body: Label = $"Margin/VBox/StatsScroll/Content/SectionGrid/BagPanel/BagBox/BagBody"
@onready var _collections_body: Label = $"Margin/VBox/StatsScroll/Content/SectionGrid/CollectionsPanel/CollectionsBox/CollectionsBody"
@onready var _deeds_body: Label = $"Margin/VBox/StatsScroll/Content/SectionGrid/DeedsPanel/DeedsBox/DeedsBody"
@onready var _almanac_body: Label = $"Margin/VBox/StatsScroll/Content/AlmanacBanner/AlmanacBox/AlmanacBody"
@onready var _achievements_body: Label = $"Margin/VBox/StatsScroll/Content/AchievementsPanel/AchievementsBox/AchievementsBody"
@onready var _back_button: Button = $"Margin/VBox/ButtonRow/BackButton"
@onready var _reset_button: Button = $"Margin/VBox/ButtonRow/ResetButton"
@onready var _restore_button: Button = $"Margin/VBox/ButtonRow/RestoreButton"
var _pending_action := ""
@onready var _confirm_panel: CanvasLayer = $"ConfirmPanel"
@onready var _guide_button: Button = $"Margin/VBox/ButtonRow/GuideButton"
@onready var _guide_overlay: Control = $"GuideOverlay"
@onready var _guide_list: Label = $"GuideOverlay/Panel/VBox/Scroll/GuideList"
@onready var _guide_close: Button = $"GuideOverlay/Panel/VBox/GuideClose"
@onready var _ledger_button: Button = $"Margin/VBox/ButtonRow/LedgerButton"
@onready var _ledger_legend: Label = $"LedgerOverlay/Panel/VBox/LedgerLegend"
@onready var _ledger_overlay: Control = $"LedgerOverlay"
@onready var _ledger_close: Button = $"LedgerOverlay/Panel/VBox/LedgerClose"
@onready var _registry_button: Button = $"Margin/VBox/ButtonRow/RegistryButton"
@onready var _registry_legend: Label = $"RegistryOverlay/Panel/VBox/RegistryLegend"
@onready var _registry_overlay: Control = $"RegistryOverlay"
@onready var _registry_close: Button = $"RegistryOverlay/Panel/VBox/RegistryClose"
@onready var _almanac_button: Button = $"Margin/VBox/ButtonRow/AlmanacButton"
@onready var _almanac_overlay: Control = $"AlmanacOverlay"
@onready var _almanac_close: Button = $"AlmanacOverlay/Panel/VBox/AlmanacClose"
@onready var _almanac_days: Array[Label] = [
	$"AlmanacOverlay/Panel/VBox/Day0",
	$"AlmanacOverlay/Panel/VBox/Day1",
	$"AlmanacOverlay/Panel/VBox/Day2",
	$"AlmanacOverlay/Panel/VBox/Day3",
	$"AlmanacOverlay/Panel/VBox/Day4",
	$"AlmanacOverlay/Panel/VBox/Day5",
	$"AlmanacOverlay/Panel/VBox/Day6",
]
@onready var _almanac_footer: Label = $"AlmanacOverlay/Panel/VBox/AlmanacFooter"


# ------------------------------------------------------------------------------
# Lifecycle
# ------------------------------------------------------------------------------

func _ready() -> void:
	_update_stats_display()
	_connect_signals()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# Escape closes the guide first, then leaves the stats page.
		if _guide_overlay and _guide_overlay.visible:
			_close_guide()
		elif _ledger_overlay and _ledger_overlay.visible:
			_close_ledger()
		elif _registry_overlay and _registry_overlay.visible:
			_close_registry()
		elif _almanac_overlay and _almanac_overlay.visible:
			_close_almanac()
		else:
			_on_back()


# ------------------------------------------------------------------------------
# Binding
# ------------------------------------------------------------------------------

func _connect_signals() -> void:
	if _back_button:
		_back_button.pressed.connect(_on_back)
	if _restore_button and _confirm_panel:
		_restore_button.pressed.connect(_on_restore_pressed)
		_refresh_restore_button()
	if _reset_button and _confirm_panel:
		_reset_button.pressed.connect(_on_reset_pressed)
		_confirm_panel.confirmed.connect(_on_reset_confirmed)
	if _guide_button:
		_guide_button.pressed.connect(_open_guide)
	if _guide_close:
		_guide_close.pressed.connect(_close_guide)
	if _ledger_button:
		_ledger_button.pressed.connect(_open_ledger)
		_refresh_ledger_button()
	if _ledger_close:
		_ledger_close.pressed.connect(_close_ledger)
	for i in LEDGER_BUTTONS.size():
		var button := _ledger_overlay.get_node_or_null("Panel/VBox/" + LEDGER_BUTTONS[i]) as Button
		if button:
			button.pressed.connect(_on_ledger_bottle.bind(LEDGER_IDS[i]))
	if _registry_button:
		_registry_button.pressed.connect(_open_registry)
		_refresh_registry_button()
	if _registry_close:
		_registry_close.pressed.connect(_close_registry)
	for i in REGISTRY_BUTTONS.size():
		var button := _registry_overlay.get_node_or_null("Panel/VBox/" + REGISTRY_BUTTONS[i]) as Button
		if button:
			button.pressed.connect(_on_registry_fish.bind(REGISTRY_IDS[i]))
	if _almanac_button:
		_almanac_button.pressed.connect(_open_almanac)
		_refresh_almanac_button()
	if _almanac_close:
		_almanac_close.pressed.connect(_close_almanac)


# ------------------------------------------------------------------------------
# Display & Formatting
# ------------------------------------------------------------------------------

func _update_stats_display() -> void:
	_journal_label.text = _build_journal_line()
	var saved := SaveManager.get_save_mtime()
	_saved_label.text = "Last saved: %s" % Time.get_datetime_string_from_unix_time(saved) if saved > 0 else "Last saved: unknown"

	_bench_body.text = "Upcycle score: %d  (best %d)\nBest sort streak: %d  ·  Flawless shifts: %d\nBench runs: %d" % [
		GameState.upcycle_score, GameState.best_upcycle_score,
		GameState.best_sort_streak, GameState.flawless_shifts,
		GameState.upcycle_runs,
	]

	_till_body.text = "Money: %d$  (lifetime %d$)\nMarket Contact: +%d$/unit\nQuests turned in: %d\nCircuits completed: %d  (+$%d each)" % [
		GameState.money, GameState.lifetime_earnings,
		GameState.get_market_bonus(),
		GameState.quests_completed,
		GameState.circuits_completed, GameState.CIRCUIT_BONUS_MONEY,
	]

	_reef_body.text = "Reef garbage: %d kg  (best depth %d m)\nFish bumps taken: %d  (best %d)\nBest combo: %d chain  (×%d)\nHeaviest dive: %d kg  ·  Clean dives: %d\nDives: %d" % [
		int(GameState.reef_garbage), int(GameState.best_reef_depth),
		GameState.reef_fish, GameState.best_reef_fish,
		GameState.best_reef_combo, 1 + int(GameState.best_reef_combo / 3),
		GameState.best_reef_haul, GameState.clean_dives,
		GameState.reef_dives,
	]

	var carried: Array[String] = []
	for mat: String in GameState.trash_by_type.keys():
		var count: int = int(GameState.trash_by_type[mat])
		if count > 0:
			carried.append("%s %d" % [mat, count])
	_bag_body.text = "Bag: %d/%d kg\nCarried: %s\nLifetime garbage: %d kg" % [
		GameState.get_inventory_weight(), GameState.get_inventory_capacity(),
		"nothing yet" if carried.is_empty() else ", ".join(carried),
		GameState.lifetime_garbage_kg,
	]

	var fish_names: Array[String] = []
	for id in GameState.fish_met:
		fish_names.append(FishCatalog.name_of(id))
	_collections_body.text = "Starfish found: %d / 5\nGolden scraps: %d\nFish spotted: %d / 5 species%s" % [
		GameState.starfish_found.size(),
		GameState.golden_finds,
		GameState.fish_met.size(),
		"  ·  " + ", ".join(fish_names) if not fish_names.is_empty() else "",
	]

	var deeds: Array[String] = ["Era: %s — %s" % [_era_name(), _era_tag()], "Field log: %d dives · %d bench runs" % [GameState.reef_dives, GameState.upcycle_runs]]
	_refresh_registry_button()
	_refresh_ledger_button()
	deeds.append("Deep Cache: %s" % ("tier %d" % GameState.deep_cache_tier if GameState.deep_cache else "not owned"))
	deeds.append("Days on the island: %d" % GameState.tide_days_visited)
	if GameState.tide_streak > 1:
		deeds.append("Tide streak: %d days running" % GameState.tide_streak)
	if GameState.tide_best_streak > 1:
		deeds.append("Best streak: %d days" % GameState.tide_best_streak)
	var all_days := SaveManager.total_tide_days()
	if all_days > GameState.tide_days_visited:
		deeds.append("All islands, one keeper: %d days" % all_days)
	# All six voices agree on one thing; the page says so, quietly.
	if GameState.is_achievement_unlocked("silent_chorus"):
		deeds.append("")
		deeds.append("Six voices, one shoreline — and every one of them said the tide is not a clock.")
		deeds.append("It is a heart, and it beats in four, and you learned the rhythm.")
	# Corl keeps his own ledger; the page notices regulars.
	if not SaveManager.last_recovery.is_empty():
		deeds.append("Recovered from the %s this session" % SaveManager.last_recovery)
	if GameState.is_achievement_unlocked("far_point"):
		deeds.append("The far point: seen.")
	if GameState.keeper_star_found:
		deeds.append("The keeper's star: found.")
	if GameState.courier_passes > 0:
		deeds.append("The courier passed by %d time%s" % [GameState.courier_passes, "" if GameState.courier_passes == 1 else "s"])
	if GameState.is_achievement_unlocked("whole_sea"):
		deeds.append("The whole sea: every note the tide ever sent, read.")
	if GameState.fifth_tide_granted:
		deeds.append("The fifth tide: seen.")
	if GameState.harbor_tips_bought > 0:
		if GameState.is_achievement_unlocked("whispers"):
			deeds.append("Corl's ledger: 7/7 whispers — you are known at the counter")
		else:
			deeds.append("Corl's ledger: %d/7 whispers" % GameState.harbor_tips_bought)
	deeds.append("Reef Charter: %d dive bumps" % (3 + GameState.get_reef_bonus_lives()))
	if GameState.is_harbor_hero():
		var bonus_kg: int = GameState.HARBOR_HERO_CAPACITY_BONUS * 10
		deeds.append("Title: Harbor Hero — every quest tier cleared (+%d kg bag)." % bonus_kg)
	if GameState.island_patron:
		deeds.append("✦ Patron of the Isle — 1500$ given back.")
	if GameState.tide_almanac_granted:
		deeds.append("✦ The Almanac Is Kept — four tides, one patient keeper.")
	if GameState.tidekeeper:
		deeds.append("✦ Tidekeeper of the Isle — 2500$ pact funded (+10 kg bag).")
	elif GameState.quests_completed > 0:
		deeds.append("Harbor Hero at %d turn-ins (%d/%d)" % [
			GameState.HARBOR_HERO_TURNS, GameState.quests_completed, GameState.HARBOR_HERO_TURNS,
		])
	_deeds_body.text = "\n".join(deeds)

	_almanac_body.text = _build_almanac_line().trim_prefix("Tide almanac ")
	# Completed almanac glows gold — the journal acknowledges the book.
	if _almanac_body:
		_almanac_body.modulate = Color(1.0, 0.84, 0.32, 1.0) if GameState.tides_logged.size() >= 4 else Color(1.0, 1.0, 1.0, 1.0)
	_refresh_almanac_button()


	var marks: Array[String] = []
	for def in GameState.achievement_definitions():
		var id := String(def.get("id", ""))
		var mark := "✓" if GameState.is_achievement_unlocked(id) else "·"
		marks.append("%s %s" % [mark, String(def.get("short", id))])
	_achievements_body.text = "%d of %d earned —  %s" % [
		GameState.achievement_count(), GameState.achievement_total(), "  ".join(marks),
	]


## One-line completion ledger across every collectathon on the island, so a
## checklist player sees the whole book at a glance. Not a stat — a compass.
func _build_journal_line() -> String:
	var bottles := GameState.bottles_read.size()
	var starfish := GameState.starfish_found.size()
	var fish := GameState.fish_met.size()
	var ach := GameState.achievement_count()
	var total := GameState.achievement_total()
	var paid_out := " · tide pool paid" if GameState.tide_pool_granted else ""
	var almanac := " · tide almanac paid" if GameState.tide_almanac_granted else ""
	var quiet := " · tide hidden" if GameSettings.hide_tide else ""
	var tides := GameState.tides_logged.size()
	return "Journal — bottles %d/8 · starfish %d/5%s · tides %d/4%s%s · species %d/5 · achievements %d/%d" % [bottles, starfish, paid_out, tides, almanac, quiet, fish, ach, total]


## The keeper's almanac as a checklist: every tide in rotation order with a
## tick for the days already logged, so a player can see what weather they are
## still owed. Reads TideReport's table directly — no duplicated titles.
func _build_almanac_line() -> String:
	var parts: Array[String] = []
	for condition in TideReport.CONDITIONS:
		var key := String(condition.get("key", ""))
		var mark := "✓" if GameState.tides_logged.has(key) else "·"
		parts.append("%s %s" % [mark, String(condition.get("title", key)).capitalize()])
	var suffix := ""
	if GameState.tide_streak > 1:
		suffix = "  ·  streak %d" % GameState.tide_streak
	return "Tide almanac %d/4%s — %s" % [GameState.tides_logged.size(), suffix, "  ".join(parts)]


## The scrap-journal reading of the page: which era of the island is the
## player in, most advanced first. Purely cosmetic — no numbers, just flavour
## earned by what the save has actually done.
func _era_name() -> String:
	if GameState.is_achievement_unlocked("island_steward"):
		if GameState.is_achievement_unlocked("quiet_keeper"):
			return "The Quiet Steward Era"
		return "The Steward Era"
	if GameState.is_achievement_unlocked("quiet_keeper"):
		return "The Quiet Era"
	if GameState.is_achievement_unlocked("silent_chorus"):
		return "The Chorus Era"
	if GameState.tidekeeper:
		return "The Pact Era"
	if GameState.market_level >= GameState.MARKET_MAX_LEVEL:
		return "The Trading Era"
	if GameState.circuits_completed >= 3:
		return "The Circuit Era"
	if GameState.reef_dives >= 10:
		return "The Diving Era"
	if GameState.upcycle_runs >= 10:
		return "The Bench Era"
	if GameState.lifetime_earnings > 0:
		return "The First-Coin Era"
	return "The Fresh Shore"


## One line of what the name means for the bench, the reef and the till.
func _era_tag() -> String:
	if GameState.is_achievement_unlocked("island_steward"):
		if GameState.is_achievement_unlocked("quiet_keeper"):
			return "the keeper is unwitnessed by the tide, and stays unwitnessed"
		return "every page of the journal is blank except yours"
	if GameState.is_achievement_unlocked("quiet_keeper"):
		return "the sea does not say where it is going; you follow anyway"
	if GameState.is_achievement_unlocked("silent_chorus"):
		return "six voices, one shoreline"
	if GameState.tidekeeper:
		return "the tide answers its keeper"
	if GameState.market_level >= GameState.MARKET_MAX_LEVEL:
		return "peak prices, peak dives"
	if GameState.circuits_completed >= 3:
		return "the loop runs itself when you do"
	if GameState.reef_dives >= 10:
		return "the waterline knows your wake"
	if GameState.upcycle_runs >= 10:
		return "the bench is a reflex now"
	if GameState.lifetime_earnings > 0:
		return "the till has its first song"
	return "every page still blank"


# ------------------------------------------------------------------------------
# Signal Handlers
# ------------------------------------------------------------------------------

## The compact roll in the stats text only shows short names; this page spells
## out what each one actually means.
func _open_guide() -> void:
	if _guide_overlay == null:
		return
	if _guide_list:
		_guide_list.text = _build_guide_text()
	_guide_overlay.visible = true
	AudioManager.play_sfx("pickup")


func _close_guide() -> void:
	if _guide_overlay == null:
		return
	_guide_overlay.visible = false
	AudioManager.play_sfx("return")


func _build_guide_text() -> String:
	var definitions := GameState.achievement_definitions()
	var lines: Array[String] = []
	
	# Grouped by where the goal is earned, so the page doubles as a route map
	# of the island. Unknown tags fall through to a trailing section.
	for group in GUIDE_GROUPS:
		var section: Array[String] = []
		for def in definitions:
			if String(def.get("where", "")) != group:
				continue
			var id := String(def.get("id", ""))
			var mark := "✓" if GameState.is_achievement_unlocked(id) else "·"
			section.append("%s  %s\n     %s" % [mark, String(def.get("title", "")), String(def.get("subtitle", ""))])
		if section.is_empty():
			continue
		lines.append("— %s —" % group.to_upper())
		lines.append_array(section)
		lines.append("")
	
	# The tide, spelled out for keepers who never read the harbour notice.
	lines.append("— THE TIDE —")
	lines.append("Glass Calm — more debris in the reef, fewer fish")
	lines.append("The almanac logs each tide you witness (n/4)")
	lines.append("Eel Run — reef fish dart about 28% faster")
	lines.append("Slack Water — the belt runs about 18% slower")
	lines.append("Night Drift — golden debris is twice as likely")
	lines.append("The rotation is four days. The HUD shows today's reading;")
	lines.append("for the price of a dockhand, tomorrow's too.")
	lines.append("")
	lines.append("%d of %d earned." % [GameState.achievement_count(), GameState.achievement_total()])
	return "\n".join(lines)


## The legend counts what remains behind the overlay.
func _refresh_ledger_legend() -> void:
	if not _ledger_legend:
		return
	var found := 0
	for id in LEDGER_IDS:
		if GameState.is_story_read(id):
			found += 1
	_ledger_legend.text = "every note the tide ever left you — %d/%d — tap to read again" % [found, LEDGER_IDS.size()]


## The ledger button advertises its own completion state — six slots, six
## stories, no need to open the page to know where you stand.
func _refresh_ledger_button() -> void:
	if not _ledger_button:
		return
	var found := 0
	for id in LEDGER_IDS:
		if GameState.is_story_read(id):
			found += 1
	_ledger_button.text = "Tide Ledger (%d/%d)" % [found, LEDGER_IDS.size()]
	if found >= LEDGER_IDS.size():
		_ledger_button.modulate = Color(1.0, 0.85, 0.42, 1.0)
	else:
		_ledger_button.modulate = Color(1.0, 1.0, 1.0, 1.0)


## The registry's legend carries its own count, like the ledger's — no need
## to open the page to know where the reef stands.
func _refresh_registry_legend() -> void:
	if not _registry_legend:
		return
	var found := 0
	for id in REGISTRY_IDS:
		if GameState.fish_met.has(id):
			found += 1
	_registry_legend.text = "every species you have bumped into — %d/%d — tap to read what you know" % [found, REGISTRY_IDS.size()]


## The registry button advertises its own completion — five slots, five
## notes; at five it turns gold like a finished chorus.
func _refresh_registry_button() -> void:
	if not _registry_button:
		return
	var found := 0
	for id in REGISTRY_IDS:
		if GameState.fish_met.has(id):
			found += 1
	_registry_button.text = "Reef Registry (%d/%d)" % [found, REGISTRY_IDS.size()]
	if found >= REGISTRY_IDS.size():
		_registry_button.modulate = Color(1.0, 0.85, 0.42, 1.0)
	else:
		_registry_button.modulate = Color(1.0, 1.0, 1.0, 1.0)


## Tide Ledger: re-read any bottle the player has already found. Undiscovered
## notes stay as locked rows so the page doubles as a collection tracker.
func _open_ledger() -> void:
	if _ledger_overlay == null:
		return
	_refresh_ledger_legend()
	for i in LEDGER_BUTTONS.size():
		var id := LEDGER_IDS[i]
		var button := _ledger_overlay.get_node_or_null("Panel/VBox/" + LEDGER_BUTTONS[i]) as Button
		if button == null:
			continue
		if GameState.is_story_read(id):
			button.text = "✓  " + BottleCatalog.title_of(id)
			button.disabled = false
		else:
			# A hint that spoils nothing — the page is a collection tracker.
			match id:
				"bottle_tide":
					button.text = "·  A shore note — it talks back"
				"bottle_gull":
					button.text = "·  A letter with three signings"
				"bottle_light":
					button.text = "·  Something glinting off the shop"
				"bottle_pact":
					button.text = "·  The tide keeps your name"
				"bottle_keeper":
					button.text = "·  The keeper before you"
				"bottle_corl":
					button.text = "·  A folded paper, cash up front"
				"bottle_watcher":
					button.text = "·  Something on the far point"
				"bottle_far_point":
					button.text = "·  The far point's own hand"
				_:
					button.text = "·  ? ? ?  —  still out there"
			button.disabled = true
	_ledger_overlay.visible = true
	AudioManager.play_sfx("pickup")


func _close_ledger() -> void:
	if _ledger_overlay == null:
		return
	_ledger_overlay.visible = false
	AudioManager.play_sfx("return")


func _on_ledger_bottle(id: String) -> void:
	if not GameState.is_story_read(id):
		return
	var dialogue := DIALOGUE_SCENE.instantiate()
	add_child(dialogue)
	dialogue.present(BottleCatalog.title_of(id), BottleCatalog.lines_of(id))
	AudioManager.play_sfx("pickup", 0.9)


## Reef Registry: the fish counterpart to the Tide Ledger. Locked rows mark
## species the player has not bumped into yet; found rows re-show the field
## note on tap.
func _open_registry() -> void:
	if _registry_overlay == null:
		return
	_refresh_registry_legend()
	for i in REGISTRY_BUTTONS.size():
		var id := REGISTRY_IDS[i]
		var button := _registry_overlay.get_node_or_null("Panel/VBox/" + REGISTRY_BUTTONS[i]) as Button
		if button == null:
			continue
		if GameState.fish_met.has(id):
			button.text = "✓  " + FishCatalog.name_of(id)
			button.disabled = false
		else:
			match id:
				"fish_gold":
					button.text = "·  Something sunlit in the reef"
				"fish_greyreefshark":
					button.text = "·  Something grayer and heavier"
				"fish_nemo":
					button.text = "·  Something small and orange"
				"fish_crab":
					button.text = "·  Something wearing somebody else's name"
				"fish_silverfin":
					button.text = "·  Something pale and quick on the tide"
				_:
					button.text = "·  ? ? ?  —  still out there"
			button.disabled = true
	_registry_overlay.visible = true
	AudioManager.play_sfx("pickup")


func _close_registry() -> void:
	if _registry_overlay == null:
		return
	_registry_overlay.visible = false
	AudioManager.play_sfx("return")


## THE FILLED ALMANAC — the almanac's own prize for its keeper. Hidden until
## all four tides are logged; once the book is filled the stats page offers
## the rotation itself, day by day, no dockhand required.
const ALMANAC_DAY_LABELS: Array[String] = ["Today", "Tomorrow", "In 2 days", "In 3 days", "In 4 days", "In 5 days", "In 6 days"]

func _refresh_almanac_button() -> void:
	if not _almanac_button:
		return
	_almanac_button.visible = GameState.tides_logged.size() >= 4


func _open_almanac() -> void:
	if _almanac_overlay == null:
		return
	if GameSettings.hide_tide:
		# The sea keeps its own counsel — even its keeper's. The card says so
		# and nothing else; the book stays shut while the quiet holds.
		for day_label in _almanac_days:
			day_label.text = ""
			day_label.visible = false
		_almanac_days[0].text = "≈ The sea keeps its own counsel — even for its keeper."
		_almanac_days[0].visible = true
		_almanac_days[0].modulate = Color(0.72, 0.8, 0.88, 1)
		_almanac_footer.text = "hide-the-tide holds: even the almanac's own writer goes unread."
		_almanac_overlay.visible = true
		AudioManager.play_sfx("pickup")
		return
	var today := TideReport.day_index()
	for i in _almanac_days.size():
		var condition := TideReport.for_day(today + i)
		var label: Label = _almanac_days[i]
		var title := TideReport.title_case(String(condition.get("title", "Still tide")))
		var summary := String(condition.get("summary", "A steady day"))
		label.text = "%s — %s · %s" % [ALMANAC_DAY_LABELS[i], title, _trim_tide_blurb(summary)]
		label.visible = true
		# Today keeps the sea-foam highlight; the rest reads quieter.
		label.modulate = Color(0.92, 0.97, 1, 1) if i == 0 else Color(0.72, 0.8, 0.88, 1)
	_almanac_footer.text = "the rotation is four days — every page here comes round on its own tide."
	_almanac_overlay.visible = true
	AudioManager.play_sfx("pickup")


## TideReport summaries arrive as "Glass calm — debris drifts loose"; the
## panel already prints the tide name, so keep only the tail half.
func _trim_tide_blurb(summary: String) -> String:
	var pieces := summary.split("—", false, 1)
	if pieces.size() == 2:
		return pieces[1].strip_edges()
	return summary


func _close_almanac() -> void:
	if _almanac_overlay == null:
		return
	_almanac_overlay.visible = false
	AudioManager.play_sfx("return")


func _on_registry_fish(id: String) -> void:
	if not GameState.fish_met.has(id):
		return
	var dialogue := DIALOGUE_SCENE.instantiate()
	add_child(dialogue)
	dialogue.present(FishCatalog.name_of(id), [FishCatalog.blurb_of(id)])
	AudioManager.play_sfx("pickup", 0.9)


## Reset island: wipe and start fresh, straight from the stats page. Reuses
## the shared ConfirmPanel so the copy matches the main menu's guard.
## The two destructive-ish actions share the confirm card; which one fires
## is gated on _pending_action.
func _on_restore_pressed() -> void:
	_pending_action = "restore"
	AudioManager.play_sfx("open")
	var s := SaveManager.backup_summary()
	var details := "Roll this island back to its previous save. The current state is kept as the second backup."
	if not s.is_empty():
		var m := int(s.get("mtime", 0))
		var when := Time.get_datetime_string_from_unix_time(m, false) if m > 0 else "unknown"
		details = "Backup: %d$  ·  score %d  ·  %d circuits  ·  %s
Roll this island back? The current state is kept as the second backup." % [int(s.get("money", 0)), int(s.get("score", 0)), int(s.get("circuits", 0)), when]
	_confirm_panel.present("Restore backup?", details, "Restore")


func _refresh_restore_button() -> void:
	if not _restore_button:
		return
	_restore_button.disabled = not SaveManager.has_backup()


func _on_reset_pressed() -> void:
	_pending_action = "reset"
	AudioManager.play_sfx("open")
	var island := GameState.slot_name if not GameState.slot_name.is_empty() else "this island"
	_confirm_panel.present("Reset %s?" % island, "The island resets — dive, sort, sale, quest and badge all gone. You will land back on the main menu with an empty shore and a clean book.", "Reset island")


func _on_reset_confirmed() -> void:
	if _pending_action == "restore":
		if not SaveManager.restore_backup():
			_pending_action = ""
			return
		GameState.restore()
		_refresh_restore_button()
		_update_stats_display()
		AudioManager.play_sfx("return")
		_pending_action = ""
		return
	_pending_action = ""
	_on_reset_confirmed_real()


func _on_reset_confirmed_real() -> void:
	AudioManager.play_sfx("return")
	SaveManager.new_save()
	GameState.restore()
	SceneTransition.change_scene(SCENE_MAIN_MENU)


func _on_back() -> void:
	AudioManager.play_sfx("return")
	var target := GameState.return_to_scene
	if target.is_empty() or not ResourceLoader.exists(target):
		target = SCENE_MAIN_MENU
	GameState.return_to_scene = ""
	SceneTransition.change_scene(target)
