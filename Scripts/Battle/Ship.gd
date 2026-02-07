extends "BattleEntity.gd"

var ship_class:int
var ship_type:int

enum {
	PATH_1,
	PATH_2,
	PATH_3
}
var bullet_levels:Array
var laser_levels:Array
var bomb_levels:Array
var light_levels:Array

var weapon_accuracy_mult:float
var fires_remaining:int = 1
var light_cone
var light_emission_cone_angle = PI / 4.0
var display_move_path = false
var forbid_movement = false
var display_explosive_AoE = false
var move_target_position:Vector2
var move_additional_costs:float
var pushable_entities = []
var target_btns = {}
var push_movement_used:float:
	set(value):
		push_movement_used = value
		update_push_movement_used()
var entity_to_push:BattleEntity
var block_cancelling_action = false

func _ready() -> void:
	super()
	if ship_class == ShipClass.SUPPORT:
		regen_per_turn = ceil(total_HP * 0.15)
	collision_shape_radius = 36.0
	movement_remaining = (agility + agility_buff) * METERS_PER_AGILITY
	total_movement_base = (agility + agility_buff) * METERS_PER_AGILITY
	go_through_movement_cost = 30.0
	$Sprite2D.scale *= 104.0 / $Sprite2D.texture.get_width()

func initialize_stats(data: Dictionary):
	super(data)
	ship_class = data.ship_class
	bullet_levels = data.bullet
	laser_levels = data.laser
	bomb_levels = data.bomb
	light_levels = data.light
	if ship_class == ShipClass.STANDARD:
		for effect in Battle.StatusEffect.N:
			status_effect_resistances[effect] = 0.2

func turn_on_lights(index: int):
	for i in 4:
		if i == index:
			get_node("Sprite2D/Ship%sLights" % (i+1)).show()
		else:
			get_node("Sprite2D/Ship%sLights" % (i+1)).hide()

var highlighted_targets = []

func _draw() -> void:
	super()
	if display_move_path:
		forbid_movement = false
		$RayCast2D.clear_exceptions()
		for target in highlighted_targets:
			if is_instance_valid(target):
				target.draw_collision_shape = 1
		highlighted_targets.clear()
		move_additional_costs = 0.0
		var target_line_vector = battle_scene.mouse_position_local - position
		$RayCast2D.target_position = min(movement_remaining * battle_scene.PIXELS_PER_METER, target_line_vector.length()) * target_line_vector.normalized()
		var ray_movement_remaining = movement_remaining * battle_scene.PIXELS_PER_METER # px
		var ray_travel_length = 0.0 # px
		var last_hit_point = Vector2.ZERO
		while true:
			$RayCast2D.force_raycast_update()
			var hit_target = $RayCast2D.get_collider()
			if hit_target is BattleEntity:
				var hit_point = to_local($RayCast2D.get_collision_point())
				ray_travel_length += (hit_point - last_hit_point).length()
				ray_movement_remaining -= (hit_point - last_hit_point).length() + hit_target.go_through_movement_cost * battle_scene.PIXELS_PER_METER
				$RayCast2D.add_exception(hit_target)
				hit_target.draw_collision_shape = 2
				highlighted_targets.append(hit_target)
				if ray_movement_remaining <= 0.0:
					if is_inf(hit_target.go_through_movement_cost):
						forbid_movement = true
					break
				$RayCast2D.target_position = min(ray_travel_length + ray_movement_remaining, target_line_vector.length()) * target_line_vector.normalized()
				move_additional_costs += hit_target.go_through_movement_cost
				last_hit_point = hit_point
			else:
				ray_travel_length += ray_movement_remaining
				break
		var move_euclidean_distance = min(target_line_vector.length(), ray_travel_length) # px
		#var move_actual_distance = move_euclidean_distance / battle_scene.PIXELS_PER_METER + move_additional_costs # m
		var line_vector = move_euclidean_distance * target_line_vector.normalized()
		move_target_position = line_vector + position
		if forbid_movement:
			draw_line(Vector2.ZERO, line_vector, Color.RED)
			draw_string(SystemFont.new(), line_vector + 20.0 * Vector2.ONE, "-", 0, -1, 16, Color.RED)
		else:
			draw_line(Vector2.ZERO, line_vector, Color.WHITE)
			var dist_str = "%.1f m" % (move_euclidean_distance / battle_scene.PIXELS_PER_METER)
			if move_additional_costs > 0.0:
				dist_str += " (+ %.1f m)" % move_additional_costs
			draw_string(SystemFont.new(), line_vector + 20.0 * Vector2.ONE, dist_str)
	if display_explosive_AoE:
		draw_circle(battle_scene.mouse_position_local - position, Data.battle_weapon_stats.bomb.AoE_radius[bomb_levels[PATH_1] - 1], Color(1.0, 0.0, 0.0, 0.2))
		for i in range(0, 32, 2):
			draw_arc(battle_scene.mouse_position_local - position, Data.battle_weapon_stats.bomb.AoE_radius[bomb_levels[PATH_1] - 1], 2.0 * PI / 32.0 * i, 2.0 * PI / 32.0 * (i+1), 100, Color.RED)

func take_turn():
	movement_remaining = total_movement
	buffed_from_class_passive_ability = false
	if ship_class == ShipClass.ENERGETIC and randf() < 0.3:
		status_effects[Battle.StatusEffect.EXTRA_TURNS] = 2
	await super()
	if HP <= 0: # For example, if burned to death during super() call
		return
	if ship_class == ShipClass.RECKLESS:
		if turn_number == 1:
			extra_attacks = 2
		elif turn_number % 3 != 0: # Turn 2, 4, 5, 7, 8...
			extra_attacks = 1
		else:
			extra_attacks = 0
			status_effects[Battle.StatusEffect.STUN] += 2
	elif ship_class == ShipClass.UBER:
		if turn_number % 2 == 1:
			extra_attacks = 1
		else:
			extra_attacks = 0
	decrement_status_effects_buffs()

func move():
	display_move_path = false
	battle_scene.hide_and_restore_collision_shapes()
	queue_redraw()
	var move_vector = (move_target_position - position)
	var move_angle_target = atan2(move_vector.y, move_vector.x)
	# Modify move_angle_target so the ship does not rotate 358 degrees when going from
	# 179° to -179° (only needs to rotate 2°)
	#
	#		x <- move_angle_target
	# (-PI) -------------O------------> (0.0)
	#		x <- $Sprite2D.rotation
	#
	if move_angle_target < $Sprite2D.rotation - PI:
		move_angle_target -= snappedf(move_angle_target - $Sprite2D.rotation, 2.0 * PI)
	elif move_angle_target > $Sprite2D.rotation + PI:
		move_angle_target += snappedf(move_angle_target - $Sprite2D.rotation, 2.0 * PI)
	movement_remaining -= move_vector.length() / battle_scene.PIXELS_PER_METER
	movement_remaining -= move_additional_costs
	if battle_scene.animations_sped_up:
		var move_tween = create_tween().set_parallel()
		move_tween.tween_property($Sprite2D, "rotation", move_angle_target, 0.2)
		move_tween.tween_property(self, "position", move_target_position, 0.2)
		move_tween.tween_property(battle_scene.get_node("Selected"), "position", move_target_position + Vector2.UP * 80.0, 0.2)
		move_tween.tween_callback(cancel_action).set_delay(0.2)
	else:
		var rotate_duration = max(0.4, abs((move_angle_target - $Sprite2D.rotation) / PI))
		var move_tween = create_tween().set_parallel()
		move_tween.tween_property($Sprite2D, "rotation", move_angle_target, rotate_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		move_tween.tween_property(self, "position", move_target_position, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(rotate_duration)
		move_tween.tween_property(battle_scene.get_node("Selected"), "position", move_target_position + Vector2.UP * 80.0, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(rotate_duration)
		move_tween.tween_callback(cancel_action).set_delay(rotate_duration + 1.0)


func _process(delta: float) -> void:
	$FireWeaponAim.target_angle = atan2(battle_scene.mouse_position_local.y - position.y, battle_scene.mouse_position_local.x - position.x)
	$FireWeaponAim.length = (battle_scene.mouse_position_local - position).length()


func _on_fire_weapon_aim_visibility_changed() -> void:
	if $FireWeaponAim.visible:
		$FireWeaponAim.target_angle_max_deviation = 0.5 / (accuracy + accuracy_buff) / weapon_accuracy_mult
		if $FireWeaponAim.weapon_type == battle_GUI.BULLET:
			if bullet_levels[PATH_3] >= 2:
				$FireWeaponAim.target_angle_max_deviation *= 0.33
		elif $FireWeaponAim.weapon_type == battle_GUI.LASER:
			if laser_levels[PATH_3] >= 2:
				$FireWeaponAim.target_angle_max_deviation = 0.0
		$FireWeaponAim.animate(false)


func _on_mouse_entered() -> void:
	if battle_GUI.action_selected in [battle_GUI.MOVE, battle_GUI.PUSH]:
		return
	if override_tooltip_text:
		game.show_tooltip(override_tooltip_text)
	else:
		refresh_default_tooltip_text()
		default_tooltip_text += "\n" + tr("PASSIVE_ABILITY") + ":"
		default_tooltip_text += "\n - " + tr("%s_PASSIVE_ABILITY" % ShipClass.names[ship_class].to_upper())
		game.show_tooltip(default_tooltip_text, {"imgs": default_tooltip_icons})


func _on_mouse_exited() -> void:
	game.hide_tooltip()

func fire_weapon(weapon_type: int):
	game.hide_tooltip()
	display_explosive_AoE = false
	queue_redraw()
	fires_remaining -= 1
	if fires_remaining <= 0:
		$FireWeaponAim.fade_out()
		block_cancelling_action = false
	else:
		block_cancelling_action = true
	var weapon_rotation_min = $FireWeaponAim.target_angle - $FireWeaponAim.target_angle_max_deviation
	var weapon_rotation_max = $FireWeaponAim.target_angle + $FireWeaponAim.target_angle_max_deviation
	var weapon_rotation = randf_range(weapon_rotation_min, weapon_rotation_max)
	if weapon_type == battle_GUI.BULLET:
		fires_remaining = 0
		var projectiles = []
		var projectile_num = Data.battle_weapon_stats.bullet.shots_fired[bullet_levels[PATH_1] - 1]
		var status_effects = {}
		var bullet_texture = preload("res://Graphics/Battle/Projectiles/bullet.png")
		var trail_color = Color.WHITE
		if battle_GUI.bullet_2_selected_type == battle_GUI.CORROSIVE_BULLET:
			bullet_texture = preload("res://Graphics/Battle/Projectiles/corrosive_bullet.png")
			trail_color = Color.YELLOW_GREEN
			var corroding_turns = Data.battle_weapon_stats.bullet.status_effects[Battle.StatusEffect.CORRODING][bullet_levels[PATH_2] - 1]
			if corroding_turns > 0:
				status_effects[Battle.StatusEffect.CORRODING] = corroding_turns
			var radioactive_turns = Data.battle_weapon_stats.bullet.status_effects[Battle.StatusEffect.RADIOACTIVE][bullet_levels[PATH_2] - 1]
			if radioactive_turns > 0:
				status_effects[Battle.StatusEffect.RADIOACTIVE] = radioactive_turns
		elif battle_GUI.bullet_2_selected_type == battle_GUI.AQUA_BULLET:
			bullet_texture = preload("res://Graphics/Battle/Projectiles/aqua_bullet.png")
			trail_color = Color.LIGHT_BLUE
			var wet_turns = Data.battle_weapon_stats.bullet.status_effects[Battle.StatusEffect.WET][bullet_levels[PATH_2] - 1]
			if wet_turns > 0:
				status_effects[Battle.StatusEffect.WET] = wet_turns
			var frozen_turns = Data.battle_weapon_stats.bullet.status_effects[Battle.StatusEffect.FROZEN][bullet_levels[PATH_2] - 1]
			if frozen_turns > 0:
				status_effects[Battle.StatusEffect.RADIOACTIVE] = frozen_turns
		for i in projectile_num:
			var projectile = preload("res://Scenes/Battle/Weapons/Projectile.tscn").instantiate()
			projectile.collision_layer = 8
			projectile.collision_mask = 1 + 4 + 32
			projectile.set_script(load("res://Scripts/Battle/Weapons/Bullet.gd"))
			projectile.get_node("Sprite2D").texture = bullet_texture
			projectile.trail_color = trail_color
			projectile.speed = 1000.0
			projectile.mass = Data.battle_weapon_stats.bullet.mass[bullet_levels[PATH_2] - 1]
			projectile.velocity_process_modifier = 5.0 if battle_scene.animations_sped_up else 1.0
			projectile.rotation = randf_range(weapon_rotation_min, weapon_rotation_max)
			projectile.damage = Data.battle_weapon_stats.bullet.damage * Data.battle_weapon_stats.bullet.damage_multiplier[bullet_levels[PATH_2] - 1]
			projectile.crit_hit_mult = Data.battle_weapon_stats.bullet.crit_hit_mult[bullet_levels[PATH_2] - 1]
			projectile.shooter = self
			projectile.weapon_accuracy = Data.battle_weapon_stats.bullet.accuracy * accuracy
			projectile.deflects_remaining = Data.battle_weapon_stats.bullet.deflects[bullet_levels[PATH_2] - 1]
			if battle_GUI.bullet_2_selected_type == battle_GUI.BIG_BULLET:
				projectile.knockback = Data.battle_weapon_stats.bullet.knockback[bullet_levels[PATH_2] - 1]
			projectile.ignore_defense_buffs = Data.battle_weapon_stats.bullet.ignore_defense_buffs[bullet_levels[PATH_2] - 1]
			projectile.status_effects = status_effects
			projectile.position = position
			projectile.ending_turn_delay = 1.0
			projectile.end_turn.connect(ending_turn)
			projectile.battle_GUI = battle_GUI
			battle_scene.add_child(projectile)
			projectiles.append(projectile)
			$FireProjectileFlash/AnimationPlayer.stop()
			$FireProjectileFlash/AnimationPlayer.play("Flash")
			if i < projectile_num-1:
				await get_tree().create_timer(0.2).timeout
		for projectile in projectiles:
			if is_instance_valid(projectile):
				projectile.end_turn_ready = true
				break
	elif weapon_type == battle_GUI.LASER:
		fire_laser(weapon_rotation, true)
		if $FireWeaponAim.multishot >= 3:
			fire_laser(weapon_rotation - $FireWeaponAim.multishot_angle)
			fire_laser(weapon_rotation + $FireWeaponAim.multishot_angle)
		if $FireWeaponAim.multishot >= 5:
			fire_laser(weapon_rotation - $FireWeaponAim.multishot_angle / 2.0)
			fire_laser(weapon_rotation + $FireWeaponAim.multishot_angle / 2.0)
	elif weapon_type == battle_GUI.BOMB:
		var explosive = preload("res://Scenes/Battle/Weapons/Explosive.tscn").instantiate()
		explosive.collision_layer = 8
		explosive.collision_mask = 1 + 4 + 32
		explosive.set_script(load("res://Scripts/Battle/Weapons/Explosive.gd"))
		explosive.speed = 800.0
		explosive.velocity_process_modifier = 5.0 if battle_scene.animations_sped_up else 1.0
		explosive.damage = Data.battle_weapon_stats.bomb.damage * Data.battle_weapon_stats.bomb.damage_multiplier[bomb_levels[PATH_1] - 1]
		explosive.AoE_radius = Data.battle_weapon_stats.bomb.AoE_radius[bomb_levels[PATH_1] - 1]
		explosive.mass = Data.battle_weapon_stats.bomb.mass[bomb_levels[PATH_1] - 1]
		explosive.knockback = Data.battle_weapon_stats.bomb.knockback[bomb_levels[PATH_1] - 1]
		explosive.rotation = weapon_rotation
		explosive.shooter = self
		explosive.weapon_accuracy = Data.battle_weapon_stats.bomb.accuracy * accuracy
		explosive.status_effects = {Battle.StatusEffect.BURN: Data.battle_weapon_stats.bomb.status_effects[Battle.StatusEffect.BURN][bomb_levels[PATH_2] - 1]}
		var stun_turns = Data.battle_weapon_stats.bomb.status_effects[Battle.StatusEffect.STUN][bomb_levels[PATH_1] - 1]
		if stun_turns > 0:
			explosive.status_effects[Battle.StatusEffect.STUN] = stun_turns
		explosive.position = position
		explosive.battle_GUI = battle_GUI
		explosive.ending_turn_delay = 1.0
		explosive.end_turn_ready = true
		battle_scene.add_child(explosive)
		if fires_remaining <= 0:
			explosive.end_turn.connect(ending_turn)
	elif weapon_type == battle_GUI.LIGHT:
		if fires_remaining <= 0:
			light_cone.tree_exited.connect(ending_turn)
		light_cone.fire_light(0.2 if battle_scene.animations_sped_up else 1.0)

func fire_laser(angle: float, add_signal: bool = false):
	var laser = preload("res://Scenes/Battle/Weapons/Laser.tscn").instantiate()
	laser.rotation = angle
	laser.damage = Data.battle_weapon_stats.laser.damage
	laser.shooter = self
	laser.weapon_accuracy = Data.battle_weapon_stats.laser.accuracy * accuracy
	laser.position = position
	laser.fade_delay = 0.2 if battle_scene.animations_sped_up else 0.5
	laser.status_effects = {Battle.StatusEffect.STUN: Data.battle_weapon_stats.laser.status_effects[Battle.StatusEffect.STUN][laser_levels[PATH_2] - 1]}
	battle_scene.add_child(laser)
	if add_signal and fires_remaining <= 0:
		laser.tree_exited.connect(ending_turn)


func add_light_cone():
	light_cone = preload("res://Scenes/Battle/Weapons/LightCone.tscn").instantiate()
	light_cone.set_script(load("res://Scripts/Battle/Weapons/LightCone.gd"))
	light_cone.emission_cone_angle = light_emission_cone_angle
	light_cone.damage = Data.battle_weapon_stats.light.damage * Data.battle_weapon_stats.light.damage_multiplier[light_levels[PATH_2] - 1]
	light_cone.shooter = self
	add_child(light_cone)


func ending_turn(delay: float = 0.0):
	create_tween().tween_callback(end_turn).set_delay(0.0 if battle_scene.animations_sped_up else delay)

func end_turn():
	if extra_attacks > 0:
		battle_GUI.fade_in_main_panel()
	super()

func cancel_action():
	if $FireWeaponAim.visible:
		$FireWeaponAim.fade_out()
	if is_instance_valid(light_cone):
		light_cone.queue_free()
	for pushable_entity in target_btns:
		create_tween().tween_property(pushable_entity.get_node("Sprite2D").material, "shader_parameter/alpha", 1.0, 0.2)
		target_btns[pushable_entity].queue_free()
	game.block_scroll = false
	target_btns.clear()
	display_move_path = false
	display_explosive_AoE = false
	battle_scene.hide_and_restore_collision_shapes()
	queue_redraw()
	get_node("RayCast2D").enabled = false
	battle_GUI.fade_in_main_panel()
	if is_instance_valid(entity_to_push):
		entity_to_push.update_velocity_arrow()
		entity_to_push.get_node("VelocityArrow/AnimationPlayer").stop()
		entity_to_push = null


func _on_push_area_area_entered(area: Area2D) -> void:
	if area.get_instance_id() != get_instance_id():
		pushable_entities.append(area)


func _on_push_area_area_exited(area: Area2D) -> void:
	pushable_entities.erase(area)


func add_target_buttons_for_push():
	for i in len(pushable_entities):
		var entity = pushable_entities[i]
		var target_btn = preload("res://Scenes/TargetButton.tscn").instantiate()
		if i < 10:
			var shortcut_key = (i + 1) % 10
			target_btn.shortcut_str = str(shortcut_key)
			target_btn.get_node("TextureButton").shortcut = Shortcut.new()
			target_btn.get_node("TextureButton").shortcut.events.append(InputEventKey.new())
			target_btn.get_node("TextureButton").shortcut.events[0].physical_keycode = 48 + shortcut_key
		target_btn.get_node("TextureButton").pressed.connect(show_push_strength_panel.bind(entity))
		var position_difference_normalized = (position - entity.position).normalized()
		var velocity_difference = velocity - entity.velocity
		var push_difficulty_from_velocity = abs(0.05 * position_difference_normalized.rotated(PI / 2.0).dot(velocity_difference))
		print(push_difficulty_from_velocity)
		var agility_diff = 0.0
		if entity.type == Battle.EntityType.ENEMY:
			agility_diff = agility + agility_buff - entity.agility - entity.agility_buff
		elif entity.type == Battle.EntityType.SHIP:
			agility_diff = min(agility + agility_buff, entity.agility + entity.agility_buff)
		var push_success_chance = 100.0 * (1.0 - 1.0 / (1.0 + exp((agility_diff - push_difficulty_from_velocity + 9.2) / 5.8)))
		target_btn.get_node("TextureButton").mouse_entered.connect(game.show_tooltip.bind(tr("PUSH_SUCCESS_CHANCE") + ": %.1f%%" % push_success_chance, {"additional_text":tr("PUSH_SUCCESS_CHANCE_HELP")}))
		target_btn.get_node("TextureButton").mouse_exited.connect(game.hide_tooltip)
		create_tween().tween_property(entity.get_node("Sprite2D").material, "shader_parameter/alpha", 0.2, 0.2)
		entity.add_child(target_btn)
		target_btns[entity] = target_btn

func show_push_strength_panel(entity: BattleEntity):
	entity_to_push = entity
	for pushable_entity in target_btns:
		create_tween().tween_property(pushable_entity.get_node("Sprite2D").material, "shader_parameter/alpha", 1.0, 0.2)
		target_btns[pushable_entity].queue_free()
	target_btns.clear()
	battle_GUI.get_node("PushStrengthPanel/MovementUsedLower").text = "30.0 m"
	battle_GUI.get_node("PushStrengthPanel/MovementUsedUpper").text = "%.1f m" % movement_remaining
	push_movement_used = (movement_remaining + 30.0) / 2.0
	entity_to_push.get_node("VelocityArrow/AnimationPlayer").play("Blink")
	battle_GUI.get_node("PushStrengthPanel").show()
	var info_label = battle_GUI.get_node("Info")
	info_label.show()
	game.block_scroll = true
	create_tween().tween_property(info_label, "modulate:a", 1.0, 0.5)
	info_label.text = tr("CHANGE_PUSH_STRENGTH")
	
	
func push_entity():
	var push_success = true
	if entity_to_push.type == Battle.EntityType.ENEMY:
		push_success = push_entity_attempt(agility + agility_buff, entity_to_push.agility + entity_to_push.agility_buff, (position - entity_to_push.position).normalized(), velocity - entity_to_push.velocity)
	entity_to_push.update_velocity_arrow()
	if push_success:
		create_tween().tween_property(entity_to_push, "velocity", entity_to_push.velocity + calculate_velocity_change(), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		battle_scene.add_damage_text(true, entity_to_push.position)
	movement_remaining -= push_movement_used
	entity_to_push.get_node("VelocityArrow/AnimationPlayer").stop()
	var push_tween = create_tween()
	var orig_pos = position
	push_tween.tween_property(self, "position", entity_to_push.position, 0.05).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	push_tween.tween_property(self, "position", orig_pos, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	$PushEffect.scale = Vector2.ONE * remap(push_movement_used, 30.0, 100.0, 0.2, 0.5)
	$PushEffect.rotation = atan2(entity_to_push.position.y - position.y, entity_to_push.position.x - position.x)
	$PushEffect.position = 50.0 * Vector2.from_angle($PushEffect.rotation)
	$PushEffect.show()
	cancel_action()

func calculate_velocity_change():
	return (entity_to_push.position - position).normalized() * push_movement_used * 2.0 * get_mass() / entity_to_push.get_mass()
	
func update_push_movement_used():
	if is_instance_valid(entity_to_push):
		battle_GUI.get_node("PushStrengthPanel/MovementUsed").text = "%.1f m" % push_movement_used
		entity_to_push.update_velocity_arrow(calculate_velocity_change())


func _on_push_effect_visibility_changed() -> void:
	$PushEffect.play("default")


var buffed_from_class_passive_ability = false
func buff_from_class_passive_ability(stat: String, amount: int):
	if buffed_from_class_passive_ability:
		return
	self[stat + "_buff"] += amount
	update_info_labels()
	buffed_from_class_passive_ability = true


func damage_entity(weapon_data: Dictionary):
	if ship_class == ShipClass.IMPENETRABLE:
		weapon_data.nullify_damage_chance = 0.3
	var hit = super(weapon_data)
	if hit:
		if ship_class == ShipClass.DEFENSIVE:
			buff_from_class_passive_ability("defense", 3)
	else:
		if ship_class == ShipClass.AGILE:
			buff_from_class_passive_ability("agility", 3)
	return hit
