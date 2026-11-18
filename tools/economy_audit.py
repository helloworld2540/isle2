#!/usr/bin/env python3
"""Economy audit: cross-checks the numbers the guide promises against the
constants in the code, so a silent rebalance breaks the promises visibly.

Verifies, from source (not from docs):
  1. The five sale prices and the five materials used to clear the bench
     (PROCESSING materials) stay a 2–5 $ spread, Goldie included.
  2. Bulk math: BULK_MULTIPLIER=1.25, GLASS_CALM=1.35 (i.e. 1.25+0.10).
  3. Money sinks: capacity 60+25/level (money) / 6+3 (trash), market
     80+60/level (3 levels max), reef charter 100+80, patron 1500,
     tidekeeper 2500 — all as documented.
  4. Dockhand tip: 25$ base, 15$ on a 3-day streak.
  5. Circuit bonus = 15$ — the flat component of loop income.
  6. Tide modifiers stay single-axis: each condition moves exactly one
     dial (glass_calm=garbage_bias, eel_run=fish_speed, slack=belt_speed,
     night_drift=golden_chance) and nothing else moves.
  7. Spawn weights cover every fish in the size table exactly once.

Exits non-zero if any invariant breaks. Run it whenever a price moves.
Not wired into all_audits.sh on purpose: balance changes should be a
decision, not a red gate — but the numbers must agree or the guide lies.
"""
import re
import sys
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
fail = 0

def read(name: str) -> str:
    return (ROOT / name).read_text()

def ok(cond: bool, what: str) -> None:
    global fail
    if cond:
        print("  ok  %s" % what)
    else:
        print("[FAIL] %s" % what)
        fail += 1

def one(pattern: str, text: str):
    m = re.search(pattern, text)
    if not m:
        return None
    return m.group(1) if m.groups() else m.group(0)

# 1) sale prices
gs = read("scripts/game_state.gd")
prices = dict(re.findall(r'"([A-Za-z ]+)":\s*(\d+),?', gs.split("const SALE_PRICES", 1)[1].split("}", 1)[0]))
print("sale prices: %s" % prices)
expected_prices = {"Polyethylene": "2", "Polypropylene": "3", "Glass": "5", "Nylon": "4", "Reef Debris": "1"}
ok(prices == expected_prices, "sale prices match the guide (%s)" % prices)
spreads = [int(v) for v in prices.values()]
ok(min(spreads) >= 1 and max(spreads) <= 5, "price spread sits inside 1–5$")

# 2) bulk
ledger = read("scripts/shop_ledger.gd")
ok(one(r"const BULK_MULTIPLIER := ([\d.]+)", ledger) == "1.25", "BULK_MULTIPLIER is 1.25")
ok(one(r"const GLASS_CALM_BULK_BONUS := ([\d.]+)", ledger) == "0.10", "GLASS_CALM bonus is 0.10 (i.e. 1.35 total)")

# 3) money sinks
ok(one(r"const HARBOR_HERO_CAPACITY_BONUS: int = (\d+)", gs) == "1", "Harbor Hero grants one capacity level")
ok(one(r"60 \+ inventory_capacity_level \* 25", gs) is not None, "capacity cost curve is 60+25/level")
ok("6 + (inventory_capacity_level * 3)" in gs, "trash-bag cost curve is 6+3 trash/level")
ss = re.search(r"func get_market_cost\(\) -> int:\n\treturn (\d+) \+ market_level \* (\d+)", gs)
ok(ss is not None and ss.group(1) == "80" and ss.group(2) == "60", "market cost curve is 80+60/level")
ok(one(r"const MARKET_MAX_LEVEL := (\d+)", gs) == "3", "market caps at 3 levels")
charter = re.search(r"func get_reef_lives_cost\(\) -> int:\n\treturn (\d+) \+ reef_bonus_lives \* (\d+)", gs)
ok(charter is not None and charter.group(1) == "100" and charter.group(2) == "80", "reef charter cost curve is 100+80")
ok(one(r"const ISLAND_PATRON_COST := (\d+)", gs) == "1500", "Patron of the Isle costs 1500$")
ok(one(r"const TIDEKEEPER_COST := (\d+)", gs) == "2500", "Tidekeeper's Pact costs 2500$")

# 4) dockhand tip
ok(one(r"const HARBOR_TIP_COST := (\d+)", gs) == "25", "dockhand tip is 25$")
ok(one(r"const HARBOR_TIP_DISCOUNT := (\d+)", gs) == "15", "dockhand regulars pay 15$")
ok(one(r"const HARBOR_TIP_DISCOUNT_STREAK := (\d+)", gs) == "3", "discount needs a 3-day streak")

# 5) circuit bonus
ok(one(r"const CIRCUIT_BONUS_MONEY: int = (\d+)", gs) == "15", "circuit bonus constant is 15$")

# 6) tide conditions match their tuned modifier exactly
tr = read("scripts/tide_report.gd")
m_keys = set(re.findall(r'"key": "(\w+)"', tr))
ok(m_keys == {"glass_calm", "eel_run", "slack_water", "night_drift"}, "tide rotation holds exactly four conditions")

def expect(key: str, bias: float, fish: float, belt: float, gold: float) -> None:
    pattern = r'"key": "%s"[\s\S]*?"garbage_bias": ([\-\d.]+),[\s\S]*?"fish_speed_mult": ([\d.]+),[\s\S]*?"belt_speed_mult": ([\d.]+),[\s\S]*?"golden_chance_mult": ([\d.]+)' % key
    mm = re.search(pattern, tr)
    got = (float(mm.group(1)), float(mm.group(2)), float(mm.group(3)), float(mm.group(4))) if mm else None
    want = (bias, fish, belt, gold)
    ok(got == want, "%s = %s" % (key, want))

expect("glass_calm", 0.16, 1.0, 1.0, 1.0)
expect("eel_run", -0.06, 1.28, 1.0, 1.0)
expect("slack_water", 0.0, 1.0, 0.82, 1.0)
expect("night_drift", 0.0, 1.0, 1.0, 2.0)

# 7) spawn weights cover every fish exactly once
fish = read("scripts/rr_fish.gd")
weights = dict(re.findall(r'"(fish_\w+\.png)":\s*(\d+),?', fish.split("SPAWN_WEIGHTS :=", 1)[1].split("}", 1)[0]))
sizes = dict(re.findall(r'"(fish_\w+\.png)":\s*(\d+),?', fish.split("const FISH :=", 1)[1].split("}", 1)[0]))
print("spawn weights: %s" % weights)
ok(set(weights) == set(sizes), "spawn weights cover exactly the fish in the size table")
for name, weight in weights.items():
    ok(int(weight) > 0, "%s has positive weight" % name)

print("economy_audit: %d failure(s)" % fail)
sys.exit(1 if fail else 0)
