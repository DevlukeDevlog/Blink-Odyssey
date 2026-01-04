class_name MissionButton
extends Button

var mission: MissionTemplate = null

func _ready() -> void:
	if (mission): Setup_Button()

func Setup_Button() -> void:
	text = mission.mission_name
	
	disabled = !DataManager.unlocked_missions.has(mission.mission_name)

func _on_pressed():
	if (DataManager.Get_Current_Mission() != mission):
		DataManager.Set_Current_Mission(mission)
	DataManager.select_mission.emit()
	SceneManager.Set_Current_Scene(SceneManager.SCENES.CLICK)
