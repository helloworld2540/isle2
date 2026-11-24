extends CanvasLayer

## The "About" card the island never asks for. A short, honest ledger of
## who made what — the game earned its own page, same as the keeper\n## earned the almanac. Lives behind the island menu's About button.

signal closed

@export_multiline var credits: String = ""

@onready var body: RichTextLabel = $Margin/Panel/Column/BodyScroll/VBox/Body


func _ready() -> void:
	visible = false
	if body and credits.is_empty():
		body.text = _default_credits()
		if GameSettings.hide_tide:
			body.text += "
[color=#9fd0e8]— The tide is hidden —[/color]
[color=#8fb6c9]You chose to read the water without its labels.[/color]"
		if GameState.is_achievement_unlocked("island_steward"):
			body.text += "
[color=#ffd27f]— Every achievement earned —[/color]
[color=#c9a86c]The island is clean because you cleaned it. Well done.[/color]"


## The text, if nothing else was wired up. Kept short — it is a keeper's
## page, not a novel.
func _default_credits() -> String:
	return "[center]" \
		+ "A cozy single-player trash-recycling adventure.\n\n" \
		+ "[color=#9fd0e8]Built in Godot 4.7 with GDScript.[/color]\n" \
		+ "[color=#9fd0e8]Art and world: Krita-drawn, hand-built.[/color]\n" \
		+ "[color=#9fd0e8]Sound: music by Kevin Macleoud.[/color]\n" \
		+ "[color=#8fa6b3]Built with heavy tooling assistance — AI in the loop for design and code.[/color]\n" \
		+ "[color=#8fa6b3]Version " + Version.VERSION + "  ·  Linux  ·  Web  ·  Android.[/color]\n" \
		+ "[/center]"


func present() -> void:
	visible = true
	AudioManager.play_sfx("pickup", 0.9)


func _on_close_pressed() -> void:
	visible = false
	AudioManager.play_sfx("return")
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_ENTER:
			_on_close_pressed()
