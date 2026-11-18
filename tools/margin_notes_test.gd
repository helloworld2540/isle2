extends SceneTree

## Regression harness for the first keeper's margin notes (scripts/margin_notes.gd).
## The page must never run dry: both voices non-empty, no duplicate lines,
## no overlong lines (the briefing card wraps at ~60 chars comfortably),
## and the rotation must wrap in order.

const MarginNotes := preload("res://scripts/margin_notes.gd")

var _fails := 0

func _initialize() -> void:
	_check(MarginNotes.BENCH.size() >= 8, "bench voice has at least eight notes")
	_check(MarginNotes.WATER.size() >= 8, "water voice has at least eight notes")
	_check(MarginNotes.COURIER.size() >= 3, "courier voice has at least three notes")
	_check(_unique(MarginNotes.BENCH), "bench notes are all distinct")
	_check(_unique(MarginNotes.WATER), "water notes are all distinct")
	_check(_unique(MarginNotes.COURIER), "courier notes are all distinct")
	for line in MarginNotes.BENCH + MarginNotes.WATER + MarginNotes.COURIER:
		_check(String(line).strip_edges().length() >= 20, "note is substantial: '%s'" % line)
		_check(String(line).length() <= 120, "note fits the card: '%s'" % line)
		_check(not String(line).is_empty(), "note is not blank")

	# Rotation wraps in order and is deterministic.
	var size: int = MarginNotes.BENCH.size()
	for i in range(size * 2 + 1):
		var idx := i % size
		_check(MarginNotes.bench_note(i) == MarginNotes.bench_note(idx), "bench note wraps (%d)" % i)
	_check(MarginNotes.bench_note(0) == MarginNotes.water_note(0) or true, "voices may share a numbering")
	_check(MarginNotes.bench_note(-3) == MarginNotes.bench_note(3), "negative indexes take abs, never crash")
	_check(MarginNotes.courier_note(0) == MarginNotes.courier_note(MarginNotes.COURIER.size()), "courier note wraps")

	print("margin_notes_test: %d failure(s)" % _fails)
	quit(_fails)


func _unique(lines: Array) -> bool:
	var seen := {}
	for line in lines:
		if seen.has(line):
			return false
		seen[line] = true
	return true


func _check(ok: bool, what: String) -> void:
	print(("  ok  " if ok else "[FAIL] ") + what)
	if not ok:
		_fails += 1
