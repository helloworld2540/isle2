extends Node
class_name ShopTrader

# Minimal in-game shop/trader scaffold. Converts material counts to shell coins at
# tunable rates. Intended to be wired into a future shop scene/UI.

const RATES := {
	"Polyethylene": 2,
	"Polypropylene": 3,
	"Glass": 5,
	"Nylon": 4,
}

func get_price(t: String) -> int:
	return int(RATES.get(t, 0))

func sell(t: String, amount: int) -> int:
	if amount <= 0:
		return 0
	var available := int(GameState.trash_by_type.get(t, 0))
	var sellable := min(available, amount)
	if sellable <= 0:
		return 0
	GameState.consume_trash_type(t, sellable)
	var earnings := sellable * get_price(t)
	GameState.upcycle_score += earnings
	GameState._persist()
	return earnings
