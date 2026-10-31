extends CanvasLayer
# Temporary overlay summarizing controls for each minigame.
var timer: float = 4.0
var intro_title := "Mini-game"
var intro_lines: Array = []
var _next_scene := ""
func configure(title_text: String, lines: PackedStringArray, next_scene: String) -> void:
	intro_title = title_text
	intro_lines = lines
	_next_scene = next_scene
var dismiss_label: Label

func _ready() -> void:
	layer = 99
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.45)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var panel := VBoxContainer.new()
	panel.position = Vector2(40, 60)
	add_child(panel)
	var title := Label.new()
	title.text = intro_title
	title.add_theme_font_size_override("font_size", 32)
	panel.add_child(title)
	for line in intro_lines:
		var l := Label.new()
		l.text = line
		panel.add_child(l)
	dismiss_label = Label.new()
	dismiss_label.text = "Starting in %ds..." % int(timer)
	panel.add_child(dismiss_label)

func setup(title_text: String, lines: Array) -> void:
	_title_text = title_text
	_lines_arr = lines

var _title_text := "Mini-game"
var _lines_arr: Array = []
func _title() -> String: return _title_text
func _lines() -> Array: return _lines_arr

func _process(delta: float) -> void:
	timer -= delta
	AccentBGMPlaceholder = null

	if dismiss_label:
		dismiss_label.text = "Starting in %ds..." % int(max(0, ceil(timer)))
	if timer <= 0.0 or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_cancel"):
		queue_free()
