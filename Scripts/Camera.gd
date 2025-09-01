extends Camera2D

@onready var half_size := Vector2(get_viewport().size) / 2.0

var move_with_keyboard = true
var zoom_target: Vector2
var zoom_start: float
var zoom_start_position: Vector2
var zoom_tween: Tween

func _process(delta: float) -> void:	
	if move_with_keyboard:
		var input_vector = Vector2.ZERO
		input_vector.x = Input.get_action_strength("D") - Input.get_action_strength("A")
		input_vector.y = Input.get_action_strength("S") - Input.get_action_strength("W")
		input_vector = input_vector.normalized()
		position += input_vector * delta * 1000.0 / zoom.x

# From https://forum.godotengine.org/t/camera2d-zoom-position-towards-the-mouse/28757/7
func zoom_towards(new_zoom: float, mouse_pos: Vector2):
	zoom_start = zoom.x
	zoom_start_position = position
	zoom_target = mouse_pos
	if zoom_tween:
		zoom_tween.kill()
	zoom_tween = create_tween()
	zoom_tween.tween_method(zoom_towards_val, zoom_start, new_zoom, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)

func zoom_towards_val(z: float) -> void:
	zoom = Vector2.ONE * z
	position = zoom_start_position + (-half_size + zoom_target) * (z - zoom_start) / (zoom_start * z)
