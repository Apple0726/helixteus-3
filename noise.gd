extends Sprite


func _input(event):
	if event is InputEventMouseMotion:
		var image = texture.get_data()
		image.lock()
		print(image.get_pixel(event.position.x, event.position.y))
