extends "BattleEntity.gd"

@export var texture:Texture2D

var movement_remaining:float
var total_movement:float

func _ready():
	$Sprite2D.texture = texture

func damage_entity(base_damage: float, enemy_accuracy: float, damage_label_initial_velocity:Vector2 = Vector2.ZERO):
	var dodged = 1.0 / (1.0 + exp((enemy_accuracy - agility - agility_buff + 3.7) / 4.3)) > randf()
	if dodged:
		battle_scene.add_damage_text(true, position)
	else:
		var actual_damage:int = max(1, base_damage - (defense + defense_buff) / 1.5)
		var critical = randf() < 0.005 * enemy_accuracy
		if critical:
			actual_damage *= 2
		HP -= actual_damage
		battle_scene.add_damage_text(false, position, actual_damage, critical, damage_label_initial_velocity)
		$Sprite2D.material.set_shader_parameter("hurt_flash", 0.5)
		create_tween().tween_property($Sprite2D.material, "shader_parameter/hurt_flash", 0.0, 0.4)
	return not dodged
