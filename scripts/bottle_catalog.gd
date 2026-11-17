extends RefCounted
class_name BottleCatalog

## Canonical text for every "message in a bottle" on the island.
##
## Bottles are placed in scenes/world.tscn (position + id only); the words
## live here so two readers — the world pickup (wm_bottle.gd) and the Tide
## Ledger on the stats page — never drift apart. Adding a bottle means one
## entry here plus one node in the world scene.

const ENTRIES: Array[Dictionary] = [
	{
		"id": "bottle_tide",
		"title": "The Shorekeeper's Note",
		"lines": [
			"This note bobbed up beside the reef dock.",
			"The fish are already coming back — I counted six kinds today.",
			"Whatever you are carrying down there: bring it up gently.",
			"— Tom, shorekeeper",
		],
	},
	{
		"id": "bottle_gull",
		"title": "Nina's Third Letter",
		"lines": [
			"Mara, this is the third message I have sent you and I know you never read them.",
			"The glass tide gardens are beautiful from the air.",
			"The tide remembers a keeper who finds every note. Keep looking.",
			"— Nina",
		],
	},
	{
		"id": "bottle_light",
		"title": "Kai's Stock Tip",
		"lines": [
			"Kai — the shop sold out of everything again by noon.",
			"Stock the shelves and the island will stock itself.",
			"Also, I am told glass fetches best when it glitters. Noted.",
			"— Kai",
		],
	},
	{
		"id": "bottle_pact",
		"title": "The Tidekeeper's Reply",
		"lines": [
			"You were the one who paid to keep us here.",
			"Two thousand and five hundred dollars, and the reef never asked for it.",
			"The fish are counting on you, and I find that is a good thing.",
			"The tide keeps your name now. Walk proud, keeper.",
			"— The Tidekeeper",
		],
	},
	{
		"id": "bottle_keeper",
		"title": "The Keeper's Own Note",
		"lines": [
			"If you are reading this, you finished the almanac — four tides, four days, one patient pair of hands.",
			"I was the keeper before you. I never left, and the island never let me. That is the job: staying.",
			"The almanac is not a record of the sea. It is a record of you, learning to wait.",
			"Leave the last page blank when you go. The next keeper will need somewhere to write.",
			"— The Keeper",
		],
	},
]


static func find(id: String) -> Dictionary:
	for entry in ENTRIES:
		if String(entry.get("id", "")) == id:
			return entry
	return {}


static func title_of(id: String) -> String:
	return String(find(id).get("title", "A waterlogged note"))


static func lines_of(id: String) -> Array[String]:
	var raw: Array = find(id).get("lines", [])
	var lines: Array[String] = []
	for line in raw:
		lines.append(String(line))
	return lines
