extends "BattleEntity.gd"

@export var texture:Texture2D

var movement_remaining:float
var total_movement:float

func _ready():
	$Sprite2D.texture = texture

func damage_entity(weapon_data: Dictionary):
	var dodged = 1.0 / (1.0 + exp((weapon_data.weapon_accuracy - agility - agility_buff + 3.7) / 4.3)) > randf()
	if dodged:
		battle_scene.add_damage_text(true, position)
	else:
		var damage_multiplier:float
		var attack_defense_difference:int = weapon_data.shooter_attack - defense - defense_buff
		if attack_defense_difference >= 0:
			damage_multiplier = attack_defense_difference * 0.125 + 1
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
