extends Label

# Reusable scene template for dynamic toast/label feedback.
# Call `_apply` after instantiation or manually set text/position before add_child.

func _ready() -> void:
    # Keep same lightweight behavior as previous procedural toast labels.
    pass

func set_position_offset(offset: Vector2) -> void:
    position = offset

func set_modulate_color(col: Color) -> void:
    modulate = col