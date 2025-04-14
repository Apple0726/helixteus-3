extends "Projectile.gd"

var deflects_remaining:int

func _ready() -> void:
	super()
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	var weapon_data = {
		"type":Battle.DamageType.PHYSICAL,
		"damage":damage,
		"shooter_attack":shooter_attack,
		"weapon_accuracy":weapon_accuracy,
		"orientation":Vector2.from_angle(rotation),
		"velocity":speed * Vector2.from_angle(rotation),
		"mass":mass,
	}
	if area.damage_entity(weapon_data):
		if deflects_remaining == 0 or area.type == 2:
			if area.type == 2: # If it is a boundary
				ending_turn_delay = 0.0
			queue_free()
		else:
			# The bullet can now hit anything, regardless of the shooter
			collision_mask = 1 + 2 + 4 + 32
			var incidence_angle = atan2(position.y - area.position.y, position.x - area.position.x)
			rotation = Vector2.from_angle(rotation).bounce(Vector2.from_angle(incidence_angle)).angle()
			deflects_remaining -= 1
