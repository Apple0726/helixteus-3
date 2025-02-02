extends Area2D

var fade_speed:float

func _process(delta):
	scale += Vector2.ONE * delta * 5.0
	modulate.a -= fade_speed * delta
	if modulate.a <= 0.0:
		set_process(false)
		queue_free()


func _on_area_entered(area):
	area.get_parent().hit(1)
