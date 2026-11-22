extends SceneTree

## Regression harness for the courier's letters (scripts/courier_letters.gd).
## A page that ships dry never gets bought; keep the post honest.

const Letters := preload("res://scripts/courier_letters.gd")

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
	_print_header("Courier Letters Tests")

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

	_print_summary()
	quit(_fails)


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
