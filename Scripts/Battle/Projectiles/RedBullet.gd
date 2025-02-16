extends Area2D

var speed:float
var damage:float
var shooter_attack:int
var weapon_accuracy:float

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
		queue_free()
