class_name WeaknessIcon
extends Control

@onready var weakness_icon_texture = %WeaknessIconTexture
@onready var weakness_label = %WeaknessLabel

@export var weakness_icons_textures: Array[Texture2D] = []
@export var weakness_font: Font 

var enemy: EnemyTemplate = null

func _ready():
	Setup_Icon()

func Setup_Icon() -> void:
	if (enemy == null): return
	
	weakness_icon_texture = _get_weakness_texture(enemy.Get_Weakness_Name())
	weakness_label.hide()
	
	var weakness_name = enemy.Get_Weakness_Name()
	weakness_label.text = str("Weak to [font=" + weakness_font.resource_path + "]" + weakness_name + "[/font]")

func _get_weakness_texture(weakness_name: String) -> Texture2D:
	match weakness_name:
		"Fire":
			return weakness_icons_textures[0]
		"Dark":
			return weakness_icons_textures[1]
		"Light":
			return weakness_icons_textures[2]
	return weakness_icons_textures[-1]

func _on_mouse_entered():
	weakness_label.show()

func _on_mouse_exited():
	weakness_label.hide()
