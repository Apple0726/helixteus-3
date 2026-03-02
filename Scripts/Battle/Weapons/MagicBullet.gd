extends "Projectile.gd"


func _ready() -> void:
	super()
	area_entered.connect(_on_area_entered)
	$Trail.default_color = trail_color
	$Trail.show()

func _on_area_entered(area: Area2D) -> void:
	if check_boundary(area):
		return
	var weapon_data = {
		"type":Battle.DamageType.PHYSICAL,
		"damage":damage,
		"shooter":shooter,
		"weapon_accuracy":weapon_accuracy,
		"orientation":Vector2.from_angle(rotation),
		"velocity":speed * Vector2.from_angle(rotation),
		"mass":mass,
	}
	if crit_hit_mult != 1.0:
		weapon_data.crit_hit_mult = crit_hit_mult
	if knockback > 0.0:
		weapon_data.knockback = knockback * Vector2.from_angle(rotation)
	if not status_effects.is_empty():
		weapon_data.status_effects = status_effects
	if area.damage_entity(weapon_data):
		if area.HP <= 0 and shooter.type == Battle.EntityType.SHIP and shooter.ship_class == ShipClass.OFFENSIVE:
			shooter.buff_from_class_passive_ability("attack", 3)
	else:
		if shooter.type == Battle.EntityType.SHIP and shooter.ship_class == ShipClass.ACCURATE:
			shooter.buff_from_class_passive_ability("accuracy", 3)
