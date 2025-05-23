extends Node2D

var shooter:BattleEntity
var damage:float
var weapon_accuracy:int
var fade_delay:float

func _ready() -> void:
	$RayCast2D.target_position.x = 5000.0
	var laser_absorbed = false
	var laser_length:float = 200.0
	while not laser_absorbed:
		$RayCast2D.force_raycast_update()
		var hit_target = $RayCast2D.get_collider()
		var hit_point = to_local($RayCast2D.get_collision_point())
		if hit_target is BattleEntity:
			var weapon_data = {
				"type":Battle.DamageType.EMG,
				"damage":damage,
				"shooter_attack":shooter.attack + shooter.attack_buff,
				"weapon_accuracy":weapon_accuracy,
				"orientation":Vector2.from_angle(rotation),
				"velocity":100.0 * Vector2.from_angle(rotation),
				"status_effects":{Battle.StatusEffect.STUN: 2 if shooter.laser_levels[1] >= 3 else 1},
			}
			if hit_target.damage_entity(weapon_data):
				laser_absorbed = true
				laser_length = hit_point.length()
			$RayCast2D.add_exception(hit_target)
		else:
			laser_absorbed = true
	$ColorLaser.scale.x = laser_length / 200.0
	$WhiteLaser.scale.x = laser_length / 200.0
	var tween = create_tween().set_parallel()
	tween.tween_property($WhiteLaser, "modulate:a", 0.0, fade_delay)
	tween.tween_property($ColorLaser.material, "shader_parameter/modulate", 0.0, fade_delay)
	tween.tween_callback(queue_free).set_delay(fade_delay)
