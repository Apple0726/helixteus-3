extends Area2D

signal end_turn

static var amount:int = 0
var speed:float
var damage:float
var shooter_attack:int
var weapon_accuracy:float
var deflects_remaining:int
var ending_turn_delay:float

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	tree_exiting.connect(decrement_amount)
	amount += 1

func decrement_amount():
	amount -= 1
	if amount <= 0:
		emit_signal("end_turn", ending_turn_delay)

func _process(delta: float) -> void:
	position += speed * Vector2.from_angle(rotation) * delta
	if (position - Vector2(640, 360)).length_squared() > pow(1280, 2) + pow(720, 2):
		ending_turn_delay = 0.0
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	var weapon_data = {
		"damage":damage,
		"shooter_attack":shooter_attack,
		"weapon_accuracy":weapon_accuracy,
		"orientation":Vector2.from_angle(rotation),
		"damage_label_initial_velocity":0.3 * speed * Vector2.from_angle(rotation),
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
