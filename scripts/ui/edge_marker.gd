extends Label

## Off-screen pointer shown at the viewport edge for Reef Rescue items.
## Garbage points stay calm yellow; fish points flare red and shimmer as
## the fish closes in — a fair, readable warning that costs no extra HUD.

class_name EdgeMarker

const FISH_COLOR := Color(1.0, 0.42, 0.35, 1.0)
const TRASH_COLOR := Color(1.0, 0.95, 0.35, 0.95)

func _ready() -> void:
	pivot_offset = size * 0.5


func set_kind(is_fish: bool) -> void:
	add_theme_color_override("font_color", FISH_COLOR if is_fish else TRASH_COLOR)


func set_direction(dir: Vector2) -> void:
	if dir.x < 0.0:
		text = "<"
	elif dir.x > 0.0:
		text = ">"
	elif dir.y < 0.0:
		text = "^"
	else:
		text = "v"


## Shimmer intensity 0..1. 0 = calm marker, 1 = fish is close and closing;
## the marker swells and burns brighter so a dive feels dodgeable, not random.
func pulse(amount: float) -> void:
	var a := clampf(amount, 0.0, 1.0)
	pivot_offset = size * 0.5
	var s := 1.0 + 0.38 * a
	scale = Vector2(s, s)
	modulate.a = lerpf(0.72, 1.0, a)
