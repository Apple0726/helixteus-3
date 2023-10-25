extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_bullet_timer_timeout():
	var bullet:STMBullet = preload("res://Scenes/STM/STMBullet.tscn").instantiate()
	bullet.position = position
	get_parent().add_child(bullet)


func _on_laser_timer_timeout():
	pass # Replace with function body.


func _on_bomb_timer_timeout():
	pass # Replace with function body.
