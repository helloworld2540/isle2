extends RefCounted
class_name FishCatalog

## Canonical journal entries for the six reef species. The stats page's
## "Fish spotted" line reads it so the journal shows names, not texture keys.
## Adding a species means one entry here and one FISH row in rr_fish.gd.

const ENTRIES: Array[Dictionary] = [
	{
		"id": "fish_gold",
		"name": "Goldie",
		"blurb": "A bright gold fish with brass-coloured scales. The reef's small reward for a careful dive.",
	},
	{
		"id": "fish_greyreefshark",
		"name": "Grey Reef Shark",
		"blurb": "The heavy bump you feel through the drone's hull. Big, wide, and older than the buoys.",
	},
	{
		"id": "fish_nemo",
		"name": "Nemo",
		"blurb": "Small, orange, and faster than he looks. You'll learn his route by your third dive.",
	},
	{
		"id": "fish_crab",
		"name": "Crab",
		"blurb": "Not a fish, but the reef counts it anyway — and so will you after a few dives.",
	},
	{
		"id": "fish_silverfin",
		"name": "Silverfin",
		"blurb": "The strait's pale courier: quick and gone by dawn. The shop sells its letters one page at a time, and the Reef Registry records its name. No one has ever caught up with it.",
	},
	{
		"id": "fish_star",
		"name": "Starfish",
		"blurb": "A five-armed starfish resting calmly on the reef floor. It doesn't flee the drone; the drone is the one that has to steer around it.",
	},
]


static func name_of(id: String) -> String:
	for entry in ENTRIES:
		if String(entry.get("id", "")) == id:
			return String(entry.get("name", id))
	return id


static func blurb_of(id: String) -> String:
	for entry in ENTRIES:
		if String(entry.get("id", "")) == id:
			return String(entry.get("blurb", ""))
	return ""
