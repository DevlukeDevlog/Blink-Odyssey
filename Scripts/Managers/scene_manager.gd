extends Node

enum SCENES {CLICK, INVENTORY, UPGRADE}

var current_scene := SCENES.CLICK

func Get_Current_Scene() -> SCENES: return current_scene
func Set_Current_Scene(scene: SCENES) -> void: current_scene = scene
