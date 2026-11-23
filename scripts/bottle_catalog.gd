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
		"title": "Tip: The Loop",
		"lines": [
			"This note washed up on the reef dock.",
			"TIP: The loop is Reef Rescue → Upcycle → Shop. Dive, sort, sell, repeat.",
			"Reef Debris from a dive becomes materials at the bench — sort the right bin to build a streak.",
			"Wrong sorts and burned trash earn nothing, so check the color before you drop.",
			"— Tom, shorekeeper",
		],
	},
	{
		"id": "bottle_gull",
		"title": "Tip: The Tides",
		"lines": [
			"Mara, this is the third message I sent you and I know you never read them.",
			"TIP: Four tides rotate — Glass Calm, Slack Water, Night Drift, and Eel Run. Each one changes the sea and the prices.",
			"Buy tomorrow's tide from the dockhand (15-20$) to plan your next dive and belt.",
			"The 'Hide the tide' setting (Settings → Game) keeps tomorrow's tide hidden for harder runs.",
			"— Nina",
		],
	},
	{
		"id": "bottle_light",
		"title": "Tip: The Market",
		"lines": [
			"Kai — the shop sold out of everything again by noon.",
			"TIP: Sell 5+ at once for the bulk bonus. Sell All clears the bag in one trip.",
			"Market Contacts raise every unit's price by +1$; Island Patron and Tidekeeper's Pact are one-time upgrades.",
			"Reef Charter allows an extra fish catch per dive — buy it early if big fish are your problem.",
			"— Kai",
		],
	},
	{
		"id": "bottle_pact",
		"title": "Tip: The Bag",
		"lines": [
			"You were the one who paid to keep us here.",
			"TIP: The Tidekeeper's Pact costs 2500$ and permanently adds +10 kg to your bag capacity.",
			"Bag capacity is the real bottleneck — upgrade it before chasing depth.",
			"The island remembers who paid for the pact: the pact bottle only appears once it's paid.",
			"— The Tidekeeper",
		],
	},
	{
		"id": "bottle_keeper",
		"title": "Tip: The Almanac",
		"lines": [
			"If you are reading this, you finished the almanac — four tides over four days, with patience.",
			"TIP: Log all four tides (Tide Almanac) to unlock the keeper's note and the 'The Whole Sea' achievement.",
			"Reading every bottle unlocks the Silent Chorus; finding all 5 starfish earns Starlight Keeper.",
			"Keep the shore and keep the ledger — achievements are tracked on the Stats page.",
			"— The Keeper",
		],
	},
	{
		"id": "bottle_watcher",
		"title": "Tip: The Watcher",
		"lines": [
			"You saw me. That was never supposed to happen — not here, not with a keeper who counts.",
			"TIP: The watcher only appears once you've logged every tide (Whole Sea achievement).",
			"Meeting him once marks the far point as seen — the watcher's bottle washes up after.",
			"He never moves and never speaks again; walk past the far point to find him.",
			"— the watcher",
		],
	},
	{
		"id": "bottle_far_point",
		"title": "Tip: The Star",
		"lines": [
			"You found the star. Of course you did — you always did.",
			"TIP: The Keeper's Star (hidden at the far point) pays 50$ and only exists for Island Stewards.",
			"It is not counted toward the 5-star Starlight set — it's the epilogue.",
			"Walk the far eastern water to find it; it glints but never ticks like the others.",
			"— the far point, at last",
		],
	},
	{
		"id": "bottle_corl",
		"title": "Tip: The Counter",
		"lines": [
			"Seven mornings I sold you tomorrow. You never once asked my name. It's Corl. It was always Corl.",
			"TIP: Buy 7 dockhand tips to unlock Corl's folded paper and the Whisperer achievement.",
			"Each tip costs 15-20$ (15$ if you're a 3-day regular) and reveals tomorrow's tide.",
			"The 7th tip is free — Corl's thanks for a week of patience.",
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
