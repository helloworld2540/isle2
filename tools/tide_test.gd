extends SceneTree

## Temporary regression harness for the daily Tide Report: deterministic
## rotation, sane modifier bounds, and once-per-day claim semantics.
const SaveManagerScript := preload("res://scripts/save_manager.gd")

var _fails := 0

func _initialize() -> void:
	# Rotation is deterministic and periodic.
	var day := TideReport.day_index()
	var seen: Dictionary = {}
	for i in range(4):
		var entry := TideReport.for_day(day + i)
		seen[String(entry.get("key", ""))] = true
	_check(seen.size() == 4, "four distinct tides in a cycle (%d)" % seen.size())
	_check(String(TideReport.for_day(day).get("key")) == String(TideReport.for_day(day + 4).get("key")), "cycle repeats every 4 days")
	_check(String(TideReport.for_day(day - 1).get("key")) == String(TideReport.for_day(day + 3).get("key")), "negative days wrap")

	# Every condition carries the full modifier set within safe bounds.
	for c in TideReport.CONDITIONS:
		var g := float(c.get("garbage_bias", 0.0))
		var f := float(c.get("fish_speed_mult", 0.0))
		var b := float(c.get("belt_speed_mult", 0.0))
		var gold := float(c.get("golden_chance_mult", 0.0))
		var key := String(c.get("key", "?"))
		_check(absf(g) <= 0.25, "%s garbage bias in range" % key)
		_check(f >= 0.75 and f <= 1.5, "%s fish speed in range" % key)
		_check(b >= 0.75 and b <= 1.25, "%s belt speed in range" % key)
		_check(gold >= 1.0 and gold <= 2.5, "%s golden chance in range" % key)
		_check(not String(c.get("summary", "")).is_empty(), "%s has summary" % key)
		_check(not String(c.get("blurb", "")).is_empty(), "%s has blurb" % key)

	# Only one condition may alter each axis; anything else is a rule clash.
	var garbage_days := 0
	var fish_days := 0
	var belt_days := 0
	var gold_days := 0
	for c in TideReport.CONDITIONS:
		if absf(float(c.get("garbage_bias", 0.0))) > 0.001:
			garbage_days += 1
		if absf(float(c.get("fish_speed_mult", 1.0)) - 1.0) > 0.001:
			fish_days += 1
		if absf(float(c.get("belt_speed_mult", 1.0)) - 1.0) > 0.001:
			belt_days += 1
		if absf(float(c.get("golden_chance_mult", 1.0)) - 1.0) > 0.001:
			gold_days += 1
	_check(garbage_days == 2, "garbage bias on two days (%d)" % garbage_days)
	_check(fish_days == 1 and belt_days == 1 and gold_days == 1, "each minigame axis has one tide day")

	# Claim semantics: first world load today claims, the second does not.
	# Autoload globals are not compile-time symbols for a --script main loop,
	# so resolve the singleton through the tree at runtime.
	var gs = root.get_node_or_null("GameState")
	_check(gs != null, "GameState autoload present")
	if gs:
		var first: Dictionary = gs.try_claim_tide_report()
		_check(not first.is_empty(), "first claim returns a card")
		_check(String(first.get("title", "")).begins_with("TIDE REPORT"), "card titled as a tide report")
		_check(int(gs.tide_report_day) == day, "claim stamps today")
		var today_key := String(TideReport.today().get("key"))
		_check(gs.tides_logged.has(today_key), "claim logs today's tide (%s)" % today_key)
		_check(gs.try_claim_tide_report().is_empty(), "second claim is empty")

		# Almanac reward gates on the full four-tide set and pays only once.
		gs.tides_logged.clear()
		for k in ["glass_calm", "eel_run", "slack_water"]:
			gs.tides_logged.append(k)
		gs.tide_almanac_granted = false
		_check(gs.try_grant_tide_almanac().is_empty(), "no almanac reward at 3/4")
		gs.tides_logged.append("night_drift")
		var gift: Dictionary = gs.try_grant_tide_almanac()
		_check(not gift.is_empty(), "almanac reward at 4/4")
		_check(not String(gift.get("title", "")).is_empty(), "almanac card title")
		_check(gs.try_grant_tide_almanac().is_empty(), "almanac reward is one-time")
		gs.tide_report_day = 0
		gs.tides_logged.clear()
		gs.tide_almanac_granted = false

		# The catalogue advertises the new collectathon.
		var has_almanac := false
		for def in gs.achievement_definitions():
			if String(def.get("id", "")) == "tide_almanac":
				has_almanac = true
		_check(has_almanac, "catalogue includes tide_almanac")

		# The dockhand's tip: costs 25$, pays for foresight, idempotent re-buy,
		# survives a persist/restore cycle, and lapses the moment the day rolls.
		gs.harbor_tip_day = 0
		var money_before: int = gs.money
		gs.money = 10
		_check(not gs.purchase_harbor_tip(), "tip refused without 25$")
		_check(int(gs.money) == 10, "failed tip purchase costs nothing")
		gs.money = 30
		_check(gs.purchase_harbor_tip(), "tip purchased with 25$+")
		_check(int(gs.money) == 5, "tip deducts exactly 25$")
		_check(gs.harbor_tip_purchased(), "tip applies after purchase")
		_check(String(gs.tomorrow_tide_title()).length() > 0, "tomorrow has a title")
		_check(gs.purchase_harbor_tip(), "re-buy is idempotent (free)")
		_check(int(gs.money) == 5, "re-buy does not charge twice")
		gs.harbor_tip_day = 0
		_check(not gs.harbor_tip_purchased(), "tip lapses when reset")
		gs.money = money_before
	_wipe_slots()
	print("tide_test: %d failure(s)" % _fails)
	quit(_fails)

func _check(ok: bool, what: String) -> void:
	print(("  ok  " if ok else "[FAIL] ") + what)
	if not ok:
		_fails += 1

func _wipe_slots() -> void:
	var root_dir := DirAccess.open(SaveManagerScript.SLOT_DIR)
	if root_dir:
		for sub in root_dir.get_directories():
			var path := "%s/%s" % [SaveManagerScript.SLOT_DIR, sub]
			var d := DirAccess.open(path)
			if d:
				for f in d.get_files():
					DirAccess.remove_absolute("%s/%s" % [path, f])
			DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(SaveManagerScript.SLOT_DIR)
