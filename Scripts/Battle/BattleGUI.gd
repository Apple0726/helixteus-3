class_name BattleGUI
extends Control

@onready var game = get_node("/root/Game")
@onready var turn_order_hbox = $TurnOrderHBox
var battle_scene

# Actions
enum {
	BULLET,
	LASER,
	BOMB,
	LIGHT,
	MOVE,
	PUSH,
	NONE,
}
var action_selected = NONE

enum {
	BIG_BULLET,
	CORROSIVE_BULLET,
	AQUA_BULLET
}
var bullet_2_selected_type = BIG_BULLET

var main_panel_tween
var turn_order_hbox_tween

func _ready() -> void:
	var p_i:Dictionary = game.planet_data[game.c_p]
	Helper.set_back_btn($Back)
	$MainPanel.hide()
	$MainPanel.modulate.a = 0.0
	$MainPanel/Bullet.mouse_exited.connect(game.hide_tooltip)
	$MainPanel/Laser.mouse_exited.connect(game.hide_tooltip)
	$MainPanel/Bomb.mouse_exited.connect(game.hide_tooltip)
	$MainPanel/Light.mouse_exited.connect(game.hide_tooltip)
	$MainPanel/Move.mouse_entered.connect(game.show_tooltip.bind(tr("BATTLE_MOVE_DESC")))
	$MainPanel/Move.mouse_exited.connect(game.hide_tooltip)
	$MainPanel/Push.mouse_exited.connect(game.hide_tooltip)
	$Speedup.mouse_entered.connect(game.show_tooltip.bind(tr("SPEED_UP_ANIMATIONS") + " (%s)" % OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(KEY_SPACE))))
	$Speedup.mouse_exited.connect(game.hide_tooltip)
	for weapon in ["Bullet", "Laser", "Bomb", "Light"]:
		for path in 3:
			for lv in 3:
				$MainPanel.get_node("%sLevels/Path%s/Level%s" % [weapon, path+1, lv+1]).mouse_entered.connect(show_weapon_tooltip.bind(weapon.to_lower(), path, lv))
				$MainPanel.get_node("%sLevels/Path%s/Level%s" % [weapon, path+1, lv+1]).mouse_exited.connect(game.hide_tooltip)
	seed(p_i.seed)
	$PlanetBG.texture = load("res://Graphics/Planets/%s.png" % p_i.type)
	var random_depth = randf_range(0.6, 1.1)
	$PlanetBG.scale *= random_depth * 640.0 / $PlanetBG.texture.get_width()
	$PlanetLight.scale *= $PlanetBG.scale.x * 0.2
	$PlanetBG.position.x = randf_range(180.0, 1100.0)
	$PlanetBG.position.y = randf_range(180.0, 540.0)
	var average_starlight_color:Color = Color.BLACK
	for star in game.system_data[game.c_s].stars:
		average_starlight_color += Helper.get_star_modulate(star.class) * star.luminosity
	average_starlight_color /= max(average_starlight_color.r, average_starlight_color.g, average_starlight_color.b)
	average_starlight_color.a = 1.0
	$PlanetLight.color = average_starlight_color
	$PlanetLight.position = -350.0 * random_depth * Vector2.from_angle(p_i.angle) + $PlanetBG.position
	$PlanetLight.energy = clamp(remap(p_i.temperature, -270.0, 600.0, 0.0, 8.0), 0.0, 8.0)
	randomize()

func show_weapon_tooltip(weapon: String, path: int, lv: int):
	var ship_node = battle_scene.get_selected_ship()
	if not ship_node:
		return
	var tooltip = tr("%s_%s_%s_DESC" % [weapon.to_upper(), path+1, lv+1])
	if ship_node[weapon + "_levels"][path] <= lv+1:
		tooltip = "[color=#888888]" + tooltip
	game.show_tooltip(tooltip)

func _input(event: InputEvent) -> void:
	Helper.set_back_btn($Back)
	if event is InputEventMouseMotion:
		$PushStrengthPanel.position = Vector2(1280 - $PushStrengthPanel.size.x - 10, 720 - $PushStrengthPanel.size.y - 10).min(battle_scene.mouse_position_global)
		$LightEmissionConePanel.position = Vector2(1280 - $LightEmissionConePanel.size.x - 10, 720 - $LightEmissionConePanel.size.y - 10).min(battle_scene.mouse_position_global)
		$LaserConePanel.position = Vector2(1280 - $LaserConePanel.size.x - 10, 720 - $LaserConePanel.size.y - 10).min(battle_scene.mouse_position_global)
	var ship_node = battle_scene.get_selected_ship()
	if action_selected != NONE and is_instance_valid(ship_node):
		if Input.is_action_just_pressed("cancel") and not ship_node.block_cancelling_action:
			action_selected = NONE
			ship_node.cancel_action()
			reset_GUI()
		elif Input.is_action_just_released("left_click") and not game.view.dragged and $MainPanel.modulate.a == 0.0:
			if action_selected in [BULLET, LASER, BOMB, LIGHT]:
				ship_node.fire_weapon(action_selected)
				if ship_node.fires_remaining <= 0:
					action_selected = NONE
					reset_GUI()
			elif action_selected == MOVE:
				if not ship_node.forbid_movement:
					ship_node.move()
					action_selected = NONE
					reset_GUI()
			elif action_selected == PUSH:
				pass
	if action_selected == NONE and is_instance_valid(ship_node):
		if Input.is_action_just_pressed("1"):
			_on_bullet_pressed()
		elif Input.is_action_just_pressed("2"):
			_on_laser_pressed()
		elif Input.is_action_just_pressed("3"):
			_on_bomb_pressed()
		elif Input.is_action_just_pressed("4"):
			_on_light_pressed()
		elif Input.is_action_just_pressed("5"):
			_on_move_pressed()
		elif Input.is_action_just_pressed("6"):
			_on_push_pressed()
	elif action_selected == BULLET and is_instance_valid(ship_node):
		if ship_node.bullet_levels[1] >= 2 and Input.is_action_pressed("shift"):
			if Input.is_action_just_pressed("scroll_down"):
				bullet_2_selected_type = [BIG_BULLET, CORROSIVE_BULLET, AQUA_BULLET][(bullet_2_selected_type + 1) % 3]
				refresh_info_label("bullet_2")
			if Input.is_action_just_pressed("scroll_up"):
				bullet_2_selected_type = [BIG_BULLET, CORROSIVE_BULLET, AQUA_BULLET][(bullet_2_selected_type - 1) % 3]
				refresh_info_label("bullet_2")
		if Input.is_action_just_pressed("shift"):
			game.block_scroll = true
		elif Input.is_action_just_released("shift"):
			game.block_scroll = false
	elif action_selected == LASER:
		if Data.battle_weapon_stats.laser.multishot[ship_node.laser_levels[0] - 1] > 1:
			if Input.is_action_pressed("shift"):
				if Input.is_action_just_pressed("scroll_down"):
					ship_node.get_node("FireWeaponAim").multishot_angle = min(ship_node.get_node("FireWeaponAim").multishot_angle + PI / 64.0, 0.3 * PI)
					override_enemy_tooltips()
				if Input.is_action_just_pressed("scroll_up"):
					ship_node.get_node("FireWeaponAim").multishot_angle = max(ship_node.get_node("FireWeaponAim").multishot_angle - PI / 64.0, PI / 64.0)
					override_enemy_tooltips()
			if Input.is_action_just_pressed("shift"):
				game.block_scroll = true
				$LaserConePanel.show()
			elif Input.is_action_just_released("shift"):
				game.block_scroll = false
				$LaserConePanel.hide()
	elif action_selected == LIGHT and is_instance_valid(ship_node):
		if Input.is_action_pressed("shift"):
			if Input.is_action_just_pressed("scroll_down"):
				if ship_node.light_levels[1] >= 2:
					ship_node.light_cone.emission_cone_angle = min(ship_node.light_cone.emission_cone_angle + PI / 64.0, 1.8 * PI)
				else:
					ship_node.light_cone.emission_cone_angle = min(ship_node.light_cone.emission_cone_angle + PI / 64.0, 0.3 * PI)
				ship_node.light_emission_cone_angle = ship_node.light_cone.emission_cone_angle
				ship_node.light_cone.update_cone_animate()
				override_enemy_tooltips()
			if Input.is_action_just_pressed("scroll_up"):
				ship_node.light_cone.emission_cone_angle = max(ship_node.light_cone.emission_cone_angle - PI / 64.0, PI / 64.0)
				ship_node.light_emission_cone_angle = ship_node.light_cone.emission_cone_angle
				ship_node.light_cone.update_cone_animate()
				override_enemy_tooltips()
		if Input.is_action_just_pressed("shift"):
			game.block_scroll = true
			$LightEmissionConePanel.show()
		elif Input.is_action_just_released("shift"):
			game.block_scroll = false
			$LightEmissionConePanel.hide()
	elif action_selected != NONE and event is InputEventMouseMotion and is_instance_valid(ship_node):
		ship_node.queue_redraw()
	elif action_selected == PUSH and is_instance_valid(ship_node.entity_to_push):
		if Input.is_action_just_pressed("scroll_up"):
			if Input.is_action_pressed("shift"):
				update_push_strength(1.0)
			else:
				update_push_strength(0.1)
		if Input.is_action_just_pressed("scroll_down"):
			if Input.is_action_pressed("shift"):
				update_push_strength(-1.0)
			else:
				update_push_strength(-0.1)
		if Input.is_action_just_released("left_click"):
			ship_node.push_entity()
			action_selected = NONE
			reset_GUI()

func refresh_info_label(type: String):
	if type == "bullet_2":
		$Info.text = tr("BULLET_2_TYPE_%s" % (bullet_2_selected_type + 1)) + "\n" + tr("SCROLL_TO_SWITCH_BULLET")
		if bullet_2_selected_type == BIG_BULLET:
			$Info/TextureRect.texture = preload("res://Graphics/Weapons/bullet1.png")
		elif bullet_2_selected_type == CORROSIVE_BULLET:
			$Info/TextureRect.texture = preload("res://Graphics/Weapons/corrosive_bullet.png")
		elif bullet_2_selected_type == AQUA_BULLET:
			$Info/TextureRect.texture = preload("res://Graphics/Weapons/aqua_bullet.png")

func update_push_strength(update_by: float):
	var ship_node = battle_scene.get_selected_ship()
	if not ship_node:
		return
	var current_strength = $PushStrengthPanel/Bar.material.get_shader_parameter("strength")
	var strength_target = clamp(current_strength + update_by, 0.0, 1.0)
	create_tween().tween_property($PushStrengthPanel/Bar.material, "shader_parameter/strength", strength_target, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	create_tween().tween_property(ship_node, "push_movement_used", remap(strength_target, 0.0, 1.0, 30.0, ship_node.movement_remaining), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	create_tween().tween_property($PushStrengthPanel/MovementUsed, "position:y", remap(strength_target, 0.0, 1.0, 288.0, 32.0), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
func reset_GUI():
	restore_default_enemy_tooltips()
	$Info.hide()
	$Info/TextureRect.texture = null
	$LightEmissionConePanel.hide()
	$LaserConePanel.hide()
	$PushStrengthPanel.hide()
	game.block_scroll = false
	if turn_order_hbox.visible:
		if turn_order_hbox_tween and turn_order_hbox_tween.is_running():
			turn_order_hbox_tween.kill()
			turn_order_hbox_tween = create_tween()
			turn_order_hbox_tween.tween_property(turn_order_hbox, "modulate:a", 1.0, 0.2)
	else:
		turn_order_hbox.show()
		turn_order_hbox_tween = create_tween()
		turn_order_hbox_tween.tween_property(turn_order_hbox, "modulate:a", 1.0, 0.2)

func refresh_GUI():
	var ship_node = battle_scene.get_selected_ship()
	if not ship_node:
		return
	for weapon in ["Bullet", "Laser", "Bomb", "Light"]:
		var hide_levels = true
		for path in 3:
			if ship_node[weapon.to_lower() + "_levels"][path] > 1:
				hide_levels = false
				break
		for path in 3:
			if hide_levels:
				$MainPanel.get_node("%sLevels/Path%s" % [weapon, path+1]).hide()
			else:
				$MainPanel.get_node("%sLevels/Path%s" % [weapon, path+1]).show()
				for lv in 3:
					$MainPanel.get_node("%sLevels/Path%s/Level%s" % [weapon, path+1, lv+1]).modulate = Color.WHITE if ship_node[weapon.to_lower() + "_levels"][path] > lv+1 else Color(0.3, 0.3, 0.3)
	if ship_node.bomb_levels[2] >= 3:
		$MainPanel/Bomb.icon = preload("res://Graphics/Battle/Projectiles/missile.png")
	else:
		$MainPanel/Bomb.icon = preload("res://Graphics/Weapons/bomb1.png")
	$MainPanel/MoveLabel.text = "%s (%.1f m)" % [tr("MOVE"), ship_node.movement_remaining]
	if is_zero_approx(ship_node.movement_remaining):
		$MainPanel/MoveLabel["theme_override_colors/font_color"] = Color.DARK_GRAY
		$MainPanel/Move.disabled = true
	else:
		$MainPanel/MoveLabel["theme_override_colors/font_color"] = Color.WHITE
		$MainPanel/Move.disabled = false
	if len(ship_node.pushable_entities) == 0 or ship_node.movement_remaining < 30.0:
		$MainPanel/PushLabel["theme_override_colors/font_color"] = Color.DARK_GRAY
		$MainPanel/Push.disabled = true
	else:
		$MainPanel/PushLabel["theme_override_colors/font_color"] = Color.WHITE
		$MainPanel/Push.disabled = false

func _on_back_pressed() -> void:
	if battle_scene.hard_battle:
		game.switch_music(load("res://Audio/ambient%s.ogg" % randi_range(1, 3)), game.u_i.time_speed)
	for i in len(game.ship_data):
		if game.ship_data[i].has("leveled_up"):
			game.switch_view("ship_customize_screen", {"ship_id":i, "label_text":tr("SHIP_LEVELED_UP")})
			return
	game.switch_view("system")


func _on_bullet_mouse_entered() -> void:
	var tooltip_txt = tr("BASE_DAMAGE") + ": " + str(Data.battle_weapon_stats.bullet.damage)
	tooltip_txt += "\n" + tr("BASE_ACCURACY") + ": " + str(Data.battle_weapon_stats.bullet.accuracy)
	game.show_tooltip(tooltip_txt, {"additional_text": tr("BULLET_DESC")})


func _on_laser_mouse_entered() -> void:
	var tooltip_txt = tr("BASE_DAMAGE") + ": " + str(Data.battle_weapon_stats.laser.damage)
	tooltip_txt += "\n" + tr("BASE_ACCURACY") + ": " + str(Data.battle_weapon_stats.laser.accuracy)
	game.show_tooltip(tooltip_txt, {"additional_text": tr("LASER_DESC")})


func _on_bomb_mouse_entered() -> void:
	var tooltip_txt = tr("BASE_DAMAGE") + ": " + str(Data.battle_weapon_stats.bomb.damage)
	tooltip_txt += "\n" + tr("BASE_ACCURACY") + ": " + str(Data.battle_weapon_stats.bomb.accuracy)
	game.show_tooltip(tooltip_txt, {"additional_text": tr("BOMB_DESC")})


func _on_light_mouse_entered() -> void:
	var tooltip_txt = tr("BASE_DAMAGE") + ": " + str(Data.battle_weapon_stats.light.damage)
	tooltip_txt += "\n" + tr("BASE_ACCURACY") + ": " + tr("PERFECT")
	game.show_tooltip(tooltip_txt, {"additional_text": tr("LIGHT_DESC")})


func _on_push_mouse_entered() -> void:
	var ship_node = battle_scene.get_selected_ship()
	if not ship_node:
		return
	var tooltip_txt = tr("BATTLE_PUSH_DESC")
	if ship_node.movement_remaining < 30.0:
		tooltip_txt += "\n[color=#FFAA00]" + tr("REQUIRES_MOVEMENT") + "[/color]"
	if len(ship_node.pushable_entities) == 0:
		tooltip_txt += "\n[color=#FFAA00]" + tr("NO_OBJECTS_NEAR_SHIP") + "[/color]"
	game.show_tooltip(tooltip_txt, {"additional_text": tr("BATTLE_PUSH_HELP")})


func fade_in_main_panel():
	$MainPanel.show()
	var ship_node = battle_scene.get_selected_ship()
	if is_instance_valid(ship_node):
		refresh_GUI()
	if main_panel_tween and main_panel_tween.is_running():
		main_panel_tween.kill()
	main_panel_tween = create_tween()
	main_panel_tween.tween_property($MainPanel, "modulate:a", 1.0, 0.2)

func fade_out_main_panel():
	if main_panel_tween and main_panel_tween.is_running():
		main_panel_tween.kill()
	main_panel_tween = create_tween()
	main_panel_tween.tween_property($MainPanel, "modulate:a", 0.0, 0.2)
	main_panel_tween.tween_callback($MainPanel.hide)

func _on_bullet_pressed() -> void:
	var ship_node = battle_scene.get_selected_ship()
	if not ship_node:
		return
	fade_out_main_panel()
	fade_out_turn_order_box()
	action_selected = BULLET
	ship_node.weapon_accuracy_mult = Data.battle_weapon_stats.bullet.accuracy
	override_enemy_tooltips()
	ship_node.fires_remaining = 1
	ship_node.get_node("FireWeaponAim").multishot = 1
	ship_node.get_node("FireWeaponAim").weapon_type = BULLET
	ship_node.get_node("FireWeaponAim").show()
	if ship_node.bullet_levels[1] >= 2:
		$Info.show()
		refresh_info_label("bullet_2")
	else:
		bullet_2_selected_type = BIG_BULLET
	game.hide_tooltip()


func _on_laser_pressed() -> void:
	var ship_node = battle_scene.get_selected_ship()
	if not ship_node:
		return
	fade_out_main_panel()
	fade_out_turn_order_box()
	action_selected = LASER
	ship_node.weapon_accuracy_mult = Data.battle_weapon_stats.laser.accuracy
	override_enemy_tooltips()
	ship_node.fires_remaining = Data.battle_weapon_stats.laser.consecutive_fires[ship_node.laser_levels[0] - 1]
	ship_node.get_node("FireWeaponAim").multishot = Data.battle_weapon_stats.laser.multishot[ship_node.laser_levels[0] - 1]
	if ship_node.get_node("FireWeaponAim").multishot > 1:
		$Info.show()
		$Info.text = tr("CHANGE_EMISSION_CONE")
	ship_node.get_node("FireWeaponAim").multishot_angle = PI / 16.0
	ship_node.get_node("FireWeaponAim").ship_node = ship_node
	ship_node.get_node("FireWeaponAim").weapon_type = LASER
	ship_node.get_node("FireWeaponAim").show()
	game.hide_tooltip()


func _on_bomb_pressed() -> void:
	var ship_node = battle_scene.get_selected_ship()
	if not ship_node:
		return
	fade_out_main_panel()
	fade_out_turn_order_box()
	action_selected = BOMB
	ship_node.weapon_accuracy_mult = Data.battle_weapon_stats.bomb.accuracy
	if ship_node.bomb_levels[2] >= 2:
		ship_node.weapon_accuracy_mult *= 1.7
	override_enemy_tooltips()
	ship_node.fires_remaining = 1
	ship_node.display_explosive_AoE = true
	ship_node.queue_redraw()
	ship_node.get_node("FireWeaponAim").multishot = 1
	ship_node.get_node("FireWeaponAim").weapon_type = BOMB
	ship_node.get_node("FireWeaponAim").show()
	game.hide_tooltip()


func _on_light_pressed() -> void:
	var ship_node = battle_scene.get_selected_ship()
	if not ship_node:
		return
	action_selected = LIGHT
	ship_node.weapon_accuracy_mult = Data.battle_weapon_stats.light.accuracy
	override_enemy_tooltips()
	ship_node.fires_remaining = 1
	fade_out_main_panel()
	fade_out_turn_order_box()
	ship_node.add_light_cone()
	$Info.show()
	$Info.text = tr("CHANGE_EMISSION_CONE")
	game.hide_tooltip()


func _on_move_pressed() -> void:
	var ship_node = battle_scene.get_selected_ship()
	if not ship_node:
		return
	action_selected = MOVE
	fade_out_main_panel()
	fade_out_turn_order_box()
	battle_scene.show_and_enlarge_collision_shapes()
	ship_node.get_node("RayCast2D").enabled = true
	ship_node.display_move_path = true
	game.hide_tooltip()

func fade_out_turn_order_box():
	if turn_order_hbox_tween and turn_order_hbox_tween.is_running():
		turn_order_hbox_tween.kill()
	turn_order_hbox_tween = create_tween()
	turn_order_hbox_tween.tween_property(turn_order_hbox, "modulate:a", 0.0, 0.2)
	turn_order_hbox_tween.tween_callback(turn_order_hbox.hide)

func _on_push_pressed() -> void:
	var ship_node = battle_scene.get_selected_ship()
	if not ship_node:
		return
	action_selected = PUSH
	fade_out_main_panel()
	fade_out_turn_order_box()
	ship_node.add_target_buttons_for_push()
	game.hide_tooltip()

func override_enemy_tooltips():
	var ship_node = battle_scene.get_selected_ship()
	if not ship_node:
		return
	for HX_node in battle_scene.HX_nodes:
		var damage_multiplier:float
		var attack_defense_difference:int = ship_node.attack + ship_node.attack_buff - HX_node.defense - HX_node.defense_buff
		if attack_defense_difference >= 0:
			damage_multiplier = attack_defense_difference * 0.125 + 1.0
		else:
			damage_multiplier = 1.0 / (1.0 - 0.125 * attack_defense_difference)
		var tooltip_txt = tr("DAMAGE_MULTIPLIER") + ": " + "%.2f (%s){light_intensity_mult}{light_intensity_mult_info}" % [damage_multiplier, tr("SHIP_ATK_VS_ENEMY_DEF") % [ship_node.attack + ship_node.attack_buff, HX_node.defense + HX_node.defense_buff]]
		tooltip_txt += "\n" + tr("CHANCE_OF_HITTING") + ": " + "%.1f%% (%s)" % [(100.0 * (1.0 - 1.0 / (1.0 + exp(((ship_node.accuracy + ship_node.accuracy_buff) * ship_node.weapon_accuracy_mult - HX_node.agility - HX_node.agility_buff + 9.2) / 5.8)))),
		tr("SHIP_ATK_VS_ENEMY_DEF") % [ship_node.accuracy + ship_node.accuracy_buff, HX_node.agility + HX_node.agility_buff]]
		HX_node.override_tooltip_text = tooltip_txt

func restore_default_enemy_tooltips():
	for HX_node in battle_scene.HX_nodes:
		HX_node.override_tooltip_text = ""
		HX_node.override_tooltip_dict = HX_node.default_override_tooltip_dict.duplicate()


func flash_screen(intensity: float, duration: float):
	$ScreenFlash.show()
	$ScreenFlash.modulate.a = intensity
	var tween = create_tween()
	tween.tween_property($ScreenFlash, "modulate:a", 0.0, duration)
	tween.tween_callback($ScreenFlash.hide)


func _on_speedup_pressed() -> void:
	battle_scene.animations_sped_up = not battle_scene.animations_sped_up
	if battle_scene.animations_sped_up:
		Engine.physics_ticks_per_second = 500
		Engine.max_physics_steps_per_frame = 48
		$Speedup/Polygon2D.material.set_shader_parameter("amplitude", 3.0)
		$Speedup/Polygon2D.color.a = 1.0
	else:
		Engine.physics_ticks_per_second = 60
		Engine.max_physics_steps_per_frame = 8
		$Speedup/Polygon2D.material.set_shader_parameter("amplitude", 0.0)
		$Speedup/Polygon2D.color.a = 0.5
