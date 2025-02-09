extends Area2D

var speed:float
var damage:float
var projectile_accuracy:float

func _process(delta: float) -> void:
	position += speed * Vector2.from_angle(rotation) * delta


func _on_area_entered(area: Area2D) -> void:
	if area.damage_entity(damage, projectile_accuracy, 0.3 * speed * Vector2.from_angle(rotation)):
		queue_free()
