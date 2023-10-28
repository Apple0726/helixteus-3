class_name STMHX
extends Node2D

var HP:int = 3

func _ready():
	position.x = 1400
	position.y = randf_range(50, 670)
	var target_position = Vector2(randf_range(850, 1200), randf_range(50, 670))
	var travel_duration = (position - target_position).length() / 200.0 * sqrt(scale.x)
	var tween = create_tween()
	tween.tween_property(self, "position", target_position, travel_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	$ShootTimer.start(travel_duration)
	for i in HP:
		var HP_dot = TextureRect.new()
		HP_dot.texture = preload("res://Graphics/Misc/bullet.png")
		HP_dot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		HP_dot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		HP_dot.custom_minimum_size.x = 48
		$HPBar.add_child(HP_dot)

func hit(damage:int):
	HP -= damage
	for i in damage:
		if $HPBar.get_child_count() > 0:
			$HPBar.get_child(0).queue_free()
	if HP <= 0:
		$Area2D.set_deferred("monitorable", false)
		$AnimationPlayer.play("DeathAnim")
		await $AnimationPlayer.animation_finished
		queue_free()


func _on_shoot_timer_timeout():
	if $ShootTimer.one_shot:
		$ShootTimer.start(1.4)
		$ShootTimer.one_shot = false
	for i in 5:
		var angle = remap(i, 0, 4, -0.5, 0.5)
		var projectile:STMProjectile = preload("res://Scenes/STM/STMProjectile.tscn").instantiate()
		projectile.is_enemy_projectile = true
		projectile.velocity = Vector2(-300 * cos(angle), 100 * sin(angle))
		projectile.position = position
		projectile.damage = 1
		projectile.get_node("Sprite2D").texture = preload("res://Graphics/Cave/Projectiles/enemy_bullet.png")
		get_parent().add_child(projectile)
