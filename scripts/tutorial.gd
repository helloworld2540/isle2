extends CanvasLayer

@export var title_text: String = "Tutorial"
@export var body_text: String = ""
@export var button_text: String = "Start!"
@export var art_texture: Texture2D

@onready var backdrop: ColorRect = get_node_or_null("Backdrop")
@onready var title: Label = get_node_or_null("Title")
@onready var body: Label = get_node_or_null("Body")
@onready var btn: Button = get_node_or_null("Button")
@onready var art: Sprite2D = get_node_or_null("Art")

func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	if is_instance_valid(title):
		title.text = title_text
	if is_instance_valid(body):
		body.text = body_text
	if is_instance_valid(btn):
		btn.text = button_text
		btn.pressed.connect(_on_dismiss)
	if is_instance_valid(art):
		art.texture = art_texture
	get_tree().paused = true

func _on_dismiss() -> void:
	get_tree().paused = false
	queue_free()
