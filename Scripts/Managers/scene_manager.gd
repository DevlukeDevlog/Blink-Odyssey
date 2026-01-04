extends Node

enum SCENES { CLICK, INVENTORY, UPGRADE, MISSIONS }

var MAIN_SCENE: PackedScene
var START_SCENE: PackedScene

var current_scene: SCENES = SCENES.CLICK
var current_node_scene: Node = null

func _ready() -> void:
	MAIN_SCENE = load("res://Scenes/main_scene.tscn")
	START_SCENE = load("res://Scenes/start_scene.tscn")

func Get_Current_Scene() -> SCENES:
	return current_scene

func Set_Current_Scene(scene: SCENES) -> void:
	current_scene = scene
	DataManager.update_ui.emit()

func Set_Scene(scene: PackedScene) -> void:
	if current_node_scene:
		current_node_scene.queue_free()
		current_node_scene = null
	
	current_node_scene = scene.instantiate()
	add_child(current_node_scene)
