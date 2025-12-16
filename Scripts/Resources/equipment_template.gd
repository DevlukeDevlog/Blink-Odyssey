class_name EquipmentTemplate
extends Resource

enum EQUIPMENT_TYPE {WEAPON, SPACEHELMET, SPACESUIT, SPACEBOOTS}
enum EQUIPMENT_ATTRIBUTE {NONE, FIRE, DARK, LIGHT}

@export var equipment_type := EQUIPMENT_TYPE.WEAPON
@export var equipment_attribute := EQUIPMENT_ATTRIBUTE.NONE
@export var equipment_name := "Equipment Name"
@export var equipment_min_multiplier_attack := 0.01
@export var equipment_max_multiplier_attack := 0.50
@export var equipment_base_upgrade_cost := 50
@export var equipment_drop_chance := 0.02
@export var equipment_icon_texture := Texture2D.new()

var equipment_current_multiplier_attack := 0.00
var equipment_current_level := 0.00
var equipment_current_upgrade_cost := 50
