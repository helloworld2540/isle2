extends RefCounted
class_name MarginNotes

## The first keeper's margin notes — one quiet line per shift or dive,
## rotated by how many the keeper has logged. Pure flavour: no mechanics,
## no saves, just handwriting in the corner of the briefing card.
##
## Two voices share the page: the bench (upcycle) and the water (reef).
## Kept in one file so both minigames draw from the same hand.

const BENCH: Array[String] = [
	"Sort it twice, sort it right. The reef keeps what we miss.",
	"The fire only eats what we feed it. Mind what you feed it.",
	"Glass glitters. Nylon stretches. Polyethylene lies.",
	"A clean shift is a quiet bench. Aim for quiet.",
	"Someone before you stood here with the same blisters.",
	"The island does not need you fast. It needs you thorough.",
	"Every bottle you shelve teaches the sea you are listening.",
	"Leave the bench better than you found it. It always remembers.",
	"The courier crossed my window once. I wrote it on the wall.",
	"The courier has never once surprised a bin. Rare trait, out there.",
]

const WATER: Array[String] = [
	"Go down slow. The reef forgives patience before anything else.",
	"The fish were here before the trash. Mind which is which.",
	"A haul is not a victory. A clean dive is.",
	"Deep water keeps its own counsel. Take only what it offers.",
	"The current lies about distance. Your lungs do not.",
	"Come up with less than you brought down. That is the whole job.",
	"The reef is not a warehouse. It is a neighbour.",
	"Surface slow. Let the sea decide what you keep.",
	"If something pale crosses ahead of you, do not chase it. It arrives for its own reasons.",
	"The courier never bumps into anything. Learn from the courier.",
]


## On Eel Run — the courier's own day — the first keeper's hand turns to the
## one thing it always watched for. Same page, different tide.
const COURIER: Array[String] = [
	"The courier runs with the eel today. Do not chase it — log it.",
	"Fast water, pale fin. Today the strait shows off; let it.",
	"On a day like this the courier makes the crossing twice. I never learned how.",
	"Eel Run. If you see the silver, the day has already paid you.",
]


## Pick a note by run/dive count so the page turns in order, then wraps.
static func bench_note(runs: int) -> String:
	return BENCH[absi(runs) % BENCH.size()]


static func water_note(dives: int) -> String:
	return WATER[absi(dives) % WATER.size()]


## The courier's-day margin note (Eel Run), rotated by the same count.
static func courier_note(count: int) -> String:
	return COURIER[absi(count) % COURIER.size()]
