extends RefCounted
class_name SaveSlot

## One player-owned save slot. The save FILE holds the island; this module
## only answers "what would a human-readable summary of this save look like",
## so the main menu, the slot picker and the stats page all read one
## implementation instead of each formatting the same fields differently.
##
## A slot is self-describing: every file carries its own `slot_name` and
## `slot_id`, so `list_slots()` can build the picker by scanning the directory
## without opening more than the header of each file.

const SLOT_NAME_KEY := "slot_name"
const SLOT_ID_KEY := "slot_id"
const SLOT_CREATED_KEY := "slot_created"
const SLOT_MODIFIED_KEY := "slot_modified"

## Slug a display name into a safe, collision-free file id.
## "My Island 2!" -> "my-island-2"; on collision, "-2", "-3"…
static func slugify(name: String) -> String:
	var s := name.to_lower().strip_edges()
	var out := ""
	for i in s.length():
		var c := s[i]
		if (c >= "a" and c <= "z") or (c >= "0" and c <= "9"):
			out += c
		elif not out.is_empty() and not out.ends_with("-"):
			out += "-"
	out = out.trim_suffix("-")
	if out.is_empty():
		out = "island"
	return out


## Next available id for a base slug, by scanning the existing slot files.
static func unique_slug(base: String, existing: Array) -> String:
	var candidate := base
	var n := 2
	while _slug_taken(candidate, existing):
		candidate = "%s-%d" % [base, n]
		n += 1
	return candidate


static func _slug_taken(slug: String, existing: Array) -> bool:
	for e in existing:
		if String(e.get("id", "")) == slug:
			return true
	return false


## Compact summary for a slot-picker row. Reads only the fields the menu needs;
## the full restore lives in GameState.
static func summary(data: Dictionary) -> Dictionary:
	var money := int(data.get("money", 0))
	var score := int(data.get("upcycle_score", 0))
	var circuits := int(data.get("circuits_completed", 0))
	var dives := int(data.get("reef_dives", 0))
	var runs := int(data.get("upcycle_runs", 0))
	var starfish := int(data.get("starfish_found", []).size()) if data.get("starfish_found") is Array else 0
	var ach := int(data.get("achievements", []).size()) if data.get("achievements") is Array else 0
	var days := int(data.get("tide_days_visited", 0))
	var fish_met: Array = data.get("fish_met", []) if data.get("fish_met") is Array else []
	var achievements: Array = data.get("achievements", []) if data.get("achievements") is Array else []
	# The island's two quiet signatures, for the row glyphs.
	var courier := fish_met.has("fish_silverfin")
	var whole_sea := achievements.has("whole_sea")
	var last_run: Dictionary = data.get("last_run", {})
	var last_title := String(last_run.get("title", "")) if last_run is Dictionary else ""
	return {
		"money": money,
		"score": score,
		"circuits": circuits,
		"dives": dives,
		"runs": runs,
		"starfish": starfish,
		"achievements": ach,
		"days": days,
		"courier": courier,
		"whole_sea": whole_sea,
		"last_run_title": last_title,
	}


## One-line preview for the main menu's active-slot label.
static func one_liner(data: Dictionary) -> String:
	var s := summary(data)
	var bits: Array[String] = []
	bits.append("%d$" % s["money"])
	bits.append("score %d" % s["score"])
	if s["days"] > 0:
		bits.append("day %d" % s["days"])
	if s["circuits"] > 0:
		bits.append("%d circuits" % s["circuits"])
	if s["starfish"] > 0:
		bits.append("★%d" % s["starfish"])
	if s["courier"]:
		bits.append("✳")
	if s["whole_sea"]:
		bits.append("✦")
	if s["last_run_title"] != "":
		bits.append("\"%s\"" % s["last_run_title"])
	return "  ·  ".join(bits) if not bits.is_empty() else "a fresh shore"


## Human timestamp for a slot row.
static func age_label(unix: int) -> String:
	if unix <= 0:
		return "never played"
	var now := Time.get_unix_time_from_system()
	var diff := now - unix
	if diff < 60:
		return "just now"
	if diff < 3600:
		return "%d min ago" % [int(diff / 60)]
	if diff < 86400:
		return "%d h ago" % [int(diff / 3600)]
	if diff < 604800:
		return "%d d ago" % [int(diff / 86400)]
	return Time.get_datetime_string_from_unix_time(unix, false)