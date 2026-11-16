extends Area2D

const RouteAdvisor := preload("res://scripts/route_advisor.gd")

## Glowing world-map pad. Standing on it transitions into a scene and remembers
## a safe spot to drop the player back onto when they return.

## How far from the pad centre the player is placed after coming back.
const RETURN_DISTANCE := 120.0

## Grace period after the world loads, so a returning player standing on the
## pad is not bounced straight back into the scene they just left.
const SPAWN_GRACE_MSEC := 900

@export var target_scene: String = ""
@export var portal_title: String = "Enter"
## Station id for the island-circuit tracker ("reef_rescue", "upcycle", "shop").
## Empty means this pad does not count toward a circuit.
@export var station_id: String = ""
@export var warn_if_empty: bool = false
@export var required_material: String = ""
@export var empty_warning: String = ""

@onready var pad: ColorRect = $Pad
@onready var label: Label = $Label
@onready var warn_label: Label = $WarnLabel

var _ignore_entries_until := 0
var _hint_tick := 0.0
## Re-derived a few times a second while the world map is open.
const RECOMMENDATION_TICK_SECONDS := 0.5
var _advice_tick := 0.0


func _ready() -> void:
	# Set synchronously: any await here can leave the pad permanently inert.
	_ignore_entries_until = Time.get_ticks_msec() + SPAWN_GRACE_MSEC
	if label:
		label.text = portal_title
	_start_idle_animation()
	_apply_requirement_state()


# Keeps the pad honest about what it needs before the player steps on it.
func _process(delta: float) -> void:
	_advice_tick += delta
	if _advice_tick >= RECOMMENDATION_TICK_SECONDS:
		_advice_tick = 0.0
		_refresh_recommendation()
	
	if not warn_if_empty:
		return
	
	_hint_tick += delta
	if _hint_tick < 0.4:
		return
	_hint_tick = 0.0
	_apply_requirement_state()


## Lights the label of the pad the HUD is recommending, so route advice shows
## up in the world and not only as a line of text in the corner.
func _refresh_recommendation() -> void:
	if not label or station_id.is_empty():
		return
	var recommended := String(RouteAdvisor.next_stop(get_tree()).get("station", "")) == station_id
	label.modulate = Color(1.0, 0.86, 0.35, 1.0) if recommended else Color(1.0, 1.0, 1.0, 0.85)


func _apply_requirement_state() -> void:
	var blocked := _warned_empty()
	
	if warn_label:
		warn_label.visible = blocked
		if blocked:
			warn_label.text = empty_warning
	
	if pad and not pad.scale.is_equal_approx(Vector2(1.12, 1.12)):
		pad.color = Color(0.45, 0.52, 0.62, 0.32) if blocked else Color(0.4, 0.749, 1.0, 0.5)


# --- Presentation ---

func _start_idle_animation() -> void:
	if pad:
		pad.color = Color(0.4, 0.749, 1.0, 0.5)
		var glow := create_tween().set_loops()
		glow.tween_property(pad, "modulate:a", 0.85, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		glow.tween_property(pad, "modulate:a", 0.5, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	if label:
		var bob := create_tween().set_loops()
		bob.tween_property(label, "position:y", label.position.y - 6.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		bob.tween_property(label, "position:y", label.position.y, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _set_hovered() -> void:
	if pad:
		pad.color = Color(0.6, 1.0, 0.6, 0.6)
		var tw := create_tween()
		tw.tween_property(pad, "scale", Vector2(1.12, 1.12), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _set_idle() -> void:
	_apply_requirement_state()
	
	if pad:
		var tw := create_tween()
		tw.tween_property(pad, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _play_enter_pulse() -> void:
	if GameSettings.reduce_motion:
		return
	
	var pulse := create_tween()
	pulse.tween_property(self, "scale", Vector2(1.8, 1.8), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pulse.tween_property(self, "scale", Vector2(0.55, 0.55), 0.07)
	pulse.tween_property(self, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# --- Flow ---

func _on_body_exited(body: Node2D) -> void:
	if not body or not body.is_in_group("player"):
		return
	
	_set_idle()


func _on_body_entered(body: Node2D) -> void:
	if not body or not body.is_in_group("player"):
		return
	
	_set_hovered()
	
	if Time.get_ticks_msec() < _ignore_entries_until:
		return
	if target_scene.is_empty():
		push_warning("wm_portal: empty target_scene on %s" % name)
		return
	if SceneTransition.is_busy():
		return
	if _warned_empty():
		_apply_requirement_state()
		return
	
	_save_return_position(body)
	# Ticked before the transition so the world map can show the updated route
	# the moment the player comes back out of this station.
	GameState.record_station_visit(station_id)
	AudioManager.play_sfx("portal")
	if label:
		label.modulate = Color(0.2, 1.0, 0.4, 1.0)
	_play_enter_pulse()
	await get_tree().create_timer(0.25).timeout
	SceneTransition.change_scene(target_scene)


func _warned_empty() -> bool:
	if not warn_if_empty:
		return false
	if required_material.is_empty():
		return GameState.get_inventory_weight() <= 0
	return int(GameState.trash_by_type.get(required_material, 0)) <= 0


# Save a spot just outside the pad so the player walks back onto the map
# instead of reappearing on top of the trigger.
func _save_return_position(player: Node2D) -> void:
	var away := player.global_position - global_position
	if away.length() < 1.0:
		away = Vector2.DOWN
	
	SaveManager.save_player_position(global_position + away.normalized() * RETURN_DISTANCE)
