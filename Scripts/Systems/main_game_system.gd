extends Control

# Game UI
@onready var gold_label: Label = %GoldLabel
@onready var mission_label: Label = %MissionLabel
@onready var inventory_size_label: Label = %InventorySizeLabel

# Player's UI
@onready var level_label: Label = %LevelLabel
@onready var power_label: Label = %PowerLabel
@onready var gear_container = %GearContainer

# Enemy's UI
@onready var mission_progress_label: Label = %MissionProgressLabel
@onready var enemy_name_label: Label = %EnemyNameLabel
@onready var enemy_texture: TextureRect = %EnemyTexture
@onready var enemy_health_bar: ProgressBar = %EnemyHealthBar

# Mission Log UI
@onready var mission_log_label: RichTextLabel = %MissionLogLabel

# Inventory UI
@onready var selected_equipment_label = %SelectedEquipmentLabel
@onready var selected_equipment_information_label = %SelectedEquipmentInformationLabel
@onready var inventory_open_button = %InventoryOpenButton
@onready var equipment_grid_container = %EquipmentGridContainer
@onready var actions_inventory_container = %ActionsInventoryContainer
@onready var equip_button = %EquipButton

# Scenes
@onready var game_play_scene = %GamePlayScene
@onready var clicker_scene = %ClickerScene
@onready var inventory_scene = %InventoryScene
@onready var upgrade_scene: UpgradeSystem = %UpgradeScene

@export var mission: MissionTemplate = null

var _current_mission: MissionTemplate = null
var _current_enemy: EnemyTemplate = null
var _on_boss_battle := false
var _mission_completed := false
var _selected_equipment: EquipmentTemplate = null

func _ready() -> void:
	_setup_game()
	DataManager.select_equipment.connect(_update_selected_equiment_ui)

# Setups
func _setup_game() -> void:
	if (mission):
		_current_mission = mission.duplicate()
		_setup_signals()
		_setup_enemy(_current_mission.mission_enemies[0])
		_update_game_ui()
		_update_enemy_ui()
		_update_player_ui()
		_update_gear_ui()
		_update_selected_equiment_ui()
		mission_log_label.text = ""
	else:
		printerr("No mission selected!")

func _setup_signals() -> void:
	DataManager.update_ui.connect(_update_game_ui)
	DataManager.update_ui.connect(_update_player_ui)
	DataManager.update_ui.connect(_update_gear_ui)
	DataManager.update_ui.connect(_update_inventory_ui)
	DataManager.update_ui.connect(_update_selected_equiment_ui)
	DataManager.update_ui.connect(upgrade_scene.Update_UI)

func _setup_enemy(new_enemy: EnemyTemplate) -> void:
	new_enemy.Setup()
	enemy_health_bar.max_value = new_enemy.enemy_base_max_health
	enemy_health_bar.value = new_enemy.enemy_base_max_health
	enemy_texture.texture = new_enemy.enemy_texture
	enemy_name_label.text = new_enemy.enemy_name
	
	var enemy_reward_multiplier := randf_range(_current_mission.min_reward_multiplier, _current_mission.max_reward_multiplier)
	new_enemy.Set_Reward(enemy_reward_multiplier)
	
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
	level_label.text = str("Lv: ", FormatManager.format_number(DataManager.Get("level")))
	power_label.text = str("Power: ", FormatManager.format_number(DataManager.Get("power")))

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

func _update_selected_equiment_ui(selected_equipment: EquipmentTemplate = null) -> void:
	var equipment_slots = equipment_grid_container.get_children()
	for slots in equipment_slots as Array[EquipmentSLot]:
		slots.disabled = false
	
	if (selected_equipment == null):
		selected_equipment_label.text = "Select item"
		selected_equipment_information_label.text = ""
		actions_inventory_container.visible = false
	else:
		_selected_equipment = selected_equipment
		selected_equipment_label.text = _selected_equipment.equipment_name
		
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
	var scene := SceneManager.Get_Current_Scene()
	game_play_scene.show()
	inventory_scene.hide()
	clicker_scene.hide()
	upgrade_scene.hide()
	
	match scene:
		SceneManager.SCENES.CLICK:
			clicker_scene.show()
		SceneManager.SCENES.INVENTORY:
			inventory_scene.show()
		SceneManager.SCENES.UPGRADE:
			game_play_scene.hide()
			upgrade_scene.show()
	
	mission_label.text = _current_mission.mission_name
	gold_label.text = str(FormatManager.format_number(DataManager.Get("gold")), " Gold")
	inventory_size_label.text = str(FormatManager.format_number(DataManager.inventory.size()), " Items")

func _update_mission_log_ui(add_text: String) -> void:
	var current_log = mission_log_label.text
	mission_log_label.text = str("- ", add_text, "\n", current_log)

func _clear_enemy_ui() -> void:
	enemy_texture.texture = null
	enemy_name_label.text = ""

# Buttons
func _on_mission_select_button_pressed() -> void:
	pass # Replace with function body.

func _on_options_button_pressed() -> void:
	pass # Replace with function body.

func _on_upgrade_button_pressed() -> void:
	if (SceneManager.Get_Current_Scene() != SceneManager.SCENES.UPGRADE):
		upgrade_scene.Setup_Upgrades()
		SceneManager.Set_Current_Scene(SceneManager.SCENES.UPGRADE)
	else:
		SceneManager.Set_Current_Scene(SceneManager.SCENES.CLICK)
	_update_game_ui()

func _on_attack_button_pressed() -> void:
	if (_current_enemy and !_mission_completed):
		_current_enemy.Take_Damage(DataManager.Get("power"))
		
		if (_current_enemy.Is_Defeated()):
			var enemies := _current_mission.mission_enemies
			if (_on_boss_battle):
				_update_mission_log_ui(str("Boss Defeated"))
			else:
				_update_mission_log_ui(str("Defeated ", _current_enemy.enemy_name))
			_update_mission_log_ui(str("Gained ", FormatManager.format_number(_current_enemy.Get_Reward()), " Gold"))
			
			var drop_name = _current_enemy.Possible_Drop()
			if (drop_name != ""):
				_update_mission_log_ui(str("Picked up (", drop_name, ")"))
			
			if (enemies.size() > 1):
				enemies.pop_front()
				_setup_enemy(enemies[0])
				_current_mission.mission_enemies = enemies
			elif (!_on_boss_battle):
				_setup_enemy(_current_mission.mission_boss)
				_on_boss_battle = true
			else:
				_update_mission_log_ui(str("Mission Complete"))
				_clear_enemy_ui()
				_mission_completed = true
			
		_update_enemy_ui()

func _on_inventory_open_button_pressed() -> void:
	if (SceneManager.Get_Current_Scene() != SceneManager.SCENES.INVENTORY):
		SceneManager.Set_Current_Scene(SceneManager.SCENES.INVENTORY)
		inventory_open_button.text = "Close Inventory"
		_update_inventory_ui()
	else:
		SceneManager.Set_Current_Scene(SceneManager.SCENES.CLICK)
		inventory_open_button.text = "Inventory"
	_update_game_ui()

func _on_sell_button_pressed():
	DataManager.Delete_From_Inventory(_selected_equipment)
	_selected_equipment.Sell_Equipment()
	_selected_equipment = null

func _on_equip_button_pressed():
	if (DataManager.Is_Equiped(_selected_equipment)):
		DataManager.Remove_Gear(_selected_equipment)
	else:
		DataManager.Set_Gear(_selected_equipment)
