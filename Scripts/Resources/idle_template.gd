class_name IdleTemplate
extends Resource

@export var idle_name := "Idle Name"
@export var idle_base_power := 10
@export var idle_base_upgrade_cost := 50
@export var idle_cost_growth := 1.15
@export var idle_icon_texture := Texture2D.new()

var idle_amount := 0
var idle_current_power := 0

# =====================================================
# POWER
# =====================================================
func Update_Power() -> void:
	idle_current_power = idle_amount * idle_base_power

func Get_Power() -> int:
	return idle_current_power

# =====================================================
# BUY COST
# =====================================================
func Get_Buy_Cost_For_Amount(amount: int) -> int:
	return int(
		idle_base_upgrade_cost *
		pow(idle_cost_growth, max(0, amount))
	)

func Get_Buy_Cost() -> int:
	return Get_Buy_Cost_For_Amount(idle_amount)

func Get_Buy_Cost_Batch(multiplier: int) -> int:
	var temp_amount := idle_amount
	var total := 0
	var iterations := multiplier

	if iterations == 0:
		iterations = 999999

	for i in range(iterations):
		var cost := Get_Buy_Cost_For_Amount(temp_amount)
		total += cost
		temp_amount += 1

	return total

# =====================================================
# BUY
# =====================================================
func Buy(iterations: int) -> bool:
	if iterations == 0:
		iterations = 999999

	var bought := false

	for i in range(iterations):
		var cost := Get_Buy_Cost()
		if DataManager.Get("gold") < cost:
			break

		DataManager.Set("gold", DataManager.Get("gold") - cost)
		idle_amount += 1
		bought = true

	if bought:
		Update_Power()

	return bought

# =====================================================
# SELL VALUE
# =====================================================
func Get_Sell_Value_For_Amount(amount: int) -> int:
	var buy_cost := Get_Buy_Cost_For_Amount(amount)
	return int(buy_cost * 0.5)

func Get_Sell_Value_Batch(multiplier: int) -> int:
	var temp_amount := idle_amount
	var total := 0
	var iterations := multiplier

	if iterations == 0:
		iterations = temp_amount

	for i in range(iterations):
		if temp_amount <= 0:
			break

		temp_amount -= 1
		total += Get_Sell_Value_For_Amount(temp_amount)

	return total

# =====================================================
# SELL (NOW GIVES GOLD)
# =====================================================
func Sell(iterations: int) -> bool:
	if idle_amount <= 0:
		return false

	if iterations == 0:
		iterations = idle_amount

	var sold = min(iterations, idle_amount)
	var gold_gain := 0

	for i in range(sold):
		idle_amount -= 1
		gold_gain += Get_Sell_Value_For_Amount(idle_amount)

	DataManager.Set("gold", DataManager.Get("gold") + gold_gain)
	Update_Power()
	return true

# =====================================================
# UI PREVIEW
# =====================================================
func Get_Next_Buy_Power_Batch(multiplier: int) -> int:
	var temp_amount := idle_amount
	var gained := 0
	var remaining_gold = DataManager.Get("gold")

	if multiplier == 0:
		multiplier = 999999

	for i in range(multiplier):
		var cost := Get_Buy_Cost_For_Amount(temp_amount)
		if remaining_gold < cost:
			break

		remaining_gold -= cost
		temp_amount += 1
		gained += idle_base_power

	return gained
