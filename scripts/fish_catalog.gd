extends RefCounted
class_name FishCatalog

## Canonical journal entries for the four reef species. The stats page's
## "Fish spotted" line reads it so the journal shows names, not texture keys.
## Adding a species means one entry here and one FISH row in rr_fish.gd.

const ENTRIES: Array[Dictionary] = [
	{
		"id": "fish_gold",
		"name": "Goldie",
		"blurb": "A sunlit scrap of brass and scales. The reef sheds its coins; the keeper spends them.",
	},
	{
		"id": "fish_greyreefshark",
		"name": "Grey Reef Shark",
		"blurb": "The bump you feel through the hull. Broader than the shelf, older than the buoy.",
	},
	{
		"id": "fish_nemo",
		"name": "Nemo",
		"blurb": "Small, orange, faster than he looks. He knows the current by name; you'll notice by the third night.",
	},
	{
		"id": "fish_crab",
		"name": "Crab",
		"blurb": "Not a fish. The reef doesn't care. Neither, after a few dives, do you.",
	},
	{
		"id": "fish_silverfin",
		"name": "Silverfin",
		"blurb": "The strait's quiet courier — quick, pale, and gone by dawn. The counter sells its post by the page; the reef registry keeps its name. Nobody has ever kept up with it.",
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
