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


func _ready() -> void:
	super()
	movement_remaining = (agility + agility_buff) * METERS_PER_AGILITY
	total_movement = (agility + agility_buff) * METERS_PER_AGILITY
	go_through_movement_cost = 30.0
	update_default_tooltip_text()

func _draw() -> void:
	if display_move_path:
		$RayCast2D.clear_exceptions()
		move_additional_costs = 0.0
		var target_line_vector = battle_scene.mouse_position_local - position
		$RayCast2D.target_position = movement_remaining * battle_scene.PIXELS_PER_METER * target_line_vector.normalized()
		var ray_movement_remaining = movement_remaining
		while true:
			$RayCast2D.force_raycast_update()
			var hit_target = $RayCast2D.get_collider()
			if hit_target is BattleEntity:
				var hit_point = to_local($RayCast2D.get_collision_point())
				var diff_length = ($RayCast2D.target_position - hit_point).length() / battle_scene.PIXELS_PER_METER
				if diff_length > hit_target.go_through_movement_cost:
					move_additional_costs += hit_target.go_through_movement_cost
					ray_movement_remaining = max(ray_movement_remaining - hit_target.go_through_movement_cost, 0.0)
				else:
					move_additional_costs += diff_length
					ray_movement_remaining = max(ray_movement_remaining - diff_length, 0.0)
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
		draw_string(SystemFont.new(), line_vector + 20.0 * Vector2.ONE, "%.1f m" % (move_distance_px / battle_scene.PIXELS_PER_METER))

func move():
	display_move_path = false
	queue_redraw()
	var move_tween = create_tween()
	movement_remaining -= (move_target_position - position).length() / battle_scene.PIXELS_PER_METER
	movement_remaining -= move_additional_costs
	print(move_additional_costs)
	move_tween.tween_property(self, "position", move_target_position, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	move_tween.tween_callback(cancel_action)

func update_default_tooltip_text():
	default_tooltip_text = "@i \t%s / %s" % [HP, total_HP]
	default_tooltip_text += "\n@i \t%s" % attack
	if attack_buff > 0:
		default_tooltip_text += " + " + str(attack_buff) + " = " + str(attack + attack_buff)
	elif attack_buff < 0:
		default_tooltip_text += " - " + str(abs(attack_buff)) + " = " + str(attack + attack_buff)
	default_tooltip_text += "\n@i \t%s" % defense
	if defense_buff > 0:
		default_tooltip_text += " + " + str(defense_buff) + " = " + str(defense + defense_buff)
	elif defense_buff < 0:
		default_tooltip_text += " - " + str(abs(defense_buff)) + " = " + str(defense + defense_buff)
	default_tooltip_text += "\n@i \t%s" % accuracy
	if accuracy_buff > 0:
		default_tooltip_text += " + " + str(accuracy_buff) + " = " + str(accuracy + accuracy_buff)
	elif accuracy_buff < 0:
		default_tooltip_text += " - " + str(abs(accuracy_buff)) + " = " + str(accuracy + accuracy_buff)
	default_tooltip_text += "\n@i \t%s" % agility
	if agility_buff > 0:
		default_tooltip_text += " + " + str(agility_buff) + " = " + str(agility + agility_buff)
	elif agility_buff < 0:
		default_tooltip_text += " - " + str(abs(agility_buff)) + " = " + str(agility + agility_buff)

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
	if override_tooltip_text:
		game.show_tooltip(override_tooltip_text)
	else:
		game.show_adv_tooltip(default_tooltip_text, [Data.HP_icon, Data.attack_icon, Data.defense_icon, Data.accuracy_icon, Data.agility_icon])


func _on_mouse_exited() -> void:
	game.hide_tooltip()

func fire_weapon(weapon_type: int):
	$FireWeaponAim.fade_out()
	var weapon_rotation = randf_range($FireWeaponAim.target_angle - $FireWeaponAim.target_angle_max_deviation, $FireWeaponAim.target_angle + $FireWeaponAim.target_angle_max_deviation)
	if weapon_type == battle_GUI.BULLET:
		for i in 2:
			var projectile = preload("res://Scenes/Battle/Weapons/Projectile.tscn").instantiate()
			projectile.collision_layer = 8
			projectile.collision_mask = 1 + 4
			projectile.set_script(load("res://Scripts/Battle/Weapons/Bullet.gd"))
			projectile.speed = 1000.0
			projectile.rotation = weapon_rotation
			projectile.damage = Data.bullet_data[bullet_lv-1].damage
			projectile.shooter_attack = attack + attack_buff
			projectile.weapon_accuracy = Data.bullet_data[bullet_lv-1].accuracy * accuracy
			projectile.deflects_remaining = bullet_lv
			projectile.position = position
			battle_scene.add_child(projectile)
			if i == 1:
				projectile.tree_exited.connect(ending_turn)
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
		explosive.collision_mask = 1 + 3
		explosive.set_script(load("res://Scripts/Battle/Weapons/Explosive.gd"))
		explosive.speed = 800.0
		explosive.AoE_radius = 100.0
		explosive.rotation = weapon_rotation
		explosive.damage = Data.bomb_data[bomb_lv-1].damage
		explosive.shooter_attack = attack + attack_buff
		explosive.weapon_accuracy = Data.bomb_data[bomb_lv-1].accuracy * accuracy
		explosive.position = position
		battle_scene.add_child(explosive)
		explosive.tree_exited.connect(ending_turn)
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


func ending_turn():
	create_tween().tween_callback(end_turn).set_delay(1.0)


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
	display_move_path = false
	get_node("RayCast2D").enabled = false
	battle_GUI.fade_in_main_panel()
