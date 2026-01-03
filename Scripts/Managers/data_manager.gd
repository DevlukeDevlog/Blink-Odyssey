extends Node

signal update_ui
@warning_ignore("unused_signal")
signal select_equipment(selected_equipment: EquipmentTemplate)

const MAX_OFFLINE_SECONDS := 60 * 60 * 8 # 8 hours cap
const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 1
const OFFLINE_EFFICIENCY := 0.01 

var welcome_back_message := ""

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
var last_active_time: int = 0

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
var equipment_group : Array[EquipmentTemplate] = [] 
var equipment_templates := {}

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
		"power":
			current_player_power = value
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
	var save_data := {}

	save_data["version"] = 1

	save_data["player"] = {
		"level": Get("level"),
		"gold": Get("gold"),
		"power": current_player_power,
	}

	save_data["inventory"] = Save_Equipment_List(inventory)
	save_data["equipped"] = Save_Equipment_List(equiped_gear)
	save_data["upgrade_equipment"] = Save_Upgrade_List()
	save_data["idle_upgrades"] = Save_Idle_List()
	save_data["last_played"] = Time.get_unix_time_from_system()

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	file.close()

func Load_Data() -> void:
	if !FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(data) != TYPE_DICTIONARY:
		push_error("Save file corrupted")
		return

	# =====================
	# PLAYER
	# =====================
	var p = data["player"]
	Set("level", p["level"])
	Set("gold", p["gold"])
	Set("power", p["power"])
	
	Load_Equipment(data)
	Load_Upgrade_List(data)
	Load_Idle_List(data)
	
	Apply_Offline_Progress(data.get("last_played", Time.get_unix_time_from_system()))
	
	update_ui.emit()

func Load_Equipment_Templates(equipment: ResourceGroup) -> void:
	equipment_group.clear()
	equipment.load_all_into(equipment_group)
	
	for res in equipment_group:
		if res is EquipmentTemplate:
			equipment_templates[res.equipment_name] = res

func Save_Equipment_List(list: Array) -> Array:
	var result := []
	for equip in list as Array[EquipmentTemplate]:
		result.append({
			"name": equip.equipment_name,
			"base_power": equip.equipment_current_attack_base_power,
			"power": equip.equipment_current_attack_power,
			"equiped": Is_Equiped(equip)
		})
	return result

func Create_Equipment_From_Save(data: Dictionary) -> EquipmentTemplate:
	if !equipment_templates.has(data["name"]):
		push_error("Missing equipment template: " + data["name"])
		return null

	var base: EquipmentTemplate = equipment_templates[data["name"]]
	var equip: EquipmentTemplate = base.duplicate(true)

	equip.equipment_current_attack_base_power = data["base_power"]
	equip.equipment_current_attack_power = data["power"]

	return equip

func Load_Equipment(save_data: Dictionary) -> void:
	inventory.clear()
	equiped_gear.clear()

	for e in save_data.get("inventory", []):
		var item = Create_Equipment_From_Save(e)
		if item:
			inventory.append(item)
			if (e["equiped"]):
				Set_Gear(item)

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

func Save_Idle_List() -> Array:
	var arr := []
	for idle in idle_upgrades:
		arr.append({
			"name": idle.idle_name,
			"amount": idle.idle_amount
		})
	return arr

func Load_Upgrade_List(data: Dictionary) -> void:
	upgrade_list_equipment.clear()

	for entry in data.get("upgrade_equipment", []):
		var equip_name = entry["name"]

		# Base equipment must exist
		if !equipment_templates.has(equip_name):
			push_error("Missing equipment template for upgrade: " + equip_name)
			continue

		var base_equip: EquipmentTemplate = equipment_templates[equip_name]

		var upgrade := UpgradeEquipmentTemplate.new()
		upgrade.item_name = equip_name
		upgrade.item_icon_texture = base_equip.equipment_icon_texture
		upgrade.base_item_power = base_equip.equipment_base_attack_power
		upgrade.base_upgrade_cost = base_equip.equipment_base_upgrade_cost

		upgrade.item_lv = entry["lv"]
		upgrade.item_bonus_power = entry["bonus"]

		upgrade_list_equipment.append(upgrade)

func Save_Upgrade_List() -> Array:
	var arr := []
	for upgrade in upgrade_list_equipment:
		arr.append({
			"name": upgrade.item_name,
			"lv": upgrade.item_lv,
			"bonus": upgrade.item_bonus_power
		})
	return arr

func Load_Idle_List(data: Dictionary) -> void:
	for entry in data.get("idle_upgrades", []):
		for idle in idle_upgrades:
			if (idle.idle_name == entry["name"]):
				idle.idle_amount = entry["amount"]
				idle.Update_Power()

func Apply_Offline_Progress(last_played: int) -> void:
	var now := Time.get_unix_time_from_system()
	var seconds_away = max(0, now - last_played)
	
	# Cap offline seconds to MAX_OFFLINE_SECONDS
	seconds_away = min(seconds_away, MAX_OFFLINE_SECONDS)
	
	var dps = Get("dps") * OFFLINE_EFFICIENCY
	var earned = roundi(dps * seconds_away)
	Set("gold", Get("gold") + earned)
	
		# Format time into hours, minutes, seconds
	var time_str = format_seconds(seconds_away)
	
	# Show welcome back message
	welcome_back_message = str("Welcome back\nYou've been away for %s" % time_str,"\nYou earned ", FormatManager.format_number(earned), " Gold")

# Helper function to format seconds into hh:mm:ss
func format_seconds(seconds: float) -> String:
	var h = int(seconds / 3600)
	var m = int(float(int(seconds) % 3600) / 60)
	var s = int(int(seconds) % 60)
	return "%02d:%02d:%02d" % [h, m, s]

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Save_Last_Active_Time()

func _on_about_to_quit():
	Save_Last_Active_Time()

func Save_Last_Active_Time():
	last_active_time = int(Time.get_unix_time_from_system())
	Save_Data()
	get_tree().quit()

func Reset_Game() -> void:
	# =====================
	# CLEAR PLAYER VALUES
	# =====================
	current_player_lv = start_player_lv
	current_player_power = start_player_power
	current_equipment_power = 0
	current_player_gold = start_player_gold
	current_difficulty = start_difficulty
	current_planet = start_planet
	upgrade_multiplier = 1
	prestige_multiplier = 1.0
	last_active_time = 0

	# =====================
	# CLEAR INVENTORY / GEAR
	# =====================
	inventory.clear()
	equiped_gear.clear()
	upgrade_list_equipment.clear()

	# =====================
	# RESET IDLE UPGRADES
	# =====================
	for idle in idle_upgrades:
		idle.idle_amount = 0
		idle.Update_Power()

	# =====================
	# DELETE SAVE FILE
	# =====================
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

	update_ui.emit()

	# =====================
	# RELOAD CURRENT SCENE
	# =====================
	var tree := get_tree()
	if tree:
		tree.reload_current_scene()
