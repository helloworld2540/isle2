extends CanvasLayer

## The "About" card the island never asks for. A short, honest ledger of
## who made what — the game earned its own page, same as the keeper\n## earned the almanac. Lives behind the island menu's About button.

signal closed

@export_multiline var credits: String = ""

@onready var body: RichTextLabel = $Margin/Column/Panel/VBox/BodyScroll/Body


func _ready() -> void:
	visible = false
	if body and credits.is_empty():
		body.text = _default_credits()
		if GameState.is_achievement_unlocked("island_steward"):
			body.text += "
[color=#ffd27f]— The keeper who kept it all —[/color]
[color=#c9a86c]The island is tidy because you made it so. Walk proud.[/color]"


## The text, if nothing else was wired up. Kept short — it is a keeper's
## page, not a novel.
func _default_credits() -> String:
	return "[center][font_size=22][color=#ffd27f]Trash Island[/color][/font_size]\n\n" \
		+ "A cozy single-player trash-recycling adventure.\n\n" \
		+ "[color=#9fd0e8]Built in Godot 4. GDScript. No engine plugins changed.[/color]\n" \
		+ "[color=#9fd0e8]Art and world: Krita-drawn, hand-built, slightly wet.[/color]\n" \
		+ "[color=#9fd0e8]Sound: placeholder library; ambience mixed in-game.[/color]\n" \
		+ "[color=#9fd0e8]Writing: a keeper's tide, a dockhand, and a man on the far point.[/color]\n\n" \
		+ "[color=#8fa6b3]All rights reserved — see LICENSE\n[/color]" \
		+ "[color=#c9a86c]The far point is only the beginning.[/color]\n" \
		+ "[color=#8fa6b3]Built with heavy tooling assistance — AI in the loop for design, code, art and words, defended by a green harness.[/color]\n" \
		+ "[color=#8fa6b3]Version 1.1.0  ·  Linux  ·  Web  ·  Android\nAll three verified before the day the box opened.[/color]\n" \
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
