# Isle 2 — Gameplay Guide

*Guide for version **1.3.0***

Welcome to Isle 2. You manage a small island by diving for debris, sorting your haul, and selling materials at the shop to fund upgrades.

## Core Gameplay Loop

The game follows a three-step cycle: **Dive → Sort → Sell**. 
Follow the trail dots on the world map to find your next destination. Complete all three steps in order to earn a **$15 island-circuit bonus**.

| Step | Location | Activity |
| --- | --- | --- |
| 1. Dive | South Dock | Control a drone to collect debris while avoiding fish. |
| 2. Sort | East Belt | Sort collected debris into matching bins. |
| 3. Sell | North Shop | Sell materials for money and buy upgrades. |

A full loop typically takes 3–6 minutes. Focusing on one type of material is often more profitable than a mixed haul due to bulk bonuses.

## Controls

| Mode | Control |
| --- | --- |
| **World Map** | Tap to walk; glowing pads enter the dive site, sorting bench, or shop. |
| **Sorting Bench** | Swipe to switch bins; tap the item to inspect; drop it in the matching bin. |
| **Reef Rescue** | Drag to steer the drone (it has momentum); **ESC** or **Return to Map** ends the dive. |
| **Shop** | Use buttons to **Sell 1**, **Sell 5**, **Sell All** (one material), or **Sell everything** (the whole bag at once). **Undo** reverts the last sale. |
| **General** | **ESC** closes menus; **☰** opens the island menu. |

## Frequently Asked Questions

- **Where do I start?** Go to the South Dock (Reef Rescue).
- **How do I make the most money?** Sell 5 or more of the same material on the day its "standing order" is active.
- **How much can I carry?** You start with 10 kg capacity. Each upgrade adds +10 kg.
- **How do I save?** The game autosaves frequently and when you select **Save & Quit**. Two rolling backups are maintained.
- **Can I disable screen shake/fast movement?** Yes, go to **☰ → Settings → Reduce Motion**.
- **Where are my achievements?** Check the Stats page for your badges, Reef Registry, and progress.

## Materials & Economy

| Material | Weight | Base Price |
| --- | --- | --- |
| Polyethylene | 1 kg | $2 |
| Polypropylene | 2 kg | $3 |
| Glass | 3 kg | $5 |
| Nylon | 2 kg | $4 |
| Reef Debris | 1 kg | $1 |

### Bonuses
- **Bulk Bonus:** Selling 5+ units of the same material gives a **+25% price bonus** (+35% during Glass Calm).
- **Standing Order:** Each day, one material sells for **+$1 extra per unit**.
    - **Glass Calm:** Glass
    - **Eel Run:** Nylon
    - **Slack Water:** Polyethylene
    - **Night Drift:** Polypropylene

## The Four Tides

Tides change every real-world day and rotate in a fixed order.

| Tide | Gameplay Effects | Atmosphere |
| --- | --- | --- |
| **Glass Calm** | More debris, fewer fish. Glass bulk bonus increased to +35%. | Frequent seagull cries. |
| **Eel Run** | Fish move 28% faster. The Courier (Silverfin) appears more often. | Constant seagull sounds. |
| **Slack Water** | The sorting belt moves 18% slower. | No seagull sounds. |
| **Night Drift** | Golden debris, golden fish, and golden belt scrap are 2x more likely. | Foghorn sounds in the distance. |

### Almanac & Tips
- The current tide is shown on the HUD (e.g., `≈ Glass Calm`).
- **Almanac:** Log all four tides to receive a one-time **$30 bonus**. Once complete, the Stats page will show the tide schedule for the next 7 days.
- **Tide Tips:** Corl at the shop sells a "Tide Tip" for **$25** ($15 if you've bought it several days in a row) which reveals tomorrow's tide.

## Gameplay Details

### Reef Rescue (Diving)
- **Movement:** Drag to steer. The drone has momentum and takes time to slow down.
- **Collection:** Bump debris to pick it up (1 kg per item).
- **Health:** Hitting fish ends the dive. You have 3 "lives" by default.
- **Combos:** Picking up debris in quick succession increases your bonus score.
- **Milestones:** Reaching 400m counts as a "Deep Dive"; 900m is "The Abyss".
- **Rare Finds:** 
    - **Goldie (Fish):** Worth $5 and doesn't hurt you if hit.
    - **Golden Debris:** Provides a +1 bonus score.
    - **Starfish:** A slow-moving creature that is easy to avoid.

### Upcycle (Sorting)
- **Sorting:** Place items in the correct bins. Mistakes reset your scoring streak.
- **Streaks:** Every 5 correct sorts grants **+5 bonus score**.
- **Golden Items:** Worth double points (+2).
- **Completion:** The session ends when all collected Reef Debris is sorted.

## Upgrades

### Shop Upgrades (Costs Money)
| Item | Cost | Effect |
| --- | --- | --- |
| **Bag Capacity** | $60 + $25/level | Increases inventory space. |
| **Market Contact** | $80 / $140 / $200 | Adds +$1 to the price of every unit sold. |
| **Reef Charter** | $100 / $180 | Adds +1 hit point (fish bump) per dive. |
| **Patron of the Isle** | $1500 | One-time prestige title and badge. |
| **Tidekeeper's Pact** | $2500 | Permanent +10 kg bag, badge, and lore item. |

### Equipment Upgrades (Costs Material Weight)
Purchased in the Island Menu (☰) using materials you have in your bag.

| Upgrade | Initial Cost | Effect |
| --- | --- | --- |
| **Move Speed** | 8 kg | Increases walking speed by 8% per level. |
| **Collection Range**| 12 kg | Increases drone pickup radius by 12px per level. |
| **Deep Cache** | 30 Score | Increases debris density in dives. Costs Score instead of weight. |

## Collections & Secrets

- **The Courier (Silverfin):** A rare pale fish seen during **Eel Run**. After seeing it, you can buy "Courier Letters" ($10 each) at the shop to learn the island's lore. There are 14 letters in total.
- **Starfish:** Collect 5 to earn the "Starlight" badge and $25.
- **Bottles:** There are 8 collectible bottles hidden around the island.
- **Island Residents:** As you earn badges and complete milestones, characters like Mara, Tom, Nina, Kai, and Oda will acknowledge your progress in dialogue.
- **Completion:** Earning all 47 achievements grants the "Island Steward" title and changes the world's lighting slightly.

## Technical Settings

- **Multiple Saves:** You can start a "New Island" without deleting your current one.
- **Backups:** If a save is corrupted, use **Restore Backup** on the Stats page.
- **Tide Display:** "Hide the Tide" in settings removes tide labels from the HUD if you prefer to play without knowing the current bonuses.
