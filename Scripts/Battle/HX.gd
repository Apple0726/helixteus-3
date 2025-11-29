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
	var ship_target_id = determine_target()
	target_position = ship_nodes[ship_target_id].position
	position_preferences = {}
	var movement_remaining_base = total_movement
	var speed = velocity.length()
	if speed > 0.0:
		create_tween().tween_property(self, "velocity", velocity.normalized() * max(speed - movement_remaining_base, 0.0), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		movement_remaining_base = max(movement_remaining_base - speed, 0.0)
		await get_tree().create_timer(0.1).timeout
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
	var distance_from_current_position_weight:float = 0.001 * pos.distance_squared_to(position)
	for HX in HX_nodes:
		# Enemies try to move far from each other
		HX_proximity_weight += 1.0e6 / max(pow(10.0 * PIXELS_PER_METER, 2), pos.distance_squared_to(HX.position))
	var ship_target_distance = 40.0 + accuracy + accuracy_buff + 2.0 * max(0.0, accuracy + accuracy_buff - 12.0)
	for ship in ship_nodes:
		# Try to get close to ships, but not too close or too far (ideal distance of ship_target_distance meters)
		var r = pos.distance_squared_to(ship.position)
		ship_proximity_weight += 1000.0 * (1.0 - exp(-pow(r - pow(ship_target_distance * PIXELS_PER_METER, 2), 2) / 4.0e9)) + 0.001 * abs(r - pow(ship_target_distance * PIXELS_PER_METER, 2))
	position_preferences[pos] = HX_proximity_weight + ship_proximity_weight + distance_from_current_position_weight
	
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

func attack_target():
	target_angle = atan2(target_position.y - position.y, target_position.x - position.x)
	target_angle_max_deviation = 1.0 / (accuracy + accuracy_buff) / aim_mult
	if battle_scene.animations_sped_up:
		await get_tree().create_timer(0.1).timeout
	else:
		$FireWeaponAim.show()
		await get_tree().create_timer(0.7).timeout
	var projectile = preload("res://Scenes/Battle/Weapons/Projectile.tscn").instantiate()
	projectile.set_script(load("res://Scripts/Battle/Weapons/Bullet.gd"))
	projectile.get_node("Sprite2D").texture = preload("res://Graphics/Battle/Projectiles/enemy_bullet.png")
	projectile.trail_color = Color.RED
	projectile.collision_layer = 16
	projectile.collision_mask = 1 + 2 + 32
	projectile.speed = 1000.0
	projectile.mass = 1.0
	projectile.velocity_process_modifier = 5.0 if battle_scene.animations_sped_up else 1.0
	projectile.rotation = randf_range(target_angle - target_angle_max_deviation, target_angle + target_angle_max_deviation)
	projectile.damage = 2.0
	projectile.shooter = self
	projectile.weapon_accuracy = 1.0 * accuracy
	projectile.deflects_remaining = 0
	projectile.position = position
	projectile.ending_turn_delay = 1.0
	projectile.end_turn_ready = true
	battle_scene.add_child(projectile)
	projectile.end_turn.connect(ending_turn)


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
	if override_tooltip_text:
		game.show_tooltip(override_tooltip_text.format(override_tooltip_dict), {"imgs": override_tooltip_icons})
	else:
		refresh_default_tooltip_text()
		default_tooltip_text += "\n" + tr("PASSIVE_ABILITY") + ":"
		for PA in passive_abilities:
			default_tooltip_text += "\n - " + tr("PASSIVE_%s" % PA)
		game.show_tooltip(default_tooltip_text, {"imgs": default_tooltip_icons})


func _on_mouse_exited() -> void:
	game.hide_tooltip()
