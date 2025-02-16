extends "BattleEntity.gd"

var movement_remaining:float
var total_movement:float
var bullet_lv:int
var laser_lv:int
var bomb_lv:int
var light_lv:int
var weapon_accuracy_mult:float


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
		$FireWeaponAim.target_angle_max_deviation = 1.0 / (accuracy + accuracy_buff) / weapon_accuracy_mult
		$FireWeaponAim.animate(false)

func override_enemy_tooltips():
	if battle_GUI.action_selected == battle_GUI.BULLET:
		weapon_accuracy_mult = Data.bullet_data[bullet_lv-1].accuracy
	elif battle_GUI.action_selected == battle_GUI.LASER:
		weapon_accuracy_mult = Data.laser_data[laser_lv-1].accuracy
	elif battle_GUI.action_selected == battle_GUI.BOMB:
		weapon_accuracy_mult = Data.bomb_data[bomb_lv-1].accuracy
	elif battle_GUI.action_selected == battle_GUI.LIGHT:
		weapon_accuracy_mult = Data.light_data[light_lv-1].accuracy
	for HX_node in battle_scene.HX_nodes:
		var damage_multiplier:float
		var attack_defense_difference:int = attack + attack_buff - HX_node.defense - HX_node.defense_buff
		if attack_defense_difference >= 0:
			damage_multiplier = attack_defense_difference * 0.125 + 1.0
		else:
			damage_multiplier = 1.0 / (1.0 - 0.125 * attack_defense_difference)
		var tooltip_txt = tr("DAMAGE_MULTIPLIER") + ": " + "%.2f" % damage_multiplier
		tooltip_txt += "\n" + tr("CHANCE_OF_HITTING") + ": " + "%.1f%%" % (100.0 * (1.0 - 1.0 / (1.0 + exp(((accuracy + accuracy_buff) * weapon_accuracy_mult - HX_node.agility - HX_node.agility_buff + 3.7) / 4.3))))
		HX_node.override_tooltip_text = tooltip_txt

func restore_default_enemy_tooltips():
	for HX_node in battle_scene.HX_nodes:
		HX_node.override_tooltip_text = ""


func _on_mouse_entered() -> void:
	if override_tooltip_text:
		game.show_tooltip(override_tooltip_text)
	else:
		game.show_adv_tooltip(default_tooltip_text, [Data.HP_icon, Data.attack_icon, Data.defense_icon, Data.accuracy_icon, Data.agility_icon])


func _on_mouse_exited() -> void:
	game.hide_tooltip()
