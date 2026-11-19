extends SceneTree
## Pacing simulation for the fresh-save reef → bench → shop loop.
##
## Mirrors the shipped code paths with the real constants read from the
## scripts (kept in sync by inspection — tools/economy_audit.py guards the
## price/bulk tables):
##   * Reef dive ends with max(1, round(garbage_picked)) kg of Reef Debris,
##     clamped by free bag space (fresh bag = 10 kg).
##   * Bench: every spawned belt item consumes 1 Reef Debris. Spawn is
##     uniform over the five sprites in scripts/upcycle.gd TRASH_SPRITES,
##     mapped by scripts/u_trash.gd TRASH_MAP to (material, units).
##   * Deposit grants units clamped by free space (TRASH_WEIGHTS), the same
##     clamp Inventory.add_weighted applies — so a full bag silently eats
##     the overflow, exactly like the real bench.
##   * Shop: sell everything; 5+ of a type earns the 1.25 bulk multiplier
##     (not applied on top of a hypothetical Glass Calm — this is the
##     neutral-tide baseline); plus the $15 circuit bonus.
##
## Also prints the measured fish-share of reef spawns per depth band, the
## curve guide.md promises (~16/27/43/57/72%% at 0/200/400/600/800 m),
## computed with the same randfn the spawn code rolls.
##
## Run: godot --headless --path . -s tools/pacing_sim.gd
## Exits 0 always; prints a table. Intended for balance review, not a gate.

const CAPACITY_KG := 10
const WEIGHTS := {
	"Polyethylene": 1,
	"Polypropylene": 2,
	"Glass": 3,
	"Nylon": 2,
	"Reef Debris": 1,
}
const PRICES := {
	"Polyethylene": 2,
	"Polypropylene": 3,
	"Glass": 5,
	"Nylon": 4,
	"Reef Debris": 1,
}
const UNIT_SIZES := {  ## from TRASH_MAP (units granted per belt item)
	"Polyethylene": 2,
	"Polypropylene": 2,
	"Glass": 1,
	"Nylon": 1,
}
## Uniform over 5 sprites: PE 1/5, PP 2/5, Glass 1/5, Nylon 1/5.
const SPAWN_TABLE := [
	["Polyethylene", 1], ["Polypropylene", 2], ["Glass", 1], ["Nylon", 1],
]
const CIRCUIT_BONUS := 15
const BULK_MULT := 1.25
const BULK_AT := 5

func _weight(inv: Dictionary) -> int:
	var total := 0
	for k in inv:
		total += int(inv[k]) * int(WEIGHTS.get(k, 1))
	return total

func _add_weighted(inv: Dictionary, mat: String, amount: int) -> int:
	var unit: int = int(WEIGHTS.get(mat, 1))
	var free_kg := CAPACITY_KG - _weight(inv)
	var accepted: int = mini(amount, free_kg / unit)
	if accepted > 0:
		inv[mat] = int(inv.get(mat, 0)) + accepted
	return accepted

func _sim_loop(rng: RandomNumberGenerator, garbage_lo: int, garbage_hi: int) -> Dictionary:
	var inv := {}
	# --- Dive: bank debris up to the bag cap ---
	var garbage := rng.randi_range(garbage_lo, garbage_hi)
	var debris := mini(maxi(1, garbage), CAPACITY_KG)
	inv["Reef Debris"] = debris
	# --- Bench: feed the belt until debris runs dry or the run is sorted out ---
	var sorted := 0
	var guard := 500
	while int(inv.get("Reef Debris", 0)) > 0 and guard > 0:
		guard -= 1
		inv["Reef Debris"] = int(inv["Reef Debris"]) - 1
		var roll := rng.randi_range(1, 5)
		var mat := ""
		match roll:
			1: mat = "Polyethylene"
			2, 3: mat = "Polypropylene"
			4: mat = "Glass"
			5: mat = "Nylon"
		_add_weighted(inv, mat, UNIT_SIZES[mat])
		sorted += 1
	# --- Shop: sell everything at bulk-adjusted prices + circuit bonus ---
	var gross := 0.0
	for mat in ["Polyethylene", "Polypropylene", "Glass", "Nylon", "Reef Debris"]:
		var count: int = int(inv.get(mat, 0))
		if count <= 0:
			continue
		var each: float = float(PRICES[mat])
		if count >= BULK_AT:
			each *= BULK_MULT
		gross += each * count
	gross += CIRCUIT_BONUS
	return {"gross": gross, "sorted": sorted, "debris_banked": debris}

func _fish_share_at(depth: float, n: int, rng: RandomNumberGenerator) -> float:
	# rr_fish spawn roll: randfn(depth/1000, 0.5) > 0.5 means "fish".
	var hits := 0
	for i in n:
		if rng.randfn(depth / 1000.0, 0.5) > 0.5:
			hits += 1
	return float(hits) / n

func _initialize() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261119
	for depth in [0.0, 200.0, 400.0, 600.0, 800.0]:
		print("  fish share of spawns at %d m: %.0f%%" % [depth, 100.0 * _fish_share_at(depth, 20000, rng)])
	print("  guide promises: 16 / 27 / 43 / 57 / 72 (%)")
	var n := 4000
	var total := 0.0
	var sorted_total := 0
	var worst := INF
	var best := 0.0
	for i in n:
		var r := _sim_loop(rng, 15, 25)
		total += float(r.gross)
		sorted_total += int(r.sorted)
		worst = minf(worst, float(r.gross))
		best = maxf(best, float(r.gross))
	print("fresh-save loop (bag 10 kg, neutral tide, %d sims):" % n)
	print("  mean gross per loop: $%.2f  (worst $%.0f / best $%.0f)" % [total / n, worst, best])
	print("  mean belt items sorted per visit: %.1f" % (float(sorted_total) / n))
	print("  guide claims: +$34 / +$32 / +$32 with ~$17 of materials + $15 circuit")
	quit(0)
