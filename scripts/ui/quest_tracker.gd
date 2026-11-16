extends CanvasLayer

## Bottom-left quest tracker: lists the quests NPCs are currently offering and
## how close the bag is to fulfilling them.

const REFRESH_SECONDS := 0.4
const READY_COLOR := Color(1.0, 0.86, 0.35, 1.0)
const ACTIVE_COLOR := Color(0.82, 0.92, 1.0, 0.95)
const FLASH_COLOR := Color(1.0, 1.0, 0.85, 1.0)

@onready var panel: PanelContainer = $Panel

var _tick := REFRESH_SECONDS
## Previous "ready" state per quest key (npc+tier) for edge detection.
var _prev_ready: Dictionary = {}
## First refresh after boot just records the baseline; no chimes.
var _primed := false


func _ready() -> void:
	_refresh()


func _process(delta: float) -> void:
	_tick += delta
	if _tick < REFRESH_SECONDS:
		return
	_tick = 0.0
	_refresh()


func _refresh() -> void:
	var quests := _collect_quests()
	var rows := _rows()
	
	panel.visible = not quests.is_empty()
	for i in range(rows.size()):
		var row: Label = rows[i]
		if i >= quests.size():
			row.visible = false
			continue
		
		var quest: Dictionary = quests[i]
		row.visible = true
		row.text = "%s · %d/%d %s" % [quest.get("npc", "?"), quest.get("have", 0), quest.get("amount", 0), quest.get("material", "")]
		var ready := bool(quest.get("ready", false))
		row.modulate = READY_COLOR if ready else ACTIVE_COLOR
		
		var key := "%s#%d" % [quest.get("npc", "?"), int(quest.get("tier", 1))]
		if ready and _primed and not _prev_ready.get(key, false):
			_on_quest_ready(row)
		_prev_ready[key] = ready
	
	_primed = true


## A row just became turn-in-able: flourish SFX + a quick brighten pulse.
func _on_quest_ready(row: Label) -> void:
	AudioManager.play_sfx("combo", 1.15)
	if GameSettings.reduce_motion:
		return
	var flash := create_tween()
	row.modulate = FLASH_COLOR
	flash.tween_property(row, "modulate", READY_COLOR, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _collect_quests() -> Array:
	var quests: Array = []
	for npc in get_tree().get_nodes_in_group("npc"):
		if npc.has_method("get_active_quest"):
			var quest: Dictionary = npc.get_active_quest()
			if not quest.is_empty():
				quests.append(quest)
	return quests


func _rows() -> Array:
	var result: Array = []
	for child in $Panel/VBox.get_children():
		if child is Label and String(child.name).begins_with("Row"):
			result.append(child)
	return result
