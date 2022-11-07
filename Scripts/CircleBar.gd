extends Sprite

var progress = 0.0

func _draw():
	draw_arc(Vector2.ZERO, 64, -PI/2, progress / 100.0 * 2 * PI-PI/2, 64, Color.green, 5)
