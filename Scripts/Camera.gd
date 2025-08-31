extends Camera2D

var move_with_keyboard = true

func _process(delta: float) -> void:	
	if move_with_keyboard:
		var input_vector = Vector2.ZERO
		input_vector.x = Input.get_action_strength("D") - Input.get_action_strength("A")
		input_vector.y = Input.get_action_strength("S") - Input.get_action_strength("W")
		input_vector = input_vector.normalized()
		position += input_vector * delta * 1000.0 / zoom.x
