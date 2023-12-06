extends Node2D

@onready var game = get_node("/root/Game")
@onready var STM_node = get_parent()
var laser_ready = false
var bomb_ready = false
var light_ready = false
var areas_in_laser_range = []

func _draw():
	var laser_range = 200.0 * (1.0 + STM_node.laser_lv / 5.0)
	if laser_ready:
		draw_arc(Vector2.ZERO, laser_range, 0, 2*PI, 100, Color(1.0, 0.0, 0.0, 0.3), -1)
		draw_circle(Vector2.ZERO, laser_range, Color(1.0, 0.0, 0.0, 0.1))
	else:
		draw_arc(Vector2.ZERO, laser_range, 0, 2*PI, 100, Color(0.4, 0.4, 0.4, 0.3), -1)
		draw_circle(Vector2.ZERO, laser_range, Color(0.4, 0.4, 0.4, 0.1))

func _input(event):
	if not $StunTimer.is_stopped():
		return
	if bomb_ready and Input.is_action_just_pressed("left_click"):
		bomb_ready = false
		$BombTimer.start()
		$Bomb/AnimationPlayer.stop()
		$BombParticles.emitting = false
		var bomb:STMProjectile = preload("res://Scenes/STM/STMProjectile.tscn").instantiate()
		bomb.type = bomb.BOMB
		bomb.get_node("Sprite2D").texture = load("res://Graphics/Weapons/bomb%s.png" % STM_node.bomb_lv)
		bomb.velocity = Vector2(700, 0)
		bomb.scale *= 2.0
		bomb.damage = 2 + STM_node.bomb_lv
		bomb.position = position
		bomb.STM_node = STM_node
		STM_node.add_child(bomb)
		get_node("../Control/BombActivateLabel").visible = false
	if light_ready and Input.is_action_just_pressed("right_click"):
		light_ready = false
		$LightTimer.start()
		$Sprite2D.material.set_shader_parameter("glow", 0.0)
		var light = preload("res://Scenes/STM/STMLight.tscn").instantiate()
		light.fade_speed = 2.0
		light.position = position
		STM_node.get_node("GlowLayer").add_child(light)
		get_node("../Control/LightActivateLabel").visible = false

func stun():
	$Stun.show()
	$BulletTimer.paused = true
	$LaserTimer.paused = true
	$BombTimer.paused = true
	$LightTimer.paused = true

func _on_bullet_timer_timeout():
	var projectile:STMProjectile = preload("res://Scenes/STM/STMProjectile.tscn").instantiate()
	projectile.type = projectile.BULLET
	projectile.get_node("Sprite2D").texture = load("res://Graphics/Weapons/bullet%s.png" % STM_node.bullet_lv)
	projectile.velocity = Vector2(1200, 0)
	projectile.damage = 1
	projectile.scale *= [1.0, 1.2, 1.4, 1.7, 2.0][STM_node.bullet_lv - 1]
	projectile.position = position
	projectile.STM_node = STM_node
	STM_node.add_child(projectile)


func _on_laser_timer_timeout():
	animate_flash(get_node("../LaserTimerBar/TextureProgressBar/ColorRect"))
	laser_ready = true
	queue_redraw()
	if len(areas_in_laser_range) == 0:
		return
	var closest_enemy_distance = INF
	var closest_area = null
	for area in areas_in_laser_range:
		var enemy:STMHX = area.get_parent()
		if enemy.stunned:
			continue
		var enemy_distance = enemy.position.distance_to(position)
		if enemy_distance < closest_enemy_distance:
			closest_enemy_distance = enemy_distance
			closest_area = area
	if closest_area != null:
		shoot_laser(closest_area.get_parent())


func _on_bomb_timer_timeout():
	animate_flash(get_node("../BombTimerBar/TextureProgressBar/ColorRect"))
	bomb_ready = true
	$Bomb/AnimationPlayer.play("Bomb grow")
	$BombParticles.emitting = true
	var bomb_activate_label:Label = get_node("../Control/BombActivateLabel")
	if bomb_activate_label.visible:
		var label_tween = create_tween()
		label_tween.tween_property(bomb_activate_label, "modulate:a", 1.0, 0.3)

func _on_light_timer_timeout():
	animate_flash(get_node("../LightTimerBar/TextureProgressBar/ColorRect"))
	light_ready = true
	var tween = create_tween()
	tween.tween_property($Sprite2D.material, "shader_parameter/glow", 0.7, 0.3)
	var light_activate_label:Label = get_node("../Control/LightActivateLabel")
	if light_activate_label.visible:
		var label_tween = create_tween()
		label_tween.tween_property(light_activate_label, "modulate:a", 1.0, 0.3)

func animate_flash(flash):
	flash.visible = true
	flash.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	
func hit(damage:int):
	STM_node.penalty_time += 6 * (1 + (game.MUs.STMB - 1) * 0.15) * damage


func _on_laser_area_area_entered(area):
	areas_in_laser_range.append(area)
	if laser_ready:
		shoot_laser(area.get_parent())

func shoot_laser(enemy:STMHX):
	laser_ready = false
	queue_redraw()
	$LaserTimer.start()
	enemy.stun(1.2 * STM_node.laser_lv / STM_node.minigame_time_speed)
	var laser:Control = get_node("../GlowLayer/Laser")
	laser.visible = true
	laser.rotation = atan2(enemy.position.y - position.y, enemy.position.x - position.x)
	var laser_length = enemy.position.distance_to(position)
	laser.size.x = laser_length
	laser.material.set_shader_parameter("noise_scale", Vector2(100.0 / laser_length, 0.0))
	get_node("../GlowLayer/LaserAnimationPlayer").play("Laser fade", -1, STM_node.minigame_time_speed)

func _on_laser_area_area_exited(area):
	areas_in_laser_range.erase(area)

func _on_stun_timer_timeout():
	$Stun.hide()
	$BulletTimer.paused = false
	$LaserTimer.paused = false
	$BombTimer.paused = false
	$LightTimer.paused = false
