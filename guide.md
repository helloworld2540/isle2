
# Isle 2 — How to Play (updated)

Welcome to Isle 2. Shared economy across world map, two minigames, shop, NPCs and upgrades.

## Economy basics
- Materials: Polyethylene(1kg), Polypropylene(2kg), Glass(3kg), Nylon(2kg), Reef Debris(1kg).
- Bag capacity starts at 10kg and grows by +10kg per level.

### Pacing (measured on a fresh save, three consecutive loops)
- A surface dive fishes ~16% of spawns as fish (~27% at 200 m, ~43% at 400 m,
  ~57% at 600 m). Each garbage pickup banks 1 kg toward the end-of-dive payout.
- Loop yields: +$34, +$32, +$32 (≈$17 of materials + the flat $15 island-circuit
  bonus; bulk ×1.25 hits whenever a single material reaches 5+).
- Market Contact (80$) lands after ~2–3 loops (~10–12 minutes); Bag and Reef
  Charter sinks are a 3–5 loop goal. Pacing is intentional — the island circuit
  is the reliable earner, bulk sales reward focused hauls over mixed ones.
- A typical 60–90 s dive banks ~15–30 kg of Reef Debris, which the upcycle
  converts one-for-one into materials (each correct sort burns 1 debris).
- The opening loop (dive → sort → sell) pays out in ~3–6 minutes.
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
- Tidekeeper's Pact — 2500$ one time. The final sink: a permanent +10 kg bag
  and the KEEPER OF THE TIDE achievement (no prestige-only fill — the reward is
  mechanical). Funding it AND reading all three shore bottles washes a fourth,
  hidden reply bottle up on the south beach — the tide answers its keeper.
  Funded pacts also earn the island's harbor gossip: NPCs occasionally trade a
  mint-green nod among their idle lines.

## Money-sink payback audit (re-derived from measured $32/loop)
*Measured on a fresh save, three consecutive full loops ≈ $32 each; a loop is
dives → sortie → sell, ~$17 materials plus the $15 circuit bonus. All prices
checked against this yield — nothing changed, deliberately.*
- **Bag +10 kg (60+25$/level):** at a 10 kg hold, bag space is the binding
  constraint. Level 1 roughly doubles cargo per run (≈$17→~$30 materials), so
  it repays in **~3 loops** and every loop afterwards. The single best first
  purchase — this is what the **Room for more?** nudge points at.
- **Trash-priced bag (6+3 trash/level, island terminal):** the low-cash route.
  One dive banks ~15–30 kg Reef Debris; converting that to capacity instead of
  materials is the right deal when money is tight.
- **Market Contact 80/140/200$:** each level is +$1 per unit. A 10-unit haul
  earns +$10/level, so **Level 1 pays back in ~8 loops**; Levels 2–3 extend the
  same economics over the mid-game. It is deliberately the slowest normal sink
  per dollar — the $200 third level is the long-game stretch. Left as priced.
- **Reef Charter 100/180$:** pure survival (one extra fish bump per level) —
  it buys depth access rather than money, so it is priced by feel, not payback.
- **Circuit bonus $15:** the flat, guaranteed component of loop income (~47%);
  it is the stabiliser that stops the whole economy from depending on RNG
  hauls. Not reduced.
- **Patron of the Isle 1500$:** aspirational finish line, ~47 median loops —
  the game's final money sink.

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
- Eight one-shot ambient nudges also live here: a **Bag almost full!** card the
  first time your hold crosses 85% (fires once per save, skipped while another
  card is up), a **Bottles on the shore** card shown right after the tour
  finishes, a **Room for more?** card after your first sale — pointing at
  both bag-expansion paths (shop cash or island-map trash), an **Oops — bulk
  sale?** card after your first bulk sale — pointing at the Undo last sale
  button — a **Tune up the dock** card the first time you can afford a
  speed/range tier, naming the live trash cost and reminding you upgrades
  spend materials, not money, an **Islanders about** card on the first world
  entry after the tour while any resident is still unmet — pointing at the
  trail walkers and their first-visit gifts, a **Someone needs a hand** card
  the first time you hold enough material to turn in a quest — pointing at
  the quest tracker and the ★ glow, and a **Deep Cache** card the first time
  you can afford the 30-score unlock, pointing at the score-priced Deep Cache at
  the island menu (both a dive and a bench run feed the score). Nudges fire
  one card at a time: if a card or modal owns the screen, the nudge waits
  for it to close instead of evaporating.

## Upcycle
- Sort belt trash into matching bins. Wrong/burned does not produce materials or score loss reward except streak reset.
- Correct sort gains that material and updates recycled counter/belt counter HUD.
- Back on the map the run is titled like a chapter — "Bench Run № 2 —
  Hot Streak" — named by the longest streak you kept inside that run, and it
  flags a new personal best. Ten finished runs earns BENCH REGULAR.
- Mid-run the score readout carries "(best N)" so the chase stays visible, and
  passing the record fires a one-shot gold "NEW BEST — N!" callout with a punch.
- The pre-round briefing leads with your personal stake — "Best score: N ·
  Runs finished: M" — so the ghost follows you into the room.
- Combo milestones (every five clean sorts) add +5 score and a "FIVE ON THE
  BELT!" banner; a burned or wrong item resets the streak.
- When only 5 Reef Debris remain the bench warns you once; when the pile runs
  out it stops feeding the belt and lets you finish whatever is on it, then
  closes on a gold **SHIFT COMPLETE** panel (nothing left unsorted).
- The workshop hums while you sort (low drone + fan whir under the music); it is
  on the Ambience slider, not SFX.

## Reef Rescue
- Dodge fish, collide with garbage to collect 1kg per hit, combos multiply debris bonus.
- 3 fish hits ends run (Reef Charter at the shop raises this); escape early with ESC or button.
- Combo counter appears under the depth HUD from ×2 up and punches at every
  x3 milestone; depth milestones (100/250/400/700/900 m) fire a one-time banner
  each — 400 m is DEEP DIVE, 900 m is TO THE ABYSS.
- Off-screen edge markers: fish markers flare red and swell/throb as they
  close on the drone (proximity + depth-scaled shimmer); garbage markers stay calm yellow.
- Fish telegraph: a red wake blooms at the bottom edge in the fish's lane ~1.15s
  before it rises into view (swells and fades; skipped under reduced motion).
- One bump left from the fish limit: the screen edges breathe a soft red
  vignette (static dim under reduced motion).
- Dive summary payoff: when a dive beats your deepest ever, the summary leads
  with "★ NEW BEST DEPTH — N m! ★" and plays the achievement chime.
- Debris payout breakdown on the summary card — haul, deep-cache bonus and
  "bag full −N kg" so the capacity cap reads as a rule, not a bug.
- Bottles you have already read can be re-read from the stats page via the Tide Ledger overlay (the game nudges you there once the third base bottle is read) (undiscovered notes stay locked).
- Quest economics audit (SALE_PRICES-weighted): turn-ins are deliberately slightly under market value — that is the price of quest progress and the Harbor Hero +10 kg cap — but the old numbers were punitive (Tom 24$->12$, Nina 30$->15$, Kai 25$->10$, Mara t2 25$->18$). Buffed: Tom t1 4->6 PP (18$), Nina t1 5->6 PP (18$), Kai t1 now 6 PP (18$), Mara t2 6->8 PP (24$). Nina t2 (+8$) and Kai t2 (+4$) remain the profitable tiers.
- Depth is tracked in the stats page and feeds two achievements: DEEP DIVE (400 m) and TO THE ABYSS (900 m). Ten finished dives earns REEF REGULAR; the stats page keeps a running "Field log" of dives and bench runs.
- Species you have bumped into are logged in the stats page ("Fish spotted"); meeting all four earns REEF REGISTRY; the Reef Registry overlay on the stats page re-shows each species note you have earned. Lifetime counters (stats page) track clean dives and flawless shifts and feed the CLEAN SWEEP (5 clean dives) and SILK TOUCH (5 flawless shifts) achievements. A dive with no fish bumps and at least 8 kg hauled earns a CLEAN DIVE tag on the summary and recap cards. A belt run with no misses and at least 5 sorted items earns a FLAWLESS SHIFT tag on the summary and recap cards. Your longest sort streak persists as "Best sort streak" (stats page) and feeds the HOT STREAK achievement at 15 in a row. Your heaviest single dive persists as "Heaviest dive" (stats page) and feeds the HEAVY HARVEST achievement at 30 kg banked in one dive. Your longest single-dive garbage chain persists as "Best reef combo" (stats page) and feeds the RHYTHM OF THE REEF achievement at a 9-chain (a x4 score multiplier).
- Long-game badges: BENCH MASTER (25 runs), REEF VETERAN (25 dives) and
  LOOP MASTER (25 circuits) sit behind the 10-run regulars — the island's
  endgame chase alongside the two pact/patron money sinks.
- Garbage converts into Reef Debris (plus Deep Cache bonus per tier and capacity).
  The Deep Cache bonus is never lost to a full bag: any part that does not fit is
  salvaged as money ($1/kg, shown as "N$ salvaged" on the summary card). Without
  that, the upgrade would do nothing at the 10 kg starting bag, where every dive
  fills up.
- A dive that never reaches a pickup or a fish bump is not counted: no dive
  counter, no depth best, no "Dive № N" recap card, no haul ("No pickups this
  dive." on the summary card). Mirrors the bench's empty-shift rule. Ten finished
  *counted* dives still earns REEF REGULAR.
- A muffled underwater current runs under the dive music; trim it with the
  Ambience slider without quieting pickup or combo feedback.

## Settings & touch
- The island menu (☰) holds Master / Music / Ambience / SFX sliders and the
  **Reduce motion** toggle. Each slider sits on its own row with a big, fat
  touch track, so it is easy to grab on a phone without the labels moving.
- The in-run **Return to Map** buttons in both minigames are 48 px tall, and the
  shop and stats lists drag-scroll (mouse drag or finger) without stealing taps
  from the buttons inside them.
- Every shop button is ≥ 44 px tall — the row **Sell 1 / Sell 5 / Sell All**, the
  Buy buttons and the footer Return / Undo — so nothing needs a pinpoint tap; the
  two-column counter still fits a 1152×648 screen with no scrolling.
- The world-menu (☰) buttons match: the five upgrade buttons (Move / Range /
  Deep Cache / its tier-up / Inv Cap), the **Settings** toggle and the **Reduce
  motion** checkbox are each ≥ 44 px, so the whole island menu is thumb-friendly.

## Screen layout & toasts
- Everything obeys one 24 px screen margin. Centered **modal cards** (welcome
  guide, minigame briefings, the pause/Island Menu) sit on a full-rect
  `CenterContainer` inset by 24 px; non-modal **bottom cards** (tutorial step
  hints) sit in a bottom `Margin` column. Both register in a group
  (`ui_modal_card` / `hud_bottom_card`) so the toast queue and the tutorial
  director stack above / wait for them instead of overlapping.
- The pause/Island Menu card is 880 px-min with its own header row (title +
  live upgrade status), an ACTIONS column (Resume, Save & quit) beside the
  infobox, and a **Settings** view that swaps out the upgrades/progress pane
  so the card never outgrows a 1152×648 screen. Under **Reduce motion** the
  card simply appears; otherwise it fades in over 0.16 s.
- Minigame HUDs group their stat labels into a `UI/HUDStats` VBox pinned at
  the 24 px safe margin (20 px type).
- Toast notifications live in a bottom-centre lane, 24 px off the edge, 18 px
  type with a dark outline, and lift clear of any visible bottom-centre card.

## Upgrades
- Move speed +8% / level via trash.
- Collection radius +12px / level via trash.
- Deep Cache 30 score purchase and 15*tier upgrade increases reef debris; the
  world-menu button names the current/next per-run bonus (e.g. "+10 kg/run"), and
  the bonus is never wasted on a full bag (see the reef notes below). The score
  is a lifetime bank — both a dive (combo multiplier) and a bench run feed it,
  and the world HUD bar counts down to the next Deep Cache purchase.
- Inventory capacity +10 level via trash.

### Trash-upgrade payback audit (measured, pass 5)
*Trash costs are paid in **kg of held material** (`Inventory.spend` compares inventory
weight), and the bag is the hard cap on a loop's haul — so one loop banks at most your
bag capacity in material. Measured on the live dive payout: accepted Reef Debris equals
free capacity (10 kg at the starting bag, 20 kg at Bag Lv.1) for any haul ≥ capacity, and
each debris sorts 1:1 into a material.*
- **Inventory Capacity Lv.1 (6 kg):** ~0.6 loops. The cheapest first step on the terminal.
- **Move Speed Lv.1 (8 kg):** ~0.8 loops; **Lv.2 (12 kg):** ~1.2 loops. This is what the
  **Tune up the dock** nudge points at.
- **Collection Range Lv.1 (12 kg):** ~1.2 loops.
- Because bag income grows +10 kg/level while the costs grow only +3/+4/+6, every later
  tier costs *fewer* loops than the one before (Move Lv.3 ≈ 0.5 loops at a 30 kg bag).
  Note the cost is real, not trivial: paying 8–12 kg is most of a starting bag's haul,
  so a trash upgrade is a roughly one-loop commitment of material you could have sold.
  That is the intended first-upgrade shape — a modest, affordable step right after the
  tour, not a money sink — so **no prices changed.**
- **Tune-nudge timing (verified):** with the tour complete and an empty nudge history,
  the card does **not** appear at a 7 kg hold (below the 8 kg cheapest tier) and appears
  with the live cost ("8 trash") the moment the hold reaches 8 kg. It fires from the world
  HUD, never mid-sale, and persists `nudge_tune_shown` so it is once per save.

## World map & dock ambience
- Tap any walkable tile to walk there (BFS pathfinding); glowing pads are the
  portals to the bench, the reef dive, and the shop.
- Completing all three stations in a lap pays the **$15 island-circuit** bonus
  and the return card names your lap "Circuit No N".
- The dock is alive even when you stand still: a **harbor cry** sounds every
  40–75 s (a lone, lower-pitched gull answering itself across the water), on top
  of the four gulls patrolling the open water east of the island. The harbor cry
  is audio-only, so it keeps playing even with **Reduced motion** on — where the
  birds hold still, the water still sounds like water.
- Under it all runs a continuous **surf wash**, a seamless 12 s loop that fades
  in when you reach the map and keeps rolling while the pause menu is open. It
  has its own **Ambience** slider (settings: Master / Music / Ambience / SFX), so
  you can quiet the wash and wildlife without softening the sort/sale feedback.
- Bottles wash up on the shore with lore; after the Tidekeeper's Pact is funded
  and all base bottles are read, a hidden fourth bottle surfaces.
