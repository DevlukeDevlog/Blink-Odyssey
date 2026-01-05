class_name MainScene
extends Control

# Game UI
@onready var gold_label: Label = %GoldLabel
@onready var mission_label: Label = %MissionLabel
@onready var inventory_size_label: Label = %InventorySizeLabel

# Player's UI
@onready var level_label: Label = %LevelLabel
@onready var power_label: Label = %PowerLabel
@onready var idle_label = %IdleLabel
@onready var gear_container = %GearContainer

# Enemy's UI
@onready var mission_progress_label: Label = %MissionProgressLabel
@onready var enemy_name_label: Label = %EnemyNameLabel
@onready var enemy_texture: TextureRect = %EnemyTexture
@onready var enemy_health_bar: ProgressBar = %EnemyHealthBar
@onready var weakness_container = %WeaknessContainer
@onready var boss_timer_bar = %BossTimerBar
@onready var boss_timer: Timer = %BossTimer
@onready var boss_timer_label = %BossTimerLabel
@onready var boss_timer_bar_container = %BossTimerBarContainer
@onready var rematch_boss_button = %RematchBossButton

# Mission UI
@onready var mission_log_label: RichTextLabel = %MissionLogLabel
@onready var missions_container = %MissionsContainer
@onready var mission_select_button = %MissionSelectButton

# Inventory UI
@onready var selected_equipment_label = %SelectedEquipmentLabel
@onready var selected_equipment_information_label = %SelectedEquipmentInformationLabel
@onready var inventory_open_button = %InventoryOpenButton
@onready var equipment_grid_container = %EquipmentGridContainer
@onready var actions_inventory_container = %ActionsInventoryContainer
@onready var equip_button = %EquipButton
@onready var sell_button = %SellButton

# Options UI
@onready var option_open_actions = %OptionOpenActions
@onready var options_button = %OptionsButton

# Popup UI
@onready var popup_screen = %PopupScreen
@onready var offline_earnings_label = %OfflineEarningsLabel
@onready var confirmation_screen = %ConfirmationScreen
@onready var mission_cleared_screen = %MissionClearedScreen
@onready var final_boss_cleared_screen = %FinalBossClearedScreen
@onready var game_lost_screen = %GameLostScreen

# Scenes
@onready var game_play_scene = %GamePlayScene
@onready var clicker_scene = %ClickerScene
@onready var inventory_scene = %InventoryScene
@onready var upgrade_scene: UpgradeSystem = %UpgradeScene
@onready var missions_scene = %MissionsScene
@onready var enemy_scene = %EnemyScene
@onready var game_won_screen = %GameWonScreen

@export var mission: MissionTemplate = null
@export var all_missions: ResourceGroup = null
@export var idle_upgrades: ResourceGroup = null
@export var equipment_list: ResourceGroup = null

var _current_mission: MissionTemplate = null
var _current_enemy: EnemyTemplate = null
var _on_boss_battle := false
var _boss_failed := false
var _mission_completed := false
var _selected_equipment: EquipmentTemplate = null
var _selected_quipment_array: Array[EquipmentTemplate] = []
var _damage_timer := Timer.new()

func _ready() -> void:
	SceneManager.Set_Current_Scene(SceneManager.SCENES.CLICK)
	_load_game()
	_setup_game()
	DataManager.select_equipment.connect(_update_selected_equiment_ui)
	DataManager.unselect_equipment.connect(_update_unselected_equiment_ui)

func _process(_delta):
	if (_on_boss_battle):
		boss_timer_bar.value = boss_timer.time_left
		boss_timer_label.text = "%.2f" % boss_timer.time_left
	
	if (_boss_failed and !_on_boss_battle and !rematch_boss_button.is_visible_in_tree()):
		rematch_boss_button.show()

func _load_game() -> void:
	DataManager.Load_Equipment_Templates(equipment_list)
	DataManager.Load_Idle_Templates(idle_upgrades)
	DataManager.Load_Missions(all_missions)
	DataManager.Create_Idle_Upgrades()
	DataManager.Load_Data()
	_setup_signals()

# Setups
func _setup_game() -> void:
	confirmation_screen.hide()
	mission_cleared_screen.hide()
	final_boss_cleared_screen.hide()
	game_won_screen.hide()
	game_lost_screen.hide()
	mission_log_label.text = ""
	
	rematch_boss_button.hide()
	
	if (DataManager.Get_Current_Mission() == null and mission != null):
		DataManager.Set_Current_Mission(mission)
	else:
		mission = DataManager.Get_Current_Mission()
	
	if (!DataManager.unlocked_missions.has(mission.mission_name)):
		DataManager.unlocked_missions.append(mission.mission_name)
	
	_popup_ui()
	
	if (mission):
		_current_mission = mission.duplicate()
		
		for i in DataManager.Get("progress"):
			_current_mission.mission_enemies.pop_front()
		
		if (_current_mission.mission_enemies.size() > 0):
			_setup_enemy(_current_mission.mission_enemies[0])
		else:
			DataManager.Set("progress", 0)
			_on_boss_battle = true
			_setup_enemy(_current_mission.mission_boss)
		_update_game_ui()
		_update_enemy_ui()
		_update_player_ui()
		_update_gear_ui()
		_update_selected_equiment_ui()
	else:
		printerr("No mission selected!")

func _setup_signals() -> void:
	DataManager.update_ui.connect(_update_game_ui)
	DataManager.update_ui.connect(_update_player_ui)
	DataManager.update_ui.connect(_update_gear_ui)
	DataManager.update_ui.connect(_update_inventory_ui)
	DataManager.update_ui.connect(upgrade_scene.Update_UI)
	DataManager.select_mission.connect(_reset_game)
	
	_damage_timer.timeout.connect(_on_damage_timer_timeout)
	_damage_timer.wait_time = 1
	_damage_timer.autostart = true
	add_child(_damage_timer)

func _setup_enemy(enemy: EnemyTemplate) -> void:
	var new_enemy := enemy.duplicate()
	new_enemy.Setup(_current_mission)
	enemy_health_bar.max_value = new_enemy.enemy_base_max_health
	enemy_health_bar.value = new_enemy.enemy_base_max_health
	enemy_texture.texture = new_enemy.enemy_texture
	enemy_name_label.text = new_enemy.enemy_name
	
	var enemy_reward_multiplier := randf_range(_current_mission.min_reward_multiplier, _current_mission.max_reward_multiplier)
	new_enemy.Set_Reward(enemy_reward_multiplier)
	
	for child in weakness_container.get_children():
		child.free()
	
	if (new_enemy.enemy_weakness != new_enemy.ENEMY_WEAKNESS.NONE):
		var weakness_icon := ComponentsManager.WEAKNESS_ICON.instantiate()
		weakness_icon.enemy = new_enemy
		weakness_container.add_child(weakness_icon)
	
	_current_enemy = new_enemy
	
	if (_on_boss_battle):
		_start_boss_timer()

# UI
func _popup_ui() -> void:
	offline_earnings_label.text = DataManager.welcome_back_message
	if (DataManager.welcome_back_message.trim_prefix(" ") == ""): 
		popup_screen.hide()
	else:
		popup_screen.show()

func _update_enemy_ui() -> void:
	mission_progress_label.text = ""
	if (_current_enemy == null): return
	
	enemy_health_bar.visible = true
	enemy_health_bar.value = _current_enemy.enemy_current_health
	
	var current_mission_progress = mission.Get_Mission_Size() - _current_mission.Get_Mission_Size() + 1
	DataManager.Set("progress", current_mission_progress - 1)
	if (_on_boss_battle):
		mission_progress_label.text = "Boss"
		boss_timer_bar_container.show()
	else:
		boss_timer_bar_container.hide()
		mission_progress_label.text = str(current_mission_progress, " / ", mission.Get_Mission_Size())

func _update_player_ui() -> void:
	level_label.text = str("Lv: ", FormatManager.format_number(DataManager.Get("level")))
	power_label.text = str("Power: ", FormatManager.format_number(DataManager.Get("power")))
	idle_label.text = str("DPS: ", FormatManager.format_number(DataManager.Get("dps")), " /s")

func _update_gear_ui() -> void:
	var gear_slots = gear_container.get_children()
	for slots in gear_slots:
		slots.free()
	
	for gear in DataManager.equiped_gear:
		var new_gear_slot: EquipmentSLot = ComponentsManager.EQUIPMENT_SLOT.instantiate()
		new_gear_slot.equipment = gear
		gear_container.add_child(new_gear_slot)

func _update_inventory_ui() -> void:
	var equipment_slots = equipment_grid_container.get_children()
	for slots in equipment_slots:
		slots.free()
	
	for equipment in DataManager.inventory:
		var new_equipment_slot: EquipmentSLot = ComponentsManager.EQUIPMENT_SLOT.instantiate()
		new_equipment_slot.equipment = equipment
		new_equipment_slot.in_inventory = true
		new_equipment_slot.is_equiped = DataManager.Is_Equiped(equipment)
		equipment_grid_container.add_child(new_equipment_slot)
		if (_selected_quipment_array.size() == 0):
			_update_selected_equiment_ui()
		else:
			_update_selected_equiment_ui(_selected_equipment)

func _update_unselected_equiment_ui(selected_equipment: EquipmentTemplate = null) -> void:
	if (_selected_quipment_array.has(selected_equipment)):
		_selected_quipment_array.erase(selected_equipment)
	
	if (_selected_quipment_array.size() == 0):
		_update_selected_equiment_ui()
	else:
		_selected_equipment = _selected_quipment_array[0]
		_update_selected_equiment_ui(_selected_equipment)

func _update_selected_equiment_ui(selected_equipment: EquipmentTemplate = null) -> void:
	selected_equipment_label.show()
	selected_equipment_information_label.show()
	equip_button.show()
	
	if (selected_equipment != null):
		if (Input.is_action_pressed("shift")):
			if (!_selected_quipment_array.has(selected_equipment)):
				_selected_quipment_array.append(selected_equipment)
		else:
			if (!_selected_quipment_array.has(selected_equipment)):
				_selected_quipment_array.clear()
				_selected_quipment_array.append(selected_equipment)
	
	var equipment_slots = equipment_grid_container.get_children()
	for slots in equipment_slots as Array[EquipmentSLot]:
		if (!_selected_quipment_array.has(slots.equipment)):
			slots.disabled = false
		else:
			slots.disabled = true
	
	if (selected_equipment == null):
		selected_equipment_label.text = "Select item"
		selected_equipment_information_label.text = "Hold Shift for multiselect\nRight Mouse Button for unselecting"
		actions_inventory_container.visible = false
	else:
		selected_equipment_label.hide()
		selected_equipment_information_label.hide()
		equip_button.hide()
		sell_button.text = "Sell All"
		
		if (_selected_quipment_array.size() == 1):
			selected_equipment_label.show()
			selected_equipment_information_label.show()
			equip_button.show()
			sell_button.text = "Sell"
			
			_selected_equipment = selected_equipment
			selected_equipment_label.text = str(_selected_equipment.equipment_name, " ", _selected_equipment.Get_Attribute_Name()) 
			var improved_power_text := ""
			
			if (!DataManager.Is_Equiped(_selected_equipment)):
				equip_button.text = "Equip"
				var improved_power := DataManager.Calculate_Improved_Power(_selected_equipment)
				if (improved_power < 0):
					
					improved_power_text = str("[color=#B3261E]",FormatManager.format_number(improved_power) ," Once Equipped[/color]")
				else:
					improved_power_text = str("[color=#1F7A1F]+",FormatManager.format_number(improved_power) ," Once Equipped[/color]")
			else:
				equip_button.text = "Unequip"
			selected_equipment_information_label.text = str(FormatManager.format_number(_selected_equipment.equipment_current_attack_power), " Power\n", improved_power_text)
		
		actions_inventory_container.visible = true

func _update_game_ui() -> void:
	var scene: SceneManager.SCENES = SceneManager.Get_Current_Scene()
	game_play_scene.show()
	enemy_scene.hide()
	missions_scene.hide()
	inventory_scene.hide()
	clicker_scene.hide()
	upgrade_scene.hide()
	
	match scene:
		SceneManager.SCENES.CLICK:
			clicker_scene.show()
			enemy_scene.show()
		SceneManager.SCENES.INVENTORY:
			inventory_scene.show()
		SceneManager.SCENES.UPGRADE:
			game_play_scene.hide()
			upgrade_scene.show()
		SceneManager.SCENES.MISSIONS:
			clicker_scene.show()
			missions_scene.show()
	
	mission_label.text = DataManager.Get("mission")
	gold_label.text = str(FormatManager.format_number(DataManager.Get("gold")), " Gold")
	inventory_size_label.text = str(FormatManager.format_number(DataManager.inventory.size()), " Items")

func _update_mission_log_ui(add_text: String) -> void:
	var current_log = mission_log_label.text
	mission_log_label.text = str("- ", add_text, "\n", current_log)

func _update_missions_ui() -> void:
	for child in missions_container.get_children():
		child.free()
	
	for data_mission in DataManager.missions:
		if (data_mission.mission_enemies.size() == 0):
			if (DataManager.FINAL_DIFFICULTY != DataManager.Get("difficulty")):
				return
		
		var mission_button := ComponentsManager.MISSION_BUTTON.instantiate()
		mission_button.mission = data_mission
		mission_button.pressed.connect(_reset_buttons)
		missions_container.add_child(mission_button)

func _clear_enemy_ui() -> void:
	enemy_texture.texture = null
	enemy_name_label.text = ""
	enemy_health_bar.visible = false
	boss_timer.stop()
	boss_timer_bar_container.hide()
	
	for child in weakness_container.get_children():
		child.free()
	
	if (_current_mission.unlock_mission != null):
		if (!DataManager.unlocked_missions.has(_current_mission.unlock_mission.mission_name)):
			DataManager.unlocked_missions.append(_current_mission.unlock_mission.mission_name)
	
	var available_missions: Array[MissionTemplate] = []
	for data_mission in DataManager.missions:
		if (data_mission.mission_enemies.size() == 0):
			if (DataManager.FINAL_DIFFICULTY != DataManager.Get("difficulty")):
				break
		available_missions.append(data_mission)
	
	var last_mission := available_missions.back() as MissionTemplate
	if (_current_mission.mission_name == last_mission.mission_name):
		if (_current_mission.mission_enemies.size() > 0):
			final_boss_cleared_screen.show()
		else:
			game_won_screen.show()
	else:
		if (_current_mission.unlock_mission == null):
			if (!DataManager.unlocked_missions.has(last_mission.mission_name)):
				DataManager.unlocked_missions.append(last_mission.mission_name)
		mission_cleared_screen.show()

# Helpers
func _check_defeated() -> void:
	if (_current_enemy.Is_Defeated()):
		var enemies := _current_mission.mission_enemies
		if (_on_boss_battle):
			_update_mission_log_ui(str("Boss Defeated"))
		else:
			_update_mission_log_ui(str("Defeated ", _current_enemy.enemy_name))
		_update_mission_log_ui(str("Gained ", FormatManager.format_number(_current_enemy.Get_Reward()), " Gold"))
		
		var drop_name = _current_enemy.Possible_Drop(_current_mission)
		if (drop_name != ""):
			_update_mission_log_ui(str("Picked up (", drop_name, ")"))
		
		if (enemies.size() > 1):
			enemies.pop_front()
			_setup_enemy(enemies[0])
			_current_mission.mission_enemies = enemies
		elif (!_on_boss_battle):
			if (_boss_failed):
				_reset_game()
			else:
				_on_boss_battle = true
				_setup_enemy(_current_mission.mission_boss)
		else:
			_current_enemy = null
			_update_mission_log_ui(str("Mission Complete"))
			_clear_enemy_ui()
			_mission_completed = true
		
	_update_enemy_ui()

func _start_boss_timer() -> void:
	boss_timer.paused = false
	boss_timer.start(_current_enemy.enemy_timer)
	boss_timer_bar.max_value = _current_enemy.enemy_timer
	boss_timer_bar.value = _current_enemy.enemy_timer

func _reset_game() -> void:
	boss_timer.paused = false
	if (_mission_completed or _boss_failed or DataManager.Get("progress") == 0):
		mission = DataManager.Get_Current_Mission()
		_current_mission = mission.duplicate()
		_mission_completed = false
		_on_boss_battle = false
		
		var enemies := _current_mission.mission_enemies
		if (enemies.size() > 0):
			_setup_enemy(_current_mission.mission_enemies[0])
		else:
			_boss_failed = false
			_on_boss_battle = true
			_setup_enemy(_current_mission.mission_boss)
	_update_enemy_ui()

func _reset_buttons() -> void:
	inventory_open_button.text = "Inventory"
	mission_select_button.text = "Missions"

# Buttons
func _on_mission_select_button_pressed() -> void:
	boss_timer.paused = true
	_reset_buttons()
	if (SceneManager.Get_Current_Scene() != SceneManager.SCENES.MISSIONS):
		SceneManager.Set_Current_Scene(SceneManager.SCENES.MISSIONS)
		mission_select_button.text = "Close Missions"
		_update_missions_ui()
	else:
		boss_timer.paused = false
		SceneManager.Set_Current_Scene(SceneManager.SCENES.CLICK)
	_update_game_ui()

func _on_options_button_pressed() -> void:
	option_open_actions.visible = !option_open_actions.visible 
	if (option_open_actions.visible):
		options_button.text = "Close options"
	else:
		options_button.text = "Options"

func _on_upgrade_button_pressed() -> void:
	boss_timer.paused = true
	_reset_buttons()
	if (SceneManager.Get_Current_Scene() != SceneManager.SCENES.UPGRADE):
		upgrade_scene.Setup_Upgrades()
		SceneManager.Set_Current_Scene(SceneManager.SCENES.UPGRADE)
	else:
		boss_timer.paused = false
		SceneManager.Set_Current_Scene(SceneManager.SCENES.CLICK)
	_update_game_ui()

func _on_attack_button_pressed() -> void:
	if (_current_enemy and !_mission_completed):
		_current_enemy.Take_Damage(DataManager.Get("power"))
		_check_defeated()

func _on_inventory_open_button_pressed() -> void:
	boss_timer.paused = true
	_reset_buttons()
	if (SceneManager.Get_Current_Scene() != SceneManager.SCENES.INVENTORY):
		SceneManager.Set_Current_Scene(SceneManager.SCENES.INVENTORY)
		inventory_open_button.text = "Close Inventory"
		_selected_quipment_array.clear()
		_update_inventory_ui()
		_update_selected_equiment_ui()
	else:
		boss_timer.paused = false
		SceneManager.Set_Current_Scene(SceneManager.SCENES.CLICK)
	_update_game_ui()

func _on_sell_button_pressed():
	for equipment in _selected_quipment_array:
		DataManager.Delete_From_Inventory(equipment)
		equipment.Sell_Equipment()
	_selected_equipment = null
	_selected_quipment_array.clear()
	_update_selected_equiment_ui()

func _on_equip_button_pressed():
	if (DataManager.Is_Equiped(_selected_equipment)):
		DataManager.Remove_Gear(_selected_equipment)
	else:
		DataManager.Set_Gear(_selected_equipment)
	
	_update_selected_equiment_ui(_selected_equipment)

func _on_damage_timer_timeout() -> void:
	if (_current_enemy != null and DataManager.Get("dps") > 0):
		_current_enemy.Take_Damage(DataManager.Get("dps"))
		_check_defeated()

func _on_reset_button_pressed():
	game_won_screen.hide()
	confirmation_screen.show()

func _on_quit_button_pressed():
	DataManager._on_about_to_quit()

func _on_close_button_pressed():
	popup_screen.hide()

func _on_accept_restart_button_pressed():
	mission_log_label.text = ""
	DataManager.Reset_Game()
	confirmation_screen.hide()

func _on_close_restart_button_pressed():
	confirmation_screen.hide()

func _on_redo_mission_button_pressed():
	_reset_game()
	mission_cleared_screen.hide()
	game_lost_screen.hide()

func _on_new_mission_button_pressed():
	_on_mission_select_button_pressed()
	mission_cleared_screen.hide()
	game_lost_screen.hide()
	final_boss_cleared_screen.hide()

func _on_challange_mission_button_pressed():
	DataManager.Set("difficulty", DataManager.Get("difficulty") + 1)
	DataManager.unlocked_missions.clear()
	DataManager.Set_Current_Mission(DataManager.missions[0])
	DataManager.unlocked_missions.append(DataManager.Get_Current_Mission().mission_name)
	DataManager.Save_Data()
	final_boss_cleared_screen.hide()
	_reset_game()

func _on_boss_timer_timeout():
	_boss_failed = true
	boss_timer.stop()
	game_lost_screen.show()

func _on_rematch_boss_button_pressed():
	_boss_failed = false
	_on_boss_battle = true
	rematch_boss_button.hide()
	_current_mission.mission_enemies.clear()
	_setup_enemy(_current_mission.mission_boss)
	_update_enemy_ui()
