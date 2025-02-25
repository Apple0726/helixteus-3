extends Node2D

var damage:float
var shooter_attack:int
var weapon_accuracy:int

func _ready() -> void:
	$RayCast2D.target_position.x = 5000.0
	$RayCast2D.force_raycast_update()
	var hit_target = $RayCast2D.get_collider()
	var hit_point = to_local($RayCast2D.get_collision_point())
	var laser_length:float = 200.0
	if hit_target is BattleEntity:
		var weapon_data = {
			"damage":damage,
			"shooter_attack":shooter_attack,
			"weapon_accuracy":weapon_accuracy,
			"damage_label_initial_velocity":100.0 * Vector2.from_angle(rotation),
		}
		hit_target.damage_entity(weapon_data)
		laser_length = hit_point.length()
	$ColorLaser.scale.x = laser_length / 200.0
	$WhiteLaser.scale.x = laser_length / 200.0
	$AnimationPlayer.play("FadeOut")
