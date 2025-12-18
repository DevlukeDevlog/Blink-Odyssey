extends Control

@onready var gold_label: Label = %GoldLabel
@onready var level_label: Label = %LevelLabel
@onready var power_label: Label = %PowerLabel
@onready var mission_label: Label = %MissionLabel
@onready var inventory_size_label: Label = %InventorySizeLabel
@onready var mission_progress_label: Label = %MissionProgressLabel
@onready var enemy_name_label: Label = %EnemyNameLabel
@onready var enemy_texture: TextureRect = %EnemyTexture
@onready var enemy_health_bar: ProgressBar = %EnemyHealthBar
@onready var mission_log_label: RichTextLabel = %MissionLogLabel

@export var mission: MissionTemplate = null

var _current_mission: MissionTemplate = null
var _current_enemy: EnemyTemplate = null
var _on_boss_battle := false
var _mission_completed := false

func _ready() -> void:
	_setup_game()

# Setups
func _setup_game() -> void:
	if (mission):
		_current_mission = mission.duplicate()
		_setup_enemy(_current_mission.mission_enemies[0])
		_update_enemy_ui()
		_update_player_ui()
		_update_game_ui()
		mission_log_label.text = ""
	else:
		printerr("No mission selected!")

func _setup_enemy(new_enemy: EnemyTemplate) -> void:
	new_enemy.Setup()
	enemy_health_bar.max_value = new_enemy.enemy_base_max_health
	enemy_health_bar.value = new_enemy.enemy_base_max_health
	enemy_texture.texture = new_enemy.enemy_texture
	enemy_name_label.text = new_enemy.enemy_name
	_current_enemy = new_enemy

# UI
func _update_enemy_ui() -> void:
	enemy_health_bar.value = _current_enemy.enemy_current_health
	if (_mission_completed):
		mission_progress_label.text = ""
		return
	
	var current_mission_progress = mission.Get_Mission_Size() - _current_mission.Get_Mission_Size() + 1
	if (_on_boss_battle):
		mission_progress_label.text = "Boss"
	else:
		mission_progress_label.text = str(current_mission_progress, " / ", mission.Get_Mission_Size())

func _update_player_ui() -> void:
	level_label.text = str("Lv: ", DataManager.current_player_lv)
	power_label.text = str("Power: ", DataManager.current_player_power)

func _update_game_ui() -> void:
	mission_label.text = _current_mission.mission_name
	gold_label.text = str(DataManager.current_player_gold, " Gold")
	inventory_size_label.text = str(DataManager.inventory.size(), " Items")

func _update_mission_log_ui(add_text: String) -> void:
	var current_log = mission_log_label.text
	mission_log_label.text = str("- ", add_text, "\n", current_log)

func _clear_ui() -> void:
	enemy_texture.texture = null
	enemy_name_label.text = ""

# Buttons
func _on_mission_select_button_pressed() -> void:
	pass # Replace with function body.

func _on_options_button_pressed() -> void:
	pass # Replace with function body.

func _on_inventory_open_button_pressed() -> void:
	pass # Replace with function body.

func _on_upgrade_button_pressed() -> void:
	pass # Replace with function body.

func _on_attack_button_pressed() -> void:
	if (_current_enemy and !_mission_completed):
		_current_enemy.Take_Damage(DataManager.current_player_power)
		
		if (_current_enemy.Is_Defeated()):
			var enemies := _current_mission.mission_enemies
			if (_on_boss_battle):
				_update_mission_log_ui(str("Boss Defeated"))
			else:
				_update_mission_log_ui(str("Defeated ", _current_enemy.enemy_name))
			_update_mission_log_ui(str("Gained ", _current_enemy.Get_Reward(), " Gold"))
			if (enemies.size() > 1):
				enemies.pop_front()
				_setup_enemy(enemies[0])
				_current_mission.mission_enemies = enemies
			elif (!_on_boss_battle):
				_setup_enemy(_current_mission.mission_boss)
				_on_boss_battle = true
			else:
				_update_mission_log_ui(str("Mission Complete"))
				_clear_ui()
				_mission_completed = true
			
			_update_game_ui()
		_update_enemy_ui()
