extends Node

## Shows the first-run guide once per save, the first time the world map loads.

const TUTORIAL_SCENE := preload("res://scenes/tutorial.tscn")
const SEEN_KEY := "tutorial_seen"


func _ready() -> void:
	TutorialDirector.scene_started("world")
	var data := SaveManager.load_game()
	if bool(data.get(SEEN_KEY, false)):
		# The returning keeper gets greeted if they were away long enough —
		# days, not hours. One-shot per save; the island remembers.
		var mtime := SaveManager.get_save_mtime()
		if mtime > 0:
			var days_away := int((Time.get_unix_time_from_system() - float(mtime)) / 86400.0)
			if days_away >= 2:
				TutorialDirector.nudge("welcome_back")
		return
	# Deferred so the world map (HUD, player, camera) finishes ready first.
	call_deferred("_show_guide")


func _show_guide() -> void:
	var guide := TUTORIAL_SCENE.instantiate()
	guide.title_text = "Welcome to Isle 2"
	guide.button_text = "Let's clean up"
	guide.body_text = "[font_size=24]The island runs on a recycling loop:[/font_size]\n\n" \
		+ "[color=#9fe2ff]1 · Reef Rescue[/color] (south)  Dive, grab junk, dodge fish. Hauls bank as Reef Debris.\n" \
		+ "[color=#9fe2ff]2 · Upcycle bench[/color] (east)  Sort debris into matching bins. Correct sorts become material.\n" \
		+ "[color=#9fe2ff]3 · Shop[/color] (north)  Sell material for money and buy a bigger bag.\n\n" \
		+ "[color=#9fe2ff]The trail and flow dots show the way.[/color] Complete one full circuit (Reef → Upcycle → Shop) for a $15 bonus.\n\n" \
		+ "[color=#ffd27f]Click to walk  ·  Tab / Esc opens the menu  ·  NPCs hand out quests[/color]\n" \
		+ "[color=#8fd0a0]Look for bottles along the shore — they hold stories. Blue cards are achievements.[/color]"
	guide.dismissed.connect(_on_guide_dismissed)
	# current_scene is not always assigned yet (e.g. when the world scene is
	# launched directly via F6 or a frozen run) — fall back to our own parent
	# (the world root) and finally the window root.
	var target := get_tree().current_scene
	if target == null:
		target = get_parent()
	if target == null:
		target = get_tree().root
	target.add_child(guide)


func _on_guide_dismissed() -> void:
	SaveManager.update_game({SEEN_KEY: true})
	TutorialDirector.start()
