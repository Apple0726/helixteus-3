extends "Projectile.gd"

var deflects_remaining:int
var ignore_defense_buffs = false

func _ready() -> void:
	super()
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	var weapon_data = {
		"type":Battle.DamageType.PHYSICAL,
		"damage":damage,
		"shooter_attack":shooter.attack + shooter.attack_buff,
		"weapon_accuracy":weapon_accuracy,
		"orientation":Vector2.from_angle(rotation),
		"velocity":speed * Vector2.from_angle(rotation),
		"mass":mass,
	}
	if crit_hit_mult != 1.0:
		weapon_data.crit_hit_mult = crit_hit_mult
	if knockback > 0.0:
		weapon_data.knockback = knockback * Vector2.from_angle(rotation)
	if ignore_defense_buffs:
		weapon_data.ignore_defense_buffs = true
	if not status_effects.is_empty():
		weapon_data.status_effects = status_effects
	if area.damage_entity(weapon_data):
		if deflects_remaining == 0 or area.type == Battle.EntityType.BOUNDARY:
			if area.type == Battle.EntityType.BOUNDARY:
				ending_turn_delay = 0.0
			queue_free()
		else:
			# The bullet can now hit anything, regardless of the shooter
			collision_mask = 1 + 2 + 4 + 32
			# Unless the shooter is a ship and has the necessary upgrade
			if shooter.type == Battle.EntityType.SHIP and shooter.bullet_levels[2] >= 3:
				collision_mask = 1 + 4 + 32
			var incidence_angle = atan2(position.y - area.position.y, position.x - area.position.x)
			rotation = Vector2.from_angle(rotation).bounce(Vector2.from_angle(incidence_angle)).angle()
			deflects_remaining -= 1
		if area.type != Battle.EntityType.BOUNDARY and area.HP <= 0 and shooter.type == Battle.EntityType.SHIP and shooter.ship_class == ShipClass.OFFENSIVE:
			shooter.buff_from_class_passive_ability("attack", 3)
	else:
		if shooter.type == Battle.EntityType.SHIP and shooter.ship_class == ShipClass.ACCURATE:
			shooter.buff_from_class_passive_ability("accuracy", 3)
