extends SceneTree

## Regression harness for the courier's letters (scripts/courier_letters.gd).
## A page that ships dry never gets bought; keep the post honest.

const Letters := preload("res://scripts/courier_letters.gd")

var _fails := 0

func _initialize() -> void:
	_check(Letters.LETTERS.size() >= 12, "at least twelve pages on the counter")

	var seen: Dictionary = {}
	for line in Letters.LETTERS:
		var text := String(line)
		_check(text.length() >= 25, "page is substantial: '%s'" % text)
		_check(text.length() <= 140, "page fits the card: '%s'" % text)
		_check(not seen.has(text), "no two pages are identical")
		seen[text] = true

	# Wrap-around: the counter never runs dry, never repeats in order.
	var size: int = Letters.LETTERS.size()
	_check(Letters.letter_at(0) == Letters.letter_at(size), "rotation wraps")
	_check(Letters.letter_at(1) == Letters.letter_at(size + 1), "rotation wraps with offset")
	_check(Letters.letter_at(-1) == Letters.letter_at(1), "negative indexes use abs, never crash")

	print("courier_letters_test: %d failure(s)" % _fails)
	quit(_fails)


func _check(ok: bool, what: String) -> void:
	print(("  ok  " if ok else "[FAIL] ") + what)
	if not ok:
		_fails += 1
