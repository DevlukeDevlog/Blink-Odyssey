extends Node

signal update_ui
@warning_ignore("unused_signal")
signal select_equipment(selected_equipment: EquipmentTemplate)

# =====================================================
# STARTING VALUES
# =====================================================
var start_player_lv := 1
var start_player_power := 1
var start_idle_power := 0
var start_player_gold := 0
var start_difficulty := 1.0
var start_planet := "planet_1"

# =====================================================
# CURRENT VALUES
# =====================================================
var current_player_lv := start_player_lv
var current_player_power := start_player_power
var current_idle_power := start_idle_power
var current_equipment_power := 0
var current_player_gold := start_player_gold
var current_difficulty := start_difficulty
var current_planet := start_planet
var upgrade_multiplier := 1 # can be 1, 10, 100, 1000, or 0 for Max

# =====================================================
# LEVEL / UPGRADE SYSTEM (SAME THING)
# =====================================================
var level_base_cost := 10
var level_cost_growth := 1.15
var power_flat_per_level := 1

# =====================================================
# POWER SCALING (CORE)
# =====================================================
var level_power_growth := 1.10     # +10% per level
var prestige_multiplier := 1.0

# =====================================================
# INVENTORY / EQUIPMENT / UPGRADES
# =====================================================
var inventory: Array[EquipmentTemplate] = []
var equiped_gear: Array[EquipmentTemplate] = []
var upgrade_list_equipment: Array[UpgradeEquipmentTemplate] = []

# =====================================================
# IDLE UPGRADES
# =====================================================
var idle_upgrade_templates: Array[IdleTemplate] = []
var idle_upgrades: Array[IdleTemplate] = []         


# =====================================================
# GENERIC SET / GET
# =====================================================
func Set(property: String, value) -> void:
	match property:
		"gold":
			current_player_gold = value
		"level":
			current_player_lv = value
		"equipment_power":
			current_equipment_power = value
		"multiplier":
			upgrade_multiplier = value
		"dps":
			current_idle_power = value
	update_ui.emit()

func Get(property: String):
	match property:
		"gold":
			return current_player_gold
		"power":
			return get_final_click_power()
		"level":
			return current_player_lv
		"level_cost":
			return get_level_up_cost()
		"multiplier":
			return upgrade_multiplier
		"dps":
			return current_idle_power
	return null

# =====================================================
# FINAL CLICK POWER (GUARANTEED GROWTH)
# =====================================================
func get_final_click_power() -> int:
	var scaled_player := float(current_player_power)
	scaled_player *= pow(level_power_growth, current_player_lv - 1)
	
	var total_power := scaled_player + current_equipment_power
	total_power *= prestige_multiplier
	total_power *= current_difficulty
	
	return max(1, int(floor(total_power)))

func Get_Player_Level_Up_Power() -> int:
	var current_final := get_final_click_power()
	
	var simulated_power := current_player_power + get_player_flat_power_gain()
	var simulated_lv := current_player_lv + 1
	
	var scaled_simulated := float(simulated_power)
	scaled_simulated *= pow(level_power_growth, simulated_lv - 1)
	
	var simulated_final := scaled_simulated + current_equipment_power
	simulated_final *= prestige_multiplier
	simulated_final *= current_difficulty
	
	var simulated_int = max(1, int(floor(simulated_final)))
	return max(1, simulated_int - current_final)

func Get_Player_Level_Up_Power_Batch(multiplier: int) -> int:
	var temp_player_power := current_player_power
	var temp_player_lv := current_player_lv
	var total_gain := 0

	var iterations := multiplier
	if iterations == 0:
		iterations = 999999  # effectively Max

	var remaining_gold = current_player_gold

	for i in range(iterations):
		var cost = int(level_base_cost * pow(level_cost_growth, temp_player_lv - 1))
		if remaining_gold < cost:
			break

		# simulate one upgrade
		temp_player_lv += 1
		temp_player_power += max(1, int(round(temp_player_power * 0.08)))

		var scaled := float(temp_player_power) * pow(level_power_growth, temp_player_lv - 1)
		var new_final := scaled + current_equipment_power
		new_final *= prestige_multiplier
		new_final *= current_difficulty

		total_gain = max(1, int(floor(new_final))) - get_final_click_power()
		
		remaining_gold -= cost

	return total_gain

func get_player_flat_power_gain() -> int:
	return max(1, int(round(current_player_power * 0.08)))

# =====================================================
# LEVEL UP COST (EXPONENTIAL)
# =====================================================
func get_level_up_cost() -> int:
	return int(
		level_base_cost *
		pow(level_cost_growth, current_player_lv - 1)
	)

func Get_Player_Level_Up_Cost(multiplier: int) -> int:
	var temp_lv := current_player_lv
	var total_cost := 0
	var iterations := multiplier
	if iterations == 0:
		iterations = 999999  # effectively Max

	var remaining_gold = current_player_gold

	for i in range(iterations):
		var cost = int(level_base_cost * pow(level_cost_growth, temp_lv - 1))
		if remaining_gold < cost:
			break
		total_cost += cost
		remaining_gold -= cost
		temp_lv += 1

	return total_cost

# =====================================================
# LEVEL UP (THIS IS THE UPGRADE)
# =====================================================
func Level_Up_Player_Batch(multiplier: int) -> void:
	if multiplier == 0:
		# Max affordable
		while true:
			var cost = int(level_base_cost * pow(level_cost_growth, current_player_lv - 1))
			if current_player_gold < cost:
				break
			Level_Up_Player()
		return

	for i in range(multiplier):
		var cost = int(level_base_cost * pow(level_cost_growth, current_player_lv - 1))
		if current_player_gold < cost:
			break
		Level_Up_Player()

func Level_Up_Player() -> void:
	var cost := get_level_up_cost()
	if current_player_gold < cost:
		return
	
	current_player_gold -= cost
	current_player_lv += 1
	current_player_power += get_player_flat_power_gain()
	
	update_ui.emit()

func Level_Up_Player_Max() -> void:
	while true:
		var cost = get_level_up_cost()
		if current_player_gold < cost:
			break
		Level_Up_Player()

# =====================================================
# INVENTORY / EQUIPMENT / UPGRADES
# =====================================================
func Add_To_Inventory(added_equipment: EquipmentTemplate) -> void:
	inventory.append(added_equipment)
	update_ui.emit()

func Delete_From_Inventory(deleted_equipment: EquipmentTemplate) -> void:
	inventory.erase(deleted_equipment)
	if Is_Equiped(deleted_equipment):
		equiped_gear.erase(deleted_equipment)
		Calculate_Gear_Power()
	update_ui.emit()

func Is_Equiped(equipment: EquipmentTemplate) -> bool:
	return equiped_gear.has(equipment)

func Set_Gear(equiped_equipment: EquipmentTemplate) -> void:
	for i in equiped_gear.size():
		if equiped_gear[i].equipment_type == equiped_equipment.equipment_type:
			equiped_gear[i] = equiped_equipment
			Calculate_Gear_Power()
			return
	
	equiped_gear.append(equiped_equipment)
	Calculate_Gear_Power()

func Remove_Gear(selected_equipment: EquipmentTemplate) -> void:
	if equiped_gear.has(selected_equipment):
		equiped_gear.erase(selected_equipment)
		Calculate_Gear_Power()

func Calculate_Gear_Power() -> void:
	var power := 0
	for equip in equiped_gear:
		power += equip.equipment_current_attack_power
	current_equipment_power = power
	update_ui.emit()

func Calculate_Improved_Power(selected_equipment: EquipmentTemplate) -> int:
	for equip in equiped_gear:
		if equip.equipment_type == selected_equipment.equipment_type:
			return selected_equipment.equipment_current_attack_power - equip.equipment_current_attack_power
	return selected_equipment.equipment_current_attack_power

func Add_To_Upgrade_List(added_equipment: EquipmentTemplate) -> void:
	if Get_Upgrade_Item(added_equipment.equipment_name) != null:
		return
	
	var new_upgrade := UpgradeEquipmentTemplate.new()
	new_upgrade.item_name = added_equipment.equipment_name
	new_upgrade.item_icon_texture = added_equipment.equipment_icon_texture
	new_upgrade.base_item_power = added_equipment.equipment_base_attack_power
	new_upgrade.base_upgrade_cost = added_equipment.equipment_base_upgrade_cost
	upgrade_list_equipment.append(new_upgrade)

func Get_Upgrade_Item(item_name: String) -> UpgradeEquipmentTemplate:
	for item in upgrade_list_equipment:
		if (item.item_name == item_name) : return item
	return null

# =====================================================
# RESET / SAVE
# =====================================================
func Clear_Data() -> void:
	current_player_lv = start_player_lv
	current_player_power = start_player_power
	current_player_gold = start_player_gold
	current_difficulty = start_difficulty
	current_planet = start_planet
	
	prestige_multiplier = 1.0
	
	inventory.clear()
	equiped_gear.clear()
	update_ui.emit()

func Save_Data() -> void:
	# TODO
	pass

func Load_Data() -> void:
	# TODO
	pass

func Load_Idle_Templates(upgrades: ResourceGroup) -> void:
	idle_upgrade_templates.clear()
	upgrades.load_all_into(idle_upgrade_templates)

func Create_Idle_Upgrades() -> void:
	idle_upgrades.clear()

	for template in idle_upgrade_templates:
		var instance: IdleTemplate = template.duplicate(true)
		instance.idle_amount = 0
		instance.Update_Power()
		idle_upgrades.append(instance)

	update_ui.emit()
