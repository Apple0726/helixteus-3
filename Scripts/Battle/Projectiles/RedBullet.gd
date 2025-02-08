extends Area2D

var speed:float
var damage:float

func _process(delta: float) -> void:
	position += speed * Vector2.from_angle(rotation) * delta


func _on_area_entered(area: Area2D) -> void:
	area.do_damage(damage)
	queue_free()
