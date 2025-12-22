class_name EquipmentSLot
extends TextureButton

@onready var equipment_icon = %EquipmentIcon
@onready var equiped_label = %EquipedLabel

var equipment: EquipmentTemplate = null
var in_inventory := false
var is_equiped := false

func _ready() -> void:
	if (equipment):
		Setup_Equipment()

func Setup_Equipment() -> void:
	equipment_icon.texture = equipment.equipment_icon_texture
	disabled = !in_inventory
	
	if (is_equiped):
		equiped_label.text = "E"
	else:
		equiped_label.text = ""

func _on_pressed():
	DataManager.select_equipment.emit(equipment)
	disabled = true
