class_name EquipmentTemplate
extends Resource

enum EQUIPMENT_TYPE {WEAPON, SPACEHELMET, SPACESUIT, SPACEBOOTS}
enum EQUIPMENT_ATTRIBUTE {NONE, FIRE, DARK, LIGHT}

@export var equipment_type := EQUIPMENT_TYPE.WEAPON
@export var equipment_attribute := EQUIPMENT_ATTRIBUTE.NONE
@export var equipment_name := "Equipment Name"
@export var equipment_sell_price := 100
@export var equipment_min_multiplier_attack := 1.00
@export var equipment_max_multiplier_attack := 1.50
@export var equipment_base_attack_power := 2
@export var equipment_base_upgrade_cost := 10
@export var equipment_drop_chance := 0.02
@export var equipment_icon_texture := Texture2D.new()

var equipment_current_attack_base_power := 2
var equipment_current_attack_power := 2

func Sell_Equipment() -> void:
	DataManager.Set("gold", DataManager.current_player_gold + equipment_sell_price)

func Set_Power() -> void:
	var multiplier := randf_range(equipment_min_multiplier_attack, equipment_max_multiplier_attack)
	equipment_current_attack_base_power = int(round(equipment_base_attack_power * multiplier))
	equipment_current_attack_power = equipment_current_attack_base_power
	Update_Power()

func Update_Power() -> void:
	var bonus_power := 0
	var upgrade_item := DataManager.Get_Upgrade_Item(equipment_name)
	if (upgrade_item != null):
		bonus_power = upgrade_item.Get_Bonus_Power()
	equipment_current_attack_power = bonus_power + equipment_current_attack_base_power
