class_name ItemSlot
extends TextureRect

@onready var item_icon = %ItemIcon

var item = null

func _ready() -> void:
	Setup_Slot()

func Setup_Slot() -> void:
	if (item is UpgradeEquipmentTemplate):
		item_icon.texture = item.item_icon_texture
	elif (item is IdleTemplate):
		item_icon.texture = item.idle_icon_texture
