extends Area2D

export var texture:Texture
var y_acc:float = 0.0
var y_speed:float = 0.0

func _ready():
	$Sprite.texture = texture
