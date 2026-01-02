class_name UpgradeSystem
extends VBoxContainer

@export var slot_template : PackedScene

@onready var player_upgrades_container = %PlayerUpgradesContainer
@onready var equipment_upgrades_container = %EquipmentUpgradesContainer
@onready var idle_upgrades_container = %IdleUpgradesContainer

@onready var x_1_button = %X1Button
@onready var x_10_button = %X10Button
@onready var x_100_button = %X100Button
@onready var max_button = %MaxButton

var update_multiplier := 1

func Setup_Upgrades() -> void:
	_clear_upgrades(player_upgrades_container)
	_clear_upgrades(equipment_upgrades_container)
	_clear_upgrades(idle_upgrades_container)

	_populate_upgrades()
	_populate_idle_upgrades()

	_on_x_1_button_pressed()


func _clear_upgrades(container) -> void:
	for child in container.get_children():
		if (child is UpgradeSlot):
			child.free()

func _populate_upgrades() -> void:
	var upgrade_slot = slot_template.instantiate() as UpgradeSlot
	upgrade_slot.can_sell = false
	upgrade_slot.custom_minimum_size.x = 350
	player_upgrades_container.add_child(upgrade_slot)
	
	# Player slot does not have item, just upgrade button
	upgrade_slot.update_multiplier = DataManager.Get("multiplier")
	
	# Equipment upgrades
	for item_gear in DataManager.equiped_gear:
		var upgrade_item := DataManager.Get_Upgrade_Item(item_gear.equipment_name)
		if upgrade_item:
			# Move to front
			DataManager.upgrade_list_equipment.erase(upgrade_item)
			DataManager.upgrade_list_equipment.insert(0, upgrade_item)
	
	for item in DataManager.upgrade_list_equipment:
		upgrade_slot = slot_template.instantiate() as UpgradeSlot
		upgrade_slot.can_sell = false
		upgrade_slot.item = item
		upgrade_slot.custom_minimum_size.x = 350
		upgrade_slot.update_multiplier = DataManager.Get("multiplier")
		equipment_upgrades_container.add_child(upgrade_slot)

func _populate_idle_upgrades() -> void:
	for idle in DataManager.idle_upgrades:
		var slot := slot_template.instantiate() as UpgradeSlot
		slot.item = idle
		slot.can_sell = true
		slot.custom_minimum_size.x = 350
		slot.update_multiplier = DataManager.Get("multiplier")
		idle_upgrades_container.add_child(slot)


func Update_UI() -> void:
	for child in player_upgrades_container.get_children():
		if (child is UpgradeSlot):
			child.Update_UI()

func _setup_buttons() -> void:
	x_1_button.disabled = false
	x_10_button.disabled = false
	x_100_button.disabled = false
	max_button.disabled = false

func _on_x_1_button_pressed():
	_setup_buttons()
	x_1_button.disabled = true
	DataManager.Set("multiplier",1)
	_update_all_slots_multiplier(1)

func _on_x_10_button_pressed():
	_setup_buttons()
	x_10_button.disabled = true
	DataManager.Set("multiplier",10)
	_update_all_slots_multiplier(10)

func _on_x_100_button_pressed():
	_setup_buttons()
	x_100_button.disabled = true
	DataManager.Set("multiplier",100)
	_update_all_slots_multiplier(100)

func _on_max_button_pressed():
	_setup_buttons()
	max_button.disabled = true
	DataManager.Set("multiplier",0)
	_update_all_slots_multiplier(0)

func _update_all_slots_multiplier(multiplier: int) -> void:
	for container in [player_upgrades_container, equipment_upgrades_container, idle_upgrades_container]:
		for child in container.get_children():
			if child is UpgradeSlot:
				child.update_multiplier = multiplier
				child.Update_UI()
