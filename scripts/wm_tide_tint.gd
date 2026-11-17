extends CanvasLayer

## A breath of the sea over the world map. The tide is the same for every
## keeper on that day, so its tint belongs to the weather rather than the
## player; every dawn the island wears its mood again.
##
## Alpha is deliberately faint — the island's palette is painted, not
## photographed, and a heavy wash would fight the tiles.

const TINTS: Dictionary = {
	"glass_calm": Color(1.0, 0.92, 0.75, 0.08),
	"eel_run": Color(0.55, 0.95, 0.85, 0.08),
	"slack_water": Color(0.75, 0.82, 0.9, 0.08),
	"night_drift": Color(0.35, 0.4, 0.65, 0.16),
}


func _ready() -> void:
	var tint := $TintRect as ColorRect
	if tint:
		var colour: Color = TINTS.get(TideReport.today_key(), Color.WHITE)
		tint.color = colour
