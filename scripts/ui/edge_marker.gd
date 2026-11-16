extends Label

## Off-screen pointer shown at the viewport edge for Reef Rescue items.

class_name EdgeMarker


func set_direction(dir: Vector2) -> void:
	if dir.x < 0.0:
		text = "<"
	elif dir.x > 0.0:
		text = ">"
	elif dir.y < 0.0:
		text = "^"
	else:
		text = "v"
