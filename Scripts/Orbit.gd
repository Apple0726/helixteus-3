extends Node2D

var radius:float
var alpha:float

func _draw():
	draw_arc(Vector2.ZERO, radius, 0, 2*PI, 100, Color(1, 1, 0, alpha), -1.0)
