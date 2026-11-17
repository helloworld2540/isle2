extends RefCounted
class_name TideReport

## The island's daily sea conditions. A pure, deterministic table: every player
## (and every island) gets the same tide on the same calendar day, derived from
## the unix day number — no state to save, nothing to sync, no RNG to seed.
##
## Each condition nudges one minigame so the loop never plays identically two
## days running:
##   - garbage_bias        : added to the reef's fish threshold (> = fish), so a
##                           positive value means more debris and fewer fish.
##   - fish_speed_mult     : multiplies reef fish drift speed.
##   - belt_speed_mult     : multiplies the upcycle belt speed.
##   - golden_chance_mult  : multiplies both golden-item rolls (reef + belt).
##
## The banner announces the day's tide once per island per day; the world HUD
## keeps a one-line reminder for the whole session.

## Four-day rotation. Keys are stable (used by tests and the HUD accent), so
## reordering the array changes which day a condition lands on — not its rules.
const CONDITIONS: Array[Dictionary] = [
	{
		"key": "glass_calm",
		"title": "GLASS CALM",
		"summary": "Glass calm — debris drifts loose",
		"blurb": "The swell lies down and the reef lets go of its litter. More debris, fewer fish.",
		"garbage_bias": 0.16,
		"fish_speed_mult": 1.0,
		"belt_speed_mult": 1.0,
		"golden_chance_mult": 1.0,
	},
	{
		"key": "eel_run",
		"title": "EEL RUN",
		"summary": "Eel run — fish are quick today",
		"blurb": "A warm current pushes through the reef. The fish dart faster, so aim a little ahead.",
		"garbage_bias": -0.06,
		"fish_speed_mult": 1.28,
		"belt_speed_mult": 1.0,
		"golden_chance_mult": 1.0,
	},
	{
		"key": "slack_water",
		"title": "SLACK WATER",
		"summary": "Slack water — the belt turns slow",
		"blurb": "No tide to hurry the workshop. The belt runs slow and forgiving; line up your sorts.",
		"garbage_bias": 0.0,
		"fish_speed_mult": 1.0,
		"belt_speed_mult": 0.82,
		"golden_chance_mult": 1.0,
	},
	{
		"key": "night_drift",
		"title": "NIGHT DRIFT",
		"summary": "Night drift — gold glints in the water",
		"blurb": "Moonlight catches the shiny things. Golden debris and golden scrap are twice as common.",
		"garbage_bias": 0.0,
		"fish_speed_mult": 1.0,
		"belt_speed_mult": 1.0,
		"golden_chance_mult": 2.0,
	},
]

## Days since the unix epoch, in the player's local calendar. Using the local
## day (not UTC) means the tide flips at midnight where the player lives.
static func day_index() -> int:
	var unix := int(Time.get_unix_time_from_system())
	var offset := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	return int(floor(float(unix + offset) / 86400.0))


## The condition for a given day number. Deterministic and total: every day
## has a tide, wrapped across the rotation table.
static func for_day(day: int) -> Dictionary:
	var wrapped := posmod(day, CONDITIONS.size())
	return CONDITIONS[wrapped]


## Today's condition, the entry point every caller uses.
static func today() -> Dictionary:
	return for_day(day_index())


## Name of today's tide, e.g. "GLASS CALM".
static func title() -> String:
	return String(today().get("title", "STILL TIDE"))


## One-line HUD reminder, e.g. "Glass calm — debris drifts loose".
static func summary() -> String:
	return String(today().get("summary", "Still tide — a steady day"))


## The full sentence the banner card shows under the title.
static func blurb() -> String:
	return String(today().get("blurb", "The sea is quiet today."))


# --- Effect accessors -------------------------------------------------------
# Small typed helpers keep the minigames from poking raw dictionary keys, and
# give the tests one obvious surface to assert against.

## Added to the reef spawn threshold: >0 means more garbage, <0 means more fish.
static func garbage_bias() -> float:
	return float(today().get("garbage_bias", 0.0))


## Reef fish drift-speed multiplier.
static func fish_speed_multiplier() -> float:
	return float(today().get("fish_speed_mult", 1.0))


## Upcycle belt-speed multiplier.
static func belt_speed_multiplier() -> float:
	return float(today().get("belt_speed_mult", 1.0))


## Multiplier on the 10%/12% golden rolls in both minigames.
static func golden_chance_multiplier() -> float:
	return float(today().get("golden_chance_mult", 1.0))


## One-line observation an islander might mutter about the sea today. All tide-
## aware NPCs share the day's line, so the island reads as one place with one
## opinion of the weather rather than four unrelated scripts.
static func ambient_line() -> String:
	match String(today().get("key", "")):
		"glass_calm":
			return "Sea's like glass. You can spot a lost fork from the dock."
		"eel_run":
			return "Eel run today. The fish are thinking twice before the shallows."
		"slack_water":
			return "Slack water. Nothing pushes, nothing hurries."
		"night_drift":
			return "Moon's doing tricks with the glitter today. Keep your eyes low."
	return "Still tide. Good day for the old rhythms."
