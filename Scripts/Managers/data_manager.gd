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
var current_player_gold := 0
var current_difficulty := 1.0
var current_planet := "planet 1"

var inventory: Array[EquipmentTemplate] = []
var equiped_gear: Array[EquipmentTemplate] = []

func Set(property, value):
	match property:
		"current_player_gold":
			current_player_gold = value
	update_ui.emit()

func Clear_Data() -> void:
	current_player_lv = start_player_lv
	current_player_power = start_player_power
	current_player_gold = start_player_gold
	current_difficulty = start_difficulty
	current_planet = start_planet
	inventory.clear()

func Add_To_Inventory(added_equipment: EquipmentTemplate) -> void:
	inventory.append(added_equipment)
	update_ui.emit()

func Delete_From_Inventory(deleted_equipment: EquipmentTemplate) -> void:
	inventory.erase(deleted_equipment)
	update_ui.emit()

func Save_Data() -> void:
	#TODO: Create save system
	pass

func Load_Data() -> void:
	#TODO: Create load system
	pass
