extends CanvasLayer

# --- Node References ---
@onready var panel: PanelContainer = $"Panel"
@onready var vbox: VBoxContainer = $"Panel/VBox"
@onready var uc_bar: ProgressBar = $"Panel/VBox/UpcycleBar"
@onready var reef_bar: ProgressBar = $"Panel/VBox/ReefBar"
@onready var main_label: Label = $"Panel/VBox/Label"
@onready var inv_label: Label = $Panel/VBox/InvLabel
@onready var money_label: Label = $Panel/VBox/MoneyLabel
@onready var hero_label: Label = $Panel/VBox/HeroTitle

var _pulse_state: float = 0.0

func _ready() -> void:
	GameState.restore()
	
	if main_label:
		main_label.modulate = Color(0.9, 0.95, 1.0, 0.9)
	GameState.harbor_hero_unlocked.connect(_refresh_hero_title)
	_refresh_hero_title()

func _process(delta: float) -> void:
	# Calculate shared variables once per frame
	var cap: int = max(1, GameState.get_inventory_capacity())
	var inv_amount: int = GameState.get_inventory_weight()
	var ratio: float = float(inv_amount) / float(cap)
	
	_update_progress_bars()
	_update_main_label(cap, inv_amount, ratio)
	_update_money_label()
	_update_inventory_label(delta, ratio, cap, inv_amount)

# --- Initialization ---

# --- Update Methods ---

func _update_progress_bars() -> void:
	if uc_bar:
		uc_bar.max_value = max(1.0, float(GameState.best_upcycle_score))
		uc_bar.value = min(uc_bar.max_value, float(GameState.upcycle_score))
		
	if reef_bar:
		reef_bar.max_value = max(10.0, float(GameState.best_reef_depth))
		reef_bar.value = min(reef_bar.max_value, float(GameState.reef_garbage))

func _update_money_label() -> void:
	if money_label:
		money_label.text = "Money: %d$" % GameState.money


## The earned title lives on the always-visible progress card, not only in the
## stats page, so the reward stays present while the player loops the island.
func _refresh_hero_title() -> void:
	if not hero_label:
		return
	hero_label.visible = GameState.is_harbor_hero()
	if hero_label.visible:
		var bonus_kg: int = GameState.HARBOR_HERO_CAPACITY_BONUS * 10
		hero_label.text = "★ Harbor Hero · +%d kg bag" % bonus_kg


func _update_main_label(cap: int, inv_amount: int, ratio: float) -> void:
	if not main_label: return
	
	var cap_state := ""
	if ratio >= 1.0:
		cap_state = "Bag FULL (%d/%d)" % [inv_amount, cap]
	elif ratio >= 0.85:
		cap_state = "Bag heavy (%d/%d)" % [inv_amount, cap]
		
	main_label.text = "Trash %d/%d kg" % [inv_amount, cap]
	if cap_state != "":
		main_label.text += " | " + cap_state

func _update_inventory_label(delta: float, ratio: float, cap: int, inv_amount: int) -> void:
	var pulse_target := 0.0
	if ratio >= 1.0:
		pulse_target = 1.0
	elif ratio >= 0.85:
		pulse_target = 0.6 + 0.4 * (0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006))
		
	# Smoothly transition the pulse state (replaces the old set_meta/get_meta usage)
	_pulse_state = lerpf(_pulse_state, pulse_target, delta * 4.0)

	inv_label.text = _get_inv_summary_text(inv_amount, cap)

func _get_inv_summary_text(current_inv: int, max_cap: int) -> String:
	var lines: Array[String] = []
	
	for key in GameState.trash_by_type.keys():
		var qty := int(GameState.trash_by_type.get(key, 0))
		if qty > 0:
			lines.append("%s %d" % [str(key), qty])
			
	if lines.is_empty():
		return " (empty)"
		
	return ", ".join(lines)
