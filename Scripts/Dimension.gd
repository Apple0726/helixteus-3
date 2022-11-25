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
var num_errors:Dictionary = {"maths":false, "physics":false, "engineering":false}

var table

func _ready():
	$ModifyDimension/Maths/Control/CostGrowthFactors/BUCGF.step = 0.0001
	$ModifyDimension/Maths/Control/CostGrowthFactors/ULUGF.step = 0.0001
	$ModifyDimension/Maths.rect_clip_content = true
	if game.c_u != -1 and not game.help.has("flash_send_probe_btn") and game.universe_data[0].has("generated"):
		$Universes/SendProbes/AnimationPlayer.play("FlashButton")
	$ModifyDimension/Reset/DimResetInfo.text = tr("DIM_JUST_RESET_INFO") % tr("GENERATE_STARTING_UNIVERSE")
	$ModifyDimension/Physics/Control/UnivPropertiesLabel.visible = false
	for univ_prop in $ModifyDimension/Physics/Control/VBox.get_children():
		univ_prop.value = game.physics_bonus[univ_prop.name]
		var univ_prop_text = preload("res://Scenes/HelpText.tscn").instance()
		univ_prop_text.label_text = tr(univ_prop.name.to_upper())
		univ_prop_text.help_text = tr("%s_DESC" % univ_prop.name.to_upper())
		univ_prop_text.rect_min_size.y = 32.0
		univ_prop_text.size_flags_horizontal = Label.SIZE_EXPAND_FILL
		#univ_prop_text.size_flags_vertical = Label.SIZE_EXPAND_FILL
		$ModifyDimension/Physics/Control/VBox2.add_child(univ_prop_text)
		univ_prop_text.name = univ_prop.name
	
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
			$ModifyDimension/OPMeter/OPMeter.max_value = subject.lv * (1.5 if game.subjects.dimensional_power.lv >= 4 else 1.0)
			$ModifyDimension/OPMeter/OPMeter.value = self["%s_OP_points" % subj_name.to_lower()]
			calc_OP_points()
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
		lv_sum += pow(univ.lv, 2.2) * univ.universe_value
	for node in $Subjects/Grid.get_children():
		node.get_node("HBox/Invest").disabled = game.DRs == 0
	new_dim_DRs = floor(lv_sum / 10000.0)
	$TopInfo/Reset.text = "%s (+ %s %s)" % [tr("NEW_DIMENSION"), new_dim_DRs, tr("DR")]
	$TopInfo/DRs.bbcode_text = "[center]%s: %s  %s" % [tr("DR_TITLE"), game.DRs, "[img]Graphics/Icons/help.png[/img]"]
	$TopInfo/DimensionN.text = "%s #%s" % [tr("DIMENSION"), game.dim_num]
	for univ in $Universes/Scroll/VBox.get_children():
		univ.queue_free()
	for subj in $Subjects/Grid.get_children():
		var subject:Dictionary = game.subjects[subj.name.to_lower()]
		subj.refresh(subject.DRs, subject.lv)
		if subj.get_node("HBox/Invest").is_connected("pressed", self, "on_invest"):
			subj.get_node("HBox/Invest").disconnect("pressed", self, "on_invest")
			
	for univ_prop in $ModifyDimension/Physics/Control/VBox.get_children():
		univ_prop.set_value(game.physics_bonus[univ_prop.name])
		univ_prop.editable = reset
	$ModifyDimension/Physics/Control/MVOUP.set_value(game.physics_bonus.MVOUP)
	$ModifyDimension/Physics/Control/MVOUP.editable = reset
	for maths_bonus in game.maths_bonus:
		if $ModifyDimension/Maths/Control/CostGrowthFactors.has_node(maths_bonus):
			$ModifyDimension/Maths/Control/CostGrowthFactors.get_node(maths_bonus).set_value(game.maths_bonus[maths_bonus])
			$ModifyDimension/Maths/Control/CostGrowthFactors.get_node(maths_bonus).editable = reset
		else:
			$ModifyDimension/Maths/Control.get_node(maths_bonus).set_value(game.maths_bonus[maths_bonus])
			$ModifyDimension/Maths/Control.get_node(maths_bonus).editable = reset
	for engineering_bonus in game.engineering_bonus:
		$ModifyDimension/Engineering/Control.get_node(engineering_bonus).set_value(game.engineering_bonus[engineering_bonus])
		$ModifyDimension/Engineering/Control.get_node(engineering_bonus).editable = reset
	
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
		$ModifyDimension/Reset/DRsPerCilck.visible = game.dim_num >= 3
		$ModifyDimension/Reset/LineEdit.visible = game.dim_num >= 3
		$Subjects.margin_left = 448
		for subj in $Subjects/Grid.get_children():
			if subj.name in ["Maths", "Physics", "Engineering", "Dimensional_Power"]:
				subj.get_node("HBox/Invest").connect("pressed", self, "on_invest", [subj])
	$Universes.visible = not reset
	$UnivInfo.visible = not reset
	$ModifyDimension/Reset.visible = reset
	if game.subjects.dimensional_power.lv >= 1:
		$ModifyDimension/Physics/Control/VBox/universe_value.visible = true
		$ModifyDimension/Physics/Control/VBox2/universe_value.visible = true
	else:
		$ModifyDimension/Physics/Control/VBox/universe_value.visible = false
		$ModifyDimension/Physics/Control/VBox2/universe_value.visible = false

func on_invest(subj_node):
	if game.DRs > 0:
		var old_DRs:int = game.DRs
		game.DRs = max(game.DRs - int($ModifyDimension/Reset/LineEdit.text), 0)
		$TopInfo/DRs.bbcode_text = "[center]%s: %s  %s" % [tr("DR_TITLE"), game.DRs, "[img]Graphics/Icons/help.png[/img]"]
		var subject:Dictionary = game.subjects[subj_node.name.to_lower()]
		subject.DRs += old_DRs - game.DRs
		while subject.DRs > subject.lv:
			subject.lv += 1
			subject.DRs -= subject.lv
		if subj_node.name == "Maths" and $ModifyDimension/Maths.visible:
			$ModifyDimension/OPMeter/OPMeter.max_value = subject.lv * (1.5 if game.subjects.dimensional_power.lv >= 4 else 1.0)
		elif subj_node.name == "Physics" and $ModifyDimension/Physics.visible:
			$ModifyDimension/OPMeter/OPMeter.max_value = subject.lv * (1.5 if game.subjects.dimensional_power.lv >= 4 else 1.0)
		elif subj_node.name == "Engineering" and $ModifyDimension/Engineering.visible:
			$ModifyDimension/OPMeter/OPMeter.max_value = subject.lv * (1.5 if game.subjects.dimensional_power.lv >= 4 else 1.0)
		if subj_node.name == "Dimensional_Power":
			if $ModifyDimension/Maths.visible:
				$ModifyDimension/OPMeter/OPMeter.max_value = game.subjects.maths.lv * (1.5 if subject.lv >= 4 else 1.0)
			elif $ModifyDimension/Physics.visible:
				$ModifyDimension/OPMeter/OPMeter.max_value = game.subjects.physics.lv * (1.5 if subject.lv >= 4 else 1.0)
			elif $ModifyDimension/Engineering.visible:
				$ModifyDimension/OPMeter/OPMeter.max_value = game.subjects.engineering.lv * (1.5 if subject.lv >= 4 else 1.0)
			$ModifyDimension/Dimensional_Power/Control/TextureProgress.value = subject.lv + subject.DRs / float(subject.lv + 1)
			if subject.lv >= 1:
				$ModifyDimension/Physics/Control/VBox/universe_value.visible = true
				$ModifyDimension/Physics/Control/VBox2/universe_value.visible = true
			if $ModifyDimension/Dimensional_Power/Control.has_node("Label%s" % subject.lv):
				$ModifyDimension/Dimensional_Power/Control.get_node("Label%s" % subject.lv)["custom_colors/font_color"] = Color.white
		subj_node.refresh(subject.DRs, subject.lv)
		

func on_univ_out():
	game.hide_tooltip()
	$UnivInfo.text = ""

func on_univ_over(id:int):
	var u_i = game.universe_data[id] #universe_info
	game.show_tooltip("%s (%s %s)" % [u_i.name, tr("LEVEL"), u_i.lv])
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
	$UnivInfo.text += "%s: %s\n%s: %s\n%s: %s" % [
		tr("DARK_ENERGY"),
		u_i.dark_energy,
		tr("DIFFICULTY"),
		u_i.difficulty,
		tr("TIME_SPEED"),
		u_i.time_speed,
		]
	if game.subjects.dimensional_power.lv > 2:
		$UnivInfo.text += "\n%s: %s" % [tr("ANTIMATTER"), u_i.antimatter]
	if game.subjects.dimensional_power.lv > 0:
		$UnivInfo.text += "\n%s: %s" % [tr("UNIVERSE_VALUE"), u_i.universe_value]

func e(n, e):
	return n * pow(10, e)

func on_univ_press(id:int):
	var u_i:Dictionary = game.universe_data[id]
	if u_i.has("generated") or u_i.lv > 1:
		game.c_u = id
		game.load_univ()
		game.switch_view(game.c_v)
	else:
		game.remove_dimension()
		game.new_game(false, id)
		game.HUD.dimension_btn.visible = true
		game.switch_music(load("res://Audio/ambient" + String(Helper.rand_int(1, 3)) + ".ogg"))
	game.HUD.refresh_visibility()
	game.HUD.refresh_bookmarks()

func _on_SendProbes_pressed():
	game.help.flash_send_probe_btn = true
	$Universes/SendProbes/AnimationPlayer.play("RESET")
	game.toggle_panel(game.send_probes_panel)

func _on_mouse_exited():
	game.hide_tooltip()

func _on_Reset_mouse_entered():
	if $TopInfo/Reset.disabled:
		game.show_tooltip(tr("DIM_RESET_CONDITIONS"))


func _on_Reset_pressed():
	game.show_YN_panel("reset_dimension", tr("RESET_1ST_DIM_CONFIRM").format({"DRnumber":new_dim_DRs, "DRs":tr("DRs")}), [new_dim_DRs])

func calc_math_points(node, default_value:float, op_factor:float, lower_limit:float = 0.0, upper_limit:float = INF):
	if node.value <= lower_limit or node.value >= upper_limit:
		node["custom_colors/font_color"] = Color.red
		num_errors.maths = true
		return
	else:
		node["custom_colors/font_color"] = Color.black
		var points_to_add:float
		if upper_limit == INF and op_factor > 0:
			points_to_add = (node.value - default_value) * op_factor
		else:
			if upper_limit != INF and op_factor > 0:
				points_to_add += abs(op_factor) * (1 / abs(node.value - upper_limit) - 1 / abs(default_value - upper_limit))
			elif op_factor < 0:
				points_to_add += abs(op_factor) * (1 / abs(node.value - lower_limit) - 1 / abs(default_value - lower_limit))
		if not is_equal_approx(points_to_add, 0) and points_to_add < 0:
			points_to_add = -atan(-points_to_add) * 0.25
		maths_OP_points += points_to_add

onready var math_defaults = $ModifyDimension/Maths/Control/Defaults
onready var physics_defaults = $ModifyDimension/Physics/Control/Defaults
func _input(event):
	if event is InputEventMouseMotion:
		if is_instance_valid(table):
			var mouse_pos:Vector2 = game.mouse_pos
			if game.op_cursor:
				if Geometry.is_point_in_polygon(mouse_pos, game.quadrant_top_left) or Geometry.is_point_in_polygon(mouse_pos, game.quadrant_bottom_left):
					table.rect_position = mouse_pos - Vector2(-9, table.rect_size.y + 9)
				else:
					table.rect_position = mouse_pos - table.rect_size - Vector2(9, 9)
			else:
				if Geometry.is_point_in_polygon(mouse_pos, game.quadrant_top_left):
					table.rect_position = mouse_pos + Vector2(9, 9)
				elif Geometry.is_point_in_polygon(mouse_pos, game.quadrant_top_right):
					table.rect_position = mouse_pos - Vector2(table.rect_size.x + 9, -9)
				elif Geometry.is_point_in_polygon(mouse_pos, game.quadrant_bottom_left):
					table.rect_position = mouse_pos - Vector2(-9, table.rect_size.y + 9)
				elif Geometry.is_point_in_polygon(mouse_pos, game.quadrant_bottom_right):
					table.rect_position = mouse_pos - table.rect_size - Vector2(9, 9)
			table.visible = true
	if $ColorRect.visible and $ColorRect/Label.modulate.a == 1.0 and Input.is_action_just_released("left_click"):
		show_DR_help()
	if $ModifyDimension/Reset.visible:
		var DR_per_click:int = int($ModifyDimension/Reset/LineEdit.text)
		if DR_per_click < 0:
			$ModifyDimension/Reset/LineEdit.text = "0"
		if DR_per_click <= 1:
			for subj in $Subjects/Grid.get_children():
				subj.get_node("HBox/Invest").text = tr("INVEST")
		else:
			for subj in $Subjects/Grid.get_children():
				subj.get_node("HBox/Invest").text = tr("INVEST_X") % Helper.format_num(DR_per_click, false, 3)
		if event is InputEventKey or event is InputEventMouse:
			yield(get_tree(), "idle_frame")
			calc_OP_points()

func calc_OP_points():
	maths_OP_points = 0
	num_errors = {"maths":false, "physics":false, "engineering":false}
	calc_math_points($ModifyDimension/Maths/Control/CostGrowthFactors/BUCGF, 1.3, -12.0, 1.2)#Building upgrade cost
	calc_math_points($ModifyDimension/Maths/Control/CostGrowthFactors/MUCGF_MV, 1.9, -8.0, 1.2)#Mineral value
	calc_math_points($ModifyDimension/Maths/Control/CostGrowthFactors/MUCGF_MSMB, 1.6, -2.5, 1.2)#Mining speed multiplier
	calc_math_points($ModifyDimension/Maths/Control/CostGrowthFactors/MUCGF_AIE, 2.3, -10.0, 1.5)#Aurora intensity exponent
	calc_math_points($ModifyDimension/Maths/Control/IRM, 1.2, 80.0, 1.0, 3.0)#Infinite research
	calc_math_points($ModifyDimension/Maths/Control/CostGrowthFactors/SLUGF_XP, 1.3, -12.0, 1.1)#Ship level up XP
	calc_math_points($ModifyDimension/Maths/Control/CostGrowthFactors/SLUGF_Stats, 1.15, 240.0, 1.0, 3.0)#Ship stats
	calc_math_points($ModifyDimension/Maths/Control/COSHEF, 1.5, 0.4)#Chance of ship hitting enemy
	calc_math_points($ModifyDimension/Maths/Control/MMBSVR, 10, -100.0, 2)#Material metal buy/sell
	calc_math_points($ModifyDimension/Maths/Control/CostGrowthFactors/ULUGF, 1.6, -120.0, 1.15)#Universe level XP

	math_defaults.get_node("BUCGF").visible = not is_equal_approx($ModifyDimension/Maths/Control/CostGrowthFactors/BUCGF.value, float(math_defaults.get_node("BUCGF").text.right(1)))
	math_defaults.get_node("MUCGF_MV").visible = not is_equal_approx($ModifyDimension/Maths/Control/CostGrowthFactors/MUCGF_MV.value, float(math_defaults.get_node("MUCGF_MV").text.right(1)))
	math_defaults.get_node("MUCGF_MSMB").visible = not is_equal_approx($ModifyDimension/Maths/Control/CostGrowthFactors/MUCGF_MSMB.value, float(math_defaults.get_node("MUCGF_MSMB").text.right(1)))
	math_defaults.get_node("MUCGF_AIE").visible = not is_equal_approx($ModifyDimension/Maths/Control/CostGrowthFactors/MUCGF_AIE.value, float(math_defaults.get_node("MUCGF_AIE").text.right(1)))
	math_defaults.get_node("IRM").visible = not is_equal_approx($ModifyDimension/Maths/Control/IRM.value, float(math_defaults.get_node("IRM").text.right(1)))
	math_defaults.get_node("SLUGF_XP").visible = not is_equal_approx($ModifyDimension/Maths/Control/CostGrowthFactors/SLUGF_XP.value, float(math_defaults.get_node("SLUGF_XP").text.right(1)))
	math_defaults.get_node("SLUGF_Stats").visible = not is_equal_approx($ModifyDimension/Maths/Control/CostGrowthFactors/SLUGF_Stats.value, float(math_defaults.get_node("SLUGF_Stats").text.right(1)))
	math_defaults.get_node("COSHEF").visible = not is_equal_approx($ModifyDimension/Maths/Control/COSHEF.value, float(math_defaults.get_node("COSHEF").text.right(1)))
	math_defaults.get_node("MMBSVR").visible = not is_equal_approx($ModifyDimension/Maths/Control/MMBSVR.value, float(math_defaults.get_node("MMBSVR").text.right(1)))
	math_defaults.get_node("ULUGF").visible = not is_equal_approx($ModifyDimension/Maths/Control/CostGrowthFactors/ULUGF.value, float(math_defaults.get_node("ULUGF").text.right(1)))
	physics_OP_points = 0
	if $ModifyDimension/Physics/Control/MVOUP.value <= 0:
		$ModifyDimension/Physics/Control/MVOUP["custom_colors/font_color"] = Color.red
		num_errors.physics = true
		return
	else:
		$ModifyDimension/Physics/Control/MVOUP["custom_colors/font_color"] = Color.black
		physics_OP_points += 0.5 / min($ModifyDimension/Physics/Control/MVOUP.value, 0.5) - 1.0
	physics_defaults.get_node("MVOUP").visible = not is_equal_approx($ModifyDimension/Physics/Control/MVOUP.value, float(physics_defaults.get_node("MVOUP").text.right(1)))
	for cost in $ModifyDimension/Physics/Control/VBox.get_children():
		if cost.value <= 0:
			cost["custom_colors/font_color"] = Color.red
			num_errors.physics = true
			return
		else:
			cost["custom_colors/font_color"] = Color.black
			if cost.value > Data.univ_prop_weights[cost.name]:
				physics_OP_points += Data.univ_prop_weights[cost.name] / cost.value - 1.0
			else:
				physics_OP_points += pow(Data.univ_prop_weights[cost.name] / cost.value, 2) - 1.0
		physics_defaults.get_node(cost.name).visible = not is_equal_approx(cost.value, float(physics_defaults.get_node(cost.name).text.right(1)))
	
	engineering_OP_points = 0
	calc_engi_points($ModifyDimension/Engineering/Control/BCM, 7.0, false)
	calc_engi_points($ModifyDimension/Engineering/Control/PS, 0.15, true)
	calc_engi_points($ModifyDimension/Engineering/Control/RSM, 0.4, true)
	if $ModifyDimension/Maths.visible:
		if is_equal_approx(maths_OP_points, 0):
			maths_OP_points = 0
		$ModifyDimension/OPMeter/OPMeter.value = maths_OP_points
		$ModifyDimension/OPMeter/TooOP.text = "%s / %s" % [Helper.clever_round(maths_OP_points), $ModifyDimension/OPMeter/OPMeter.max_value]
		if maths_OP_points > $ModifyDimension/OPMeter/OPMeter.max_value or num_errors.maths:
			$ModifyDimension/OPMeter/TooOP.text += " - %s" % tr("TOO_OP")
			$Subjects/Grid/Maths/Effects["custom_colors/font_color"] = Color(0.8, 0, 0)
		else:
			$Subjects/Grid/Maths/Effects["custom_colors/font_color"] = Color.white
	elif $ModifyDimension/Physics.visible:
		$ModifyDimension/OPMeter/OPMeter.value = physics_OP_points
		$ModifyDimension/OPMeter/TooOP.text = "%s / %s" % [Helper.clever_round(physics_OP_points), $ModifyDimension/OPMeter/OPMeter.max_value]
		if physics_OP_points > $ModifyDimension/OPMeter/OPMeter.max_value or num_errors.physics:
			$ModifyDimension/OPMeter/TooOP.text += " - %s" % tr("TOO_OP")
			$Subjects/Grid/Physics/Effects["custom_colors/font_color"] = Color(0.8, 0, 0)
		else:
			$Subjects/Grid/Physics/Effects["custom_colors/font_color"] = Color.white
	elif $ModifyDimension/Engineering.visible:
		$ModifyDimension/OPMeter/OPMeter.value = engineering_OP_points
		$ModifyDimension/OPMeter/TooOP.text = "%s / %s" % [Helper.clever_round(engineering_OP_points), $ModifyDimension/OPMeter/OPMeter.max_value]
		if engineering_OP_points > $ModifyDimension/OPMeter/OPMeter.max_value or num_errors.engineering:
			$ModifyDimension/OPMeter/TooOP.text += " - %s" % tr("TOO_OP")
			$Subjects/Grid/Engineering/Effects["custom_colors/font_color"] = Color(0.8, 0, 0)
		else:
			$Subjects/Grid/Engineering/Effects["custom_colors/font_color"] = Color.white
	if $ModifyDimension/Reset.visible:
		var OP_mult:float = (1.5 if game.subjects.dimensional_power.lv >= 4 else 1.0)
		$ModifyDimension/Reset/Generate.visible = true
		#Save migration
		$ModifyDimension/Reset/Generate.disabled = not (maths_OP_points <= game.subjects.maths.lv * OP_mult and (game.subjects.physics.lv == 0 or physics_OP_points <= game.subjects.physics.lv * OP_mult) and engineering_OP_points <= game.subjects.engineering.lv * OP_mult) or num_errors.maths or num_errors.physics or num_errors.engineering

func calc_engi_points(node, op_factor:float, growth:bool):
	if node.value <= 0:
		node["custom_colors/font_color"] = Color.red
		num_errors.engineering = true
		return
	else:
		node["custom_colors/font_color"] = Color.black
		if growth:
			engineering_OP_points += op_factor * (node.value - 1.0)
		else:
			engineering_OP_points += op_factor * (1.0 / node.value - 1.0)

func set_bonuses():
	for bonus in game.maths_bonus:
		if $ModifyDimension/Maths/Control/CostGrowthFactors.has_node(bonus):
			game.maths_bonus[bonus] = $ModifyDimension/Maths/Control/CostGrowthFactors.get_node(bonus).value
		else:
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


func _on_Label1_mouse_entered():
	game.show_tooltip("When customizing a universe, a new slider called \"Universe value\" will appear which will multiply the effectiveness of universe levels when calculating probe points and DRs.")


func _on_Label2_mouse_entered():
	game.show_tooltip("More precisely, the actual time speed in caves and in battles will be equal to ln(universe time speed - 1 + e). Everything else (building construction speed, mining minigame etc.) is unaffected.")

var DR_help_index:int = 1

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "FadeOut":
		$ColorRect.visible = false
	else:
		show_DR_help()
		game.physics_bonus.universe_value = 250#Save migration
		refresh_univs(true)

func show_DR_help():
	var tween = $ColorRect/Tween
	if $ColorRect/Label.modulate.a > 0:
		tween.interpolate_property($ColorRect/Label, "modulate", null, Color(1, 1, 1, 0), 0.5)
		tween.start()
		yield(tween, "tween_all_completed")
		DR_help_index += 1
	if DR_help_index == 5:
		$ColorRect/AnimationPlayer.play("FadeOut")
		game.help.DR_reset = true
	else:
		if DR_help_index == 2:
			$ColorRect/Label.text = tr("DR_HELP%s" % DR_help_index) % [Helper.format_num(game.stats_global.bldgs_built), Helper.format_num(game.stats_global.total_money_earned), Helper.format_num(game.stats_global.planets_conquered)]
		else:
			$ColorRect/Label.text = tr("DR_HELP%s" % DR_help_index)
		tween.interpolate_property($ColorRect/Label, "modulate", null, Color.white, 0.5)
		tween.start()

func _on_ColorRect_visibility_changed():
	if $ColorRect.visible:
		$ColorRect/AnimationPlayer.play("Fade")


func _on_CostGrowthFactor_mouse_entered():
	game.show_tooltip("Cost growth factor formula. Costs (e.g. building costs, XP requirements) are multiplied by a certain value every time they level up. This value corresponds to q.")


func _on_ShipHitChance_mouse_entered():
	game.show_tooltip("ship_hit_chance is a number between 0 and 1. 0 means the ship will never hit enemies, 1 means it will always hit them.\nThe variable you're modifying is a, which basically multiplies a ship's accuracy stat.")

func _on_Table_mouse_entered(maths_bonus:String, level_1_value:float):
	if is_instance_valid(table):
		table.queue_free()
	table = preload("res://Scenes/Table.tscn").instance()
	table.visible = false
	game.get_node("Tooltips").add_child(table)
	table.get_node("GridContainer/Value").text = "%s (q=%s)" % [tr("VALUE"), $ModifyDimension/Maths/Control/CostGrowthFactors.get_node(maths_bonus).text]
	table.get_node("GridContainer/Default").text = "%s (q=%s)" % [tr("DEFAULT"), float(math_defaults.get_node(maths_bonus).text.right(1))]
	table.get_node("GridContainer/1Value").text = str(level_1_value)
	table.get_node("GridContainer/1Default").text = str(level_1_value)
	table.get_node("GridContainer/10Value").text = Helper.format_num(round(level_1_value * pow($ModifyDimension/Maths/Control/CostGrowthFactors.get_node(maths_bonus).value, 10)))
	table.get_node("GridContainer/10Default").text = Helper.format_num(round(level_1_value * pow(float(math_defaults.get_node(maths_bonus).text.right(1)), 10)))
	table.get_node("GridContainer/100Value").text = Helper.format_num(round(level_1_value * pow($ModifyDimension/Maths/Control/CostGrowthFactors.get_node(maths_bonus).value, 100)))
	table.get_node("GridContainer/100Default").text = Helper.format_num(round(level_1_value * pow(float(math_defaults.get_node(maths_bonus).text.right(1)), 100)))


func _on_Table_mouse_exited():
	table.queue_free()
