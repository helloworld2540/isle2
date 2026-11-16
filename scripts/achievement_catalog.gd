extends RefCounted

## Pure data and unlock predicates for the island's one-time achievements.
## GameState owns the save, the pending-card queue and the signal; this module
## only answers "what exists" and "is it earned given that state", so menus and
## banners can read the catalogue without touching the save system.
##
## Conditions are deliberately plain field reads on the state object passed in
## (GameState or a test double), which keeps this file free of autoload calls.

const ENTRIES: Array[Dictionary] = [
	{
		"id": "first_dive",
		"short": "Dive",
		"title": "FIRST DIVE",
		"subtitle": "Reef Rescue cleared — the loop has started.",
		"where": "Reef Rescue",
	},
	{
		"id": "first_sort",
		"short": "Sort",
		"title": "FIRST SORT",
		"subtitle": "Sorted a load at the Upcycle bench.",
		"where": "Upcycle",
	},
	{
		"id": "bench_regular",
		"short": "Bench",
		"title": "BENCH REGULAR",
		"subtitle": "Finished 10 runs at the Upcycle bench.",
		"where": "Upcycle",
	},
	{
		"id": "benchmark",
		"short": "Bench+",
		"title": "BENCH MASTER",
		"subtitle": "Finished 25 runs at the Upcycle bench.",
		"where": "Upcycle",
	},
	{
		"id": "first_sale",
		"short": "Sale",
		"title": "FIRST SALE",
		"subtitle": "Turned material into money at the Shop.",
		"where": "Shop",
	},
	{
		"id": "first_quest",
		"short": "Favour",
		"title": "FIRST FAVOUR",
		"subtitle": "An islander's request is done.",
		"where": "Islanders",
	},
	{
		"id": "harbor_hero",
		"short": "Harbor",
		"title": "HARBOR HERO",
		"subtitle": "Every quest tier cleared — bag capacity +10 kg!",
		"where": "Islanders",
	},
	{
		"id": "big_bag",
		"short": "Bag",
		"title": "ROOM TO SPARE",
		"subtitle": "Bag capacity reached 30 kg.",
		"where": "Island",
	},
	{
		"id": "deep_cache",
		"short": "Cache",
		"title": "CACHE FOUND",
		"subtitle": "Bought the Deep Cache for richer hauls.",
		"where": "Island",
	},
	{
		"id": "well_off",
		"short": "Money",
		"title": "WELL OFF",
		"subtitle": "Earned 300$ on the island.",
		"where": "Shop",
	},
	{
		"id": "market_contact",
		"short": "Market",
		"title": "MARKET CONTACT",
		"subtitle": "Bought a Market Contact — sales pay +1$ per unit.",
		"where": "Shop",
	},
	{
		"id": "reef_charter",
		"short": "Charter",
		"title": "REEF CHARTER",
		"subtitle": "Chartered an extra fish bump for Reef Rescue.",
		"where": "Shop",
	},
	{
		"id": "reef_deep",
		"short": "Depth",
		"title": "DEEP DIVE",
		"subtitle": "Reached 400 m in Reef Rescue.",
		"where": "Reef Rescue",
	},
	{
		"id": "reef_abyss",
		"short": "Abyss",
		"title": "TO THE ABYSS",
		"subtitle": "Reached 900 m in Reef Rescue.",
		"where": "Reef Rescue",
	},
	{
		"id": "reef_regular",
		"short": "Dives",
		"title": "REEF REGULAR",
		"subtitle": "Completed 10 dives at Reef Rescue.",
		"where": "Reef Rescue",
	},
	{
		"id": "reef_veteran",
		"short": "Dives+",
		"title": "REEF VETERAN",
		"subtitle": "Completed 25 dives at Reef Rescue.",
		"where": "Reef Rescue",
	},
	{
		"id": "hot_streak",
		"short": "Streak",
		"title": "HOT STREAK",
		"subtitle": "Sorted 15 items in a row without a miss.",
		"where": "Upcycle",
	},
	{
		"id": "reef_registry",
		"short": "Registry",
		"title": "REEF REGISTRY",
		"subtitle": "Bumped into all four fish species.",
		"where": "Reef Rescue",
	},
	{
		"id": "clean_sweep",
		"short": "Sweep",
		"title": "CLEAN SWEEP",
		"subtitle": "Five dives without a single fish bump.",
		"where": "Reef Rescue",
	},
	{
		"id": "silk_touch",
		"short": "Silk",
		"title": "SILK TOUCH",
		"subtitle": "Five bench shifts without a single miss.",
		"where": "Upcycle",
	},
	{
		"id": "heavy_haul",
		"short": "Haul",
		"title": "HEAVY HARVEST",
		"subtitle": "Banked 30 kg of debris in a single dive.",
		"where": "Reef Rescue",
	},
	{
		"id": "reef_rhythm",
		"short": "Rhythm",
		"title": "RHYTHM OF THE REEF",
		"subtitle": "Chained 9 pickups in a single dive — a ×4 combo.",
		"where": "Reef Rescue",
	},
	{
		"id": "loop_master",
		"short": "Loop",
		"title": "LOOP MASTER",
		"subtitle": "Closed 25 island circuits.",
		"where": "Island",
	},
	{
		"id": "tide_keeper",
		"short": "Pact",
		"title": "KEEPER OF THE TIDE",
		"subtitle": "Funded the Tidekeeper's Pact — the reef keeps your bag.",
		"where": "Shop",
	},
	{
		"id": "pact_reply",
		"short": "Reply",
		"title": "THE PACT'S REPLY",
		"subtitle": "Read the tide's answer at the shore.",
		"where": "Island",
	},
	{
		"id": "island_patron",
		"short": "Patron",
		"title": "PATRON OF THE ISLE",
		"subtitle": "Gave 1500$ to keep the island clean.",
		"where": "Shop",
	},
	{
		"id": "tide_messages",
		"short": "Tides",
		"title": "TIDE KEEPER",
		"subtitle": "Found every message the tide left on the island.",
		"where": "Island",
	},
	{
		"id": "island_steward",
		"short": "Steward",
		"title": "ISLAND STEWARD",
		"subtitle": "Every other achievement earned. The island is yours.",
		"where": "Island",
	},
]


static func definitions() -> Array[Dictionary]:
	return ENTRIES


static func total() -> int:
	return ENTRIES.size()


static func find(id: String) -> Dictionary:
	for def in ENTRIES:
		if String(def.get("id", "")) == id:
			return def
	return {}


## True when `id` is satisfied by the fields currently on `state`.
## Kept as a predicate chain rather than data expressions so each unlock can
## read several fields and the capstone can look at the whole catalogue.
static func is_met(id: String, state: Node) -> bool:
	if state == null:
		return false
	
	match id:
		"first_dive":
			return state.best_reef_depth > 0 or state.reef_garbage > 0.0
		"first_sort":
			return state.best_upcycle_score > 0
		"bench_regular":
			return state.upcycle_runs >= 10
		"benchmark":
			return state.upcycle_runs >= 25
		"first_sale":
			return state.lifetime_earnings > 0
		"first_quest":
			return state.quests_completed > 0
		"harbor_hero":
			return state.harbor_hero_granted
		"big_bag":
			return state.get_inventory_capacity() >= 30
		"deep_cache":
			return state.deep_cache
		"well_off":
			return state.lifetime_earnings >= 300
		"market_contact":
			return state.market_level > 0
		"reef_charter":
			return state.reef_bonus_lives > 0
		"reef_deep":
			return state.best_reef_depth >= 400
		"reef_abyss":
			return state.best_reef_depth >= 900
		"island_patron":
			return state.island_patron
		"hot_streak":
			return state.best_sort_streak >= 15
		"reef_registry":
			return state.fish_met.size() >= 4
		"clean_sweep":
			return state.clean_dives >= 5
		"silk_touch":
			return state.flawless_shifts >= 5
		"heavy_haul":
			return state.best_reef_haul >= 30
		"reef_rhythm":
			return state.best_reef_combo >= 9
		"reef_regular":
			return state.reef_dives >= 10
		"reef_veteran":
			return state.reef_dives >= 25
		"loop_master":
			return state.circuits_completed >= 25
		"tide_keeper":
			return state.tidekeeper
		"pact_reply":
			return state.bottles_read.has("bottle_pact")
		"tide_messages":
			return state.bottles_read.size() >= 3
		"island_steward":
			# Capstone: every other goal in the catalogue is already earned.
			for def in ENTRIES:
				var other := String(def.get("id", ""))
				if other != "island_steward" and not state.unlocked_achievements.has(other):
					return false
			return true
	return false