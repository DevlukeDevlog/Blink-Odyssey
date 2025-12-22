extends Node

signal update_ui

@warning_ignore("unused_signal")
signal select_equipment(selected_equipment: EquipmentTemplate)

var start_player_lv := 1
var start_player_power := 1
var start_player_gold := 0
var start_difficulty := 1.0
var start_planet := "planet 1"

var current_player_lv := 1
var current_player_power := 1
var current_equipment_power := 0
var current_player_gold := 0
var current_difficulty := 1.0
var current_planet := "planet 1"

var inventory: Array[EquipmentTemplate] = []
var equiped_gear: Array[EquipmentTemplate] = []

func Set(property, value):
	match property:
		"current_player_gold":
			current_player_gold = value
		"current_equipment_power":
			current_equipment_power = value
	update_ui.emit()

func Get(property):
	match property:
		"power":
			return current_equipment_power + current_player_power
		"level":
			return current_player_lv

func Add_To_Inventory(added_equipment: EquipmentTemplate) -> void:
	inventory.append(added_equipment)
	update_ui.emit()

func Delete_From_Inventory(deleted_equipment: EquipmentTemplate) -> void:
	inventory.erase(deleted_equipment)
	if (Is_Equiped(deleted_equipment)):
		equiped_gear.erase(deleted_equipment)
		Calculate_Gear_Power()
	update_ui.emit()

func Is_Equiped(equipment: EquipmentTemplate) -> bool:
	return equiped_gear.has(equipment)

func Set_Gear(equiped_equipment: EquipmentTemplate) -> void:
	for equip in equiped_gear:
		if (equip.equipment_type == equiped_equipment.equipment_type):
			var index = equiped_gear.find(equip)
			equiped_gear[index] = equiped_equipment
			Calculate_Gear_Power()
			return
	
	equiped_gear.append(equiped_equipment)
	Calculate_Gear_Power()

func Remove_Gear(selected_equipment: EquipmentTemplate) -> void:
	if (equiped_gear.has(selected_equipment)):
		equiped_gear.erase(selected_equipment)
		Calculate_Gear_Power()

func Calculate_Gear_Power() -> void:
	var power := 0
	for equip in equiped_gear:
		power += equip.equipment_current_attack_power
	Set("current_equipment_power", power) 

func Calculate_Improved_Power(selected_equipment: EquipmentTemplate) -> int:
	for equip in equiped_gear:
		if (equip.equipment_type == selected_equipment.equipment_type):
			return selected_equipment.equipment_current_attack_power - equip.equipment_current_attack_power
	return selected_equipment.equipment_current_attack_power

func Clear_Data() -> void:
	current_player_lv = start_player_lv
	current_player_power = start_player_power
	current_player_gold = start_player_gold
	current_difficulty = start_difficulty
	current_planet = start_planet
	inventory.clear()

func Save_Data() -> void:
	#TODO: Create save system
	pass

func Load_Data() -> void:
	#TODO: Create load system
	pass
