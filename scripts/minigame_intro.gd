extends CanvasLayer

# Lightweight pre-round overlay. It is fully configured before entering
# the scene tree, so _ready can build the UI with the final text.
class_name MinigameIntro

@export var intro_title := "Mini-game"
@export var intro_lines: Array = []

var _panel: Control
var _got_it_button: Button

func _ready() -> void:
	layer = 99
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	get_tree().paused = true
	get_tree().root.set_disable_input(false)
	set_process(true)

func configure(title_text: String, lines: Array, next_scene: String = "") -> void:
	intro_title = title_text
	intro_lines = lines.duplicate()
	if is_inside_tree():
		_build_ui()

func setup(title_text: String, lines: Array) -> void:
	configure(title_text, lines)

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	var bg := load("res://scenes/ui/color_rect.tscn").instantiate() as ColorRect
	bg.color = Color(0, 0, 0, 0.48)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	_panel = load("res://scenes/ui/panel_container.tscn").instantiate() as PanelContainer
	_panel.position = Vector2(32, 48)
	_panel.custom_minimum_size = Vector2(560, 0)
	add_child(_panel)

	var box := load("res://scenes/ui/vbox_container.tscn").instantiate() as VBoxContainer
	box.add_theme_constant_override("separation", 8)
	_panel.add_child(box)

	var title := load("res://scenes/ui/label.tscn").instantiate() as Label
	title.text = intro_title
	title.add_theme_font_size_override("font_size", 28)
	box.add_child(title)

	for line in intro_lines:
		var line_label := load("res://scenes/ui/label.tscn").instantiate() as Label
		line_label.text = str(line)
		line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line_label.custom_minimum_size = Vector2(520, 0)
		box.add_child(line_label)

	var spacer := load("res://scenes/ui/control.tscn").instantiate() as Control
	spacer.custom_minimum_size = Vector2(0, 8)
	box.add_child(spacer)

	_got_it_button = load("res://scenes/ui/button.tscn").instantiate() as Button
	_got_it_button.text = "Got it"
	_got_it_button.custom_minimum_size = Vector2(140, 0)
	_got_it_button.pressed.connect(_on_got_it_pressed)
	box.add_child(_got_it_button)

func _on_got_it_pressed() -> void:
	get_tree().paused = false
	queue_free()

func _process(_delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and is_instance_valid(_got_it_button):
		_on_got_it_pressed()
