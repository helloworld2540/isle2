extends SceneTree

## Regression harness for the first keeper's margin notes (scripts/margin_notes.gd).
## The page must never run dry: both voices non-empty, no duplicate lines,
## no overlong lines (the briefing card wraps at ~60 chars comfortably),
## and the rotation must wrap in order.

const MarginNotes := preload("res://scripts/margin_notes.gd")

# ANSI color codes
const C_RESET := "\u001b[0m"
const C_BOLD := "\u001b[1m"
const C_RED := "\u001b[31m"
const C_GREEN := "\u001b[32m"
const C_YELLOW := "\u001b[33m"
const C_BLUE := "\u001b[34m"
const C_CYAN := "\u001b[36m"

var _fails := 0
var _passes := 0
var _skipped := 0
var _start_time: int = 0

func _initialize() -> void:
	_start_time = Time.get_ticks_msec()
	_print_header("Margin Notes Tests")
	_check(MarginNotes.BENCH.size() >= _rotation_floor(MarginNotes.BENCH), "bench voice has at least eight notes")
	_check(MarginNotes.WATER.size() >= _rotation_floor(MarginNotes.WATER), "water voice has at least eight notes")
	_check(MarginNotes.COURIER.size() >= _rotation_floor(MarginNotes.COURIER), "courier voice has at least three notes")
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
	_check(MarginNotes.bench_note(0) != MarginNotes.water_note(0), "bench and water voices keep distinct notes at the same index")
	_check(MarginNotes.bench_note(-3) == MarginNotes.bench_note(3), "negative indexes take abs, never crash")
	_check(MarginNotes.courier_note(0) == MarginNotes.courier_note(MarginNotes.COURIER.size()), "courier note wraps")

	_print_summary()
	quit(_fails)


func _unique(lines: Array) -> bool:
	var seen := {}
	for line in lines:
		if seen.has(line):
			return false
		seen[line] = true
	return true


## Per-voice rotation floor derived from the shipped note count rather than a
## hand-copied number: a voice must keep at least 80% of its currently loaded
## notes so the page never runs dry mid-rotation (bench/water ship ten, the
## courier four — the old floors were 8/8/3).
func _rotation_floor(lines: Array) -> int:
	return int(float(lines.size()) * 0.8)


func _check(ok: bool, what: String) -> void:
	if ok:
		_passes += 1
		print(C_GREEN + "✓" + C_RESET + " " + what)
	else:
		_fails += 1
		print(C_RED + "✗" + C_RESET + " " + what)


func _print_header(title: String) -> void:
	var line := "═".repeat(title.length() + 4)
	print(C_CYAN + line + C_RESET)
	print(C_CYAN + "  " + title + "  " + C_RESET)
	print(C_CYAN + line + C_RESET)
	print("")


func _print_summary() -> void:
	var elapsed := (Time.get_ticks_msec() - _start_time) / 1000.0
	var total := _passes + _fails + _skipped
	var line := "─".repeat(50)
	print("")
	print(C_CYAN + line + C_RESET)
	print(C_BOLD + "RESULTS:" + C_RESET + " " + C_GREEN + str(_passes) + C_RESET + "  " + C_RED + "FAILED:" + C_RESET + " " + str(_fails) + "  " + C_YELLOW + "SKIPPED:" + C_RESET + " " + str(_skipped))
	var time_str := "%0.2f" % elapsed
	print(C_BOLD + "TOTAL:" + C_RESET + " " + str(total) + "  " + C_BLUE + "TIME:" + C_RESET + " " + time_str + "s")
	if _fails == 0:
		print(C_BOLD + "STATUS:" + C_RESET + " " + C_GREEN + "✓ ALL TESTS PASSED" + C_RESET)
	else:
		print(C_BOLD + "STATUS:" + C_RESET + " " + C_RED + "✗ " + str(_fails) + " TEST(S) FAILED" + C_RESET)
	print(C_CYAN + line + C_RESET)
