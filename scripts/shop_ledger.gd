extends RefCounted

## Pure sale pricing for the shop. Keeps every sale path (Sell 1, Sell 5,
## Sell All, undo bookkeeping) reading the same bulk rule and the same
## market-bonus math, so the preview line and the payout can never drift.
##
## GameState owns stock and money; this only computes and applies.

const BULK_THRESHOLD := 5
const BULK_MULTIPLIER := 1.25
## Extra bulk multiplier on Glass Calm days: the reef lets go of its litter,
## supply floods the market and the harbor pays over the odds for a full load.
const GLASS_CALM_BULK_BONUS := 0.10


## Bulk multiplier for the sales happening today. Reads the deterministic
## tide rather than rolling anything, so preview and payout always agree.
static func bulk_multiplier() -> float:
	if TideReport.today_key() == "glass_calm":
		return BULK_MULTIPLIER + GLASS_CALM_BULK_BONUS
	return BULK_MULTIPLIER


## Display string for the bulk bump, e.g. "+25%" (or "+35%" on Glass Calm).
static func bulk_label() -> String:
	return "+%d%%" % int(round((bulk_multiplier() - 1.0) * 100.0))


## How many units a sale would move and what it would pay. Returns {} when
## there is nothing to sell. `qty` is what the button asked for; the answer is
## clamped to the stock on hand.
static func quote(mat: String, qty: int) -> Dictionary:
	var available := int(GameState.trash_by_type.get(mat, 0))
	if available <= 0 or qty <= 0:
		return {}
	var units: int = min(qty, available)
	var price := int(GameState.SALE_PRICES.get(mat, 0))
	var bulk: bool = units >= BULK_THRESHOLD
	var multiplier: float = bulk_multiplier() if bulk else 1.0
	var earnings := int(round(float(units) * float(price) * multiplier)) + units * GameState.get_market_bonus()
	return {
		"material": mat,
		"units": units,
		"price": price,
		"bulk": bulk,
		"multiplier": multiplier,
		"earnings": earnings,
	}


## Applies the sale and returns the same dictionary, or {} if it could not
## be done. Caller owns feedback, receipts and persistence.
static func apply(mat: String, qty: int) -> Dictionary:
	var fitted := quote(mat, qty)
	if fitted.is_empty():
		return {}
	GameState.consume_trash_type(mat, int(fitted.get("units", 0)))
	GameState.add_earnings(int(fitted.get("earnings", 0)))
	return fitted