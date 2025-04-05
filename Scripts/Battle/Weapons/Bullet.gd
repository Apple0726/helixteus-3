extends Area2D

signal end_turn

static var amount:int = 0
var speed:float
# Contrary to `speed`, `velocity_process_modifier` does not affect the initial velocity of damage labels
# Only used for `animations_sped_up` variable in Battle.gd
var velocity_process_modifier:float = 1.0
var damage:float
var shooter_attack:int
var weapon_accuracy:float
var deflects_remaining:int
var ending_turn_delay:float
var mass:float # For now only used to determine knockback when something is defeated by this projectile (so purely aesthetic)

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	tree_exiting.connect(decrement_amount)
	amount += 1

func decrement_amount():
	amount -= 1
	if amount <= 0:
		emit_signal("end_turn", ending_turn_delay)

func _physics_process(delta: float) -> void:
	position += speed * Vector2.from_angle(rotation) * delta * velocity_process_modifier
	if (position - Vector2(640, 360)).length_squared() > pow(1280, 2) + pow(720, 2):
		ending_turn_delay = 0.0
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	var weapon_data = {
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
