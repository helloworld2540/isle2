# Current project todo:

# done this pass
- Stats page now registers Corl's regulars: a deed line shows the whispers
  ledger (n/7, or the 7/7 "you are known at the counter" line once earned).
- Tutorial finale now gestures at the long game: the tide keeps four
  days and never repeats in a hurry. New players are pointed at NPCs,
  bottles and the tide from the very last card.
- The Steward Era now tints the world: once ISLAND STEWARD is earned the
  map wears a subtle golden hush (alpha 0.12, no motion) — the completion
  state finally has a visual signature.
- NPC dialogue body now scrolls: the lines area is a DragScrollContainer
  (200 px, 46 px touch-friendly) so long milestone-stacked conversations no
  longer overflow the card — touch drag works, the OK button stays put.
- Refactor: TideReport gains typed accessor today_key(); four call sites
  (shop night-drift flavor, shop ledger glass_calm bonus, both recap screens)
  now use it instead of poking the dictionary.
- Tide call-outs land on both recap screens: Slack Water and Night Drift in
  the bench summary ("the belt gave you an easy day" / "the gold came out to
  play"), Glass Calm and Eel Run in the dive summary ("the reef let go of its
  litter" / "the fish were quick about it"). The tide is acknowledged
  everywhere the player actually looks.

# high priority
- (none outstanding.)

# medium priority
# (shimmer item promoted to high priority)

# low priority backlog
- (none outstanding.)
