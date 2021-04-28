extends Node2D

var velocity:Vector2
var speed:float
var cave_ref
var laser_texture

func _ready():
	pass # Replace with function body.

func _process(delta):
	position += speed * velocity
	speed *= 0.98 * delta * 60
	if speed < 0.5:
		for j in 9:
			cave_ref.add_proj(true, position, 10, deg2rad(j * 40), laser_texture, 5)
		set_process(false)
		cave_ref.remove_child(self)
		queue_free()
