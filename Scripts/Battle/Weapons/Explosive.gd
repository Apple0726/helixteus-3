extends "Projectile.gd"

var entities_inside_explosion_AoE:Array = []
var AoE_radius:float
var spawn_smaller_explosives = false

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
	if not is_instance_valid(shooter):
		queue_free()
		return
	var weapon_data = {
		"type":Battle.DamageType.PHYSICAL,
		"damage":damage,
		"shooter_attack":shooter.attack + shooter.attack_buff,
		"shooter_mass":shooter.get_mass(),
		"shooter_type":shooter.type,
		"shooter_velocity":shooter.velocity,
		"weapon_accuracy":weapon_accuracy,
		"orientation":Vector2.from_angle(rotation),
		"velocity":speed * Vector2.from_angle(rotation),
		"mass":mass,
		"status_effects":status_effects,
		"knockback":mass * Vector2.from_angle(rotation),
	}
	if area.damage_entity(weapon_data):
		if area.type == Battle.EntityType.BOUNDARY:
			ending_turn_delay = 0.0
			queue_free()
			return
		for area_in_AoE in entities_inside_explosion_AoE:
			if area_in_AoE is BattleEntity and area_in_AoE != area:
				var dist_from_point_blank = (area_in_AoE.position - position).length()
				var AoE_weapon_data = {
					"type":Battle.DamageType.EMG,
					"damage":damage * remap(dist_from_point_blank, 0.0, AoE_radius, 1.0, 0.2),
					"shooter_attack":shooter.attack + shooter.attack_buff,
					"shooter_type":shooter.type,
					"weapon_accuracy":INF,
					"velocity":200.0 * (area_in_AoE.position - position).normalized(),
					"status_effects":status_effects if shooter.type == Battle.EntityType.SHIP and shooter.bomb_levels[1] >= 2 else {},
				}
				area_in_AoE.damage_entity(AoE_weapon_data)
		if Settings.screen_shake:
			get_node("/root/Game/Camera2D/Screenshake").start(0.5,15,4)
		var explosion = preload("res://Scenes/Battle/Explosion.tscn").instantiate()
		battle_GUI.battle_scene.add_child(explosion)
		explosion.position = position
		explosion.rotation = randf_range(0.0, 2.0 * PI)
		explosion.scale = Vector2.ONE * AoE_radius / 128.0
		explosion.play("explosion")
		explosion.animation_finished.connect(explosion.queue_free)
		$AnimationPlayer.play("Explode")
		battle_GUI.flash_screen(0.3, 0.2)
		set_physics_process(false)
		$AnimationPlayer.animation_finished.connect(func(anim_name): queue_free())
		if spawn_smaller_explosives:
			for i in 8:
				var explosive = preload("res://Scenes/Battle/Weapons/Explosive.tscn").instantiate()
				explosive.collision_layer = 8
				explosive.collision_mask = 1 + 4 + 32
				explosive.set_script(load("res://Scripts/Battle/Weapons/Explosive.gd"))
				explosive.speed = 800.0
				explosive.velocity_process_modifier = 5.0 if battle_scene.animations_sped_up else 1.0
				explosive.damage = 0.3 * Data.battle_weapon_stats.bomb.damage * Data.battle_weapon_stats.bomb.damage_multiplier[shooter.bomb_levels[0] - 1]
				explosive.AoE_radius = 0.5 * Data.battle_weapon_stats.bomb.AoE_radius[shooter.bomb_levels[0] - 1]
				explosive.mass = 0.5 * Data.battle_weapon_stats.bomb.mass[shooter.bomb_levels[0] - 1]
				explosive.rotation = rotation + (i + 0.5) / 8.0 * 2.0 * PI
				explosive.shooter = shooter
				explosive.weapon_accuracy = Data.battle_weapon_stats.bomb.accuracy * (shooter.accuracy + shooter.accuracy_buff)
				explosive.status_effects = {Battle.StatusEffect.BURN: 0.5 * Data.battle_weapon_stats.bomb.status_effects[Battle.StatusEffect.BURN][shooter.bomb_levels[1] - 1]}
				explosive.position = position + 50.0 * Vector2.from_angle(explosive.rotation)
				explosive.battle_scene = battle_scene
				explosive.battle_GUI = battle_GUI
				explosive.ending_turn_delay = 1.0
				explosive.end_turn.connect(shooter.ending_turn)
				explosive.end_turn_ready = true
				battle_scene.call_deferred("add_child", explosive)
