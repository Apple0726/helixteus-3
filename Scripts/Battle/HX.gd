extends "BattleEntity.gd"

var HX_nodes:Array
var ship_nodes:Array
var position_preferences:Dictionary
var PIXELS_PER_M:float
var ship_target_distance = 5.0


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
	var ship_target = determine_target()
	position_preferences = {}
	# General battlefield position preferences. Low resolution
	for x in range(-640, 1920, 80):
		for y in range(-360, 1080, 80):
			calculate_position_preferences(Vector2(x, y))
	# Position preferences around ship target, where this enemy will most likely go to. High resolution
	for i in range(-5, 10):
		var r = ship_target_distance + i * 0.2
		for j in range(32):
			var th = lerp(0.0, 2.0 * PI, j / 32.0)
			calculate_position_preferences(r * Vector2.from_angle(th))
	var ideal_target_position:Vector2 = position
	var lowest_weight:float = INF
	for pos in position_preferences:
		if position_preferences[pos] < lowest_weight:
			lowest_weight = position_preferences[pos]
			ideal_target_position = pos
	await get_tree().create_timer(1.0).timeout
	move(ideal_target_position)
	
func calculate_position_preferences(pos:Vector2):
	if position_preferences.has(pos):
		return
	var HX_proximity_weight:float = 0.0 
	var ship_proximity_weight:float = 0.0
	var distance_from_current_position_weight:float = 0.001 * pos.distance_squared_to(position)
	for HX in HX_nodes:
		# Enemies try to move far from each other
		HX_proximity_weight += 1.0e6 / max(pow(1.0 * PIXELS_PER_M, 2), pos.distance_squared_to(HX.position))
	for ship in ship_nodes:
		# Try to get close to ships, but not too close (ideal distance of ship_target_distance meters)
		var r = pos.distance_squared_to(ship.position)
		ship_proximity_weight += 1000.0 * (1.0 - exp(-pow(r - pow(ship_target_distance * PIXELS_PER_M, 2), 2) / 4.0e9))
	position_preferences[pos] = HX_proximity_weight + ship_proximity_weight + distance_from_current_position_weight
	
func move(target_pos:Vector2):
	var tween = create_tween().set_parallel()
	tween.tween_property(self, "position", target_pos, 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(game.view, "position", Vector2(640, 360) - target_pos, 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
