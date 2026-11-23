extends RefCounted
class_name BottleCatalog

## Canonical text for every "message in a bottle" on the island.
##
## Bottles are placed in scenes/world.tscn (position + id only); the words
## live here so two readers — the world pickup (wm_bottle.gd) and the Tide
## Ledger on the stats page — never drift apart. Adding a bottle means one
## entry here plus one node in the world scene.
##
## Every bottle is a letter from the island itself, in that writer's voice:
## Tom at the shore, Nina at the till, Kai at the shelves, the Keeper at the
## almanac, the Watcher at the far point, the Far Point, and Corl behind the
## counter. No line here is an instruction to the keeper — it is the island
## thinking to itself about them.

const ENTRIES: Array[Dictionary] = [
	{
		"id": "bottle_tide",
		"title": "Tom — The Loop",
		"lines": [
			"You went round the isle and came back with the pattern.",
			"Dive, sort, sell — that is the whole loop, keeper, and we run it honest.",
			"Feed the right bin and the streak builds itself; wrong sorts just burn the fuel.",
			"The reef gave us the trash. We gave it back as a streak.",
			"— Tom, shorekeeper",
		],
	},
	{
		"id": "bottle_gull",
		"title": "Nina — The Tides",
		"lines": [
			"Mara, third note and you still have not answered me.",
			"The tides turn themselves — Glass Calm, Slack Water, Night Drift, Eel Run, each one remaking the sea.",
			"Buy tomorrow's tide from the dockhand, twenty-five or fifteen if you are a regular, before you read the bin.",
			"The hide-the-tide setting keeps tomorrow's tide hidden for the harder runs.",
			"— Nina",
		],
	},
	{
		"id": "bottle_light",
		"title": "Kai — The Market",
		"lines": [
			"Kai — the shelves sold out again by noon.",
			"Sell five or more in a single go and the bulk bonus kicks in. Sell All clears the bag in one trip.",
			"Market Contacts raise every unit's price by a dollar; the Patron and the Pact are one-time upgrades.",
			"A Reef Charter buys an extra fish a dive — take it before the big ones start showing up.",
			"— Kai",
		],
	},
	{
		"id": "bottle_pact",
		"title": "The Keeper — The Bag",
		"lines": [
			"You were the one who paid to keep us here.",
			"The Tidekeeper's Pact is twenty-five hundred, permanent: ten kilograms added to your bag for good.",
			"The bag was always the bottleneck. Buy the capacity before you chase the depth.",
			"The island remembers who paid for the pact. The bottle only washes up once it has.",
			"— The Tidekeeper",
		],
	},
	{
		"id": "bottle_keeper",
		"title": "The Keeper — The Almanac",
		"lines": [
			"If you are reading this, you finished the almanac — four tides over four days, with patience.",
			"The log is four tides. Log all four and the almanac writes back: the keeper's note, and THE WHOLE SEA.",
			"Read every bottle and the Silent Chorus joins in. Find all five starfish and you are STARLIGHT.",
			"Keep the shore and keep the ledger. The checklist lives on the stats page.",
			"— The Keeper",
		],
	},
	{
		"id": "bottle_watcher",
		"title": "The Watcher — The Page",
		"lines": [
			"You saw me. That was never supposed to happen — not here, not with a keeper who counts.",
			"The watcher only answers keepers who have read the whole sea. Until then the page stays dark.",
			"Meeting him marks the far point as seen, and then his bottle washes up.",
			"He never moves and never speaks again. Walk past the far point and find him.",
			"— the watcher",
		],
	},
	{
		"id": "bottle_far_point",
		"title": "The Far Point — The Star",
		"lines": [
			"You found the star. Of course you did — you always did.",
			"The Keeper's Star pays fifty dollars and only exists for an Island Steward. It is the epilogue.",
			"Walk the far eastern water to find it; it glints but never ticks like the others.",
			"— the far point, at last",
		],
	},
	{
		"id": "bottle_corl",
		"title": "Corl — The Counter",
		"lines": [
			"Seven mornings I sold you tomorrow. You never once asked my name. It is Corl. It was always Corl.",
			"Seven dockhand tips unlock the folded paper and THE WHISPERER. Fifteen a day, or fifteen if you are a regular.",
			"The seventh tip is free — my thanks for a week of patience.",
			"— Corl, dockhand. Counter, more or less.",
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
