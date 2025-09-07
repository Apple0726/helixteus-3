extends "Projectile.gd"

var entities_inside_explosion_AoE:Array = []
var AoE_radius:float

func _ready() -> void:
	super()
	$ExplosionAoE/CollisionShape2D.shape.radius = AoE_radius
	area_entered.connect(_on_area_entered)
	$ExplosionAoE.area_entered.connect(_on_explosionAoE_entered)
	$ExplosionAoE.area_exited.connect(_on_explosionAoE_exited)

func decrement_amount():
	amount -= 1
	if amount <= 0:
		emit_signal("end_turn", ending_turn_delay)

func _on_explosionAoE_entered(area: Area2D):
	entities_inside_explosion_AoE.append(area)

func _on_explosionAoE_exited(area: Area2D):
	entities_inside_explosion_AoE.erase(area)


func _on_area_entered(area: Area2D) -> void:
	var weapon_data = {
		"type":Battle.DamageType.PHYSICAL,
		"damage":damage,
		"shooter_attack":shooter.attack + shooter.attack_buff,
		"weapon_accuracy":weapon_accuracy,
		"orientation":Vector2.from_angle(rotation),
		"velocity":speed * Vector2.from_angle(rotation),
		"mass":mass,
		"status_effects":{Battle.StatusEffect.BURN: 1},
		"knockback":knockback * Vector2.from_angle(rotation),
	}
	if shooter.type == Battle.EntityType.SHIP:
		if shooter.bomb_levels[1] >= 2:
			weapon_data.status_effects[Battle.StatusEffect.BURN] = 2
	if area.damage_entity(weapon_data):
		if area.type == Battle.EntityType.BOUNDARY:
			ending_turn_delay = 0.0
			queue_free()
			return
		for area_in_AoE in entities_inside_explosion_AoE:
			if area_in_AoE is BattleEntity and area_in_AoE != area:
				var dist_from_point_blank = (area_in_AoE.position - position).length()
				var AoE_weapon_data = {
					"type":Battle.DamageType.PHYSICAL,
					"damage":damage * remap(dist_from_point_blank, 0.0, AoE_radius, 1.0, 0.2),
					"shooter_attack":shooter.attack + shooter.attack_buff,
					"weapon_accuracy":INF,
					"velocity":200.0 * (area_in_AoE.position - position).normalized(),
					"knockback":30.0 * (area_in_AoE.position - position).normalized(),
					"status_effects":{},
				}
				if shooter.type == Battle.EntityType.SHIP:
					if shooter.bomb_levels[0] >= 4:
						AoE_weapon_data.status_effects[Battle.StatusEffect.STUN] = 1
					if shooter.bomb_levels[1] >= 2:
						AoE_weapon_data.status_effects[Battle.StatusEffect.BURN] = 2
				area_in_AoE.damage_entity(AoE_weapon_data)
		if Settings.screen_shake:
			get_node("/root/Game/Camera2D/Screenshake").start(0.5,15,4)
		var explosion = preload("res://Scenes/Battle/Explosion.tscn").instantiate()
		add_child(explosion)
		explosion.rotation = randf_range(0.0, 2.0 * PI)
		explosion.scale = Vector2.ONE * AoE_radius / 128.0
		$AnimationPlayer.play("Explode")
		battle_GUI.flash_screen(0.3, 0.2)
		set_physics_process(false)
		$AnimationPlayer.animation_finished.connect(func(anim_name): queue_free())
