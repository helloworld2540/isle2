extends CanvasLayer

# Lightweight pre-round overlay. It is fully configured before entering
# the scene tree, so _ready can build the UI with the final text.
class_name MinigameIntro

@export var intro_title := "Mini-game"
@export var intro_lines: Array = []
@export var duration := 3.5

var _timer := 0.0
var _next_scene := ""
var _panel: Control
var _dismiss_label: Label

func _ready() -> void:
	layer = 99
	process_mode = Node.PROCESS_MODE_ALWAYS
	_timer = duration
	_build_ui()
	set_process(true)

func configure(title_text: String, lines: Array, next_scene: String = "") -> void:
	intro_title = title_text
	intro_lines = lines.duplicate()
	_next_scene = next_scene
	if is_inside_tree():
		_build_ui()

func setup(title_text: String, lines: Array) -> void:
	configure(title_text, lines)

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.48)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	_panel = PanelContainer.new()
	_panel.position = Vector2(32, 48)
	_panel.custom_minimum_size = Vector2(560, 0)
	add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_panel.add_child(box)

	var title := Label.new()
	title.text = intro_title
	title.add_theme_font_size_override("font_size", 28)
	box.add_child(title)

	for line in intro_lines:
		var line_label := Label.new()
		line_label.text = str(line)
		line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line_label.custom_minimum_size = Vector2(520, 0)
		box.add_child(line_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	box.add_child(spacer)

	_dismiss_label = Label.new()
	_dismiss_label.text = "Autostart in %ds" % int(ceil(_timer))
	_dismiss_label.modulate = Color(0.85, 0.95, 1.0, 0.9)
	box.add_child(_dismiss_label)

func _process(delta: float) -> void:
	if _timer <= 0.0:
		return
	_timer = max(0.0, _timer - delta)
	if _dismiss_label:
		_dismiss_label.text = "Autostart in %ds" % int(max(1.0, ceil(_timer))) if _timer > 0.0 else "Launching..."
	if _timer <= 0.0:
		queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_select"):
		queue_free()
