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
