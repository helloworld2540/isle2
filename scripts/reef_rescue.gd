extends Node2D


func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			pass
		else:
			pass
	elif event is InputEventMouseMotion:
		pass
	elif event is InputEventScreenTouch:
		if event.pressed:
			pass
		else:
			pass
	elif event is InputEventScreenDrag:
		pass
