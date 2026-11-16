extends Node2D
class_name Upcycle

const NOTIFICATION_QUEUE := preload("res://scenes/ui/notification_queue.tscn")
const FxSparkle := preload("res://scripts/fx_sparkle.gd")
const FLOATING_TEXT_SCENE := preload("res://scenes/ui/floating_text.tscn")

const MATERIALS: Array[String] = ["Polyethylene", "Glass", "Polypropylene", "Nylon"]
const TRASH_SPRITES: Array[String] = [
	"trash_bottle.png",
	"trash_plasticblue.png",
	"trash_plasticwhite.png",
	"trash_net.png",
	"trash_straw.png"
]

@export_group("Grid Settings")
@export var grid_size: float = 160.0
@export var min_swipe_distance: float = 30.0
@export var min_grid_x: int = 1
@export var max_grid_x: int = 5
@export var min_grid_y: int = 0
@export var max_grid_y: int = 2

@export_group("Difficulty Tuning")
@export var base_belt_speed: float = 75.0
@export var max_belt_speed: float = 180.0
@export var max_belt_items: int = 10
@export var base_spawn_interval: float = 2.75
@export var min_spawn_interval: float = 0.75

# Game State
var score: int = 0
var sort_streak: int = 0
var _peak_streak: int = 0  ## Longest streak reached this run, for the summary card.
var _sorted_count: int = 0
var _misses: int = 0  ## Failed sorts / belt-burned items this run — 0 with a real haul earns the Flawless tag.
var _recycled_total: int = 0
var _recycled_by_mat: Dictionary = {
	"Polyethylene": 0,
	"Glass": 0,
	"Polypropylene": 0,
	"Nylon": 0
}
var _gained_by_mat: Dictionary = {}

# Entity State
var carried_item: Node2D = null
var spawn_timer: float = 0.0
var belt_speed: float = 80.0
var _belt_banner_shown: bool = false
var _leaving: bool = false
var _items_fed: int = 0  ## Belt items spawned this run — 0 means the bench visit never really happened.
var _shift_exhausted: bool = false  ## No reef debris left to feed the belt.
var _low_debris_warned: bool = false  ## One-shot "running low" callout.
var _best_beaten: bool = false  ## One-shot per run, when the player passes the saved best.
var _prev_best: int = 0  ## best_upcycle_score captured at run start.

# Interaction & UI State
var drag_start_pos: Vector2 = Vector2.ZERO
var is_dragging: bool = false
var move_tween: Tween = null
var _hud_queue: Node = null

# Node References
@onready var ui: CanvasLayer = $"UI"
@onready var score_label: Label = $"UI/HUDStats/ScoreLabel"
@onready var streak_label: Label = $"UI/HUDStats/StreakLabel"
@onready var recycled_label: Label = $"UI/HUDStats/RecycledLabel"
@onready var belt_label: Label = $"UI/HUDStats/BeltLabel"
@onready var debris_label: Label = $"UI/HUDStats/DebrisLabel"
@onready var return_btn: Button = $"UI/ReturnToMapButton"
@onready var player: CharacterBody2D = $"Player"
@onready var conveyor: Path2D = $"Conveyor"
@onready var fire: Area2D = $"Fire"
@onready var bins: Node2D = $"Bins"
@onready var game_over_canvas: CanvasLayer = $"GameOverCanvas"
@onready var go_title: Label = $"GameOverCanvas/GameOverPanel/VBox/Title"
@onready var go_body: Label = $"GameOverCanvas/GameOverPanel/VBox/Body"
@onready var go_return_btn: Button = $"GameOverCanvas/GameOverPanel/VBox/ReturnButton"
@onready var highlight_node: Node2D = $"highlight_node"
@onready var arrow: Polygon2D = $"Arrow"

func _ready() -> void:
	TutorialDirector.scene_started("upcycle")
	if go_return_btn:
		go_return_btn.pressed.connect(_game_over_leave)
	_setup_bins()
	_setup_audio()
	_prev_best = GameState.best_upcycle_score
	# Stamp the personal stake onto the briefing card while the player is reading it.
	var intro := get_node_or_null("MinigameIntro")
	if intro:
		var runs := GameState.upcycle_runs
		if runs > 0 or GameState.best_upcycle_score > 0:
			intro.set_stat_line("Best score: %d  ·  Runs finished: %d" % [GameState.best_upcycle_score, runs])
		else:
			intro.set_stat_line("First shift — nobody holds the record yet.")
	
	if player:
		player.global_position = _snap(player.global_position)
		
	if return_btn:
		return_btn.pressed.connect(_leave_to_map)
		
	if fire and not fire.body_entered.is_connected(_on_fire_body_entered):
		fire.body_entered.connect(_on_fire_body_entered)
		
	_update_ui()

func _process(delta: float) -> void:
	_process_conveyor(delta)
	_process_spawning(delta)
	_process_carried_item()
	_process_highlight()
	_update_ui()

# --- Process Loop Helpers ---

func _process_conveyor(delta: float) -> void:
	if not conveyor: return
	
	belt_speed = clampf(base_belt_speed + float(score) * 0.3, base_belt_speed, max_belt_speed)
	
	for follow in conveyor.get_children():
		if follow.get_child_count() == 0:
			follow.queue_free()
			continue
			
		var item := follow.get_child(0) as Node2D
		if not item or not item.get_meta("on_belt", false):
			continue
			
		follow.progress += belt_speed * delta
		if follow.progress_ratio >= 1.0:
			item.set_meta("on_belt", false)
			burn_item(item)

func _process_spawning(delta: float) -> void:
	# The bench only runs while there is debris to convert. Once the pile is
	# empty the shift winds down gracefully: stop feeding the belt, let the
	# player finish whatever is already on it, then close the run. Ending
	# instantly used to strand half-sorted items on the conveyor.
	if int(GameState.trash_by_type.get("Reef Debris", 0)) <= 0:
		_process_shift_wind_down()
		return
	
	spawn_timer += delta
	var remaining := int(GameState.trash_by_type.get("Reef Debris", 0))
	if remaining <= 5 and not _low_debris_warned:
		_low_debris_warned = true
		_notify_queue("%d Reef Debris left - clear the belt!" % remaining, Color(1.0, 0.84, 0.35, 1.0), 1.8)
	
	var belt_count := _count_belt_items()
	if belt_count < 5:
		_belt_banner_shown = false
		
	var interval := clampf(base_spawn_interval - float(score) * 0.03, min_spawn_interval, base_spawn_interval)
	interval = clampf(interval + randf_range(-0.25, 0.25), 1.0, 5.5)
	
	if spawn_timer >= interval:
		spawn_timer = 0.0
		if belt_count < max_belt_items:
			spawn_item()
			if belt_count + 1 >= 5 and not _belt_banner_shown:
				_belt_banner_shown = true
				_spawn_streak_banner()


## Called every frame once the debris pile is empty. The run ends only when
## the belt is clear and nothing is in hand, so the last items still count.
func _process_shift_wind_down() -> void:
	if not _shift_exhausted:
		_shift_exhausted = true
		spawn_timer = 0.0
		if _count_belt_items() > 0 or carried_item != null:
			_notify_queue("Last of the debris - clear the belt!", Color(1.0, 0.84, 0.35, 1.0), 1.8)
	
	if _count_belt_items() == 0 and carried_item == null:
		_game_over_summary(true)

func _process_carried_item() -> void:
	if not carried_item:
		carried_item = null
		_hide_arrow()
		return
		
	var deposit_bin := _find_deposit_bin(carried_item)
	carried_item.z_index = 30
	
	var bob := sin(Time.get_ticks_msec() * 0.005) * 2.0
	if deposit_bin:
		carried_item.global_position = deposit_bin.global_position + Vector2(0, -34 + bob)
	else:
		var base_pos = player.global_position if player else carried_item.global_position
		carried_item.global_position = base_pos + Vector2(0, -22 + bob)
		
	_update_arrow(carried_item, deposit_bin)

func _process_highlight() -> void:
	if not highlight_node: return
	
	var target := _get_valid_interaction_target()
	highlight_node.visible = target != null
	if target:
		highlight_node.global_position = _snap(target.global_position)

# --- Initialization Helpers ---

func _setup_bins() -> void:
	if not bins:
		return
	
	var max_bins: int = min(bins.get_child_count(), MATERIALS.size())
	for i in range(max_bins):
		var bin := bins.get_child(i)
		if not bin:
			continue
		
		bin.set_meta("material", MATERIALS[i])
		var label: Label = bin.get_node_or_null("MaterialLabel")
		if label:
			label.text = str(bin.name)
			label.modulate = bin.modulate
			label.global_position = bin.global_position


func _setup_audio() -> void:
	AudioManager.play_bgm("upcycle")

# --- Spawning & Mechanics ---

func spawn_item() -> void:
	if int(GameState.trash_by_type.get("Reef Debris", 0)) <= 0:
		_game_over_summary()
		return
		
	GameState.trash_by_type["Reef Debris"] = int(GameState.trash_by_type.get("Reef Debris", 0)) - 1
	GameState._recompute_inventory()
	GameState._persist()
	_items_fed += 1
	
	var item: Node2D = preload("res://scenes/u_trash.tscn").instantiate()
	var follow := load("res://scenes/ui/path_follow2_d.tscn").instantiate() as PathFollow2D
	
	follow.loop = false
	follow.progress = 0.0
	if conveyor:
		conveyor.add_child(follow)
	
	follow.add_child(item)
	item.position = Vector2.ZERO
	item.set_meta("on_belt", true)
	
	if item.has_method("init"):
		item.init(str(TRASH_SPRITES.pick_random()))
		
	item.modulate.a = 0.0
	item.create_tween().tween_property(item, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	var bob := item.create_tween().set_loops()
	bob.tween_property(item, "position:y", item.position.y - 6.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(item, "position:y", item.position.y + 6.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func burn_item(item: Node2D) -> void:
	_misses += 1
	sort_streak = 0
	AudioManager.play_sfx("sort_bad", 0.88)
	
	var ap: AnimationPlayer = item.get_node_or_null("AnimationPlayer")
	if ap:
		ap.play("suck")
		if not ap.animation_finished.is_connected(item.queue_free):
			ap.animation_finished.connect(func(_anim_name): item.queue_free())
	else:
		item.queue_free()
	_update_ui()

# --- Input & Interaction ---

func _input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch or event is InputEventMouseButton): return
	
	if event.pressed:
		drag_start_pos = event.position
	else:
		var drag_vector: Vector2 = event.position - drag_start_pos
		if drag_vector.length() < min_swipe_distance:
			_interact()
		else:
			_handle_swipe_movement(drag_vector)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		AudioManager.play_sfx("return")
		_leave_to_map()

func _handle_swipe_movement(drag_vector: Vector2) -> void:
	if not player: return
	
	var dir := Vector2.ZERO
	if abs(drag_vector.x) > abs(drag_vector.y):
		dir = Vector2(-1, 0) if drag_vector.x < 0 else Vector2(1, 0)
	else:
		dir = Vector2(0, -1) if drag_vector.y < 0 else Vector2(0, 1)
		
	var target_pixel_pos := _snap(player.global_position + dir * grid_size)
	var target_grid_pos := Vector2(
		round((target_pixel_pos.x - grid_size / 2.0) / grid_size),
		round((target_pixel_pos.y - grid_size / 2.0) / grid_size)
	)
	
	if _is_valid_move(target_grid_pos):
		if move_tween and move_tween.is_valid():
			move_tween.kill()
		move_tween = create_tween()
		var move_time: float = max(0.05, 0.08 / max(0.5, GameState.get_move_speed_multiplier()))
		move_tween.tween_property(player, "global_position", target_pixel_pos, move_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _interact() -> void:
	var target := _get_valid_interaction_target()
	if not target: return
	
	if carried_item == null:
		_pick_up_item(target)
	else:
		_drop_off_item(target)

func _pick_up_item(target: Node2D) -> void:
	var parent := target.get_parent()
	if parent is PathFollow2D:
		var old_gpos := target.global_position
		target.reparent(self)
		target.global_position = old_gpos
		parent.queue_free()
		
	carried_item = target
	target.set_meta("on_belt", false)
	AudioManager.play_sfx("pickup")

func _drop_off_item(target: Node2D) -> void:
	var mat: String = str(carried_item.get_meta("material"))
	var bin_mat: String = str(target.get_meta("material"))
	
	if mat == bin_mat:
		_process_successful_sort(mat, target.global_position)
	else:
		_process_failed_sort()
		
	carried_item.queue_free()
	carried_item = null

## Personal-best chase, live on the bench: once per run, the moment the current
## score passes the saved best, fire a gold callout and punch the readout — the
## same payoff the reef run gets at the summary card.
func _check_best_beaten() -> void:
	if _best_beaten or _prev_best <= 0:
		return
	if score > _prev_best:
		_best_beaten = true
		_notify_queue("NEW BEST — %d!" % score, Color(0.94, 0.95, 0.42, 1.0), 1.6)
		_play_combo_feedback()


func _process_successful_sort(mat: String, bin_pos: Vector2) -> void:
	TutorialDirector.notify("sorted")
	score += 1
	sort_streak += 1
	_peak_streak = maxi(_peak_streak, sort_streak)
	_sorted_count += 1
	_check_best_beaten()
	_recycled_total += 1
	_recycled_by_mat[mat] = _recycled_by_mat.get(mat, 0) + 1
	
	AudioManager.play_sfx("sort_ok", 1.0 + min(float(sort_streak), 15.0) * 0.03)
	
	var item_size: int = int(carried_item.get("size")) if carried_item.get("size") != null else 1
	var gained: int = GameState.add_trash_type_weighted(mat, item_size)
	_gained_by_mat[mat] = int(_gained_by_mat.get(mat, 0)) + gained
	if gained < item_size:
		AudioManager.play_sfx("empty_inventory")
		_notify_queue("%d over inventory cap" % (item_size - gained), Color(0.95, 0.5, 0.35, 1.0), 1.4)
		
	if sort_streak % 5 == 0:
		_process_combo_milestone()
		_spawn_combo_trail(bin_pos)
		
	_spawn_bin_sparkle(bin_pos)
	AudioManager.play_sfx("combo")

func _process_failed_sort() -> void:
	AudioManager.play_sfx("sort_bad", 0.92)
	_misses += 1
	sort_streak = 0
	_shake_wrong_sort()

func _process_combo_milestone() -> void:
	score += 5
	_check_best_beaten()
	_notify_queue("Combo +5! (%dx5)" % int(sort_streak / 5), Color(1.0, 0.85, 0.3, 1.0), 1.2)
	_play_combo_feedback()
	
	var is_best: bool = score > GameState.best_upcycle_score
	var msg: String = "NEW BEST %d!" % score if is_best else "Combo milestone! +5"
	var col: Color = Color(0.9, 0.95, 0.4, 1.0) if is_best else Color(0.7, 1.0, 0.6, 1.0)
	
	_notify_queue(msg, col, 1.4)
	if is_best:
		AudioManager.play_sfx("combo")

# --- Grid & Spatial Logic ---

func _get_valid_interaction_target() -> Node2D:
	if not player: return null
	
	var player_grid := _snap(player.global_position)
	var nearest: Node2D = null
	var best_dist: float = INF
	
	if carried_item == null:
		if conveyor:
			for follow in conveyor.get_children():
				if follow.get_child_count() == 0: continue
				var item := follow.get_child(0) as Node2D
				if not item or not item.get_meta("on_belt", false): continue
				
				var item_grid := _snap(item.global_position)
				var diff := (item_grid - player_grid).abs()
				if diff.x <= grid_size and diff.y <= grid_size:
					var d := item.global_position.distance_to(player.global_position)
					if d < best_dist:
						best_dist = d
						nearest = item
	else:
		if bins:
			for bin in bins.get_children():
				var bin_grid := _snap(bin.global_position)
				var diff := (bin_grid - player_grid).abs()
				if diff.x <= grid_size and diff.y <= grid_size:
					var d: float = bin.global_position.distance_to(player.global_position)
					if d < best_dist:
						best_dist = d
						nearest = bin
						
	return nearest

func _find_deposit_bin(item: Node2D) -> Node2D:
	if not bins or not player: return null
	
	var mat: String = str(item.get_meta("material"))
	var player_grid := _snap(player.global_position)
	var nearest: Node2D = null
	var best_dist: float = INF

	for bin in bins.get_children():
		if str(bin.get_meta("material")) != mat: continue
		
		# Only target the bin when the player is grid-adjacent to it
		var bin_grid := _snap(bin.global_position)
		var diff := (bin_grid - player_grid).abs()
		if diff.x <= grid_size and diff.y <= grid_size:
			var d: float = bin.global_position.distance_to(player.global_position)
			if d < best_dist:
				best_dist = d
				nearest = bin
			
	return nearest

func _is_valid_move(grid_pos: Vector2) -> bool:
	var x: int = int(grid_pos.x)
	var y: int = int(grid_pos.y)
	
	if x < min_grid_x or x > max_grid_x or y < min_grid_y or y > max_grid_y:
		return false
	if y == 0 and x != 1:
		return false # Prevent walking over the conveyor belt
	return true

func _snap(pos: Vector2) -> Vector2:
	var offset := Vector2(grid_size / 2.0, grid_size / 2.0)
	return (pos - offset).snapped(Vector2(grid_size, grid_size)) + offset

func _count_belt_items() -> int:
	var n: int = 0
	if conveyor:
		for follow in conveyor.get_children():
			if follow.get_child_count() > 0: n += 1
	return n

# --- Visual Effects & UI ---

func _update_ui() -> void:
	if score_label:
		# Ghost-best mark: the record stays visible mid-run so the chase is a
		# visible race rather than a surprise at the summary card.
		var best_line := " (best %d)" % maxi(_prev_best, GameState.best_upcycle_score) if GameState.best_upcycle_score > 0 else ""
		score_label.text = "Score: %d%s" % [score, best_line]
	if streak_label:
		streak_label.text = "Streak: %d (best %d)" % [sort_streak, GameState.best_sort_streak]
	if recycled_label:
		var parts: Array[String] = []
		for m in MATERIALS:
			parts.append("%s:%d" % [str(GameState.TRASH_SHORT.get(m, m.substr(0, 4))), int(_recycled_by_mat.get(m, 0))])
		recycled_label.text = "Recycled %d | %s" % [_recycled_total, " ".join(parts)]
	if belt_label:
		belt_label.text = "Belt: %d/%d" % [_count_belt_items(), max_belt_items]
	if debris_label:
		var debris := int(GameState.trash_by_type.get("Reef Debris", 0))
		debris_label.text = "Reef Debris banked: %d" % debris
		# The bank is invisible everywhere else, so the line itself carries the
		# warning: pale amber when four-to-five are left, red when the pile is dry.
		if debris <= 0:
			debris_label.modulate = Color(1.0, 0.5, 0.5, 1.0)
		elif debris <= 5:
			debris_label.modulate = Color(1.0, 0.85, 0.35, 1.0)
		else:
			debris_label.modulate = Color(0.88, 0.94, 1.0, 1.0)

func _update_arrow(item: Node2D, bin: Node2D) -> void:
	if not arrow: return
	if not bin:
		arrow.visible = false
		return
		
	arrow.visible = true
	var pulse := 1.0 + 0.12 * (0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.008))
	arrow.scale = Vector2(pulse, pulse)
	
	var from_pos: Vector2 = player.global_position if player else (item.global_position if item else Vector2.ZERO)
	var to_pos: Vector2 = bin.global_position
	
	arrow.global_position = from_pos + (to_pos - from_pos).normalized() * min(grid_size * 1.5, from_pos.distance_to(to_pos) * 0.6)
	arrow.rotation = (to_pos - from_pos).angle() - PI / 2.0

func _hide_arrow() -> void:
	if arrow: arrow.visible = false

## Combo milestone juice: punch the score readout. The CanvasLayer can't be
## scaled or modulated (it's not a CanvasItem), so the feedback lives on the
## score label itself.
func _play_combo_feedback() -> void:
	if not score_label:
		return
	score_label.pivot_offset = score_label.size * 0.5
	score_label.scale = Vector2(1.35, 1.35)
	score_label.modulate = Color(1.0, 1.0, 0.62, 1.0)
	var tw := create_tween()
	tw.tween_property(score_label, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(score_label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.32)

func _shake_wrong_sort() -> void:
	if GameSettings.reduce_motion:
		return
	
	var base_pos: Vector2 = position
	var tw := create_tween()
	for i in range(6):
		tw.tween_property(self, "position", base_pos + Vector2(randf_range(-8.0, 8.0), randf_range(-6.0, 6.0)), 0.03)
	tw.tween_property(self, "position", base_pos, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _spawn_bin_sparkle(at: Vector2) -> void:
	FxSparkle.burst(self, at, Color(0.7, 1.0, 0.6, 1.0), {"amount": 12 + min(10, sort_streak / 5), "lifetime": 0.4, "vel_min": 30.0, "vel_max": 90.0, "gravity": 60.0})

## Gold trail that races along the belt on every fifth consecutive sort. It is
## a chain of short bursts rather than one big bang, so the milestone reads as
## movement and matches the belt's left-to-right flow. Uses the authored
## particle scene; no nodes are constructed in code.
func _spawn_combo_trail(bin_pos: Vector2) -> void:
	if GameSettings.reduce_motion:
		return
	var player_pos: Vector2 = player.global_position if player else bin_pos + Vector2(-200.0, 0.0)
	var dir := Vector2(signf(bin_pos.x - player_pos.x), 0.0)
	if dir.x == 0.0:
		dir.x = 1.0
	for i in range(4):
		# Emitters are pre-staged with emitting=false so the milestone sweeps
		# left-to-right instead of popping all at once; free deferred.
		var p := FxSparkle.burst(self, bin_pos - dir * (34.0 * float(i)) + Vector2(0.0, randf_range(-10.0, 4.0)), Color(1.0, 0.86, 0.35, 1.0), {"explosiveness": 0.75, "amount": 8, "lifetime": 0.35, "vel_min": 20.0, "vel_max": 62.0, "gravity": 55.0, "spread": 40.0})
		if p:
			p.emitting = false
			p.direction = Vector2(dir.x, -0.35)
			var tw := create_tween()
			tw.tween_interval(0.05 * float(i))
			tw.tween_callback(func(): p.emitting = true)


func _spawn_streak_banner() -> void:
	if not ui:
		return
	
	var lbl := FLOATING_TEXT_SCENE.instantiate()
	lbl.position = Vector2(320, 14)
	lbl.rise_distance = 6.0
	lbl.hold_time = 0.7
	lbl.fade_out_time = 0.45
	lbl.punch_scale = 1.25
	ui.add_child(lbl)
	lbl.present("FIVE ON THE BELT!", Color(0.7, 0.95, 1.0, 1.0), 28)

# --- Subsystems ---

func _on_fire_body_entered(body: Node2D) -> void:
	var parent_item := body.get_parent() if body else null
	if parent_item and parent_item.has_meta("on_belt"):
		burn_item(parent_item)

func _notify_queue(text: String, col: Color = Color(0.85, 1.0, 0.6, 1.0), duration: float = 1.2) -> void:
	if not _hud_queue:
		_hud_queue = NOTIFICATION_QUEUE.instantiate()
		add_child(_hud_queue)
	_hud_queue.push(text, col, duration)

# --- Game Over & Return Flows ---

## Ends the run. `clean_finish` is true when the shift ran dry and every last
## item on the belt was processed — that reads as a completed shift, not a loss.
func _game_over_summary(clean_finish: bool = false) -> void:
	if _leaving: return
	_leaving = true

	# An empty-pile visit that never fed the belt is not a run: don't bank a
	# phantom "SHIFT COMPLETE" recap, don't count it in run stats, and don't
	# let it trip bench achievements — just send the player reef-side.
	var empty_shift := _items_fed == 0 and score == 0 and _sorted_count == 0

	var prev_best := GameState.best_upcycle_score
	if not empty_shift:
		GameState.record_sort_streak(_peak_streak)
		GameState.record_upcycle(score, _misses == 0 and _sorted_count >= 5)
		_record_run_card(prev_best)
	
	AudioManager.play_sfx("shift_complete" if clean_finish else "sort_bad")
	
	if game_over_canvas and go_body:
		if clean_finish:
			if go_title:
				go_title.text = "SHIFT COMPLETE"
				go_title.modulate = Color(1.0, 0.86, 0.35, 1.0)
			if _sorted_count > 0:
				go_body.text = "Belt clear - all debris processed\nScore: %d\nSorted %d items" % [score, _sorted_count]
				if _misses == 0 and _sorted_count >= 5:
					go_body.text += "\nFLAWLESS SHIFT - not a single miss"
			else:
				go_body.text = "No Reef Debris banked\nDive at Reef Rescue first."
		else:
			go_body.text = "Out of Reef Debris\nScore: %d\nSorted %d items" % [score, _sorted_count]
			if _misses == 0 and _sorted_count >= 5:
				go_body.text += "\nFLAWLESS SHIFT - not a single miss"
		game_over_canvas.layer = 110
		game_over_canvas.visible = true
	else:
		_show_return_summary()

func _leave_to_map() -> void:
	_game_over_summary()


## Hand-off card for the world map: what this run produced and where to go next.
## Mirrors the reef dive recap — runs are numbered "chapters" with a flavour
## title earned by the longest streak inside the run.
func _record_run_card(prev_best: int) -> void:
	var runs := GameState.upcycle_runs
	var flavor := "Belt Survived"
	if _peak_streak >= 15:
		flavor = "Golden Gloves"
	elif _peak_streak >= 10:
		flavor = "Hot Streak"
	elif _peak_streak >= 5:
		flavor = "Steady Hands"
	elif _peak_streak >= 1:
		flavor = "Belt Sorted"
	
	var material_parts: Array[String] = []
	for material in MATERIALS:
		var gained := int(_gained_by_mat.get(material, 0))
		if gained > 0:
			material_parts.append("%s +%d" % [material, gained])
	
	var lines: Array[String] = [
		"Score %d · %d sorted · peak streak %d" % [score, _sorted_count, _peak_streak],
	]
	if _misses == 0 and _sorted_count >= 5:
		lines.append("✦ FLAWLESS SHIFT — not a single miss")
	if score > prev_best:
		lines.append("★ New personal best — %d (was %d)" % [score, prev_best])
	lines.append(", ".join(material_parts) if not material_parts.is_empty() else "No materials sorted this run")
	
	var debris := int(GameState.trash_by_type.get("Reef Debris", 0))
	var hint := ""
	if debris > 0:
		hint = "%d Reef Debris still banked - keep sorting." % debris
	elif GameState.get_inventory_weight() > 0:
		hint = "Sell your materials at the Shop."
	else:
		hint = "Collect more debris at Reef Rescue."
	
	GameState.record_run("upcycle", "Bench Run № %d — %s" % [runs, flavor], lines, hint)

func _game_over_leave() -> void:
	if game_over_canvas:
		game_over_canvas.visible = false
		
	AudioManager.play_sfx("return")
	SceneTransition.change_scene("res://scenes/world.tscn")

func _show_return_summary() -> void:
	if not ui:
		return
	
	var lbl := FLOATING_TEXT_SCENE.instantiate()
	lbl.position = Vector2(240, 120)
	lbl.rise_distance = 0.0
	lbl.hold_time = 0.9
	ui.add_child(lbl)
	lbl.present("Run complete: Score %d | Sorted %d items" % [score, _sorted_count], Color(0.85, 1.0, 0.6, 1.0), 24)
	
	var tw := create_tween()
	tw.tween_interval(0.9)
	tw.tween_callback(func():
		AudioManager.play_sfx("return")
		SceneTransition.change_scene("res://scenes/world.tscn")
	)
