class_name EnemyTemplate
extends Resource

enum ENEMY_TYPE {ENEMY, BOSS}
enum ENEMY_WEAKNESS {NONE, FIRE, DARK, LIGHT}

@export var enemy_type := ENEMY_TYPE.ENEMY
@export var enemy_name := "Enemy Name"
@export var enemy_base_max_health := 10
@export var enemy_weakness := ENEMY_WEAKNESS.NONE
@export var enemy_base_min_reward := 10
@export var enemy_possible_equipment_drops: Array[EquipmentTemplate] = []
@export var enemy_timer := 0
@export var enemy_texture := Texture2D.new()

var current_reward := 10
var enemy_current_health := 10

func Setup() -> void:
	enemy_current_health = enemy_base_max_health
	Set_Reward()

func Take_Damage(damage: int) -> void:
	var attribute_multiplier := 1.0
	for gear in DataManager.equiped_gear:
		if (gear.equipment_attribute == ENEMY_WEAKNESS.NONE): return
		if (gear.equipment_attribute == enemy_weakness):
			attribute_multiplier += 0.2
	
	var total_damage := roundi(damage * attribute_multiplier)
	enemy_current_health = clampi(enemy_current_health - total_damage, 0, enemy_base_max_health)

func Is_Defeated() -> bool:
	if (enemy_current_health != 0): return false
	DataManager.Set("gold", DataManager.current_player_gold + Get_Reward())
	return true

func Possible_Drop() -> String:
	for equipment in enemy_possible_equipment_drops:
		var chance := randf()
		if (chance < equipment.equipment_drop_chance):
			var new_equipment: EquipmentTemplate = equipment.duplicate()
			if (DataManager.Get_Upgrade_Item(new_equipment.equipment_name) == null):
				DataManager.Add_To_Upgrade_List(new_equipment)
			new_equipment.Set_Power()
			DataManager.Add_To_Inventory(new_equipment)
			return equipment.equipment_name
	return ""

func Set_Reward(multiplier := 1.0) -> void:
	current_reward = roundi(enemy_base_min_reward * multiplier)

func Get_Reward() -> int: return current_reward 

func Get_Weakness_Name() -> String:
	match enemy_weakness:
		ENEMY_WEAKNESS.NONE:
			return ""
		ENEMY_WEAKNESS.FIRE:
			return "Fire"
		ENEMY_WEAKNESS.DARK:
			return "Dark"
		ENEMY_WEAKNESS.LIGHT:
			return "Light"
		_:
			return "Unknown"
