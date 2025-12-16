class_name IdleTemplate
extends Resource

@export var idle_name := "Idle Name"
@export var idle_base_power := 10
@export var idle_base_upgrade_cost := 50
@export var idle_icon_texture := Texture2D.new()

var idle_current_power := 10
var idle_current_level := 0.00
var idle_current_upgrade_cost := 50
