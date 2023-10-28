extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_bullet_timer_timeout():
	var projectile:STMProjectile = preload("res://Scenes/STM/STMProjectile.tscn").instantiate()
	projectile.type = projectile.BULLET
	projectile.velocity = Vector2(1000, 0)
	projectile.damage = 1
	projectile.is_enemy_projectile = false
	projectile.position = position
	get_parent().add_child(projectile)


func _on_laser_timer_timeout():
	pass # Replace with function body.


func _on_bomb_timer_timeout():
	pass # Replace with function body.

func hit(damage:int):
	print("ship hit for %d damage" % damage)
