extends Node2D

var laser_ready = false
var bomb_ready = false

func _draw():
	if laser_ready:
		draw_arc(Vector2.ZERO, 240.0, 0, 2*PI, 100, Color(1.0, 0.0, 0.0, 0.3), -1)
		draw_circle(Vector2.ZERO, 240.0, Color(1.0, 0.0, 0.0, 0.1))
	else:
		draw_arc(Vector2.ZERO, 240.0, 0, 2*PI, 100, Color(0.4, 0.4, 0.4, 0.3), -1)
		draw_circle(Vector2.ZERO, 240.0, Color(0.4, 0.4, 0.4, 0.1))

func _on_bullet_timer_timeout():
	var projectile:STMProjectile = preload("res://Scenes/STM/STMProjectile.tscn").instantiate()
	projectile.type = projectile.BULLET
	projectile.velocity = Vector2(1200, 0)
	projectile.damage = 1
	projectile.is_enemy_projectile = false
	projectile.position = position
	get_parent().get_node("GlowLayer").add_child(projectile)


func _on_laser_timer_timeout():
	laser_ready = true
	queue_redraw()
	var enemies_in_range = $LaserArea.get_overlapping_areas()
	var closest_enemy_index = -1
	var closest_enemy_distance = INF
	for i in len(enemies_in_range):
		var area:Area2D = enemies_in_range[i]
		var enemy_distance = area.position.distance_to(position)
		if enemy_distance < closest_enemy_distance:
			closest_enemy_distance = enemy_distance
			closest_enemy_index = i


func _on_bomb_timer_timeout():
	pass # Replace with function body.

func _on_light_timer_timeout():
	pass # Replace with function body.

func hit(damage:int):
	print("ship hit for %d damage" % damage)


func _on_laser_area_area_entered(area):
	print("Shoot laser")
	laser_ready = false
	queue_redraw()
	$LaserTimer.start()
