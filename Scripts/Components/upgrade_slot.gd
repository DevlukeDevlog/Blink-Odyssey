class_name UpgradeSlot
extends PanelContainer

@onready var upgrade_button = %UpgradeButton
@onready var sell_button = %SellButton
@onready var information_label = %InformationLabel
@onready var item_slot: ItemSlot = %ItemSlot

var can_sell := false
var information := ""
var update_multiplier := 1
var item = null

func _ready():
	Setup_Slot()
	DataManager.update_ui.connect(Update_UI)

func Setup_Slot() -> void:
	sell_button.visible = can_sell
	item_slot.visible = item != null
	item_slot.item = item
	item_slot.Setup_Slot()
	Update_UI()

func Update_UI() -> void:
	if item is UpgradeEquipmentTemplate:
		_update_item_ui()
	elif item is IdleTemplate:
		_update_idle_ui()
	else:
		_update_player_ui()

func _update_item_ui() -> void:
	var multiplier_to_show := update_multiplier
	var gold = DataManager.Get("gold")
	var temp_lv = item.item_lv
	var upgrade_cost := 0

	# Max mode: calculate how many upgrades can be afforded
	if update_multiplier == 0:
		multiplier_to_show = 0
		while true:
			var cost = int(item.base_upgrade_cost * pow(item.upgrade_cost_growth, max(1, temp_lv) - 1))
			if gold < cost:
				break
			gold -= cost
			temp_lv += 1
			multiplier_to_show += 1

		# If none affordable, still show 1 upgrade and its cost
		if multiplier_to_show == 0:
			multiplier_to_show = 1
			# Use cost of next level
			upgrade_cost = int(item.base_upgrade_cost * pow(item.upgrade_cost_growth, max(1, temp_lv) - 1))
		else:
			upgrade_cost = item.Get_Upgrade_Cost_Batch(multiplier_to_show)
	else:
		# Fixed multiplier: calculate batch cost
		upgrade_cost = item.Get_Upgrade_Cost_Batch(multiplier_to_show)

	# Update button (always show cost, disable if not enough gold)
	upgrade_button.text = str("x", multiplier_to_show, "\n", FormatManager.format_number(upgrade_cost), " Gold")
	upgrade_button.disabled = DataManager.Get("gold") < upgrade_cost

	# Update item info
	var info1 = str(item.item_name.capitalize())
	var info2 = str("Lv: ", FormatManager.format_number(item.item_lv))
	var info3 = str("Bonus Power: ", FormatManager.format_number(item.Get_Bonus_Power()))
	info3 += str(" [color=#1F7A1F]+", FormatManager.format_number(item.Get_Next_Upgrade_Bonus_Batch(multiplier_to_show)), "[/color]")
	information_label.text = str(info1, "\n", info2, "\n", info3)

func _update_idle_ui() -> void:
	var gold = DataManager.Get("gold")
	var multiplier_to_show := update_multiplier
	var buy_cost := 0
	var sell_value := 0

	# =========================
	# BUY (MAX MODE)
	# =========================
	if update_multiplier == 0:
		multiplier_to_show = 0
		var temp_amount = item.idle_amount
		var remaining_gold = gold

		while true:
			var cost = item.Get_Buy_Cost_For_Amount(temp_amount)
			if remaining_gold < cost:
				break
			remaining_gold -= cost
			temp_amount += 1
			multiplier_to_show += 1

		if multiplier_to_show == 0:
			multiplier_to_show = 1
			buy_cost = item.Get_Buy_Cost()
		else:
			buy_cost = item.Get_Buy_Cost_Batch(multiplier_to_show)

	# =========================
	# BUY (FIXED)
	# =========================
	else:
		buy_cost = item.Get_Buy_Cost_Batch(multiplier_to_show)

	# =========================
	# BUY BUTTON
	# =========================
	upgrade_button.text = str(
		"x", multiplier_to_show,
		"\n", FormatManager.format_number(buy_cost), " Gold"
	)
	upgrade_button.disabled = gold < buy_cost

	# =========================
	# SELL BUTTON
	# =========================
	if can_sell and item.idle_amount > 0:
		sell_button.visible = true

		if update_multiplier == 0:
			multiplier_to_show = item.idle_amount
			sell_value = item.Get_Sell_Value_Batch(0)
		else:
			multiplier_to_show = min(update_multiplier, item.idle_amount)
			sell_value = item.Get_Sell_Value_Batch(multiplier_to_show)

		sell_button.text = str(
			"Sell x", multiplier_to_show,
			"\n+",
			FormatManager.format_number(sell_value),
			" Gold"
		)
		sell_button.disabled = sell_value <= 0
	else:
		sell_button.visible = false

	# =========================
	# INFO
	# =========================
	var info1 = item.idle_name
	var info2 := str("Owned: ", FormatManager.format_number(item.idle_amount))
	var info3 := str(
		"DPS: ",
		FormatManager.format_number(item.Get_Power()),
		" [color=#1F7A1F]+",
		FormatManager.format_number(item.Get_Next_Buy_Power_Batch(update_multiplier)),
		"[/color]"
	)

	information_label.text = str(info1, "\n", info2, "\n", info3)

func _update_player_ui() -> void:
	var gold = DataManager.Get("gold")
	var temp_lv = DataManager.Get("level")
	var batch_cost := 0
	var multiplier_to_use := update_multiplier

	# Max mode
	if update_multiplier == 0:
		multiplier_to_use = 0
		while true:
			var cost = int(DataManager.level_base_cost * pow(DataManager.level_cost_growth, temp_lv - 1))
			if gold < cost:
				break
			gold -= cost
			temp_lv += 1
			multiplier_to_use += 1
		
		# If nothing is affordable, show 1 upgrade and its cost
		if multiplier_to_use == 0:
			multiplier_to_use = 1
			batch_cost = int(DataManager.level_base_cost * pow(DataManager.level_cost_growth, temp_lv - 1))
		else:
			batch_cost = DataManager.Get_Player_Level_Up_Cost(multiplier_to_use)
	else:
		# Fixed multiplier
		for i in range(update_multiplier):
			var cost = int(DataManager.level_base_cost * pow(DataManager.level_cost_growth, temp_lv - 1))
			batch_cost += cost
			temp_lv += 1

	# Update button (always show cost, disable if cannot afford)
	upgrade_button.text = str("x", multiplier_to_use, "\n", FormatManager.format_number(batch_cost), " Gold")
	upgrade_button.disabled = DataManager.Get("gold") < batch_cost

	# Update player info
	var info1 = str("Lv: ", FormatManager.format_number(DataManager.Get("level")))
	var info2 = str("Power: ", FormatManager.format_number(DataManager.Get("power")))
	info2 += str(" [color=#1F7A1F]+", FormatManager.format_number(DataManager.Get_Player_Level_Up_Power_Batch(multiplier_to_use)), "[/color]")
	information_label.text = str(info1, "\n", info2)

func _on_upgrade_button_pressed():
	if item == null:
		# Player upgrade
		if update_multiplier == 0:
			DataManager.Level_Up_Player_Max()
		else:
			for i in range(update_multiplier):
				DataManager.Level_Up_Player()
	elif item is UpgradeEquipmentTemplate:
		item.Upgrade(update_multiplier)
	elif item is IdleTemplate:
		item.Buy(update_multiplier)
		
	DataManager.update_ui.emit()

func _on_sell_button_pressed():
	if item is IdleTemplate:
		item.Sell(update_multiplier)
		
	DataManager.update_ui.emit()
