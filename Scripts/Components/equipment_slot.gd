class_name EquipmentSLot
extends TextureButton

@onready var equipment_icon = %EquipmentIcon

var equipment: EquipmentTemplate = null
var in_inventory := false

func _ready() -> void:
	if (equipment):
		Setup_Equipment()

func Setup_Equipment() -> void:
	equipment_icon.texture = equipment.equipment_icon_texture
	disabled = !in_inventory

func _on_pressed():
	DataManager.select_equipment.emit(equipment)
	disabled = true
