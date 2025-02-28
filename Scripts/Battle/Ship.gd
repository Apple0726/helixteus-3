extends "BattleEntity.gd"

var movement_remaining:float
var total_movement:float
var bullet_lv:int
var laser_lv:int
var bomb_lv:int
var light_lv:int
var weapon_accuracy_mult:float
var light_cone


func _ready() -> void:
	super()
	update_default_tooltip_text()


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
			projectile.collision_mask = 1 + 3
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
