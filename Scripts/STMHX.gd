class_name STMHX
extends Node2D

static var enemies_on_screen:int = 0

var HP:int = 3
var move_tween
var STM_node:Node2D
var stunned = false
var color:int
var type:int
var shoot_delay:float
var props:Dictionary = {}
var projectile_initial_speed:float

func _ready():
	position.x = 1400
	position.y = randf_range(50, 670)
	var target_position = Vector2(randf_range(750, 1200), randf_range(50, 670))
	var travel_duration = (position - target_position).length() / 100.0 * sqrt(scale.x)
	move_tween = create_tween()
	move_tween.set_speed_scale(STM_node.minigame_time_speed)
	move_tween.tween_property(self, "position", target_position, travel_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	move_tween.tween_callback(setup_shoot_timer)
	$Sprite2D.texture = load("res://Graphics/HX/%s_%s.png" % [color, type+1])
	set_process(false)
	if color == 1:
		projectile_initial_speed = 500
	elif color == 4:
		projectile_initial_speed = 150
	else:
		projectile_initial_speed = 200
	if type == 0:
		shoot_delay = 1.4
	elif type == 1:
		shoot_delay = 0.3
		props.center = clamp(target_position.y, 200, 520)
		props.y_movement_direction = [-1, 1][randi() % 2]
	elif type == 2:
		shoot_delay = 0.5
		props.shots_before_cooldown = 5
		props.cooldown_timer = 0.0
	elif type == 3:
		shoot_delay = 0.15
		props.shots_before_moving = 50
		props.angle = randf_range(0, TAU)
		props.angle_variation_direction = [-1, 1][randi() % 2]
	for i in HP:
		var HP_dot = TextureRect.new()
		HP_dot.texture = preload("res://Graphics/Misc/bullet.png")
		HP_dot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		HP_dot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		HP_dot.custom_minimum_size.x = 48
		$HPBar.add_child(HP_dot)
	enemies_on_screen += 1

func _process(delta):
	if type == 1:
		position.y += props.y_movement_direction * delta * 5.0
		if position.y < props.center - 150 or position.y > props.center + 150:
			props.y_movement_direction *= -1
	elif type == 2:
		props.cooldown_timer -= delta
		if props.cooldown_timer <= 0.0:
			props.shots_before_cooldown = 5
			set_process(false)
	
func hit(damage:int):
	HP -= damage
	for i in damage:
		if $HPBar.get_child_count() > 0:
			$HPBar.get_child(0).queue_free()
	if HP <= 0:
		if $ShootTimer.timeout.is_connected(self["_on_enemy%s_shoot_timer_timeout" % (type+1)]):
			$ShootTimer.timeout.disconnect(self["_on_enemy%s_shoot_timer_timeout" % (type+1)])
		$Area2D.set_deferred("monitorable", false)
		$Area2D.set_deferred("monitoring", false)
		$AnimationPlayer.play("DeathAnim", -1, STM_node.minigame_time_speed)
		await $AnimationPlayer.animation_finished
		queue_free()

func stun(duration:float):
	stunned = true
	$StunTimer.start(duration)
	$Sprite2D.material.set_shader_parameter("flash", 1.0)
	var tween = create_tween()
	tween.set_speed_scale(STM_node.minigame_time_speed)
	tween.tween_property($Sprite2D.material, "shader_parameter/flash", 0.0, 0.3)
	$Sprite2D/Stun.visible = true
	$ShootTimer.paused = true
	if move_tween:
		move_tween.pause()

func setup_shoot_timer():
	$ShootTimer.start(shoot_delay / STM_node.minigame_time_speed)
	set_process(type in [1])
	$ShootTimer.timeout.connect(self["_on_enemy%s_shoot_timer_timeout" % (type+1)])

func _on_enemy1_shoot_timer_timeout():
	var ship_pos:Vector2 = STM_node.mouse_pos
	var angle_relative_to_ship = atan2(position.y - ship_pos.y, position.x - ship_pos.x)
	for i in 5:
		var angle = remap(i, 0, 4, -0.6, 0.6)
		add_enemy_projectile(projectile_initial_speed * Vector2(-cos(angle - angle_relative_to_ship), sin(angle - angle_relative_to_ship)))

func _on_enemy2_shoot_timer_timeout():
	add_enemy_projectile(projectile_initial_speed * Vector2.LEFT)

func _on_enemy3_shoot_timer_timeout():
	if props.cooldown_timer > 0.0:
		return
	if props.shots_before_cooldown % 2 == 1:
		for i in 8:
			var angle = remap(i, 0, 7, -0.9, 0.9)
			add_enemy_projectile(projectile_initial_speed * Vector2(-cos(angle), sin(angle)))
	else:
		for i in 7:
			var angle = remap(i, 0, 6, -0.8, 0.8)
			add_enemy_projectile(projectile_initial_speed * Vector2(-cos(angle), sin(angle)))
	props.shots_before_cooldown -= 1
	if props.shots_before_cooldown <= 0:
		props.cooldown_timer = 2.5
		set_process(true)

func _on_enemy4_shoot_timer_timeout():
	if props.has("moving"):
		return
	add_enemy_projectile(projectile_initial_speed * Vector2(-cos(props.angle), sin(props.angle)))
	props.angle += props.angle_variation_direction * 0.05
	props.shots_before_moving -= 1
	if props.shots_before_moving <= 0:
		props.moving = true
		move_tween = create_tween()
		move_tween.set_speed_scale(STM_node.minigame_time_speed)
		var target_position = Vector2(randf_range(60, 1220), randf_range(60, 660))
		var travel_duration = (position - target_position).length() / 100.0 * sqrt(scale.x)
		move_tween.tween_property(self, "position", target_position, travel_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		move_tween.tween_callback(func():
			props.shots_before_moving = 50
			props.erase("moving"))

func add_enemy_projectile(velocity:Vector2):
	var projectile:STMProjectile = preload("res://Scenes/STM/STMProjectile.tscn").instantiate()
	projectile.enemy_projectile_type = color
	projectile.scale *= 0.5
	projectile.velocity = velocity
	projectile.position = position
	projectile.damage = 1
	projectile.get_node("Sprite2D").texture = preload("res://Graphics/Cave/Projectiles/enemy_bullet.png")
	projectile.STM_node = STM_node
	STM_node.get_node("GlowLayer").add_child(projectile)
	
func _on_stun_timer_timeout():
	if not is_inside_tree():
		return
	stunned = false
	$Sprite2D/Stun.visible = false
	$ShootTimer.paused = false
	if move_tween:
		move_tween.play()

func _on_tree_exited():
	enemies_on_screen -= 1
