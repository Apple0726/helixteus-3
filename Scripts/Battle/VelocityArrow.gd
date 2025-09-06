extends Node2D

func resize_arrow(length: float):
	if length < 32.0:
		move_points(32.0)
		scale = Vector2.ONE * length / 32.0
	else:
		scale = Vector2.ONE
		move_points(length)

func move_points(x_pos: float):
	var points = $Polygon2D.polygon
	points[1].x = x_pos - 8.0
	points[2].x = x_pos - 12.0
	points[3].x = x_pos
	points[4].x = x_pos - 12.0
	points[5].x = x_pos - 8.0
	$Polygon2D.polygon = points
