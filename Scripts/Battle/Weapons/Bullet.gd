extends Area2D

var speed:float
var damage:float
var shooter_attack:int
var weapon_accuracy:float
var deflects_remaining:int

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	position += speed * Vector2.from_angle(rotation) * delta
	if (position - Vector2(640, 360)).length_squared() > pow(1280, 2) + pow(720, 2):
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	var weapon_data = {
		"damage":damage,
		"shooter_attack":shooter_attack,
		"weapon_accuracy":weapon_accuracy,
		"damage_label_initial_velocity":0.3 * speed * Vector2.from_angle(rotation),
	}
	if area.damage_entity(weapon_data):
		if deflects_remaining == 0:
			queue_free()
		else:
			# The bullet can now hit anything, regardless of the shooter
			collision_layer = 4 + 8
			var incidence_angle = atan2(position.y - area.position.y, position.x - area.position.x)
			rotation = Vector2.from_angle(rotation).bounce(Vector2.from_angle(incidence_angle)).angle()
			deflects_remaining -= 1
