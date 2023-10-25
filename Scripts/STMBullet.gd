class_name STMBullet
extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position.x += delta * 1000.0
	if position.x >= 1400:
		queue_free()


func _on_area_2d_area_entered(area):
	area.get_parent().hit(1)
	queue_free()
