class_name BattleGUI
extends Control

@onready var game = get_node("/root/Game")
@onready var main_panel = get_node("MainPanel")
@onready var turn_order_hbox = get_node("TurnOrderHBox")
var battle_scene
var ship_node

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


func _ready() -> void:
	Helper.set_back_btn($Back)
	$MainPanel/Bullet.mouse_exited.connect(game.hide_tooltip)
	$MainPanel/Laser.mouse_exited.connect(game.hide_tooltip)
	$MainPanel/Bomb.mouse_exited.connect(game.hide_tooltip)
	$MainPanel/Light.mouse_exited.connect(game.hide_tooltip)
	$MainPanel/Move.mouse_entered.connect(game.show_tooltip.bind(tr("BATTLE_MOVE_DESC")))
	$MainPanel/Move.mouse_exited.connect(game.hide_tooltip)
	$MainPanel/Push.mouse_exited.connect(game.hide_tooltip)
	$LightEmissionConePanel.hide()
	$Speedup.mouse_entered.connect(game.show_tooltip.bind(tr("SPEED_UP_ANIMATIONS") + " (%s)" % OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(KEY_SPACE))))
	$Speedup.mouse_exited.connect(game.hide_tooltip)


func _input(event: InputEvent) -> void:
	Helper.set_back_btn($Back)
	if event is InputEventMouseMotion:
		$PushStrengthPanel.position = Vector2(1280 - $PushStrengthPanel.size.x - 10, 720 - $PushStrengthPanel.size.y - 10).min(battle_scene.mouse_position_global)
		$LightEmissionConePanel.position = Vector2(1280 - $LightEmissionConePanel.size.x - 10, 720 - $LightEmissionConePanel.size.y - 10).min(battle_scene.mouse_position_global)
	if action_selected != NONE:
		if Input.is_action_just_pressed("cancel"):
			action_selected = NONE
			ship_node.cancel_action()
			reset_GUI()
		elif Input.is_action_just_released("left_click") and not game.view.dragged and $MainPanel.modulate.a == 0.0:
			if action_selected in [BULLET, LASER, BOMB, LIGHT]:
				ship_node.fire_weapon(action_selected)
				action_selected = NONE
				reset_GUI()
			elif action_selected == MOVE:
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
	elif action_selected == LIGHT:
		if Input.is_action_pressed("shift"):
			if Input.is_action_just_pressed("scroll_down"):
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
	elif action_selected == MOVE and event is InputEventMouseMotion:
		ship_node.queue_redraw()
	elif action_selected == PUSH:
		if is_instance_valid(ship_node.entity_to_push):
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

func update_push_strength(update_by: float):
	var current_strength = $PushStrengthPanel/Bar.material.get_shader_parameter("strength")
	var strength_target = clamp(current_strength + update_by, 0.0, 1.0)
	create_tween().tween_property($PushStrengthPanel/Bar.material, "shader_parameter/strength", strength_target, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	create_tween().tween_property(ship_node, "push_movement_used", remap(strength_target, 0.0, 1.0, 30.0, ship_node.movement_remaining), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	create_tween().tween_property($PushStrengthPanel/MovementUsed, "position:y", remap(strength_target, 0.0, 1.0, 288.0, 32.0), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
func reset_GUI():
	restore_default_enemy_tooltips()
	var info_tween = create_tween()
	info_tween.tween_property($Info, "modulate:a", 0.0, 0.5)
	info_tween.tween_callback($Info.hide)
	$LightEmissionConePanel.hide()
	$PushStrengthPanel.hide()
	game.block_scroll = false
	
func refresh_GUI():
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
		if game.ship_data[i].has("unallocated_weapon_levels"):
			game.switch_view("ship_customize_screen", {"ship_id":i})
			return
	game.switch_view("system")


func _on_bullet_mouse_entered() -> void:
	var tooltip_txt = tr("BASE_DAMAGE") + ": " + str(Data.battle_weapon_stats.bullet.damage)
	tooltip_txt += "\n" + tr("BASE_ACCURACY") + ": " + str(Data.battle_weapon_stats.bullet.accuracy)
	game.show_adv_tooltip(tooltip_txt, {"additional_text": tr("BULLET_DESC")})


func _on_laser_mouse_entered() -> void:
	var tooltip_txt = tr("BASE_DAMAGE") + ": " + str(Data.battle_weapon_stats.laser.damage)
	tooltip_txt += "\n" + tr("BASE_ACCURACY") + ": " + str(Data.battle_weapon_stats.laser.accuracy)
	game.show_adv_tooltip(tooltip_txt, {"additional_text": tr("LASER_DESC")})


func _on_bomb_mouse_entered() -> void:
	var tooltip_txt = tr("BASE_DAMAGE") + ": " + str(Data.battle_weapon_stats.bomb.damage)
	tooltip_txt += "\n" + tr("BASE_ACCURACY") + ": " + str(Data.battle_weapon_stats.bomb.accuracy)
	game.show_adv_tooltip(tooltip_txt, {"additional_text": tr("BOMB_DESC")})


func _on_light_mouse_entered() -> void:
	var tooltip_txt = tr("BASE_DAMAGE") + ": " + str(Data.battle_weapon_stats.light.damage)
	tooltip_txt += "\n" + tr("BASE_ACCURACY") + ": " + str(Data.battle_weapon_stats.light.accuracy)
	game.show_adv_tooltip(tooltip_txt, {"additional_text": tr("LIGHT_DESC")})


func _on_push_mouse_entered() -> void:
	var tooltip_txt = tr("BATTLE_PUSH_DESC")
	if ship_node.movement_remaining < 30.0:
		tooltip_txt += "\n[color=#FFAA00]" + tr("REQUIRES_MOVEMENT") + "[/color]"
	if len(ship_node.pushable_entities) == 0:
		tooltip_txt += "\n[color=#FFAA00]" + tr("NO_OBJECTS_NEAR_SHIP") + "[/color]"
	game.show_adv_tooltip(tooltip_txt, {"additional_text": tr("BATTLE_PUSH_HELP")})


func fade_in_main_panel():
	$MainPanel.show()
	if is_instance_valid(ship_node):
		refresh_GUI()
	var fade_tween = create_tween()
	fade_tween.tween_property($MainPanel, "modulate:a", 1.0, 0.2)

func fade_out_main_panel():
	var fade_tween = create_tween()
	fade_tween.tween_property($MainPanel, "modulate:a", 0.0, 0.2)
	fade_tween.tween_callback($MainPanel.hide)

func _on_bullet_pressed() -> void:
	fade_out_main_panel()
	action_selected = BULLET
	override_enemy_tooltips()
	ship_node.get_node("FireWeaponAim").show()
	game.hide_tooltip()


func _on_laser_pressed() -> void:
	fade_out_main_panel()
	action_selected = LASER
	override_enemy_tooltips()
	ship_node.get_node("FireWeaponAim").show()
	game.hide_tooltip()


func _on_bomb_pressed() -> void:
	fade_out_main_panel()
	action_selected = BOMB
	override_enemy_tooltips()
	ship_node.get_node("FireWeaponAim").show()
	game.hide_tooltip()


func _on_light_pressed() -> void:
	action_selected = LIGHT
	override_enemy_tooltips()
	fade_out_main_panel()
	ship_node.add_light_cone()
	$Info.show()
	$Info.text = tr("CHANGE_EMISSION_CONE")
	create_tween().tween_property($Info, "modulate:a", 1.0, 0.5)
	game.hide_tooltip()


func _on_move_pressed() -> void:
	action_selected = MOVE
	fade_out_main_panel()
	battle_scene.show_and_enlarge_collision_shapes()
	ship_node.get_node("RayCast2D").enabled = true
	ship_node.display_move_path = true
	game.hide_tooltip()


func _on_push_pressed() -> void:
	action_selected = PUSH
	fade_out_main_panel()
	ship_node.add_target_buttons_for_push()
	game.hide_tooltip()

func override_enemy_tooltips():
	if action_selected == BULLET:
		ship_node.weapon_accuracy_mult = Data.battle_weapon_stats.bullet.accuracy
	elif action_selected == LASER:
		ship_node.weapon_accuracy_mult = Data.battle_weapon_stats.laser.accuracy
	elif action_selected == BOMB:
		ship_node.weapon_accuracy_mult = Data.battle_weapon_stats.bomb.accuracy
	elif action_selected == LIGHT:
		ship_node.weapon_accuracy_mult = Data.battle_weapon_stats.light.accuracy
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
		$Speedup/Polygon2D.material.set_shader_parameter("amplitude", 3.0)
		$Speedup/Polygon2D.color.a = 1.0
	else:
		Engine.physics_ticks_per_second = 60
		$Speedup/Polygon2D.material.set_shader_parameter("amplitude", 0.0)
		$Speedup/Polygon2D.color.a = 0.5
