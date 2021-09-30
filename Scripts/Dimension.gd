extends Control

onready var game = get_node("/root/Game")
var univ_icon = preload("res://Graphics/Misc/Universe.png")
const DUR = 0.6
const TWEEN_TYPE = Tween.TRANS_EXPO
const TWEEN_EASE = Tween.EASE_OUT
var new_dim_DRs = 0#DRs you will get once you renew dimensions

func _ready():
	$Physics/Control/UnivPropertiesLabel.visible = false
	for univ_prop in $Physics/Control/VBox.get_children():
		var univ_prop_text = preload("res://Scenes/HelpText.tscn").instance()
		univ_prop_text.label_text = tr(univ_prop.name.to_upper())
		univ_prop_text.help_text = tr("%s_DESC" % univ_prop.name.to_upper())
		univ_prop_text.size_flags_horizontal = Label.SIZE_EXPAND_FILL
		univ_prop_text.size_flags_vertical = Label.SIZE_EXPAND_FILL
		$Physics/Control/VBox2.add_child(univ_prop_text)
	refresh_univs()
	$OPMeter/OPMeterText.help_text = tr("THE_OPMETER_DESC") % tr("MATHS")
	if game.DRs == 0:
		for node in $ScrollContainer2/GridContainer.get_children():
			node.get_node("HBox/Invest").disabled = true

func refresh_univs():
	$TopInfo/Reset.disabled = true
	$ScrollContainer2/GridContainer.visible = game.dim_num > 1
	$DimBonusesInfo.visible = game.dim_num == 1
	if len(game.universe_data) > 1:
		for univ in game.universe_data:
			if univ.lv >= 100:
				$TopInfo/Reset.disabled = false
				break
	var lv_sum:int = 0
	for univ in game.universe_data:
		lv_sum += univ.lv
	new_dim_DRs = floor(lv_sum / 50.0)
	$TopInfo/Reset.text = "%s (+ %s %s)" % [tr("NEW_DIMENSION"), new_dim_DRs, tr("DR")]
	$TopInfo/DRs.bbcode_text = "[center]%s: %s  %s" % [tr("DR_TITLE"), game.DRs, "[img]Graphics/Icons/help.png[/img]"]
	$TopInfo/DimensionN.text = "%s #%s" % [tr("DIMENSION"), game.dim_num]
	for univ in $ScrollContainer/VBoxContainer.get_children():
		$ScrollContainer/VBoxContainer.remove_child(univ)
		univ.queue_free()
	for univ_info in game.universe_data:
		var univ = TextureButton.new()
		univ.texture_normal = univ_icon
		univ.expand = true
		univ.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		univ.rect_min_size = Vector2.ONE * 260.0
		var id = univ_info["id"]
		$ScrollContainer/VBoxContainer.add_child(univ)
		univ.connect("mouse_entered", self, "on_univ_over", [id])
		univ.connect("mouse_exited", self, "on_univ_out")
		univ.connect("pressed", self, "on_univ_press", [id])

func on_univ_out():
	game.hide_tooltip()
	$UnivInfo/Label.text = ""

func on_univ_over(id:int):
	var u_i = game.universe_data[id] #universe_info
	game.show_tooltip("%s\n%s: %s" % [u_i.name, tr("SUPERCLUSTERS"), u_i.supercluster_num])
	$UnivInfo/Label.text = tr("FUNDAMENTAL_PROPERTIES") + "\n"
	if id == 0:
		$UnivInfo/Label.text += "%s c = %s m·s\u207B\u00B9\n%s h = %s J·s\n%s k = %s J·K\u207B\u00B9\n%s \u03C3 = %s W·m\u207B\u00B2·K\u207B\u2074\n%s G = %s m\u00B3·kg\u207B\u00B9·s\u207B\u00B2\n%s e = %s C\n" % [
			tr("SPEED_OF_LIGHT"),
			Helper.e_notation(e(3, 8)),
			tr("PLANCK_CTE"),
			Helper.e_notation(e(6.626, -34)),
			tr("BOLTZMANN_CTE"),
			Helper.e_notation(e(1.381, -23)),
			tr("S_B_CTE"),
			Helper.e_notation(e(5.67, -8)),
			tr("GRAVITATIONAL_CTE"),
			Helper.e_notation(e(6.674, -11)),
			tr("ELEMENTARY_CHARGE"),
			Helper.e_notation(e(1.6, -19)),
			]
	else:
		$UnivInfo/Label.text += "%s: %sc\n%s: %sh\n%s: %sk\n%s: %s\u03C3\n%s: %sG\n%s: %se\n" % [
			tr("SPEED_OF_LIGHT"),
			u_i.speed_of_light,
			tr("PLANCK"),
			u_i.planck,
			tr("BOLTZMANN"),
			u_i.boltzmann,
			tr("S_B_CTE"),
			pow(u_i.boltzmann, 4) / pow(u_i.planck, 3) / pow(u_i.speed_of_light, 2),
			tr("GRAVITATIONAL"),
			u_i.gravitational,
			tr("ELEMENTARY_CHARGE"),
			u_i.charge,
			]
	$UnivInfo/Label.text += "\n%s\n" % tr("MULTIPLIERS")
	$UnivInfo/Label.text += "%s: %s\n%s: %s\n%s: %s\n%s: %s\n%s: %s" % [
		tr("DARK_ENERGY"),
		u_i.dark_energy,
		tr("DIFFICULTY"),
		u_i.difficulty,
		tr("TIME_SPEED"),
		u_i.time_speed,
		tr("ANTIMATTER"),
		u_i.antimatter,
		tr("UNIVERSE_VALUE"),
		u_i.universe_value,
		]

func e(n, e):
	return n * pow(10, e)

func on_univ_press(id:int):
	var u_i:Dictionary = game.universe_data[id]
	if u_i.has("generated") or u_i.lv > 1:
		game.c_u = id
		game.load_univ()
		game.switch_view("universe")
	else:
		game.remove_dimension()
		game.new_game(false, id)
		game.HUD.dimension_btn.visible = true
		game.switch_music(load("res://Audio/ambient" + String(Helper.rand_int(1, 3)) + ".ogg"))
	game.HUD.refresh_bookmarks()

func _on_SendProbes_pressed():
	game.toggle_panel(game.send_probes_panel)

func _on_mouse_exited():
	game.hide_tooltip()

func _on_Reset_mouse_entered():
	if $TopInfo/Reset.disabled:
		game.show_tooltip(tr("DIM_RESET_CONDITIONS"))


func _on_Reset_pressed():
	game.show_YN_panel("reset_dimension", tr("RESET_1ST_DIM_CONFIRM").format({"DRnumber":new_dim_DRs, "DRs":tr("DRs")}), [new_dim_DRs])

var maths_OP_points:float = 0
var physics_OP_points:float = 0
func calc_math_points(node:SpinBox, default_value:float, op_factor:float):
	if node.value <= 0:
		node.get_line_edit()["custom_colors/font_color"] = Color.red
		return
	else:
		node.get_line_edit()["custom_colors/font_color"] = Color.black
		maths_OP_points += (node.value - default_value) * op_factor

func _input(event):
	if event is InputEventKey or event is InputEventMouseButton:
		if get_focus_owner() is LineEdit:
			if $Maths.visible:
				maths_OP_points = 0
				calc_math_points($Maths/Control/BUCGF, 1.3, -300.0)
				calc_math_points($Maths/Control/MUCGF_MV, 1.9, -20.0)
				calc_math_points($Maths/Control/MUCGF_MSMB, 1.6, -10.0)
				calc_math_points($Maths/Control/MUCGF_AIE, 2.3, -50.0)
				calc_math_points($Maths/Control/IRM, 1.2, 40.0)
				calc_math_points($Maths/Control/SLUGF_XP, 1.3, -25.0)
				calc_math_points($Maths/Control/SLUGF_Stats, 1.15, 25.0)
				calc_math_points($Maths/Control/COSHEF, 1.5, 12.0)
				calc_math_points($Maths/Control/MMBSVR, 10, -8.0)
				calc_math_points($Maths/Control/ULUGF, 1.6, -70.0)
				$OPMeter/OPMeter.value = maths_OP_points
				$OPMeter/TooOP.visible = maths_OP_points > $OPMeter/OPMeter.max_value
			elif $Physics.visible:
				physics_OP_points = 0
				if $Physics/Control/MVOUP.value <= 0:
					$Physics/Control/MVOUP.get_line_edit()["custom_colors/font_color"] = Color.red
					return
				else:
					$Physics/Control/MVOUP.get_line_edit()["custom_colors/font_color"] = Color.black
					physics_OP_points += (0.5 / min($Physics/Control/MVOUP.value, 0.5) - 1.0)
				for cost in $Physics/Control/VBox.get_children():
					if cost.value <= 0:
						cost.get_line_edit()["custom_colors/font_color"] = Color.red
						return
					else:
						cost.get_line_edit()["custom_colors/font_color"] = Color.black
						physics_OP_points += Data.univ_prop_weights[cost.name] / cost.value - 1.0
				$OPMeter/OPMeter.value = physics_OP_points
				$OPMeter/TooOP.visible = physics_OP_points > $OPMeter/OPMeter.max_value
