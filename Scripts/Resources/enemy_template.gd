class_name EnemyTemplate
extends Resource

enum ENEMY_TYPE {ENEMY, BOSS}
enum ENEMY_WEAKNESS {NONE, FIRE, DARK, LIGHT}

@export var enemy_type := ENEMY_TYPE.ENEMY
@export var enemy_name := "Enemy Name"
@export var enemy_base_max_health := 10
@export var enemy_weakness := ENEMY_WEAKNESS.NONE
@export var enemy_base_min_reward := 10
@export var enemy_timer := 0
@export var enemy_texture := Texture2D.new()

var current_reward := 10
var enemy_current_health := 10

func Setup() -> void:
	enemy_current_health = enemy_base_max_health
	current_reward = enemy_base_min_reward

func Take_Damage(damage: int) -> void:
	enemy_current_health = clampi(enemy_current_health - damage, 0, enemy_base_max_health)

func Is_Defeated() -> bool:
	if (enemy_current_health != 0): return false
	DataManager.current_player_gold += current_reward
	return true

func Get_Reward() -> int: return current_reward 
