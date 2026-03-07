extends "BattleEntity.gd"

var enemy_class:int
var enemy_type:int
var HX_nodes:Array
var ship_nodes:Array
var position_preferences:Dictionary
var obstacles_in_range:Array = []
var target_position:Vector2
var target_angle:float
var target_angle_max_deviation:float


func _ready() -> void:
	super()
	collision_shape_radius = 24.0
	movement_remaining = (agility + agility_buff) * METERS_PER_AGILITY
	total_movement_base = (agility + agility_buff) * METERS_PER_AGILITY
	go_through_movement_cost = 30.0
	$Sprite2D.material.set_shader_parameter("starlight_enabled", true)
	$Sprite2D.material.set_shader_parameter("starlight_angle", battle_scene.starlight_angle)
	$Sprite2D.material.set_shader_parameter("starlight_color", battle_scene.average_starlight_color)
	$Sprite2D.material.set_shader_parameter("starlight_energy", battle_scene.starlight_energy)

func initialize_stats(data: Dictionary):
	passive_abilities = data.passive_abilities
	enemy_class = data["class"]
	enemy_type = data.type
	super(data)

func determine_target():
	var distances = []
	var strengths = []
	for i in len(ship_nodes):
		distances.append(position.distance_squared_to(ship_nodes[i].position))
		strengths.append(ship_nodes[i].total_HP * (
			ship_nodes[i].attack + ship_nodes[i].attack_buff
			+ ship_nodes[i].defense + ship_nodes[i].defense_buff
			+ ship_nodes[i].accuracy + ship_nodes[i].accuracy_buff
			+ ship_nodes[i].agility + ship_nodes[i].agility_buff))
	var priorities = []
	var max_priority = 0.0
	for i in len(ship_nodes):
		var priority = distances[i] * strengths[i] * (1.1 - ship_nodes[i].HP / ship_nodes[i].total_HP)
		max_priority = max(max_priority, priority)
		priorities.append(priority)
	return priorities.find(max_priority)

enum Attack {
	NORMAL,
	LASER,
	MAGIC_BULLET,
	CORRODING_BULLET,
}
var attack_type = Attack.NORMAL
var attack_data = {
	Attack.NORMAL:{"damage": 3.0, "accuracy": 1.0},
	Attack.LASER:{"damage": 2.0, "accuracy": 1.8},
	Attack.MAGIC_BULLET:{"damage": 2.0, "accuracy": 1.5},
	Attack.CORRODING_BULLET:{"damage": 2.0, "accuracy": 1.0},
}

func take_turn():
	await super()
	if HP <= 0: # For example, if burned to death during super() call
		end_turn()
		return
	if status_effects[Battle.StatusEffect.STUN] > 0:
		decrement_status_effects_buffs()
		ending_turn()
		return
	decrement_status_effects_buffs()
	if enemy_class == 2:
		if randf() < 0.4 and lv >= 9:
			attack_type = Attack.LASER
		else:
			attack_type = Attack.CORRODING_BULLET
	elif enemy_class == 3:
		var pushable_ships = get_pushable_ships()
		if not pushable_ships.is_empty():
			await get_tree().create_timer(0.5).timeout
			push_ship(pushable_ships.pick_random())
			return
	elif enemy_class == 4:
		attack_type = Attack.MAGIC_BULLET
	var ship_target_id = determine_target()
	target_position = ship_nodes[ship_target_id].position
	position_preferences = {}
	var movement_remaining_base = total_movement
	var speed = velocity.length()
	if speed > 0.0:
		create_tween().tween_property(self, "velocity", velocity.normalized() * max(speed - movement_remaining_base, 0.0), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		movement_remaining_base = max(movement_remaining_base - speed, 0.0)
		await get_tree().create_timer(0.1).timeout
	$CollisionShapeFinder/CollisionShape2D.shape.radius = movement_remaining_base
	if movement_remaining_base > 0.0:
		for j in range(64):
			var th = lerp(0.0, 2.0 * PI, j / 64.0)
			var inside_obstacle = false
			movement_remaining = movement_remaining_base # in meters
			var r = 0.0 # in pixels
			while movement_remaining > 0.0:
				r += 2.0 * PIXELS_PER_METER
				movement_remaining -= 2.0
				var pos = position + r * Vector2.from_angle(th)
				if not Rect2(-640.0, -360.0, 2560.0, 1440.0).has_point(pos):
					break
				for obstacle in obstacles_in_range:
					if not inside_obstacle and Geometry2D.is_point_in_polygon(pos, obstacle.get_node("CollisionShape2D/Polygon2D").polygon):
						movement_remaining = max(movement_remaining - obstacle.go_through_movement_cost, 0.0)
						if movement_remaining > 0.0:
							inside_obstacle = true
						else:
							continue
					elif inside_obstacle and not Geometry2D.is_point_in_polygon(pos, obstacle.get_node("CollisionShape2D/Polygon2D").polygon):
						inside_obstacle = false
				if movement_remaining >= 0.0:
					calculate_position_preferences(position + r * Vector2.from_angle(th))
		var target_move_position:Vector2 = position
		var lowest_weight:float = INF
		for pos in position_preferences:
			if position_preferences[pos] < lowest_weight:
				lowest_weight = position_preferences[pos]
				target_move_position = pos
		if velocity == Vector2.ZERO:
			if battle_scene.animations_sped_up:
				await get_tree().create_timer(0.1).timeout
			else:
				await get_tree().create_timer(0.5).timeout
		await move(target_move_position)
	attack_target()

func calculate_position_preferences(pos:Vector2):
	if position_preferences.has(pos):
		return
	var HX_proximity_weight:float = 0.0 
	var ship_proximity_weight:float = 0.0
	var obstacle_proximity_weight:float = 0.0
	var boundary_proximity_weight:float = 0.0
	var distance_from_current_position_weight:float = 0.001 * pos.distance_squared_to(position)
	for HX in HX_nodes:
		# Enemies try to move far from each other
		HX_proximity_weight += 2.0e6 / max(pow(10.0 * PIXELS_PER_METER, 2), pos.distance_squared_to(HX.position))
	for obstacle in battle_scene.obstacle_nodes:
		# Stay away from obstacles
		obstacle_proximity_weight += 5.0e6 / max(pow(10.0 * PIXELS_PER_METER, 2), pos.distance_squared_to(obstacle.position))
	var final_accuracy = (accuracy + accuracy_buff) * attack_data[attack_type].accuracy
	var ship_target_distance = 40.0 + final_accuracy + 2.0 * max(0.0, final_accuracy - 12.0)
	if enemy_class == 3:
		ship_target_distance = 16.0
	elif enemy_class == 4:
		ship_target_distance = 150.0
	for ship in ship_nodes:
		# Try to get close to ships, but not too close or too far (ideal distance of ship_target_distance meters)
		var r = pos.distance_squared_to(ship.position)
		ship_proximity_weight += 1000.0 * (1.0 - exp(-pow(r - pow(ship_target_distance * PIXELS_PER_METER, 2), 2) / 4.0e9)) + 0.001 * abs(r - pow(ship_target_distance * PIXELS_PER_METER, 2))
	boundary_proximity_weight += pow(max(-pos.x - 440.0, 0.0), 2) * 0.2
	boundary_proximity_weight += pow(max(pos.x - 1720.0, 0.0), 2) * 0.2
	boundary_proximity_weight += pow(max(-pos.y - 160.0, 0.0), 2) * 0.2
	boundary_proximity_weight += pow(max(pos.y - 880.0, 0.0), 2) * 0.2
	position_preferences[pos] = HX_proximity_weight + ship_proximity_weight + obstacle_proximity_weight + boundary_proximity_weight + distance_from_current_position_weight
	
func move(target_pos:Vector2):
	if battle_scene.animations_sped_up:
		var tween = create_tween()
		tween.tween_property(self, "position", target_pos, 0.2)
		await tween.finished
	else:
		var tween = create_tween()
		battle_scene.view_tween = create_tween()
		tween.tween_property(self, "position", target_pos, 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		battle_scene.view_tween.tween_property(game.view, "position", Vector2(640, 360) - target_pos * game.view.scale.x, 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		await tween.finished

func spawn_ball(angle:float, ball_HP:int, ball_size:float):
	var ball = preload("res://Scenes/Battle/Obstacle.tscn").instantiate()
	ball.position = 60.0 * Vector2.from_angle(angle) + position
	ball.get_node("Sprite2D").scale = Vector2.ONE * ball_size / 20.0
	ball.get_node("Sprite2D").texture = preload("res://Graphics/Cave/Projectiles/bubble.png")
	ball.total_HP = ball_HP
	ball.HP = ball_HP
	ball.attack = 10
	ball.defense = 10
	ball.accuracy = 10
	ball.agility = 10
	ball.go_through_movement_cost = 30.0
	ball.collision_shape_radius = ball_size
	ball.velocity = 80.0 * Vector2.from_angle(angle)
	if not battle_scene.animations_sped_up:
		ball.get_node("Sprite2D").material.set_shader_parameter("alpha", 0.0)
		ball.get_node("VelocityArrow").modulate.a = 0.0
		var fade_in_tween = create_tween().set_parallel()
		fade_in_tween.tween_property(ball.get_node("Sprite2D").material, "shader_parameter/alpha", 1.0, 0.5)
		fade_in_tween.tween_property(ball.get_node("VelocityArrow"), "modulate:a", 1.0, 0.5)
	battle_scene.add_child(ball)
	battle_scene.obstacle_nodes.append(ball)

var projectiles = []
func fire_magic_bullets():
	var spawn_position:Vector2
	var angle:float
	var N = len(ship_nodes)
	var target_ship
	if N == 1:
		target_ship = ship_nodes[0]
		spawn_position = 100.0 * Vector2.from_angle(randf() * 2.0 * PI) + target_ship.position
	else:
		var target1 = randi() % N
		var target2 = randi() % N
		while target2 == target1:
			target2 = randi() % N
		target_ship = ship_nodes[target2]
		var pos_diff = ship_nodes[target1].position - target_ship.position
		spawn_position = pos_diff.normalized() * -100.0 + target_ship.position
		angle = atan2(pos_diff.y, pos_diff.x)
	if not battle_scene.animations_sped_up:
		battle_scene.view_entity(target_ship, 1.0)
	spawn_position.x = clamp(spawn_position.x, -620.0, 1900.0)
	spawn_position.y = clamp(spawn_position.y, -340.0, 1060.0)
	var projectile_num = 2
	if lv >= 4:
		projectile_num = 3
	for i in projectile_num:
		var magic_bullet = preload("res://Scenes/Battle/Weapons/Projectile.tscn").instantiate()
		magic_bullet.set_script(load("res://Scripts/Battle/Weapons/MagicBullet.gd"))
		magic_bullet.get_node("Sprite2D").texture = preload("res://Graphics/Cave/Projectiles/purple_bullet.png")
		magic_bullet.trail_color = Color.PURPLE
		magic_bullet.collision_layer = 16
		magic_bullet.collision_mask = 1 + 2
		magic_bullet.speed = 1400.0
		magic_bullet.mass = 1.0
		magic_bullet.velocity_process_modifier = 5.0 if battle_scene.animations_sped_up else 1.0
		magic_bullet.rotation = angle
		magic_bullet.damage = attack_data[attack_type].damage
		magic_bullet.shooter = self
		magic_bullet.weapon_accuracy = attack_data[attack_type].accuracy * accuracy
		magic_bullet.position = spawn_position
		magic_bullet.ending_turn_delay = 1.0
		battle_scene.add_child(magic_bullet)
		magic_bullet.end_turn.connect(ending_turn)
		projectiles.append(magic_bullet)
		if i < projectile_num - 1:
			await get_tree().create_timer(0.4).timeout
	for projectile in projectiles:
		if is_instance_valid(projectile):
			projectile.end_turn_ready = true
			break

func debuff_attack():
	var target_ship:BattleEntity = ship_nodes.pick_random()
	if not battle_scene.animations_sped_up:
		battle_scene.view_entity(target_ship, 1.0)
	var buff:float
	if lv >= 12:
		buff = -4
	else:
		buff = -3
	target_ship.attack_buff = buff * pow((target_ship.attack_buff + buff) / buff, 0.8)
	buff_animation(target_ship.position, Color.RED)
	target_ship.update_info_labels()
	
func buff_animation(pos:Vector2, mod:Color):
	var attack_icon = Sprite2D.new()
	attack_icon.texture = preload("res://Graphics/Icons/attack.png")
	attack_icon.position = pos + Vector2.UP * 90.0
	attack_icon.scale *= 0.3
	battle_scene.add_child(attack_icon)
	var light = Sprite2D.new()
	light.texture = preload("res://Graphics/Decoratives/light.png")
	light.position = pos
	light.scale = Vector2.ZERO
	light.modulate = mod
	battle_scene.add_child(light)
	var tween = create_tween().set_parallel()
	tween.tween_property(attack_icon, "modulate:a", 0.0, 0.4).set_delay(1.0)
	tween.tween_callback(attack_icon.queue_free).set_delay(1.4)
	tween.tween_property(light, "scale", Vector2.ONE, 0.3)
	tween.tween_property(light, "modulate:a", 0.0, 0.3)
	tween.tween_callback(light.queue_free).set_delay(0.3)
	if battle_scene.animations_sped_up:
		ending_turn()
	else:
		tween.tween_callback(ending_turn).set_delay(1.5)
	
func buff_attack():
	var target_HX:BattleEntity = HX_nodes.pick_random()
	if not battle_scene.animations_sped_up:
		battle_scene.view_entity(target_HX, 1.0)
	var buff:float
	if lv >= 12:
		buff = 4
	else:
		buff = 3
	target_HX.attack_buff = buff * pow((target_HX.attack_buff + buff) / buff, 0.8)
	buff_animation(target_HX.position, Color.WHITE)
	target_HX.update_info_labels()

func spawn_magic_star(callback):
	var magic_star = Sprite2D.new()
	magic_star.texture = preload("res://Graphics/Decoratives/Star2.png")
	magic_star.position = position
	battle_scene.add_child(magic_star)
	var tween = create_tween().set_parallel()
	tween.tween_property(magic_star, "modulate:a", 0.0, 0.4)
	tween.tween_property(magic_star, "scale", Vector2.ONE * 2.0, 0.4)
	tween.tween_property(magic_star, "rotation", 0.5 * PI, 0.4)
	tween.tween_callback(magic_star.queue_free).set_delay(0.4)
	tween.tween_callback(callback).set_delay(0.4)

func add_projectile(angle:float, modifiers:Dictionary):
	var projectile = preload("res://Scenes/Battle/Weapons/Projectile.tscn").instantiate()
	projectile.set_script(load("res://Scripts/Battle/Weapons/Bullet.gd"))
	projectile.get_node("Sprite2D").texture = preload("res://Graphics/Battle/Projectiles/enemy_bullet.png")
	projectile.trail_color = Color.RED
	projectile.collision_layer = 16
	projectile.collision_mask = 1 + 2 + 32
	projectile.speed = 1000.0
	projectile.mass = 1.0
	projectile.velocity_process_modifier = 5.0 if battle_scene.animations_sped_up else 1.0
	projectile.rotation = angle
	projectile.damage = attack_data[attack_type].damage
	projectile.shooter = self
	projectile.weapon_accuracy = attack_data[attack_type].accuracy * accuracy
	projectile.deflects_remaining = 0
	projectile.position = position
	projectile.ending_turn_delay = 1.0
	projectile.end_turn_ready = true
	if modifiers.has("buffs"):
		projectile.buffs = modifiers.buffs
	if modifiers.has("knockback"):
		projectile.knockback = modifiers.knockback
	if modifiers.has("scale_mult"):
		projectile.scale *= modifiers.scale_mult
	if modifiers.has("damage_mult"):
		projectile.damage *= modifiers.damage_mult
	if modifiers.has("status_effects"):
		projectile.status_effects = modifiers.status_effects
	if modifiers.has("trail_color"):
		projectile.trail_color = modifiers.trail_color
	battle_scene.add_child(projectile)
	projectile.end_turn.connect(ending_turn)
	
func normal_attack():
	target_angle = atan2(target_position.y - position.y, target_position.x - position.x)
	target_angle_max_deviation = 1.0 / (accuracy + accuracy_buff) / aim_mult / attack_data[attack_type].accuracy
	if battle_scene.animations_sped_up:
		await get_tree().create_timer(0.1).timeout
	else:
		battle_scene.view_entity(self, 1.0, 200.0 * Vector2.from_angle(target_angle))
		$FireWeaponAim.show()
		await get_tree().create_timer(0.7).timeout
	var projectile_angle = randf_range(target_angle - target_angle_max_deviation, target_angle + target_angle_max_deviation)
	if attack_type == Attack.NORMAL:
		var buffs = {}
		if lv >= 12:
			buffs["defense"] = -4
		elif lv >= 9:
			buffs["defense"] = -3
		elif lv >= 6:
			buffs["defense"] = -2
		elif lv >= 3:
			buffs["defense"] = -1
		var knockback = 0.0
		if lv >= 3:
			knockback = 15.0 + min(lv, 18) * 2.0
		var scale_mult = 1.0
		var damage_mult = 1.0
		if lv >= 9:
			scale_mult *= 2.0
			damage_mult *= 2.0
		add_projectile(projectile_angle,
		{"buffs":buffs, "scale_mult":scale_mult, "damage_mult":damage_mult, "knockback":knockback})
	elif attack_type == Attack.CORRODING_BULLET:
		var proj_status_effects = {Battle.StatusEffect.CORRODING:2}
		if lv >= 15:
			proj_status_effects[Battle.StatusEffect.CORRODING] = 3
		var scale_mult = 1.0
		var damage_mult = 1.0
		if lv >= 18:
			scale_mult *= 2.0
			damage_mult *= 2.0
		var projectile_num = 2
		if lv >= 12:
			projectile_num = 3
		for i in projectile_num:
			add_projectile(projectile_angle,
			{"status_effects":proj_status_effects, "scale_mult":scale_mult, "damage_mult":damage_mult, "trail_color":Color.YELLOW_GREEN})
			if i < projectile_num-1:
				await get_tree().create_timer(0.2).timeout
	elif attack_type == Attack.LASER:
		var laser = preload("res://Scenes/Battle/Weapons/BattleLaser.tscn").instantiate()
		laser.get_node("RayCast2D").collision_mask = 1 + 2 + 32
		laser.rotation = projectile_angle
		laser.damage = attack_data[attack_type].damage
		laser.shooter = self
		laser.weapon_accuracy = attack_data[attack_type].accuracy * accuracy
		laser.position = position
		laser.fade_delay = 0.2 if battle_scene.animations_sped_up else 0.5
		if lv < 18:
			laser.status_effects = {Battle.StatusEffect.STUN: [min(0.5 + 0.05 * (lv - 9), 0.8), 1]}
		else:
			laser.status_effects = {Battle.StatusEffect.STUN: [0.8, 2]}
		battle_scene.add_child(laser)
		laser.tree_exited.connect(ending_turn)

func push_ship(ship:BattleEntity):
	var push_success = push_entity_attempt(agility + agility_buff, ship.agility + ship.agility_buff, (position - ship.position).normalized(), velocity - ship.velocity)
	ship.update_velocity_arrow()
	if push_success:
		create_tween().tween_property(ship, "velocity", ship.velocity + calculate_velocity_change(ship, movement_remaining), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		battle_scene.add_damage_text(true, ship.position)
	print("movement_remaining " + str(movement_remaining))
	print("pusheed " + str(calculate_velocity_change(ship, movement_remaining)))
	var push_tween = create_tween()
	var orig_pos = position
	push_tween.tween_property(self, "position", ship.position, 0.05).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	push_tween.tween_property(self, "position", orig_pos, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	var push_effect = preload("res://Scenes/Battle/PushEffect.tscn").instantiate()
	push_effect.scale = Vector2.ONE * remap(movement_remaining, 30.0, 100.0, 0.2, 0.5)
	push_effect.rotation = atan2(ship.position.y - position.y, ship.position.x - position.x)
	push_effect.position = position + 50.0 * Vector2.from_angle(push_effect.rotation)
	battle_scene.add_child(push_effect)
	push_effect.play("default")
	push_effect.animation_finished.connect(ending_turn.bind(0.5))
	push_effect.animation_finished.connect(push_effect.queue_free)

func attack_target():
	if enemy_class == 2:
		if lv >= 3 and randf() < 0.5:
			spawn_magic_star(debuff_attack)
		else:
			normal_attack()
	elif enemy_class == 3:
		var pushable_ships = get_pushable_ships()
		if movement_remaining < 30.0 or pushable_ships.is_empty():
			if turn_number % 3 == 1 and len(battle_scene.obstacle_nodes) < 15:
				var angle_offset = randf() * 2.0 * PI / 8.0
				var ball_number = 4
				if lv >= 24:
					ball_number = 8
				elif lv >= 18:
					ball_number = 7
				elif lv >= 12:
					ball_number = 6
				elif lv >= 6:
					ball_number = 5
				for i in ball_number:
					spawn_ball(i * 2.0 * PI / ball_number + angle_offset, total_HP * 0.8, 16.0)
			elif turn_number % 3 == 2:
				for ship in ship_nodes:
					spawn_ball(atan2(ship.position.y - position.y, ship.position.x - position.x), total_HP * 1.5, 30.0)
			else:
				var ship = ship_nodes.pick_random()
				spawn_ball(atan2(ship.position.y - position.y, ship.position.x - position.x), total_HP * 2.0, 50.0)
			ending_turn(0.05 if battle_scene.animations_sped_up else 0.5)
		else:
			push_ship(pushable_ships.pick_random())
	elif enemy_class == 4:
		var random_attack = randf()
		if random_attack < 0.5 and lv >= 3:
			spawn_magic_star(buff_attack)
		else:
			spawn_magic_star(fire_magic_bullets)
	else:
		normal_attack()

func get_pushable_ships():
	var pushable_ships = []
	for ship in ship_nodes:
		if (ship.position - position).length() < 144.0:
			pushable_ships.append(ship)
	return pushable_ships
	

func ending_turn(delay: float = 0.0):
	create_tween().tween_callback(end_turn).set_delay(0.0 if battle_scene.animations_sped_up else delay)


func _on_collision_shape_finder_area_entered(area: Area2D) -> void:
	if area.get_instance_id() != get_instance_id():
		obstacles_in_range.append(area)


func _on_collision_shape_finder_area_exited(area: Area2D) -> void:
	obstacles_in_range.erase(area)


func _on_fire_weapon_aim_visibility_changed() -> void:
	if $FireWeaponAim.visible:
		$FireWeaponAim.length = 200.0
		$FireWeaponAim.target_angle = target_angle
		$FireWeaponAim.target_angle_max_deviation = target_angle_max_deviation
		$FireWeaponAim.animate(true)


func _on_mouse_entered() -> void:
	if battle_GUI.action_selected in [battle_GUI.MOVE, battle_GUI.PUSH]:
		return
	if is_instance_valid(turn_order_box):
		turn_order_box._on_mouse_entered()
	if override_tooltip_text:
		game.show_tooltip(override_tooltip_text.format(override_tooltip_dict), {"imgs": override_tooltip_icons})
	else:
		refresh_default_tooltip_text()
		default_tooltip_text += "\n" + tr("PASSIVE_ABILITY") + ":"
		for PA in passive_abilities:
			default_tooltip_text += "\n - " + tr("PASSIVE_%s" % PA)
		game.show_tooltip(default_tooltip_text, {"imgs": default_tooltip_icons})


func _on_mouse_exited() -> void:
	if is_instance_valid(turn_order_box):
		turn_order_box._on_mouse_exited()
	game.hide_tooltip()
