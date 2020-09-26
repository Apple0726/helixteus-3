extends KinematicBody2D

var velocity:Vector2 = Vector2.ZERO
var texture

func _ready():
	$Sprite.texture = texture

func _physics_process(delta):
	if move_and_collide(velocity) != null:
		get_parent().remove_child(self)
