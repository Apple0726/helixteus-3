extends "res://Scripts/Battle/BattleEntity.gd"


func _ready() -> void:
	go_through_movement_cost = INF

func damage_entity(weapon_data: Dictionary):
	return true
