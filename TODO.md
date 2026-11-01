# Current project todo:

- Continue animation/performance polish: reduce tween allocations and cache SFX stream load results.

## Completed this pass
- Wired Shop portal into world map (PortalShop) driving existing shop flow.
- Added upgrade success SFX hook (upgrade.txt/ogg placeholder) + button flash.
- Added shop sale SFX triggers.
- Cached SFX/BGM stream loads in AudioManager.
- (Removed) Inventory stats already live; shop upgrades present.

## Backlog
- Ship placeholder audio assets to real samples.
- Reduce tween allocations further in reef/upcycle.
- World-map upgrade panel styling/content polish.

## Backlog (continued)
- Add world-map mini progress bar for reef depth and upcycle score.
- Add animation polish: spawn fade-in for reef items, juice for portal pulse overshoot.
- Main-menu Continue summary thumbnail stats (not art assets).
