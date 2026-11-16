
# Isle 2 — How to Play (updated)

Welcome to Isle 2. Shared economy across world map, two minigames, shop, NPCs and upgrades.

## Economy basics
- Materials: Polyethylene(1kg), Polypropylene(2kg), Glass(3kg), Nylon(2kg), Reef Debris(1kg).
- Bag capacity starts at 10kg and grows by +10kg per level.

### Pacing (measured on a fresh save)
- A surface dive fishes ~16% of spawns as fish (~27% at 200 m, ~43% at 400 m).
  Each garbage pickup banks 1 kg toward the end-of-dive Reef Debris payout.
- A typical 60–90 s dive banks ~15–25 kg of Reef Debris, which the upcycle
  converts one-for-one into materials (each correct sort burns 1 debris).
- A full 10 kg bag sells for roughly $18–25 (bulk bonus applies once you hold
  5+ of one material), and the island circuit adds a flat $15 on top.
- The opening loop (dive → sort → sell) pays out in ~3–5 minutes.
- Bag capacity starts at 10kg and grows by +10kg per level. Two ways to upgrade:
  trash-paid at the world menu (6 + 3*level), or money-paid at the shop (60 + 25*level).
- Shop sells at rates: Polyethylene 2, Polypropylene 3, Glass 5, Nylon 4, Reef Debris 1.
- Bulk bonus: selling 5+ of a type gives +25%.
- Sell controls: Sell 1, Sell 5, Sell All. Undo last sale is all-or-nothing — if the
  bag cannot fit the whole lot back in, the undo is refused (tooltip tells you how
  many kg you need free) rather than returning partial goods for the full price.
  Undo plays a short rewind animation (REVERSED stamp, exiting receipt).

## Shop conveniences (money sinks)
- Bag +10 kg — 60 + 25 per level. The only way to buy space with money.
- Market Contact — 80/140/200. Each level adds +1$ to every unit sold, on top of
  the bulk bonus, so it pays back across all material types.
- Reef Charter — 100/180. Each level tolerates one extra fish bump per dive
  (the base allowance is 3).
- Money comes from sales and from the $15 island-circuit bonus, so the shop has
  somewhere to spend it beyond bag space.
- Patron of the Isle — 1500$ one time. Pure prestige title shown on the stats
  page, plus the PATRON OF THE ISLE achievement.

## First playthrough (interactive tutorial)
- On a fresh save, world map load shows the "Welcome to Isle 2" card (once per save).
- The TutorialDirector then arms a five-step tour, one hint card at a time:
  1. **Take a stroll** — tap to walk; completes on your first step.
  2. **Dive the reef** — head to the south dock; completes when the dive begins.
  3. **Sort at the bench** — ride the belt east; completes on your first correct sort.
  4. **Cash in at the shop** — north; completes on your first sale (5+ pays +25% bulk).
  5. **You know the loop!** — celebratory card naming the $15 island-circuit bonus.
- Cards are non-modal (they never pause or block play) and only appear in the scene
  where the current step can be acted on; they reappear on scene re-entry until done.
- Progress saves as `tutorial_step`; the tour survives quitting mid-way and never
  re-arms on old saves.
- Two one-shot ambient nudges also live here: a **Bag almost full!** card the
  first time your hold crosses 85% (fires once per save, skipped while another
  card is up), and a **Bottles on the shore** card shown right after the tour
  finishes.

## Upcycle
- Sort belt trash into matching bins. Wrong/burned does not produce materials or score loss reward except streak reset.
- Correct sort gains that material and updates recycled counter/belt counter HUD.

## Reef Rescue
- Dodge fish, collide with garbage to collect 1kg per hit, combos multiply debris bonus.
- 3 fish hits ends run (Reef Charter at the shop raises this); escape early with ESC or button.
- Combo counter appears under the depth HUD from ×2 up and punches at every
  x3 milestone; depth milestones (100/250/400/700/900 m) fire a one-time banner
  each — 400 m is DEEP DIVE, 900 m is TO THE ABYSS.
- Depth is tracked in the stats page and feeds two achievements: DEEP DIVE (400 m) and TO THE ABYSS (900 m).
- Garbage converts into Reef Debris (plus Deep Cache bonus per tier and capacity).

## Upgrades
- Move speed +8% / level via trash.
- Collection radius +12px / level via trash.
- Deep Cache 30 score purchase and 15*tier upgrade increases reef debris.
- Inventory capacity +10 level via trash.
