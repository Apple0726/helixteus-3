extends "BattleEntity.gd"

var movement_remaining:float
var total_movement:float
var bullet_lv:int
var laser_lv:int
var bomb_lv:int
var light_lv:int

func initialize_stats(data:Dictionary):
	super(data)
	bullet_lv = data.bullet.lv
	laser_lv = data.laser.lv
	bomb_lv = data.bomb.lv
	light_lv = data.light.lv

func damage_entity(weapon_data: Dictionary):
	var dodged = 1.0 / (1.0 + exp((weapon_data.weapon_accuracy - agility - agility_buff + 3.7) / 4.3)) > randf()
	if dodged:
		battle_scene.add_damage_text(true, position)
	else:
		var damage_multiplier:float
		var attack_defense_difference:int = weapon_data.shooter_attack - defense - defense_buff
		if attack_defense_difference >= 0:
			damage_multiplier = attack_defense_difference * 0.125 + 1.0
		else:
			damage_multiplier = 1.0 / (1.0 - 0.125 * attack_defense_difference)
		var actual_damage:int = max(1, weapon_data.damage * damage_multiplier)
		var critical = randf() < 0.005 * weapon_data.weapon_accuracy
		if critical:
			actual_damage *= 2
		HP -= actual_damage
		battle_scene.add_damage_text(false, position, actual_damage, critical, weapon_data.damage_label_initial_velocity)
		$Sprite2D.material.set_shader_parameter("hurt_flash", 0.5)
		create_tween().tween_property($Sprite2D.material, "shader_parameter/hurt_flash", 0.0, 0.4)
	return not dodged


func _process(delta: float) -> void:
	$FireWeaponAim.target_angle = atan2(battle_scene.mouse_position.y - position.y, battle_scene.mouse_position.x - position.x)
	$FireWeaponAim.length = (battle_scene.mouse_position - position).length()


func _on_fire_weapon_aim_visibility_changed() -> void:
	if $FireWeaponAim.visible:
		var accuracy_mult:float
		if battle_GUI.action_selected == battle_GUI.BULLET:
			accuracy_mult = Data.bullet_data[bullet_lv-1].accuracy
		elif battle_GUI.action_selected == battle_GUI.LASER:
			accuracy_mult = Data.laser_data[laser_lv-1].accuracy
		elif battle_GUI.action_selected == battle_GUI.BOMB:
			accuracy_mult = Data.bomb_data[bomb_lv-1].accuracy
		$FireWeaponAim.target_angle_max_deviation = 1.0 / (accuracy + accuracy_buff) / accuracy_mult
		$FireWeaponAim.animate(false)
