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
var whose_turn_is_it_index:int = -1
var HX_nodes = []
var ship_nodes = []
var mouse_position_global:Vector2
var mouse_position_local:Vector2
var obstacle_nodes = []
var view_tween
var animations_sped_up = false
var enemy_AI_diff_mult:float = 1.0
var money_earned:float = 0.0
var XP_earned:float = 0.0

func _ready() -> void:
	time_speed = Helper.set_logarithmic_time_speed(game.subject_levels.dimensional_power, game.u_i.time_speed)
	var p_i:Dictionary = game.planet_data[game.c_p]
	if game.is_conquering_all:
		HX_data = Helper.get_conquer_all_data().HX_data
	else:
		HX_data = p_i.HX_data
	ship_data = game.ship_data
	if Settings.enemy_AI_difficulty == Settings.ENEMY_AI_DIFFICULTY_EASY:
		enemy_AI_diff_mult = 0.8
	elif Settings.enemy_AI_difficulty == Settings.ENEMY_AI_DIFFICULTY_HARD:
		enemy_AI_diff_mult = 1.7
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
		money_earned += round(HX_data[i].money * enemy_AI_diff_mult)
		XP_earned += round(HX_data[i].XP * enemy_AI_diff_mult)
		HX.roll_initiative()
		HX.get_node("TextureRect").texture = load("res://Graphics/HX/%s_%s.png" % [HX_data[i]["class"], HX_data[i].type])
		HX.get_node("TextureRect").material.set_shader_parameter("amplitude", 0.0)
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
	for i in len(ship_data):
		var ship_node = preload("res://Scenes/Battle/Ship.tscn").instantiate()
		ship_node.METERS_PER_AGILITY = METERS_PER_AGILITY
		ship_node.PIXELS_PER_METER = PIXELS_PER_METER
		ship_node.initialize_stats(ship_data[i])
		ship_node.turn_on_lights(i)
		ship_node.roll_initiative()
		ship_node.position = ship_data[i].initial_position
		ship_node.battle_scene = self
		ship_node.battle_GUI = battle_GUI
		ship_node.next_turn.connect(next_turn)
		ship_node.type = Battle.EntityType.SHIP
		ship_node.ship_type = i
		if Settings.op_cursor and i == 3:
			ship_node.get_node("TextureRect").texture = preload("res://Graphics/Ships/Ship3_op.png")
		else:
			ship_node.get_node("TextureRect").texture = load("res://Graphics/Ships/Ship%s top down.png" % i)
		ship_node.get_node("TextureRect").material.set_shader_parameter("amplitude", 0.0)
		ship_node.get_node("Info/HP").max_value = ship_data[i].HP
		ship_node.get_node("Info/HP").value = ship_data[i].HP
		ship_node.get_node("Info/Label").text = "%s %s" % [tr("LV"), ship_data[i].lv]
		add_child(ship_node)
		ship_nodes.append(ship_node)


func initialize_battle():
	for HX_node in HX_nodes:
		initiative_order.append(HX_node)
	for ship_node in ship_nodes:
		initiative_order.append(ship_node)
	initiative_order.sort_custom(sort_initiative)
	initiative_order.append($Boundary)
	for i in len(initiative_order):
		var turn_order_button = preload("res://Scenes/Battle/TurnOrderButton.tscn").instantiate()
		create_tween().tween_callback(turn_order_button.get_node("FadeAnim").play.bind("InitialAnim")).set_delay(0.15 * i)
		battle_GUI.turn_order_hbox.add_child(turn_order_button)
		var entity = initiative_order[i]
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
		entity.turn_order = i
		turn_order_button.pressed.connect(move_view_to_target.bind(entity, i))
		turn_order_button.mouse_entered.connect(show_target_icon.bind(entity))
		turn_order_button.mouse_exited.connect($Target.hide)
	await get_tree().create_timer(min(0.6, 0.15 * len(initiative_order))).timeout
	next_turn()

func move_view_to_target(entity: BattleEntity, turn_order: int):
	if entity.type == Battle.EntityType.BOUNDARY:
		view_battlefield(2.0)
	else:
		view_entity(entity, 2.0)
		if not ships_taking_turn.is_empty():
			for ship_node in ships_taking_turn:
				if ship_node.turn_order == turn_order:
					whose_turn_is_it_index = turn_order
					$Selected.position = ship_node.position + Vector2.UP * 80.0
					battle_GUI.refresh_GUI()
					return

func show_target_icon(entity: BattleEntity):
	if entity.type != Battle.EntityType.BOUNDARY:
		move_child($Target, get_child_count())
		$Target.show()
		$Target.position = entity.position


func battle_victory_callback():
	var victory_panel = preload("res://Scenes/Panels/VictoryPanel.tscn").instantiate()
	victory_panel.battle_scene = self
	battle_GUI.add_child(victory_panel)
	game.add_resources({"money":money_earned})
	for i in len(ship_data):
		Helper.add_ship_XP(i, XP_earned)
	var all_conquered = true
	if game.is_conquering_all:
		for planet in game.planet_data:
			if not planet.has("conquered") and planet.has("HX_data"):
				planet["conquered"] = true
				game.stats_univ.enemies_rekt_in_battle += len(planet.HX_data)
				game.stats_dim.enemies_rekt_in_battle += len(planet.HX_data)
				game.stats_global.enemies_rekt_in_battle += len(planet.HX_data)
				planet.erase("HX_data")
				game.stats_univ.planets_conquered += 1
				game.stats_dim.planets_conquered += 1
				game.stats_global.planets_conquered += 1
	else:
		if not game.planet_data[game.c_p].has("conquered"):
			game.stats_univ.enemies_rekt_in_battle += len(HX_data)
			game.stats_dim.enemies_rekt_in_battle += len(HX_data)
			game.stats_global.enemies_rekt_in_battle += len(HX_data)
			game.planet_data[game.c_p]["conquered"] = true
			game.planet_data[game.c_p].erase("HX_data")
			for planet in game.planet_data:
				if not planet.has("conquered"):
					all_conquered = false
			game.stats_univ.planets_conquered += 1
			game.stats_dim.planets_conquered += 1
			game.stats_global.planets_conquered += 1
	if all_conquered:
		game.system_data[game.c_s]["conquered"] = true
		game.stats_univ.systems_conquered += 1
		game.stats_dim.systems_conquered += 1
		game.stats_global.systems_conquered += 1
	if not game.new_bldgs.has(Building.SOLAR_PANEL) and game.stats_univ.planets_conquered > 1:
		game.new_bldgs[Building.SOLAR_PANEL] = true
	Helper.save_obj("Systems", game.c_s_g, game.planet_data)
	if all_conquered:
		Helper.save_obj("Galaxies", game.c_g_g, game.system_data)
	if not game.help.has("SP"):
		game.popup_window(tr("NEW_BLDGS_UNLOCKED_DESC"), tr("NEW_BLDGS_UNLOCKED"))
		game.help["SP"] = true

func view_battlefield(tween_speed: float = 1.0):
	if game.view.is_view_changing():
		return
	if animations_sped_up:
		game.view.scale = Vector2.ONE * 0.4
		game.view.position = Vector2(640, 360) * 0.6
	else:
		var view_tween = create_tween().set_parallel().set_speed_scale(tween_speed)
		view_tween.tween_property(game.view, "scale", Vector2.ONE * 0.4, 1.0).set_trans(Tween.TRANS_CUBIC)
		view_tween.tween_property(game.view, "position", Vector2(640, 360) * 0.6, 1.0).set_trans(Tween.TRANS_CUBIC)

func view_entity(entity: BattleEntity, tween_speed: float = 1.0):
	if game.view.is_view_changing():
		return
	if animations_sped_up:
		game.view.position = Vector2(640, 360) - entity.position * game.view.scale.x
	else:
		var view_tween = create_tween().set_speed_scale(tween_speed)
		view_tween.tween_property(game.view, "position", Vector2(640, 360) - entity.position * game.view.scale.x, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

var ships_taking_turn = [] # Stores ship nodes that can take actions interchangeably

func next_turn():
	if ship_nodes.is_empty():
		battle_GUI.get_node("Defeat").show()
		create_tween().tween_property(battle_GUI.get_node("Defeat"), "modulate:a", 1.0, 1.0)
		return
	var all_enemies_defeated = true
	for HX in HX_nodes:
		if HX.HP > 0:
			all_enemies_defeated = false
			break
	if all_enemies_defeated:
		battle_victory_callback()
		return
	if not ships_taking_turn.is_empty():
		for ship_node in ships_taking_turn:
			if not ship_node.turn_taken:
				whose_turn_is_it_index = ship_node.turn_order
				$Selected.position = ship_node.position + Vector2.UP * 80.0
				return
	ships_taking_turn.clear()
	$Selected.hide()
	whose_turn_is_it_index += 1
	# Update initiative_order and whose_turn_is_it_index if a ship or enemy has been defeated
	for i in len(initiative_order):
		if i >= len(initiative_order):
			break
		if not is_instance_valid(initiative_order[i]) or initiative_order[i].type != Battle.EntityType.BOUNDARY and initiative_order[i].HP <= 0:
			initiative_order.remove_at(i)
			if i < whose_turn_is_it_index - 1:
				whose_turn_is_it_index -= 1
			i -= 1
	if initiative_order[whose_turn_is_it_index].type == Battle.EntityType.BOUNDARY:
		view_battlefield()
		if animations_sped_up:
			create_tween().tween_callback(environment_take_turn).set_delay(0.1)
		else:
			create_tween().tween_callback(environment_take_turn).set_delay(1.0)
		initiative_order[whose_turn_is_it_index].turn_order_box.get_node("ChangeSizeAnim").play("ChangeSize")
	elif initiative_order[whose_turn_is_it_index].type == Battle.EntityType.SHIP:
		var ship_turn = whose_turn_is_it_index
		var view_moved = false
		while initiative_order[ship_turn].type == Battle.EntityType.SHIP:
			var ship_node = initiative_order[ship_turn]
			var ship_pos_before_moving:Vector2 = ship_node.position
			if not animations_sped_up and not view_moved:
				view_entity(ship_node)
				view_moved = true
			await ship_node.take_turn()
			if ship_node.HP >= 0:
				if not animations_sped_up and not ship_pos_before_moving.is_equal_approx(ship_node.position):
					view_entity(ship_node)
				if ship_node.status_effects[Battle.StatusEffect.STUN] <= 0 and ship_node.status_effects[Battle.StatusEffect.FROZEN] <= 0:
					ships_taking_turn.append(ship_node)
				else:
					ship_node.turn_order_box.get_node("ChangeSizeAnim").play_backwards("ChangeSize")
					ship_node.turn_taken = true
			ship_turn += 1
		if len(ships_taking_turn) > 0:
			$Selected.show()
			$Selected.position = ships_taking_turn[0].position + Vector2.UP * 80.0
			battle_GUI.fade_in_main_panel()
		else:
			whose_turn_is_it_index = ship_turn - 1
	elif initiative_order[whose_turn_is_it_index].type == Battle.EntityType.ENEMY:
		var HX_node = initiative_order[whose_turn_is_it_index]
		if not animations_sped_up:
			view_entity(HX_node)
		HX_node.take_turn()

func get_selected_ship():
	if whose_turn_is_it_index == -1 or initiative_order[whose_turn_is_it_index].type != Battle.EntityType.SHIP:
		return null
	return initiative_order[whose_turn_is_it_index]

func sort_initiative(a, b):
	return a.initiative > b.initiative


func _process(delta: float) -> void:
	pass


func add_damage_text(missed: bool, label_position:Vector2, damage: int = 0, critical: bool = false, label_initial_velocity:Vector2 = Vector2.ZERO):
	var damage_text = preload("res://Scenes/Battle/DamageText.tscn").instantiate()
	damage_text.missed = missed
	damage_text.damage = damage
	damage_text.critical = critical
	damage_text.velocity = label_initial_velocity
	damage_text.position = label_position
	add_child(damage_text)

func add_heal_text(label_position:Vector2, amount: int = 0):
	var damage_text = preload("res://Scenes/Battle/DamageText.tscn").instantiate()
	damage_text.missed = false
	damage_text.damage = -amount
	damage_text.critical = false
	damage_text.velocity = Vector2.ZERO
	damage_text.position = label_position
	damage_text.label_settings.font_color = Color.WEB_GREEN
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
		var entities = HX_nodes.duplicate()
		entities.append_array(ship_nodes)
		entities.append_array(obstacle_nodes)
		for entity in entities:
			entity.get_node("Info/Icon").hide()
			if entity.lv != 0:
				entity.get_node("Info/Label").text = "%s %s" % [tr("LV"), entity.lv]
			else:
				entity.get_node("Info/Label").text = ""


func display_stats(type:String):
	var entities = HX_nodes.duplicate()
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
				if is_instance_valid(obstacle) and Geometry2D.is_point_in_circle(asteroid_position, obstacle.position, (obstacle.scale.x + asteroid_scale) * 90.0):
					colliding = true
					break
		var asteroid = preload("res://Scenes/Battle/Asteroid.tscn").instantiate()
		asteroid.position = asteroid_position
		asteroid.get_node("TextureRect").scale = Vector2.ONE * asteroid_scale
		if asteroid_scale > 1.0:
			asteroid.get_node("TextureRect").texture = preload("res://Graphics/Battle/Obstacles/asteroid_big.png")
		else:
			asteroid.get_node("TextureRect").texture = preload("res://Graphics/Battle/Obstacles/asteroid.png")
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
		asteroid.velocity = -30.0 / asteroid_scale * Vector2(randf(), randf()) * sign(asteroid.position - Vector2(640.0, 360.0))
		if not animations_sped_up:
			asteroid.get_node("TextureRect").material.set_shader_parameter("alpha", 0.0)
			asteroid.get_node("VelocityArrow").modulate.a = 0.0
			var fade_in_tween = create_tween().set_parallel()
			fade_in_tween.tween_property(asteroid.get_node("TextureRect").material, "shader_parameter/alpha", 1.0, 0.5)
			fade_in_tween.tween_property(asteroid.get_node("VelocityArrow"), "modulate:a", 1.0, 0.5)
		asteroid.get_node("TextureRect").rotation = randf_range(0.0, 2.0 * PI)
		asteroid.battle_scene = self
		asteroid.battle_GUI = battle_GUI
		add_child(asteroid)
		move_child(asteroid, 0)
		obstacle_nodes.append(asteroid)
	if animations_sped_up:
		await get_tree().create_timer(0.1).timeout
	else:
		await get_tree().create_timer(0.5).timeout
	for obstacle in obstacle_nodes:
		if is_instance_valid(obstacle):
			obstacle.take_turn()
	if animations_sped_up:
		await get_tree().create_timer(0.3).timeout
	else:
		await get_tree().create_timer(1.2).timeout
	initiative_order[whose_turn_is_it_index-1].turn_order_box.get_node("ChangeSizeAnim").play_backwards("ChangeSize")
	whose_turn_is_it_index = 0
	next_turn()

func show_and_enlarge_collision_shapes():
	var ship_node = get_selected_ship()
	if not ship_node:
		return
	for HX in HX_nodes:
		HX.get_node("CollisionShape2D").shape.radius = HX.collision_shape_radius + ship_node.collision_shape_radius + 2.0
		HX.draw_collision_shape = 1
	for ship in ship_nodes:
		if ship.get_instance_id() == ship_node.get_instance_id():
			continue
		ship.get_node("CollisionShape2D").shape.radius = ship.collision_shape_radius + ship_node.collision_shape_radius + 2.0
		ship.draw_collision_shape = 1
	for obstacle in obstacle_nodes:
		if is_instance_valid(obstacle):
			obstacle.get_node("CollisionShape2D").shape.radius = obstacle.collision_shape_radius + ship_node.collision_shape_radius + 2.0
			obstacle.draw_collision_shape = 1

func hide_and_restore_collision_shapes():
	var ship_node = get_selected_ship()
	if not ship_node:
		return
	for HX in HX_nodes:
		HX.get_node("CollisionShape2D").shape.radius = HX.collision_shape_radius
		HX.draw_collision_shape = 0
	for ship in ship_nodes:
		if ship.get_instance_id() == ship_node.get_instance_id():
			continue
		ship.get_node("CollisionShape2D").shape.radius = ship.collision_shape_radius
		ship.draw_collision_shape = 0
	for obstacle in obstacle_nodes:
		if is_instance_valid(obstacle):
			obstacle.get_node("CollisionShape2D").shape.radius = obstacle.collision_shape_radius
			obstacle.draw_collision_shape = 0
