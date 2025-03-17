extends "BattleEntity.gd"

var movement_remaining:float # in meters
var total_movement:float # in meters
var bullet_lv:int
var laser_lv:int
var bomb_lv:int
var light_lv:int
var weapon_accuracy_mult:float
var light_cone
var display_move_path = false
var move_target_position:Vector2
var move_additional_costs:float
var pushable_entities = []
var target_btns = {}
var push_movement_used:float:
	set(value):
		push_movement_used = value
		update_push_movement_used()
var entity_to_push:BattleEntity


func _ready() -> void:
	super()
	movement_remaining = (agility + agility_buff) * METERS_PER_AGILITY
	total_movement = (agility + agility_buff) * METERS_PER_AGILITY
	go_through_movement_cost = 30.0

func _draw() -> void:
	if display_move_path:
		$RayCast2D.clear_exceptions()
		move_additional_costs = 0.0
		var target_line_vector = battle_scene.mouse_position_local - position
		$RayCast2D.target_position = min(movement_remaining * battle_scene.PIXELS_PER_METER, target_line_vector.length()) * target_line_vector.normalized()
		var ray_movement_remaining = movement_remaining
		while true:
			$RayCast2D.force_raycast_update()
			var hit_target = $RayCast2D.get_collider()
			if hit_target is BattleEntity:
				var hit_point = to_local($RayCast2D.get_collision_point())
				var diff_length = ($RayCast2D.target_position - hit_point).length() / battle_scene.PIXELS_PER_METER
				move_additional_costs += hit_target.go_through_movement_cost
				ray_movement_remaining = max(ray_movement_remaining - hit_target.go_through_movement_cost, 0.0)
				if ray_movement_remaining > 0.0:
					$RayCast2D.add_exception(hit_target)
				else:
					break
			else:
				break
		var move_distance_px = min(target_line_vector.length(), ray_movement_remaining * battle_scene.PIXELS_PER_METER)
		var line_vector = move_distance_px * target_line_vector.normalized()
		move_target_position = line_vector + position
		draw_line(Vector2.ZERO, line_vector, Color.WHITE)
		draw_string(SystemFont.new(), line_vector + 20.0 * Vector2.ONE, "%.1f m" % (move_distance_px / battle_scene.PIXELS_PER_METER + move_additional_costs))

func take_turn():
	movement_remaining = total_movement
	super()

func move():
	display_move_path = false
	queue_redraw()
	var move_tween = create_tween()
	movement_remaining -= (move_target_position - position).length() / battle_scene.PIXELS_PER_METER
	movement_remaining -= move_additional_costs
	move_tween.tween_property(self, "position", move_target_position, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	move_tween.tween_callback(cancel_action)
	create_tween().tween_property(game.view, "position", Vector2(640, 360) - move_target_position * game.view.scale.x, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)


func initialize_stats(data:Dictionary):
	super(data)
	bullet_lv = data.bullet.lv
	laser_lv = data.laser.lv
	bomb_lv = data.bomb.lv
	light_lv = data.light.lv


func _process(delta: float) -> void:
	$FireWeaponAim.target_angle = atan2(battle_scene.mouse_position_local.y - position.y, battle_scene.mouse_position_local.x - position.x)
	$FireWeaponAim.length = (battle_scene.mouse_position_local - position).length()


func _on_fire_weapon_aim_visibility_changed() -> void:
	if $FireWeaponAim.visible:
		$FireWeaponAim.target_angle_max_deviation = 0.5 / (accuracy + accuracy_buff) / weapon_accuracy_mult
		$FireWeaponAim.animate(false)


func _on_mouse_entered() -> void:
	if battle_GUI.action_selected in [battle_GUI.MOVE, battle_GUI.PUSH]:
		return
	if override_tooltip_text:
		game.show_tooltip(override_tooltip_text)
	else:
		game.show_adv_tooltip(default_tooltip_text, {"imgs": default_tooltip_icons})


func _on_mouse_exited() -> void:
	game.hide_tooltip()

func fire_weapon(weapon_type: int):
	$FireWeaponAim.fade_out()
	var weapon_rotation = randf_range($FireWeaponAim.target_angle - $FireWeaponAim.target_angle_max_deviation, $FireWeaponAim.target_angle + $FireWeaponAim.target_angle_max_deviation)
	if weapon_type == battle_GUI.BULLET:
		for i in 2:
			var projectile = preload("res://Scenes/Battle/Weapons/Projectile.tscn").instantiate()
			projectile.collision_layer = 8
			projectile.collision_mask = 1 + 4 + 32
			projectile.set_script(load("res://Scripts/Battle/Weapons/Bullet.gd"))
			projectile.speed = 1000.0
			projectile.rotation = weapon_rotation
			projectile.damage = Data.bullet_data[bullet_lv-1].damage
			projectile.shooter_attack = attack + attack_buff
			projectile.weapon_accuracy = Data.bullet_data[bullet_lv-1].accuracy * accuracy
			projectile.deflects_remaining = bullet_lv
			projectile.position = position
			projectile.ending_turn_delay = 1.0
			projectile.end_turn.connect(ending_turn)
			battle_scene.add_child(projectile)
			await get_tree().create_timer(0.2).timeout
	elif weapon_type == battle_GUI.LASER:
		var laser = preload("res://Scenes/Battle/Weapons/Laser.tscn").instantiate()
		laser.rotation = weapon_rotation
		laser.damage = Data.laser_data[laser_lv-1].damage
		laser.shooter_attack = attack + attack_buff
		laser.weapon_accuracy = Data.laser_data[laser_lv-1].accuracy * accuracy
		laser.position = position
		battle_scene.add_child(laser)
		laser.tree_exited.connect(ending_turn)
	elif weapon_type == battle_GUI.BOMB:
		var explosive = preload("res://Scenes/Battle/Weapons/Explosive.tscn").instantiate()
		explosive.collision_layer = 8
		explosive.collision_mask = 1 + 4 + 32
		explosive.set_script(load("res://Scripts/Battle/Weapons/Explosive.gd"))
		explosive.speed = 800.0
		explosive.AoE_radius = 100.0
		explosive.rotation = weapon_rotation
		explosive.damage = Data.bomb_data[bomb_lv-1].damage
		explosive.shooter_attack = attack + attack_buff
		explosive.weapon_accuracy = Data.bomb_data[bomb_lv-1].accuracy * accuracy
		explosive.position = position
		explosive.battle_GUI = battle_GUI
		explosive.ending_turn_delay = 1.0
		battle_scene.add_child(explosive)
		explosive.end_turn.connect(ending_turn)
	elif weapon_type == battle_GUI.LIGHT:
		light_cone.tree_exited.connect(ending_turn)
		light_cone.fire_light()


func add_light_cone():
	light_cone = preload("res://Scenes/Battle/Weapons/LightCone.tscn").instantiate()
	light_cone.set_script(load("res://Scripts/Battle/Weapons/LightCone.gd"))
	light_cone.target_angle_deviation = PI / 4.0
	light_cone.damage = Data.light_data[light_lv-1].damage
	light_cone.shooter_attack = attack + attack_buff
	add_child(light_cone)


func ending_turn(delay: float = 0.0):
	create_tween().tween_callback(end_turn).set_delay(delay)


func damage_entity(weapon_data: Dictionary):
	var hit = super(weapon_data)
	if hit:
		$Sprite2D.material.set_shader_parameter("flash_color", Color.RED)
		$Sprite2D.material.set_shader_parameter("flash", 1.0)
		create_tween().tween_property($Sprite2D.material, "shader_parameter/flash", 0.0, 0.4)
	return hit

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
	queue_redraw()
	get_node("RayCast2D").enabled = false
	battle_GUI.fade_in_main_panel()
	if is_instance_valid(entity_to_push):
		entity_to_push.update_velocity_arrow()
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
		var position_difference = position - entity.position
		var velocity_difference = velocity - entity.velocity
		var push_difficulty_from_velocity = abs(0.1 * position_difference.rotated(PI / 2.0).dot(velocity_difference))
		var push_success_chance = 100.0 * (1.0 - 1.0 / (1.0 + exp((agility + agility_buff - entity.agility - entity.agility_buff - push_difficulty_from_velocity + 9.2) / 5.8)))
		target_btn.get_node("TextureButton").mouse_entered.connect(game.show_adv_tooltip.bind(tr("PUSH_SUCCESS_CHANCE") + ": %.1f%%" % push_success_chance, {"additional_text":tr("PUSH_SUCCESS_CHANCE_HELP")}))
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
	if entity_to_push.type == battle_scene.ENEMY:
		push_success = push_entity_attempt(agility + agility_buff, entity_to_push.agility + entity_to_push.agility_buff, position - entity_to_push.position,  - entity_to_push.velocity)
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
	return (entity_to_push.position - position).normalized() * push_movement_used * 2.0 * remap(HP, 0.0, total_HP, HP * 0.66, total_HP) / remap(entity_to_push.HP, 0.0, entity_to_push.total_HP, entity_to_push.HP * 0.66, entity_to_push.total_HP)
	
func update_push_movement_used():
	battle_GUI.get_node("PushStrengthPanel/MovementUsed").text = "%.1f m" % push_movement_used
	entity_to_push.update_velocity_arrow(calculate_velocity_change())


func _on_push_effect_visibility_changed() -> void:
	$PushEffect.play("default")
