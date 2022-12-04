extends Node

func _ready():
	var label = Label.new()
	label.name = "Label"
	add_child(label)
	label["custom_colors/font_color"] = Color.white
	label["custom_colors/font_color_shadow"] = Color.black

func get_pos_from_TP(T:float, P:float):
	return Vector2(T / 1000.0 * 800, -(log(P) / log(10)) * 400 / 12.0 + 200)

func place(T:float, P:float, node):
	node.position = get_pos_from_TP(T, P)

func modify_PD(new_points:PoolVector2Array):
	$Liquid.polygon = new_points
	var default_dP = $Superfluid.polygon[1].y - $Superfluid.polygon[2].y
	var default_dT = $Gas.polygon[1].x - $Gas.polygon[0].x
	$Gas.polygon[1] = $Liquid.polygon[0]
	$Gas.polygon[0].x = max($Liquid.polygon[0].x - default_dT, 0)
	$Superfluid.polygon[1] = $Liquid.polygon[2]
	$Superfluid.polygon[2].y = max($Liquid.polygon[2].y - default_dP, 0)
	$Superfluid.polygon[0] = $Liquid.polygon[3]
	$Superfluid.polygon[3].y = $Liquid.polygon[3].y
	$Gas.polygon[2] = $Liquid.polygon[3]
	$Gas.polygon[3].y = $Liquid.polygon[3].y

func _input(event):
	if event is InputEventMouseMotion:
		$Label.rect_position = event.position
		var state:String = ""
		if Geometry.is_point_in_polygon(event.position, $Superfluid.polygon):
			state = "sc"
		elif Geometry.is_point_in_polygon(event.position, $Liquid.polygon):
			state = "l"
		elif Geometry.is_point_in_polygon(event.position, $Gas.polygon):
			state = "g"
		elif Geometry.is_point_in_polygon(event.position, $Solid.polygon):
			state = "s"
		$Label.text = "T: %s K\nP: %s bar\nState: %s" % [1000 * event.position.x / 800, pow(10, -12.0 * (event.position.y - 200)/400.0), state]
