extends Node2D

@onready var game = get_node("/root/Game")

const METERS_PER_AGILITY = 10.0
const PIXELS_PER_METER = 5.0

var battle_GUI:BattleGUI
var HX_scene = preload("res://Scenes/Battle/HX.tscn")

var HX_data:Array
var ship_data:Array
var hard_battle:bool = false
var time_speed:float = 1.0
var initiative_order = []
var whose_turn_is_it_index:int = 0
var HX_nodes = []
var ship_nodes = []
var mouse_position_global:Vector2
var mouse_position_local:Vector2
var obstacle_nodes = []
var view_tween
var animations_sped_up = false

func _ready() -> void:
	time_speed = Helper.set_logarithmic_time_speed(game.subject_levels.dimensional_power, game.u_i.time_speed)
	var p_i:Dictionary = game.planet_data[game.c_p]
	if game.is_conquering_all:
		HX_data = Helper.get_conquer_all_data().HX_data
	else:
		HX_data = p_i.HX_data
	ship_data = game.ship_data
	for i in len(HX_data):
		var HX = HX_scene.instantiate()
		HX.METERS_PER_AGILITY = METERS_PER_AGILITY
		HX.PIXELS_PER_METER = PIXELS_PER_METER
		HX.initialize_stats(HX_data[i])
		HX.battle_scene = self
		HX.battle_GUI = battle_GUI
		HX.HX_nodes = HX_nodes
		HX.ship_nodes = ship_nodes
		HX.type = Battle.EntityType.ENEMY
		HX.roll_initiative()
		HX.get_node("Sprite2D").texture = load("res://Graphics/HX/%s_%s.png" % [HX_data[i]["class"], HX_data[i].type])
		HX.get_node("Sprite2D").material.set_shader_parameter("amplitude", 0.0)
		HX.get_node("Info/HP").max_value = HX_data[i].HP
		HX.get_node("Info/HP").value = HX_data[i].HP
		HX.get_node("Info/Label").text = "%s %s" % [tr("LV"), HX_data[i].lv]
		if hard_battle:
			HX.get_node("LabelAnimation").play("LabelAnim")
		HX.position = Vector2(1340, randf_range(150, 570))
		var tween = get_tree().create_tween()
		tween.tween_property(HX, "position", HX_data[i].initial_position, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD).set_delay(i * 0.2)
		if i == len(HX_data) - 1:
			tween.finished.connect(initialize_battle)
		HX.next_turn.connect(next_turn)
		add_child(HX)
		HX_nodes.append(HX)
	for i in 4:
		if len(ship_data) > i:
			var ship_node = preload("res://Scenes/Battle/Ship.tscn").instantiate()
			ship_node.METERS_PER_AGILITY = METERS_PER_AGILITY
			ship_node.PIXELS_PER_METER = PIXELS_PER_METER
			ship_node.initialize_stats(ship_data[i])
			ship_node.roll_initiative()
			ship_node.position = ship_data[i].initial_position
			ship_node.battle_scene = self
			ship_node.battle_GUI = battle_GUI
			ship_node.next_turn.connect(next_turn)
			ship_node.type = Battle.EntityType.SHIP
			ship_node.ship_type = i
			ship_node.get_node("Sprite2D").texture = load("res://Graphics/Ships/Ship%s.png" % i)
			ship_node.get_node("Sprite2D").material.set_shader_parameter("amplitude", 0.0)
			ship_node.get_node("Info/HP").max_value = ship_data[i].HP
			ship_node.get_node("Info/HP").value = ship_data[i].HP
			ship_node.get_node("Info/Label").text = "%s %s" % [tr("LV"), ship_data[i].lv]
			ship_node.get_node("ThrusterFire").emitting = false
			add_child(ship_node)
			ship_nodes.append(ship_node)


func initialize_battle():
	for HX_node in HX_nodes:
		initiative_order.append({"node": HX_node})
	for ship_node in ship_nodes:
		initiative_order.append({"node": ship_node})
	initiative_order.sort_custom(sort_initiative)
	initiative_order.append({"node": $Boundary})
	for i in len(initiative_order):
		var turn_order_button = preload("res://Scenes/Battle/TurnOrderButton.tscn").instantiate()
		if i > 0:
			var delay = create_tween()
			delay.tween_callback(turn_order_button.get_node("AnimationPlayer").play.bind("InitialAnim")).set_delay(0.15 * i)
			turn_order_button.modulate.a = 0.0
		battle_GUI.turn_order_hbox.add_child(turn_order_button)
		turn_order_button.custom_minimum_size.x = 0.0
		turn_order_button.get_node("TextureRect").modulate.a = 0.5
		var entity = initiative_order[i].node
		if entity.type == Battle.EntityType.BOUNDARY: # Environment always goes last
			turn_order_button.show_initiative(0, 0.15 * len(initiative_order) + 3.0)
			turn_order_button.set_texture(load("res://Graphics/Achievements/BStar.png"))
			turn_order_button.get_node("Panel")["theme_override_styles/panel"].border_color = Color(1.0, 1.0, 0.0, 0.7)
		else:
			turn_order_button.show_initiative(entity.initiative, 0.15 * i + 3.0)
			if entity.type == Battle.EntityType.ENEMY:
				turn_order_button.set_texture(load("res://Graphics/HX/%s_%s.png" % [entity.enemy_class, entity.enemy_type]))
				turn_order_button.get_node("Panel")["theme_override_styles/panel"].border_color = Color(1.0, 0.0, 0.0, 0.7)
			elif entity.type == Battle.EntityType.SHIP:
				turn_order_button.set_texture(load("res://Graphics/Ships/Ship%s.png" % entity.ship_type))
				turn_order_button.get_node("Panel")["theme_override_styles/panel"].border_color = Color(0.0, 0.8, 1.0, 0.7)
			entity.show_initiative(entity.initiative)
		entity.turn_order_box = turn_order_button
	next_turn()

func next_turn():
	if animations_sped_up:
		view_tween = null
	else:
		view_tween = create_tween().set_parallel()
	battle_GUI.ship_node = null
	for i in len(initiative_order):
		if i >= len(initiative_order):
			break
		if not is_instance_valid(initiative_order[i].node) or initiative_order[i].node.type != Battle.EntityType.BOUNDARY and initiative_order[i].node.HP <= 0:
			initiative_order.remove_at(i)
			if i < whose_turn_is_it_index:
				whose_turn_is_it_index -= 1
			i -= 1
	if initiative_order[whose_turn_is_it_index].node.type == Battle.EntityType.BOUNDARY:
		var view_scale:float = 0.4
		if view_tween:
			view_tween.tween_property(game.view, "scale", Vector2.ONE * view_scale, 1.0).set_trans(Tween.TRANS_CUBIC)
			view_tween.tween_property(game.view, "position", Vector2(640, 360) - Vector2(640, 360) * view_scale, 1.0).set_trans(Tween.TRANS_CUBIC)
			create_tween().tween_callback(environment_take_turn).set_delay(1.0)
		else:
			create_tween().tween_callback(environment_take_turn).set_delay(0.1)
		initiative_order[whose_turn_is_it_index].node.turn_order_box.get_node("AnimationPlayer").play("ChangeSize")
	elif initiative_order[whose_turn_is_it_index].node.type == Battle.EntityType.SHIP:
		var ship_node = initiative_order[whose_turn_is_it_index].node
		battle_GUI.ship_node = ship_node
		await ship_node.take_turn()
		battle_GUI.fade_in_main_panel()
		if view_tween:
			view_tween.tween_property(game.view, "position", Vector2(640, 360) - ship_node.position * game.view.scale.x, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	elif initiative_order[whose_turn_is_it_index].node.type == Battle.EntityType.ENEMY:
		var HX_node = initiative_order[whose_turn_is_it_index].node
		if view_tween:
			view_tween.tween_property(game.view, "position", Vector2(640, 360) - HX_node.position * game.view.scale.x, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		HX_node.take_turn()
	whose_turn_is_it_index += 1

func sort_initiative(a, b):
	return a.node.initiative > b.node.initiative


func _process(delta: float) -> void:
	pass


func add_damage_text(missed: bool, label_position:Vector2, damage: float = 0.0, critical: bool = false, label_initial_velocity:Vector2 = Vector2.ZERO):
	var damage_text = preload("res://Scenes/Battle/DamageText.tscn").instantiate()
	damage_text.missed = missed
	damage_text.damage = damage
	damage_text.critical = critical
	damage_text.velocity = label_initial_velocity
	damage_text.position = label_position
	add_child(damage_text)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_position_global = event.position
		mouse_position_local = to_local(event.position)
	if Input.is_action_just_pressed("left_click") or Input.is_action_just_pressed("scroll_up") or Input.is_action_just_pressed("scroll_down"):
		if view_tween and view_tween.is_running():
			view_tween.kill()
	if Input.is_action_just_pressed("A"):
		display_stats("attack")
	if Input.is_action_just_pressed("D"):
		display_stats("defense")
	if Input.is_action_just_pressed("C"):
		display_stats("accuracy")
	if Input.is_action_just_pressed("G"):
		display_stats("agility")
	if Input.is_action_just_pressed("H"):
		display_stats("HP")
	if Input.is_action_just_released("A") or Input.is_action_just_released("D") or Input.is_action_just_released("C") or Input.is_action_just_released("G") or Input.is_action_just_released("H"):
		var entities = HX_nodes
		entities.append_array(ship_nodes)
		entities.append_array(obstacle_nodes)
		for entity in entities:
			entity.get_node("Info/Icon").hide()
			if entity.lv != 0:
				entity.get_node("Info/Label").text = "%s %s" % [tr("LV"), entity.lv]
			else:
				entity.get_node("Info/Label").text = ""


func display_stats(type:String):
	var entities = HX_nodes
	entities.append_array(ship_nodes)
	entities.append_array(obstacle_nodes)
	for entity in entities:
		entity.get_node("Info/Icon").show()
		entity.get_node("Info/Icon").texture = load("res://Graphics/Icons/%s.png" % type)
		if type == "HP":
			entity.get_node("Info/Label").text = "%s / %s" % [str(entity.HP), str(entity.total_HP)]
		else:
			entity.get_node("Info/Label").text = str(entity[type] + entity[type + "_buff"])

func environment_take_turn():
	while randf() < 2.0 / (len(obstacle_nodes) + 1):
		var asteroid_position = Vector2.ZERO
		var scale_rand = randf()
		var asteroid_scale:float = max(0.5 * scale_rand * pow(1.0 / (1.0 - scale_rand), 1.0 / 3.0), 0.1)
		var colliding = true
		while asteroid_position == Vector2.ZERO or colliding:
			colliding = false
			if randf() < 0.5:
				asteroid_position.x = randf_range(-1.0, 1.0) * 1280.0 + 640.0
				asteroid_position.y = -360.0 if randf() < 0.5 else 1080.0
			else:
				asteroid_position.x = -640.0 if randf() < 0.5 else 1920.0
				asteroid_position.y = randf_range(-1.0, 1.0) * 720.0 + 360.0
			for obstacle in obstacle_nodes:
				if Geometry2D.is_point_in_circle(asteroid_position, obstacle.position, (obstacle.scale.x + asteroid_scale) * 90.0):
					colliding = true
					break
		var asteroid = preload("res://Scenes/Battle/Asteroid.tscn").instantiate()
		asteroid.position = asteroid_position
		asteroid.get_node("Sprite2D").scale = Vector2.ONE * asteroid_scale
		asteroid.total_HP = pow(asteroid_scale, 3) * 10000
		asteroid.HP = asteroid.total_HP
		asteroid.get_node("Info/HP").max_value = asteroid.total_HP
		asteroid.get_node("Info/HP").value = asteroid.HP
		asteroid.attack = 10
		asteroid.defense = 10
		asteroid.accuracy = pow(asteroid_scale * 20.0, 1.5) + 1
		asteroid.agility = pow(2.0 / asteroid_scale, 1.5) + 1
		asteroid.go_through_movement_cost = asteroid_scale * 100.0
		asteroid.collision_shape_radius = asteroid_scale * 84.0
		asteroid.battle_GUI = battle_GUI
		asteroid.type = Battle.EntityType.OBSTACLE
		if not animations_sped_up:
			asteroid.get_node("Sprite2D").material.set_shader_parameter("alpha", 0.0)
			asteroid.get_node("VelocityArrow").modulate.a = 0.0
			var fade_in_tween = create_tween().set_parallel()
			fade_in_tween.tween_property(asteroid.get_node("Sprite2D").material, "shader_parameter/alpha", 1.0, 0.5)
			fade_in_tween.tween_property(asteroid.get_node("VelocityArrow"), "modulate:a", 1.0, 0.5)
		asteroid.get_node("Sprite2D").rotation = randf_range(0.0, 2.0 * PI)
		asteroid.battle_scene = self
		asteroid.battle_GUI = battle_GUI
		add_child(asteroid)
		move_child(asteroid, 0)
		asteroid.velocity = -30.0 / asteroid_scale * Vector2(randf(), randf()) * sign(asteroid.position - Vector2(640.0, 360.0))
		obstacle_nodes.append(asteroid)
	if animations_sped_up:
		await get_tree().create_timer(0.1).timeout
	else:
		await get_tree().create_timer(0.5).timeout
	for obstacle in obstacle_nodes:
		obstacle.take_turn()
	if not animations_sped_up:
		await get_tree().create_timer(1.5).timeout
	battle_GUI.turn_order_hbox.get_child(whose_turn_is_it_index-1).get_node("AnimationPlayer").play_backwards("ChangeSize")
	whose_turn_is_it_index = 0
	next_turn()

func show_and_enlarge_collision_shapes():
	for HX in HX_nodes:
		HX.get_node("CollisionShape2D").shape.radius = HX.collision_shape_radius + battle_GUI.ship_node.collision_shape_radius + 2.0
		HX.draw_collision_shape = 1
	for ship in ship_nodes:
		if ship.get_instance_id() == battle_GUI.ship_node.get_instance_id():
			continue
		ship.get_node("CollisionShape2D").shape.radius = ship.collision_shape_radius + battle_GUI.ship_node.collision_shape_radius + 2.0
		ship.draw_collision_shape = 1
	for obstacle in obstacle_nodes:
		obstacle.get_node("CollisionShape2D").shape.radius = obstacle.collision_shape_radius + battle_GUI.ship_node.collision_shape_radius + 2.0
		obstacle.draw_collision_shape = 1

func hide_and_restore_collision_shapes():
	for HX in HX_nodes:
		HX.get_node("CollisionShape2D").shape.radius = HX.collision_shape_radius
		HX.draw_collision_shape = 0
	for ship in ship_nodes:
		if ship.get_instance_id() == battle_GUI.ship_node.get_instance_id():
			continue
		ship.get_node("CollisionShape2D").shape.radius = ship.collision_shape_radius
		ship.draw_collision_shape = 0
	for obstacle in obstacle_nodes:
		obstacle.get_node("CollisionShape2D").shape.radius = obstacle.collision_shape_radius
		obstacle.draw_collision_shape = 0
