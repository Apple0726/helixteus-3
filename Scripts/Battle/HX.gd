extends "BattleEntity.gd"

var HX_nodes:Array
var ship_nodes:Array
var position_preferences:Dictionary
var ship_target_distance = 50.0
var obstacles_in_range:Array = []
var target_position:Vector2
var target_angle:float
var target_angle_max_deviation:float

# For animating aim accuracy graphic used in _draw()
var target_angle_max_deviation_visual:float
var aim_accuracy_transparency:float
var draw_aim_accuracy:bool = false


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
	super()
	var ship_target_id = determine_target()
	target_position = ship_nodes[ship_target_id].position
	position_preferences = {}
	for j in range(64):
		var th = lerp(0.0, 2.0 * PI, j / 64.0)
		var inside_obstacle = false
		var movement_left = (agility + agility_buff) * METERS_PER_AGILITY # in meters
		var r = 0.0 # in pixels
		while movement_left > 0.0:
			r += 2.0 * PIXELS_PER_METER
			movement_left -= 2.0
			var pos = position + r * Vector2.from_angle(th)
			for obstacle in obstacles_in_range:
				if not inside_obstacle and Geometry2D.is_point_in_polygon(pos, obstacle.get_node("CollisionShape2D/Polygon2D").polygon):
					if obstacle.type == 2: # If obstacle is boundary, no more movement is possible
						movement_left = 0.0
						continue
					else:
						inside_obstacle = true
						movement_left -= 30.0
				elif inside_obstacle and not Geometry2D.is_point_in_polygon(pos, obstacle.get_node("CollisionShape2D/Polygon2D").polygon):
					inside_obstacle = false
			if movement_left >= 0.0:
				calculate_position_preferences(position + r * Vector2.from_angle(th))
	var target_move_position:Vector2 = position
	var lowest_weight:float = INF
	for pos in position_preferences:
		if position_preferences[pos] < lowest_weight:
			lowest_weight = position_preferences[pos]
			target_move_position = pos
	await get_tree().create_timer(1.0).timeout
	move(target_move_position)

func calculate_position_preferences(pos:Vector2):
	if position_preferences.has(pos):
		return
	var HX_proximity_weight:float = 0.0 
	var ship_proximity_weight:float = 0.0
	var distance_from_current_position_weight:float = 0.001 * pos.distance_squared_to(position)
	for HX in HX_nodes:
		# Enemies try to move far from each other
		HX_proximity_weight += 1.0e6 / max(pow(10.0 * PIXELS_PER_METER, 2), pos.distance_squared_to(HX.position))
	for ship in ship_nodes:
		# Try to get close to ships, but not too close (ideal distance of ship_target_distance meters)
		var r = pos.distance_squared_to(ship.position)
		ship_proximity_weight += 1000.0 * (1.0 - exp(-pow(r - pow(ship_target_distance * PIXELS_PER_METER, 2), 2) / 4.0e9))
	position_preferences[pos] = HX_proximity_weight + ship_proximity_weight + distance_from_current_position_weight
	
func move(target_pos:Vector2):
	var tween = create_tween()
	var view_tween = create_tween()
	tween.tween_property(self, "position", target_pos, 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(attack_target)
	view_tween.tween_property(game.view, "position", Vector2(640, 360) - target_pos * game.view.scale.x, 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)

func attack_target():
	target_angle = atan2(target_position.y - position.y, target_position.x - position.x)
	target_angle_max_deviation = 1.0 / (accuracy + accuracy_buff)
	target_angle_max_deviation_visual = target_angle_max_deviation + PI / 16.0
	aim_accuracy_transparency = 0.0
	draw_aim_accuracy = true
	var tween = create_tween().set_parallel()
	tween.tween_property(self, "target_angle_max_deviation_visual", target_angle_max_deviation, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "aim_accuracy_transparency", 0.8, 0.6)
	tween.tween_property(self, "aim_accuracy_transparency", 0.0, 0.4).set_delay(0.9)
	tween.tween_callback(func(): draw_aim_accuracy = false).set_delay(1.3)
	tween.tween_callback(queue_redraw).set_delay(1.3)
	await get_tree().create_timer(0.9).timeout
	var projectile = preload("res://Scenes/Battle/Weapons/RedBullet.tscn").instantiate()
	projectile.speed = 1000.0
	projectile.rotation = randf_range(target_angle - target_angle_max_deviation, target_angle + target_angle_max_deviation)
	projectile.damage = attack
	projectile.projectile_accuracy = 1.0 * accuracy
	projectile.position = position
	battle_scene.add_child(projectile)
	projectile.tree_exited.connect(ending_turn)


func ending_turn():
	create_tween().tween_callback(end_turn).set_delay(1.0)


func _on_collision_shape_finder_area_entered(area: Area2D) -> void:
	if area.get_instance_id() != get_instance_id():
		obstacles_in_range.append(area)


func _on_collision_shape_finder_area_exited(area: Area2D) -> void:
	obstacles_in_range.erase(area)

func _process(delta: float) -> void:
	if draw_aim_accuracy:
		queue_redraw()

func _draw() -> void:
	if draw_aim_accuracy:
		draw_arc(Vector2.ZERO, 200.0, target_angle - target_angle_max_deviation_visual, target_angle + target_angle_max_deviation_visual, 15, Color(1.0, 1.0, 1.0, aim_accuracy_transparency))
		draw_line(Vector2.ZERO, 300.0 * Vector2.from_angle(target_angle - target_angle_max_deviation_visual), Color(1.0, 1.0, 1.0, aim_accuracy_transparency))
		draw_line(Vector2.ZERO, 300.0 * Vector2.from_angle(target_angle + target_angle_max_deviation_visual), Color(1.0, 1.0, 1.0, aim_accuracy_transparency))
