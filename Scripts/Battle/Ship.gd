extends Area2D

@export var texture:Texture2D
var y_acc:float = 0.0
var y_speed:float = 0.0

var agility:int
var initiative:int

func _ready():
	$Sprite2D.texture = texture

func roll_initiative():
	var range:int = 2 + log(randf()) / log(0.2)
	initiative = randi_range(agility - range, agility + range)
