extends Area2D

export var texture:Texture
var grav_acc:float = 0.0#gravity_acceleration

func _ready():
	$Sprite.texture = texture
