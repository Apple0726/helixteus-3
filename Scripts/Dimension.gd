extends Control

onready var game = get_node("/root/Game")
var univ_icon = preload("res://Graphics/Misc/Universe.png")
const DUR = 0.6
const TWEEN_TYPE = Tween.TRANS_EXPO
const TWEEN_EASE = Tween.EASE_OUT
var new_dim_DRs = 0#DRs you will get once you renew dimensions
var maths_OP_points:float = 0
var physics_OP_points:float = 0
var engineering_OP_points:float = 0

func _ready():
	$ModifyDimension/DimResetInfo.text = tr("DIM_JUST_RESET_INFO") % tr("GENERATE_STARTING_UNIVERSE")
	$ModifyDimension/Physics/Control/UnivPropertiesLabel.visible = false
	for univ_prop in $ModifyDimension/Physics/Control/VBox.get_children():
		var univ_prop_text = preload("res://Scenes/HelpText.tscn").instance()
		univ_prop_text.label_text = tr(univ_prop.name.to_upper())
		univ_prop_text.help_text = tr("%s_DESC" % univ_prop.name.to_upper())
		univ_prop_text.size_flags_horizontal = Label.SIZE_EXPAND_FILL
		univ_prop_text.size_flags_vertical = Label.SIZE_EXPAND_FILL
		$ModifyDimension/Physics/Control/VBox2.add_child(univ_prop_text)
	refresh_univs()
	$ModifyDimension/OPMeter/OPMeterText.help_text = tr("THE_OPMETER_DESC") % tr("MATHS")
	for i in game.subjects.dimensional_power.lv:
		if $ModifyDimension/Dimensional_Power/Control.has_node("Label%s" % i):
			$ModifyDimension/Dimensional_Power/Control.get_node("Label%s" % i)["custom_colors/font_color"] = Color.white
		else:
			break
	$ModifyDimension/Dimensional_Power/Control/TextureProgress.value = game.subjects.dimensional_power.lv + game.subjects.dimensional_power.DRs / (game.subjects.dimensional_power.lv + 1)
	for subj in $Subjects/Grid.get_children():
		subj.get_node("Effects/EffectButton").connect("pressed", self, "toggle_subj", [subj.name])

func toggle_subj(subj_name:String):
	for subj in $Subjects/Grid.get_children():
		if subj.name != subj_name and $ModifyDimension.has_node(subj.name):
			$ModifyDimension.get_node(subj.name).visible = false
	if $ModifyDimension.has_node(subj_name):
		$ModifyDimension.get_node(subj_name).visible = not $ModifyDimension.get_node(subj_name).visible
		$ModifyDimension/OPMeter.visible = $ModifyDimension.get_node(subj_name).visible and subj_name in ["Maths", "Physics", "Engineering"]
		if $ModifyDimension/OPMeter.visible:
			var subject:Dictionary = game.subjects[subj_name.to_lower()]
			$ModifyDimension/OPMeter/OPMeterText.help_text = tr("THE_OPMETER_DESC") % tr(subj_name.to_upper())
			$ModifyDimension/OPMeter/OPMeter.max_value = subject.lv * (2.0 if game.subjects.dimensional_power.lv >= 2 else 1.0)
			$ModifyDimension/OPMeter/OPMeter.value = self["%s_OP_points" % subj_name.to_lower()]
			$ModifyDimension/OPMeter/TooOP.visible = self["%s_OP_points" % subj_name.to_lower()] > $ModifyDimension/OPMeter/OPMeter.max_value
	else:
		$ModifyDimension/OPMeter.visible = false

func refresh_univs(reset:bool = false):
	$TopInfo/Reset.disabled = true
	$Subjects/Grid.visible = game.dim_num > 1
	$DimBonusesInfo.visible = game.dim_num == 1
	if len(game.universe_data) > 1:
		for univ in game.universe_data:
			if univ.lv >= 100:
				$TopInfo/Reset.disabled = false
				break
	var lv_sum:int = 0
	for univ in game.universe_data:
		lv_sum += univ.lv
	for node in $Subjects/Grid.get_children():
		node.get_node("HBox/Invest").disabled = game.DRs == 0
	new_dim_DRs = floor(lv_sum / 50.0)
	$TopInfo/Reset.text = "%s (+ %s %s)" % [tr("NEW_DIMENSION"), new_dim_DRs, tr("DR")]
	$TopInfo/DRs.bbcode_text = "[center]%s: %s  %s" % [tr("DR_TITLE"), game.DRs, "[img]Graphics/Icons/help.png[/img]"]
	$TopInfo/DimensionN.text = "%s #%s" % [tr("DIMENSION"), game.dim_num]
	for univ in $Universes/Scroll/VBox.get_children():
		$Universes/Scroll/VBox.remove_child(univ)
		univ.queue_free()
	for subj in $Subjects/Grid.get_children():
		var subject:Dictionary = game.subjects[subj.name.to_lower()]
		subj.refresh(subject.DRs, subject.lv)
		if subj.get_node("HBox/Invest").is_connected("pressed", self, "on_invest"):
			subj.get_node("HBox/Invest").disconnect("pressed", self, "on_invest")
	if not reset:
		$Subjects.margin_left = 704
		for univ_info in game.universe_data:
			var univ = TextureButton.new()
			univ.texture_normal = univ_icon
			univ.expand = true
			univ.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
			univ.rect_min_size = Vector2.ONE * 260.0
			var id = univ_info["id"]
			$Universes/Scroll/VBox.add_child(univ)
			univ.connect("mouse_entered", self, "on_univ_over", [id])
			univ.connect("mouse_exited", self, "on_univ_out")
			univ.connect("pressed", self, "on_univ_press", [id])
	else:
		$Subjects.margin_left = 448
		for subj in $Subjects/Grid.get_children():
			if subj.name in ["Maths", "Physics", "Engineering", "Dimensional_Power"]:
				subj.get_node("HBox/Invest").connect("pressed", self, "on_invest", [subj])
	$Universes.visible = not reset
	$UnivInfo.visible = not reset
	$ModifyDimension.visible = reset

func on_invest(subj_node):
	if game.DRs > 0:
		game.DRs -= 1
		$TopInfo/DRs.bbcode_text = "[center]%s: %s  %s" % [tr("DR_TITLE"), game.DRs, "[img]Graphics/Icons/help.png[/img]"]
		var subject:Dictionary = game.subjects[subj_node.name.to_lower()]
		subject.DRs += 1
		if subject.DRs > subject.lv:
			subject.DRs = 0
			subject.lv += 1
		if subj_node.name == "Dimensional_Power":
			if $ModifyDimension/Maths.visible:
				$ModifyDimension/OPMeter/OPMeter.max_value = game.subjects.maths.lv * (2.0 if subject.lv >= 2 else 1.0)
				$ModifyDimension/OPMeter/TooOP.visible = maths_OP_points > $ModifyDimension/OPMeter/OPMeter.max_value
			elif $ModifyDimension/Physics.visible:
				$ModifyDimension/OPMeter/OPMeter.max_value = game.subjects.physics.lv * (2.0 if subject.lv >= 2 else 1.0)
				$ModifyDimension/OPMeter/TooOP.visible = physics_OP_points > $ModifyDimension/OPMeter/OPMeter.max_value
			elif $ModifyDimension/Engineering.visible:
				$ModifyDimension/OPMeter/OPMeter.max_value = game.subjects.engineering.lv * (2.0 if subject.lv >= 2 else 1.0)
				$ModifyDimension/OPMeter/TooOP.visible = engineering_OP_points > $ModifyDimension/OPMeter/OPMeter.max_value
			$ModifyDimension/Dimensional_Power/Control/TextureProgress.value = subject.lv + subject.DRs / float(subject.lv + 1)
			if $ModifyDimension/Dimensional_Power/Control.has_node("Label%s" % subject.lv):
				$ModifyDimension/Dimensional_Power/Control.get_node("Label%s" % subject.lv)["custom_colors/font_color"] = Color.white
		subj_node.refresh(subject.DRs, subject.lv)
		

func on_univ_out():
	game.hide_tooltip()
	$UnivInfo.text = ""

func on_univ_over(id:int):
	var u_i = game.universe_data[id] #universe_info
	game.show_tooltip("%s\n%s: %s" % [u_i.name, tr("SUPERCLUSTERS"), u_i.supercluster_num])
	$UnivInfo.text = tr("FUNDAMENTAL_PROPERTIES") + "\n"
	if id == 0:
		$UnivInfo.text += "%s c = %s m·s\u207B\u00B9\n%s h = %s J·s\n%s k = %s J·K\u207B\u00B9\n%s \u03C3 = %s W·m\u207B\u00B2·K\u207B\u2074\n%s G = %s m\u00B3·kg\u207B\u00B9·s\u207B\u00B2\n%s e = %s C\n" % [
			tr("SPEED_OF_LIGHT"),
			Helper.e_notation(e(3, 8)),
			tr("PLANCK"),
			Helper.e_notation(e(6.626, -34)),
			tr("BOLTZMANN"),
			Helper.e_notation(e(1.381, -23)),
			tr("S_B_CTE"),
			Helper.e_notation(e(5.67, -8)),
			tr("GRAVITATIONAL"),
			Helper.e_notation(e(6.674, -11)),
			tr("CHARGE"),
			Helper.e_notation(e(1.6, -19)),
			]
	else:
		$UnivInfo.text += "%s: %sc\n%s: %sh\n%s: %sk\n%s: %s\u03C3\n%s: %sG\n%s: %se\n" % [
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
			tr("CHARGE"),
			u_i.charge,
			]
	$UnivInfo.text += "\n%s\n" % tr("MULTIPLIERS")
	$UnivInfo.text += "%s: %s\n%s: %s\n%s: %s\n%s: %s\n%s: %s" % [
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

func calc_math_points(node:SpinBox, default_value:float, op_factor:float):
	if node.value <= 0:
		node.get_line_edit()["custom_colors/font_color"] = Color.red
		$ModifyDimension/Generate.visible = false
		return
	else:
		node.get_line_edit()["custom_colors/font_color"] = Color.black
		var points_to_add:float = (node.value - default_value) * op_factor
		if not is_equal_approx(points_to_add, 0) and points_to_add < 0:
			points_to_add = -atan(-points_to_add) * 0.2
		maths_OP_points += points_to_add

onready var math_defaults = $ModifyDimension/Maths/Control/Defaults
onready var physics_defaults = $ModifyDimension/Physics/Control/Defaults
func _input(event):
	if event is InputEventKey or event is InputEventMouseButton:
		if get_focus_owner() is LineEdit:
			if $ModifyDimension/Maths.visible:
				maths_OP_points = 0
				calc_math_points($ModifyDimension/Maths/Control/BUCGF, 1.3, -30.0)
				math_defaults.get_node("BUCGF").visible = not is_equal_approx($ModifyDimension/Maths/Control/BUCGF.value, float(math_defaults.get_node("BUCGF").text.right(1)))
				calc_math_points($ModifyDimension/Maths/Control/MUCGF_MV, 1.9, -4.0)
				math_defaults.get_node("MUCGF_MV").visible = not is_equal_approx($ModifyDimension/Maths/Control/MUCGF_MV.value, float(math_defaults.get_node("MUCGF_MV").text.right(1)))
				calc_math_points($ModifyDimension/Maths/Control/MUCGF_MSMB, 1.6, -2.0)
				math_defaults.get_node("MUCGF_MSMB").visible = not is_equal_approx($ModifyDimension/Maths/Control/MUCGF_MSMB.value, float(math_defaults.get_node("MUCGF_MSMB").text.right(1)))
				calc_math_points($ModifyDimension/Maths/Control/MUCGF_AIE, 2.3, -10.0)
				math_defaults.get_node("MUCGF_AIE").visible = not is_equal_approx($ModifyDimension/Maths/Control/MUCGF_AIE.value, float(math_defaults.get_node("MUCGF_AIE").text.right(1)))
				calc_math_points($ModifyDimension/Maths/Control/IRM, 1.2, 8.0)
				math_defaults.get_node("IRM").visible = not is_equal_approx($ModifyDimension/Maths/Control/IRM.value, float(math_defaults.get_node("IRM").text.right(1)))
				calc_math_points($ModifyDimension/Maths/Control/SLUGF_XP, 1.3, -15.0)
				math_defaults.get_node("SLUGF_XP").visible = not is_equal_approx($ModifyDimension/Maths/Control/SLUGF_XP.value, float(math_defaults.get_node("SLUGF_XP").text.right(1)))
				calc_math_points($ModifyDimension/Maths/Control/SLUGF_Stats, 1.15, 5.0)
				math_defaults.get_node("SLUGF_Stats").visible = not is_equal_approx($ModifyDimension/Maths/Control/SLUGF_Stats.value, float(math_defaults.get_node("SLUGF_Stats").text.right(1)))
				calc_math_points($ModifyDimension/Maths/Control/COSHEF, 1.5, 2.5)
				math_defaults.get_node("COSHEF").visible = not is_equal_approx($ModifyDimension/Maths/Control/COSHEF.value, float(math_defaults.get_node("COSHEF").text.right(1)))
				calc_math_points($ModifyDimension/Maths/Control/MMBSVR, 10, -1.0)
				math_defaults.get_node("MMBSVR").visible = not is_equal_approx($ModifyDimension/Maths/Control/MMBSVR.value, float(math_defaults.get_node("MMBSVR").text.right(1)))
				calc_math_points($ModifyDimension/Maths/Control/ULUGF, 1.6, -15.0)
				math_defaults.get_node("ULUGF").visible = not is_equal_approx($ModifyDimension/Maths/Control/ULUGF.value, float(math_defaults.get_node("ULUGF").text.right(1)))
				$ModifyDimension/OPMeter/OPMeter.value = maths_OP_points
				$ModifyDimension/OPMeter/TooOP.visible = maths_OP_points > $ModifyDimension/OPMeter/OPMeter.max_value
			elif $ModifyDimension/Physics.visible:
				physics_OP_points = 0
				if $ModifyDimension/Physics/Control/MVOUP.value <= 0:
					$ModifyDimension/Physics/Control/MVOUP.get_line_edit()["custom_colors/font_color"] = Color.red
					$ModifyDimension/Generate.visible = false
					return
				else:
					$ModifyDimension/Physics/Control/MVOUP.get_line_edit()["custom_colors/font_color"] = Color.black
					physics_OP_points += (0.5 / min($ModifyDimension/Physics/Control/MVOUP.value, 0.5) - 1.0) * 0.5
				physics_defaults.get_node("MVOUP").visible = not is_equal_approx($ModifyDimension/Physics/Control/MVOUP.value, float(physics_defaults.get_node("MVOUP").text.right(1)))
				for cost in $ModifyDimension/Physics/Control/VBox.get_children():
					if cost.value <= 0:
						cost.get_line_edit()["custom_colors/font_color"] = Color.red
						$ModifyDimension/Generate.visible = false
						return
					else:
						cost.get_line_edit()["custom_colors/font_color"] = Color.black
						physics_OP_points += (Data.univ_prop_weights[cost.name] / cost.value - 1.0) * 0.5
					physics_defaults.get_node(cost.name).visible = not is_equal_approx(cost.value, float(physics_defaults.get_node(cost.name).text.right(1)))
				$ModifyDimension/OPMeter/OPMeter.value = physics_OP_points
				$ModifyDimension/OPMeter/TooOP.visible = physics_OP_points > $ModifyDimension/OPMeter/OPMeter.max_value
			elif $ModifyDimension/Engineering.visible:
				engineering_OP_points = 0
				calc_engi_points($ModifyDimension/Engineering/Control/BCM, 0.7, false)
				calc_engi_points($ModifyDimension/Engineering/Control/PS, 0.1, true)
				calc_engi_points($ModifyDimension/Engineering/Control/RSM, 0.15, true)
				$ModifyDimension/OPMeter/OPMeter.value = engineering_OP_points
				$ModifyDimension/OPMeter/TooOP.visible = engineering_OP_points > $ModifyDimension/OPMeter/OPMeter.max_value
			var OP_mult:float = (2.0 if game.subjects.dimensional_power.lv >= 2 else 1.0)
			$ModifyDimension/Generate.visible = maths_OP_points <= game.subjects.maths.lv * OP_mult and physics_OP_points <= game.subjects.physics.lv * OP_mult and engineering_OP_points <= game.subjects.engineering.lv * OP_mult

func calc_engi_points(node:SpinBox, op_factor:float, growth:bool):
	if node.value <= 0:
		node.get_line_edit()["custom_colors/font_color"] = Color.red
		$ModifyDimension/Generate.visible = false
		return
	else:
		node.get_line_edit()["custom_colors/font_color"] = Color.black
		if growth:
			engineering_OP_points += op_factor * (node.value - 1.0)
		else:
			engineering_OP_points += op_factor * (1.0 / node.value - 1.0)

func set_bonuses():
	for bonus in game.maths_bonus:
		game.maths_bonus[bonus] = $ModifyDimension/Maths/Control.get_node(bonus).value
	for bonus in game.physics_bonus:
		if bonus == "MVOUP":
			game.physics_bonus[bonus] = $ModifyDimension/Physics/Control.get_node(bonus).value
		elif bonus != "antimatter":
			game.physics_bonus[bonus] = $ModifyDimension/Physics/Control/VBox.get_node(bonus).value
	for bonus in game.engineering_bonus:
		game.engineering_bonus[bonus] = $ModifyDimension/Engineering/Control.get_node(bonus).value

func _on_Generate_pressed():
	game.show_YN_panel("generate_new_univ", tr("GENERATE_STARTING_UNIVERSE_CONFIRM"))
