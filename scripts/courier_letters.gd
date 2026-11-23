extends RefCounted
class_name CourierLetters

## The courier's letters — short, rare notes from the Silverfin itself, left
## at the counter on the far side of the till. One per tide day, $10 a page,
## never the same page twice in a row.
##
## The letters carry no mechanics and no tide advice — the dockhand sells
## tomorrow for that. These are the courier's own post: slow, dry, and
## occasionally about the bench.

const LETTERS: Array[String] = [
	"Counted the tides habitually, in case someone was waiting for a reply.",
	"I don't stop for bumps. If you stop me, I'll know exactly who did it.",
	"The upcycle bench smells like patience when it's done right.",
	"A jellyfish drifted by at dawn pretending it had somewhere to be. Relatable.",
	"The reef keeps a tidy ledger. You would too, if you lived here.",
	"I swam the strait at slack water. It was the calmest water I've swum.",
	"If the tide report sounded certain, it was because the almanac is certain.",
	"The sun through the bottles in the tide pool is underrated. Tell the dockhand I said so.",
	"This letter may never reach you. That is between the current and me.",
	"I rest in the eel grass on Glass Calm days. Don't tell the tide I said that.",
	"Glass Calm is when the rubbish comes to the surface; Eel Run is when the reef gets busy.",
	"News for the keeper at the bench: a sorting streak is more than a number — it's a rhythm.",
	"I was asked to deliver a message of some importance once. It was a receipt.",
	"The first keeper fed me through the glass. I remember the hand — not that one, a different one.",
]


## Pick a letter by index. The counter hands them out in the order the sea
## wrote them; it wraps when the courier runs out of post.
static func letter_at(index: int) -> String:
	return LETTERS[absi(index) % LETTERS.size()]


static func count() -> int:
	return LETTERS.size()
