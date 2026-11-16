extends RefCounted

## Pure inventory and capacity rules for the island economy. GameState owns
## the live state, signals and persistence; this module computes capacity and
## weight and moves units in and out through a passed-in state object
## (GameState, or a test double with the same fields).
##
## Capacity is 10 kg base + 10 kg per bag level. Weights are per material and
## live in GameState.TRASH_WEIGHTS. The weighted spend uses a bounded
## backtracking search rather than a greedy largest-first pick, which used to
## fail when a cheap 1 kg unit blocked matching the remaining cost exactly.

static func capacity(state) -> int:
	return 10 + (state.inventory_capacity_level * 10)


static func weight(state) -> int:
	var total: int = 0
	for k in state.trash_by_type.keys():
		total += int(state.trash_by_type[k]) * int(state.TRASH_WEIGHTS.get(k, 1))
	return total


static func free_space(state) -> int:
	return max(0, capacity(state) - weight(state))


## Adds up to `amount` units of `mat`, clamped by remaining space. Returns the
## accepted count. Mutates state.trash_by_type; no persist here.
static func add_weighted(state, mat: String, amount: int) -> int:
	var unit_weight: int = max(1, int(state.TRASH_WEIGHTS.get(mat, 1)))
	if amount <= 0:
		return 0
	var max_acceptable: int = free_space(state) / unit_weight
	var accepted: int = min(amount, max_acceptable)
	if accepted <= 0:
		return 0
	state.trash_by_type[mat] = int(state.trash_by_type.get(mat, 0)) + accepted
	return accepted


## Consumes units unconditionally on success. Returns false when stock is short.
static func consume(state, mat: String, amount: int) -> bool:
	if amount <= 0:
		return false
	var current: int = int(state.trash_by_type.get(mat, 0))
	if current < amount:
		return false
	state.trash_by_type[mat] = current - amount
	return true


## Pays `amount` of weighted trash. Returns false when the plan cannot be
## filled. Mutates state.trash_by_type on success; no persist here.
static func spend(state, amount: int) -> bool:
	if amount <= 0:
		return true
	if weight(state) < amount:
		return false
	
	var keys: Array = state.trash_by_type.keys()
	keys.sort_custom(func(a, b): return int(state.TRASH_WEIGHTS.get(a, 1)) > int(state.TRASH_WEIGHTS.get(b, 1)))
	
	var plan: Dictionary = {}
	if not _plan(state, keys, 0, amount, plan):
		return false
	
	for key in plan.keys():
		state.trash_by_type[key] = int(state.trash_by_type[key]) - int(plan[key])
	return true


## Bounded exhaustive search from heaviest to lightest material. The tree is
## shallow (5 material kinds), so worst case is tiny; the goal is exact match,
## not fastest.
static func _plan(state, keys: Array, index: int, remaining: int, plan: Dictionary) -> bool:
	if remaining == 0:
		return true
	if index >= keys.size():
		return false
	
	var key: String = keys[index]
	var unit_weight: int = max(1, int(state.TRASH_WEIGHTS.get(key, 1)))
	var available: int = int(state.trash_by_type.get(key, 0))
	var max_units: int = min(available, remaining / unit_weight)
	
	for units in range(max_units, -1, -1):
		if units > 0:
			plan[key] = units
		if _plan(state, keys, index + 1, remaining - units * unit_weight, plan):
			return true
		plan.erase(key)
	return false