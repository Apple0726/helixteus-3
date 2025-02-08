extends "BattleEntity.gd"

@export var texture:Texture2D

var movement_remaining:float
var total_movement:float

func _ready():
	$Sprite2D.texture = texture

func do_damage(damage: float):
	print(damage)
