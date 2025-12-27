class_name UpgradeEquipmentTemplate
extends Resource

# =====================================================
# STATIC DATA (SET ON CREATION)
# =====================================================
var item_name := ""
var item_icon_texture := Texture2D.new()

# Base scaling source (IMPORTANT)
var base_item_power := 1   # <- equipment base power

# =====================================================
# CURRENT STATE
# =====================================================
var item_lv := 0
var item_bonus_power := 0

# =====================================================
# SCALING VALUES
# =====================================================
var bonus_power_growth := 1.25   # 25% per level (feels GOOD)
var base_upgrade_cost := 10
var upgrade_cost_growth := 1.18

# =====================================================
# POWER CALCULATION (SCALABLE & REWARDING)
# =====================================================
func Get_Bonus_Power() -> int:
	if (item_lv == 0): return base_item_power
	return item_bonus_power

func Get_Next_Upgrade_Bonus() -> int:
	# Current bonus
	var current_bonus := Get_Bonus_Power()
	
	# Simulate next level
	var next_lv := item_lv + 1
	var next_bonus := float(base_item_power)
	next_bonus *= pow(bonus_power_growth, next_lv)
	
	var next_bonus_int = max(current_bonus + 1, int(round(next_bonus)))
	
	return next_bonus_int - current_bonus


# =====================================================
# UPGRADE COST
# =====================================================
func Get_Upgrade_Cost() -> int:
	var level = max(1, item_lv)
	return int(
		base_upgrade_cost *
		pow(upgrade_cost_growth, level - 1)
	)

func Get_Upgrade_Cost_Batch(multiplier: int) -> int:
	var temp_lv := item_lv
	var total_cost := 0
	var iterations := multiplier
	if iterations == 0:
		iterations = 999999  # effectively Max

	for i in range(iterations):
		var cost := int(base_upgrade_cost * pow(upgrade_cost_growth, max(1, temp_lv) - 1))
		total_cost += cost
		temp_lv += 1
		
		if total_cost < 0:
			return 0

	return total_cost

# =====================================================
# UPGRADE
# =====================================================
func Upgrade(iterations: int) -> bool:
	if iterations == 0:
		iterations = 999999  # MAX mode

	var upgraded_any := false

	for i in range(iterations):
		var cost := Get_Upgrade_Cost()
		if DataManager.Get("gold") < cost:
			break

		DataManager.Set("gold", DataManager.Get("gold") - cost)

		item_lv += 1

		var bonus := float(base_item_power) * pow(bonus_power_growth, item_lv)
		bonus = max(item_bonus_power + 1, int(round(bonus)))
		item_bonus_power = int(bonus)

		upgraded_any = true

	# Refresh power
	for item in DataManager.inventory:
		item.Update_Power()
	for item in DataManager.equiped_gear:
		item.Update_Power()

	DataManager.Calculate_Gear_Power()
	DataManager.update_ui.emit()

	return upgraded_any


func Get_Next_Upgrade_Bonus_Batch(multiplier: int) -> int:
	var temp_lv := item_lv
	var temp_bonus := item_bonus_power
	var iterations := multiplier
	if iterations == 0:
		iterations = 999999  # effectively Max

	var remaining_gold = DataManager.Get("gold")  # get current player gold

	for i in range(iterations):
		var cost := int(base_upgrade_cost * pow(upgrade_cost_growth, max(1, temp_lv) - 1))
		if remaining_gold < cost:
			break  # stop if cannot afford next upgrade

		# simulate bonus
		var next_bonus := float(base_item_power) * pow(bonus_power_growth, temp_lv + 1)
		next_bonus = max(int(round(next_bonus)), temp_bonus + 1)
		if next_bonus - temp_bonus <= 0:
			break

		# deduct cost for simulation
		remaining_gold -= cost

		temp_bonus = int(next_bonus)
		temp_lv += 1
	
	if (item_lv) == 0:
		temp_bonus -= base_item_power
		if (temp_bonus - item_bonus_power < 0):
			return 0
	return temp_bonus - item_bonus_power
