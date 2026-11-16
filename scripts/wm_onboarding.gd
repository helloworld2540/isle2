extends Node

## Shows the first-run guide once per save, the first time the world map loads.

const TUTORIAL_SCENE := preload("res://scenes/tutorial.tscn")
const SEEN_KEY := "tutorial_seen"


func _ready() -> void:
	var data := SaveManager.load_game()
	if bool(data.get(SEEN_KEY, false)):
		return
	# Deferred so the world map (HUD, player, camera) finishes ready first.
	call_deferred("_show_guide")


func _show_guide() -> void:
	var guide := TUTORIAL_SCENE.instantiate()
	guide.title_text = "Welcome to Isle 2"
	guide.button_text = "Let's clean up"
	guide.body_text = "[font_size=17]The island runs on a recycling loop:[/font_size]\n\n" \
		+ "[color=#9fe2ff]1 · Reef Rescue[/color] (south)  Dive, grab junk, dodge fish. Hauls bank as Reef Debris.\n" \
		+ "[color=#9fe2ff]2 · Upcycle bench[/color] (east)  Sort debris into matching bins. Correct sorts become material.\n" \
		+ "[color=#9fe2ff]3 · Shop[/color] (north)  Sell material for money and buy a bigger bag.\n\n" \
		+ "[color=#ffd27f]Click to walk  ·  Tab / Esc opens the menu  ·  NPCs hand out quests[/color]"
	guide.dismissed.connect(_on_guide_dismissed)
	get_tree().current_scene.add_child(guide)


func _on_guide_dismissed() -> void:
	SaveManager.update_game({SEEN_KEY: true})
