extends CharacterBody2D

const CELL_SIZE := 128.0
const MOVE_TIME := 0.2

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var is_moving: bool = false
var move_tween: Tween


func _physics_process(_delta: float) -> void:
	if is_moving:
		return

	var input_dir := _get_input_direction()
	if input_dir == Vector2.ZERO:
		_stop_animation()
		return

	# Pokemon-style: only move horizontally OR vertically, never diagonally.
	if absf(input_dir.x) >= absf(input_dir.y):
		input_dir = Vector2(signf(input_dir.x), 0.0)
	else:
		input_dir = Vector2(0.0, signf(input_dir.y))

	_play_animation_for(input_dir)
	_move_one_cell(input_dir)


func _get_input_direction() -> Vector2:
	return Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)


func _move_one_cell(direction: Vector2) -> void:
	is_moving = true
	var target := global_position + direction * CELL_SIZE

	move_tween = create_tween()
	move_tween.set_trans(Tween.TRANS_LINEAR)
	move_tween.tween_property(self, "global_position", target, MOVE_TIME)
	move_tween.finished.connect(_on_move_finished)


func _on_move_finished() -> void:
	is_moving = false
	global_position = global_position.snapped(Vector2(CELL_SIZE, CELL_SIZE))


func _play_animation_for(direction: Vector2) -> void:
	if direction.x > 0:
		animated_sprite.play("player_right")
	elif direction.x < 0:
		animated_sprite.play("player_left")
	elif direction.y > 0:
		animated_sprite.play("player_down")
	elif direction.y < 0:
		animated_sprite.play("player_up")


func _stop_animation() -> void:
	if animated_sprite.is_playing():
		animated_sprite.pause()
