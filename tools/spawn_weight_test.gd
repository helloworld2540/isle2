extends SceneTree

## Regression harness for the reef's weighted spawn table (scripts/rr_fish.gd).
## Asserts the Silverfin is rare on ordinary days, rides the fast water on
## Eel Run, and that every roll lands on a known species. Pure static calls —
## no save data, no scenes, no slots.

const Fish := preload("res://scripts/rr_fish.gd")

const KNOWN := {
	"fish_gold.png": true,
	"fish_greyreefshark.png": true,
	"fish_nemo.png": true,
	"fish_crab.png": true,
	"fish_silverfin.png": true,
}

const ROLLS := 20000

var _fails := 0

func _initialize() -> void:
	_check(Fish.SPAWN_WEIGHTS.size() == Fish.FISH.size(), "spawn table covers every fish in the size table")
	var unknown := false
	for key in Fish.SPAWN_WEIGHTS:
		if not KNOWN.has(key):
			unknown = true
	_check(not unknown, "spawn table holds only known species")

	var plain := _shares("")
	var eel := _shares("eel_run")
	var calm := _shares("glass_calm")
	var slack := _shares("slack_water")
	var drift := _shares("night_drift")

	print("  plain silverfin share: %.3f" % plain["fish_silverfin.png"])
	print("  calm  silverfin share: %.3f" % calm["fish_silverfin.png"])
	print("  eel   silverfin share: %.3f" % eel["fish_silverfin.png"])

	# Ordinary days: silverfin is a rare sighting (~10/102 ≈ 0.10).
	_check(plain["fish_silverfin.png"] > 0.05 and plain["fish_silverfin.png"] < 0.15, "silverfin rare on ordinary days")
	_check(calm["fish_silverfin.png"] > 0.05 and calm["fish_silverfin.png"] < 0.15, "silverfin rare on Glass Calm")
	_check(slack["fish_silverfin.png"] > 0.05 and slack["fish_silverfin.png"] < 0.15, "silverfin rare on Slack Water")
	_check(drift["fish_silverfin.png"] > 0.05 and drift["fish_silverfin.png"] < 0.15, "silverfin rare on Night Drift")
	# Eel Run: the courier rides the fast water (~20/112 ≈ 0.18).
	_check(eel["fish_silverfin.png"] > 0.13 and eel["fish_silverfin.png"] < 0.26, "silverfin boosted on Eel Run")
	_check(eel["fish_silverfin.png"] > calm["fish_silverfin.png"] * 1.5, "Eel Run meaningfully raises silverfin odds")

	# The shark stays a spice everywhere (~14/102 ≈ 0.14), even on Eel Run.
	_check(eel["fish_greyreefshark.png"] < 0.20, "shark stays uncommon on Eel Run")

	print("spawn_weight_test: %d failure(s)" % _fails)
	quit(_fails)


func _shares(tide_key: String) -> Dictionary:
	var counts := {}
	for key in KNOWN:
		counts[key] = 0
	for i in range(ROLLS):
		var picked := Fish._pick_fish_texture(tide_key)
		if not counts.has(picked):
			_check(false, "pick returned a known species (got '%s')" % picked)
			continue
		counts[picked] = int(counts[picked]) + 1
	var shares := {}
	for key in counts:
		shares[key] = float(counts[key]) / float(ROLLS)
	return shares


func _check(ok: bool, what: String) -> void:
	print(("  ok  " if ok else "[FAIL] ") + what)
	if not ok:
		_fails += 1
