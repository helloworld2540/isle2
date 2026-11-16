# Current project todo:

# done this pass
- Shop receipt stack right-aligned (fixed-width right-aligned labels; no more
  off-screen clipping); bulk sales punch; receipts reflow on expiry.
- Undo animation: REVERSED stamp + exiting receipt + red flashes + button punch;
  all-or-nothing undo with denial feedback, tooltip capacity hint, sort_bad sfx.
  (Undo was previously partial-restore but full-price clawback — now fair.)
- World HUD bag line pulses amber when near full (85%+), stronger at full;
  reduce_motion freezes the breath, tint remains.
- Main-menu world preview postcard (THE ISLE) with ambient motes.
- Step-by-step first-playthrough tutorial: TutorialDirector autoload + non-modal
  tutorial_hint cards; welcome → walk → reef dive → upcycle sort → shop sale →
  finale, persisted as tutorial_step and verified end-to-end on a fresh save.
  Fixed deferred spawn (hint used to parent to a dying scene during transitions).

# high priority
- (next) Balance pass: first-playthrough pacing from the tutorial finish to the
  first shop bulk-sale — trace XP/money curve, tune upcycle spawn interval and
  reef depth ramp so the opening loop feels rewarding inside ~5 minutes.

# medium priority
- Tutorial: add a contextual "Bag heavy — sell at the shop" hint when inventory
  first crosses 85% mid-tour, plus a bottle-finder nudge after the finale.
- Main-menu postcard: add a one-time shimmer sweep across the preview when the
  player first unlocks the island circuit (ties the postcard to progression).

# low priority backlog
