extends "Panel.gd"

var el:String = ""
var bonuses:Dictionary = {}
var op_points:Dictionary = {}
var default_l:PackedVector2Array = []
var default_g:PackedVector2Array = []
var default_sc:PackedVector2Array = []
var default_dP = 0.0
var default_dT = 0.0
var error = false
var state_moused_over = ""
var point_colors = [Color.VIOLET, Color.RED, Color.GREEN, Color.BLUE]
var editable = false

func _ready():
	set_process_input(false)
	set_polygon(size)

func calc_OP_points():
	for el in Data.lake_bonus_values.keys():
		var default = load("res://Scenes/PhaseDiagrams/%s.tscn" % el).instantiate().get_node("Liquid").polygon
		if game.chemistry_bonus.has(el):
			if not bonuses.has(el):
				bonuses[el] = game.chemistry_bonus[el]
			op_points[el] = 0.0
			for i in 4:
				op_points[el] += abs(default[i].x - bonuses[el][i].x) / 150.0
				op_points[el] += abs(default[i].y - bonuses[el][i].y) / 50.0
		else:
			bonuses[el] = default
			op_points[el] = 0.0

func refresh():
	calc_OP_points()
	for pt in get_tree().get_nodes_in_group("PD_points"):
		pt.queue_free()
	$Title.text = "%s (%s)" % [tr("PHASE_DIAGRAM_EDITOR"), tr(el.to_upper() + "_NAME")]
	default_l = load("res://Scenes/PhaseDiagrams/%s.tscn" % el).instantiate().get_node("Liquid").polygon
	default_g = load("res://Scenes/PhaseDiagrams/%s.tscn" % el).instantiate().get_node("Gas").polygon
	default_sc = load("res://Scenes/PhaseDiagrams/%s.tscn" % el).instantiate().get_node("Superfluid").polygon
	default_dP = default_sc[1].y - default_sc[2].y
	default_dT = default_g[1].x - default_g[0].x
	$Liquid.polygon = bonuses[el]
	$Liquid.modulate = Data.lake_colors[el].l
	$Gas.polygon = default_g
	$Gas.modulate = Data.lake_colors[el].s
	$Solid.modulate = Data.lake_colors[el].s
	$Supercritical.polygon = default_sc
	for i in 4:
		var pt_default = TextureRect.new()
		pt_default.texture = preload("res://Graphics/Icons/Circle.png")
		pt_default.expand = true
		pt_default.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		pt_default.size = Vector2(8, 8)
		pt_default.position = default_l[i] + $Liquid.position - Vector2(4, 4)
		pt_default.add_to_group("PD_points")
		pt_default.modulate = point_colors[i].darkened(0.3)
		add_child(pt_default)
	for i in 4:
		var pt = TextureButton.new()
		pt.texture_normal = preload("res://Graphics/Icons/Circle.png")
		pt.expand = true
		pt.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		pt.size = Vector2(16, 16)
		if editable:
			pt.connect("button_down",Callable(self,"on_drag_start").bind(pt, i))
			pt.connect("button_up",Callable(self,"on_drag_end"))
		pt.position = $Liquid.polygon[i] + $Liquid.position - Vector2(8, 8)
		pt.add_to_group("PD_points")
		pt.modulate = point_colors[i]
		add_child(pt)
	$Gas.polygon[1] = $Liquid.polygon[0]
	$Gas.polygon[0].x = max($Liquid.polygon[0].x - default_dT, 0)
	$Supercritical.polygon[1] = $Liquid.polygon[2]
	$Supercritical.polygon[2].y = max($Liquid.polygon[2].y - default_dP, 0)
	$Supercritical.polygon[0] = $Liquid.polygon[3]
	$Supercritical.polygon[3].y = $Liquid.polygon[3].y
	$Gas.polygon[2] = $Liquid.polygon[3]
	$Gas.polygon[3].y = $Liquid.polygon[3].y
	update_OP_points()

var moving_l_index:int = -1
var moving_pt:TextureButton

func on_drag_start(pt:TextureButton, i:int):
	moving_pt = pt
	moving_l_index = i
	game.hide_tooltip()

func on_drag_end():
	moving_l_index = -1
	moving_pt = null

func update_OP_points():
	error = Geometry2D.triangulate_polygon($Gas.polygon).is_empty() or Geometry2D.triangulate_polygon($Liquid.polygon).is_empty() or Geometry2D.triangulate_polygon($Supercritical.polygon).is_empty()
	$Error.visible = error
	$OPPoints.visible = not error
	op_points[el] = 0
	for i in 4:
		op_points[el] += abs(default_l[i].x - $Liquid.polygon[i].x) / 150.0
		op_points[el] += abs(default_l[i].y - $Liquid.polygon[i].y) / 50.0
	if not error:
		if op_points[el] != 0:
			$OPPoints.text = "%s: %s" % [tr("CONTRIBUTION_TO_OPMETER"), Helper.clever_round(op_points[el])]
		else:
			$OPPoints.text = ""
	bonuses[el] = $Liquid.polygon
	$Reset.visible = op_points[el] != 0 and editable

func _input(event):
	if event is InputEventMouseMotion:
		var pos:Vector2 = event.position - $Liquid.position - global_position
		if moving_l_index != -1:
			pos.x = clamp(pos.x, 0, 800)
			pos.y = clamp(pos.y, 0, 400)
			$Liquid.polygon[moving_l_index] = pos
			if moving_l_index == 0:
				$Gas.polygon[1] = pos
				$Gas.polygon[0].x = max(pos.x - default_dT, 0)
			elif moving_l_index == 2:
				$Supercritical.polygon[1] = pos
				$Supercritical.polygon[2].y = max(pos.y - default_dP, 0)
			elif moving_l_index == 3:
				$Supercritical.polygon[0] = pos
				$Supercritical.polygon[3].y = pos.y
				$Gas.polygon[2] = pos
				$Gas.polygon[3].y = pos.y
			if moving_pt:
				moving_pt.position = pos - Vector2(8, 8) + $Liquid.position
			update_OP_points()
		var info:String = ""
		if Geometry2D.is_point_in_polygon(pos, $Gas.polygon):
			if state_moused_over != "g" and moving_l_index == -1:
				game.show_tooltip(tr("GAS"))
			state_moused_over = "g"
		elif Geometry2D.is_point_in_polygon(pos, $Supercritical.polygon):
			if state_moused_over != "sc" and moving_l_index == -1:
				game.show_tooltip(tr("SUPERCRITICAL") + "\n" + tr("%s_LAKE_BONUS" % el.to_upper()) % Data.lake_bonus_values[el].sc)
			state_moused_over = "sc"
		elif Geometry2D.is_point_in_polygon(pos, $Liquid.polygon):
			if state_moused_over != "l" and moving_l_index == -1:
				game.show_tooltip(tr("LIQUID") + "\n" + tr("%s_LAKE_BONUS" % el.to_upper()) % Data.lake_bonus_values[el].l)
			state_moused_over = "l"
		elif Geometry2D.is_point_in_polygon(pos, $Solid.polygon):
			if state_moused_over != "s" and moving_l_index == -1:
				game.show_tooltip(tr("SOLID") + "\n" + tr("%s_LAKE_BONUS" % el.to_upper()) % Data.lake_bonus_values[el].s)
			state_moused_over = "s"
		else:
			if state_moused_over != "":
				game.hide_tooltip()
			state_moused_over = ""
		if state_moused_over != "":
			info = "T = %s K, P = %s bar" % [round(1000 * pos.x / 800), Helper.clever_round(pow(10, -12.0 * (pos.y - 200)/400.0))]
		$Info.text = info

func valid_polygon(polygon:PackedVector2Array):
	var s = polygon.size() - 1
	for i in range(0,s):
		var p1: Vector2 = polygon[i]
		var p2: Vector2 = polygon[i+1 % s]
		for j in range(0,s):
			var p1a: Vector2 = polygon[j]
			var p2a: Vector2 = polygon[j+1 % s]
			var intersect = Geometry2D.segment_intersects_segment(p1,p2,p1a,p2a)
			if intersect != null: 
				return false
	return true


func _on_Reset_pressed():
	bonuses[el] = default_l
	$Reset.visible = false
	$OPPoints.text = ""
	refresh()
