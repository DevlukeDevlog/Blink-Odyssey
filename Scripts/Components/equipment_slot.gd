class_name EquipmentSLot
extends TextureButton

@onready var equipment_icon = %EquipmentIcon
@onready var equiped_label = %EquipedLabel
@onready var improved_icon = %ImprovedIcon

const IMPROVED_UP_PLACEHOLDER = preload("res://Assets/Art/Test/improved_up_placeholder.png")
const IMPROVED_DOWN_PLACEHOLDER = preload("res://Assets/Art/Test/improved_down_placeholder.png")

var equipment: EquipmentTemplate = null
var in_inventory := false
var is_equiped := false
var in_slot := false

func _ready() -> void:
	if (equipment):
		Setup_Equipment()

func _process(_delta):
	if (Input.is_action_just_pressed("Deselect") and in_slot):
		DataManager.unselect_equipment.emit(equipment)
		disabled = false

func Setup_Equipment() -> void:
	improved_icon.hide()
	equipment_icon.texture = equipment.equipment_icon_texture
	disabled = !in_inventory
	
	if (is_equiped):
		equiped_label.text = "E"
	else:
		equiped_label.text = ""
		Set_Improved()

func Set_Improved() -> void:
	improved_icon.show()
	var improved_power := DataManager.Calculate_Improved_Power(equipment)
	if (improved_power) > 0:
		improved_icon.texture = IMPROVED_UP_PLACEHOLDER
	elif (improved_power) < 0:
		improved_icon.texture = IMPROVED_DOWN_PLACEHOLDER
	else:
		improved_icon.hide()

func _on_pressed():
	DataManager.select_equipment.emit(equipment)
	disabled = true

func _on_mouse_entered():
	in_slot = true

func _on_mouse_exited():
	in_slot = false
