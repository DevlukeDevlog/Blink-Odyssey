extends Node

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
var gear: Array[EquipmentTemplate] = []

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
