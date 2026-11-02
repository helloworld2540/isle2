extends CanvasLayer

@export var title_text: String = "Tutorial"
@export var body_text: String = ""
@export var button_text: String = "Start!"
@export var art_texture: Texture2D

@onready var backdrop: ColorRect = $"Backdrop"
@onready var title: Label = $"Title"
@onready var body: Label = $"Body"
@onready var btn: Button = $"Button"
@onready var art: Sprite2D = $"Art"

func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	if title:
		title.text = title_text
	if body:
		body.text = body_text
	if btn:
		btn.text = button_text
		btn.pressed.connect(_on_dismiss)
	if art:
		art.texture = art_texture
	get_tree().paused = true

func _on_dismiss() -> void:
	get_tree().paused = false
	queue_free()
