extends Control

var B = 1
var p = 0.3
var y_values = []
var star_class_masses = [0, 0.08, 0.45, 0.8, 1.04, 1.4, 2.1, 9, 100, 1000, 10000]
var star_classes = ["T", "M", "K", "G", "F", "A", "B", "O", "Q", "R", "Z"]
var mouse_pos:Vector2 = Vector2.ZERO

func _ready():
	set_process_input(false)
	add_points()

func _input(event):
	if event is InputEventMouseMotion:
		mouse_pos = event.position - global_position
		queue_redraw()
	
func _draw():
	var n = len(y_values)-1
	for i in range(n):
		draw_line(Vector2(i*size.x/n, -y_values[i]*size.y/abs(y_values.max())+size.y), Vector2((i+1)*size.x/n, -y_values[i+1]*size.y/abs(y_values.max())+size.y), Color.WHITE)
		draw_line(Vector2(i*size.x/n, -y_values[i]*size.y/abs(y_values.max())+size.y+1), Vector2((i+1)*size.x/n, -y_values[i+1]*size.y/abs(y_values.max())+size.y+1), Color.BLACK)
	if mouse_pos != Vector2.ZERO:
		var x_index_at_mouse = clamp(int(remap(mouse_pos.x, 0, size.x, 0, len(y_values))), 0, len(y_values)-1)
		var corresponding_y = -y_values[x_index_at_mouse]*size.y/abs(y_values.max())+size.y
		draw_line(Vector2(mouse_pos.x, size.y), Vector2(mouse_pos.x, corresponding_y), Color.WHITE)
		draw_line(Vector2(mouse_pos.x+1, size.y), Vector2(mouse_pos.x+1, corresponding_y), Color.BLACK)
		draw_line(Vector2(0, corresponding_y), Vector2(mouse_pos.x, corresponding_y), Color.WHITE)
		draw_line(Vector2(0, corresponding_y+1), Vector2(mouse_pos.x, corresponding_y+1), Color.BLACK)
		$Info.text = "Amount = " + str(Helper.clever_round(y_values[x_index_at_mouse], 3, true))
	else:
		$Info.text = ""

func add_points():
	y_values.clear()
	star_class_masses = [0, 0.08, 0.45, 0.8, 1.04, 1.4, 2.1, 9, 100, 1000, 10000]
	var _A = $HSlider.value * pow(1 / B, p)
	var st = ""
	for i in len(star_class_masses)-1:
		var step = (star_class_masses[i+1] - star_class_masses[i]) / 37.0
		for j in 37:
			y_values.append(integral(_A, j*step + star_class_masses[i], (j+1)*step + star_class_masses[i]))
		st += "%s: %.5f%%/" % [star_classes[i], 100 * integral(_A, star_class_masses[i], star_class_masses[i+1])]
	$Label2.text = st
	queue_redraw()


func integral(A, a, b):
	return -exp(-A*b) + exp(-A*a)


func _on_HSlider_value_changed(value):
	$Label.text = str(value)
	add_points()


func _on_p_value_changed(value):
	$pText.text = "p = " + str(value)
	add_points()


func _on_B_value_changed(value):
	$BText.text = "B = " + str(value)
	add_points()


func _on_BEnd_value_changed(value):
	$BEndText.text = "Bend = " + str(value)
	add_points()


func _on_Control_mouse_entered():
	set_process_input(true)


func _on_Control_mouse_exited():
	set_process_input(false)
