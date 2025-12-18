class_name MissionTemplate
extends Resource

@export var mission_name := "Mission Name"
@export var mission_enemies: Array[EnemyTemplate] = []
@export var mission_boss: EnemyTemplate = null
@export var unlock_mission_name := "Unlocks Mission Name"

func Get_Mission_Size() -> int: return mission_enemies.size()
