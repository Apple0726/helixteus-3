extends Node

func _ready():
	var label = Label.new()
	label.name = "Label"
	add_child(label)
	label["custom_colors/font_color"] = Color.white
	label["custom_colors/font_color_shadow"] = Color.black

func get_pos_from_TP(T:float, P:float):
	return Vector2(T / 1000.0 * 1109, -(log(P) / log(10)) * 576 / 12.0 + 290)

func place(T:float, P:float, node):
	node.position = get_pos_from_TP(T, P)

func _input(event):
	if event is InputEventMouseMotion:
		$Label.rect_position = event.position
		var state:String = ""
		if Geometry.is_point_in_polygon(event.position, $Superfluid.polygon):
			state = "SC"
		elif Geometry.is_point_in_polygon(event.position, $Liquid.polygon):
			state = "L"
		elif Geometry.is_point_in_polygon(event.position, $Gas.polygon):
			state = "G"
		elif Geometry.is_point_in_polygon(event.position, $Solid.polygon):
			state = "S"
		$Label.text = "T: %s K\nP: %s bar\nState: %s" % [1000 * event.position.x / 1109, pow(10, -12.0 * (event.position.y - 290)/576.0), state]
