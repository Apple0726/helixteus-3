extends Control

onready var game = get_node("/root/Game")
var univ_icon = preload("res://Graphics/Misc/Universe.png")
const DUR = 0.6
const TWEEN_TYPE = Tween.TRANS_EXPO
const TWEEN_EASE = Tween.EASE_OUT
var new_dim_DRs = 0#DRs you will get once you renew dimensions
var maths_OP_points:float = 0
var physics_OP_points:float = 0
var chemistry_OP_points:float = 0
var biology_OP_points:float = 0
var engineering_OP_points:float = 0
var num_errors:Dictionary = {}
var selected_element:String
var DR_mult:float = 1.0

var table

var lake_params:Dictionary = {
	"H2O":{"min_value":1, "max_value":INF, "value":1, "OP_factor":1.0},
	"CH4":{"min_value":1, "max_value":INF, "value":1, "OP_factor":0.2},
	"CO2":{"min_value":1, "max_value":INF, "value":1, "OP_factor":0.3},
	"NH3":{"min_value":1, "max_value":INF, "value":1, "OP_factor":0.2},
	"H":{"min_value":0, "max_value":3, "value":0, "is_integer":true, "OP_factor":0.8, "pw":2},
	"He":{"min_value":1, "max_value":INF, "value":1, "OP_factor":0.3},
	"O":{"min_value":1, "max_value":INF, "value":1, "OP_factor":0.5},
	"Ne":{"min_value":1, "max_value":INF, "value":1, "OP_factor":0.3},
	"Xe":{"min_value":0, "max_value":3, "value":0, "is_integer":true, "OP_factor":5, "pw":3},
}
func _ready():
	$ModifyDimension/Maths/Control/CostGrowthFactors/BUCGF.step = 0.0005
	$ModifyDimension/Maths/Control/CostGrowthFactors/ULUGF.step = 0.0005
	$ModifyDimension/Maths.rect_clip_content = true
	if game.c_u != -1 and game.help.has("flash_send_probe_btn") and game.universe_data[0].has("generated"):
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
		$ModifyDimension/Physics/Control/VBox2.add_child(univ_prop_text)
		univ_prop_text.name = univ_prop.name
	refresh_univs()
	refresh_OP_meters()
	$ModifyDimension/OPMeter/OPMeterText.help_text = tr("THE_OPMETER_DESC") % tr("MATHS")
	for i in range(1, game.subjects.dimensional_power.lv + 1):
		if $ModifyDimension/Dimensional_Power/Control.has_node("Label%s" % i):
			$ModifyDimension/Dimensional_Power/Control.get_node("Label%s" % i)["custom_colors/font_color"] = Color.white
		else:
			break
	set_grid()
	$ModifyDimension/Dimensional_Power/Control/TextureProgress.value = game.subjects.dimensional_power.lv + game.subjects.dimensional_power.DRs / (game.subjects.dimensional_power.lv + 1)
	for subj in $Subjects/Grid.get_children():
		subj.get_node("Effects/EffectButton").connect("pressed", self, "toggle_subj", [subj.name])

func refresh_OP_meters():
	for subj in ["Maths", "Physics", "Chemistry", "Biology", "Engineering"]:
		if game.subjects[subj.to_lower()].lv == 0:
			$Subjects/Grid.get_node(subj + "/OPMeter").visible = false
			continue
		$Subjects/Grid.get_node(subj + "/OPMeter").visible = true
		$Subjects/Grid.get_node(subj + "/OPMeter").value = self["%s_OP_points" % subj.to_lower()]
		$Subjects/Grid.get_node(subj + "/OPMeter").max_value = get_OP_cap(subj.to_lower())
	
func toggle_subj(subj_name:String):
	for subj in $Subjects/Grid.get_children():
		if subj.name != subj_name and $ModifyDimension.has_node(subj.name):
			$ModifyDimension.get_node(subj.name).visible = false
			$Subjects/Grid.get_node(subj.name + "/Selected").visible = false
			$Subjects/Grid.get_node(subj.name + "/Selected/AnimationPlayer").stop()
	if $ModifyDimension.has_node(subj_name):
		$ModifyDimension.get_node(subj_name).visible = not $ModifyDimension.get_node(subj_name).visible
		$Subjects/Grid.get_node(subj_name + "/Selected").visible = $ModifyDimension.get_node(subj_name).visible
		$Subjects/Grid.get_node(subj_name + "/Selected/AnimationPlayer").play("New Anim")
		$ModifyDimension/OPMeter.visible = $ModifyDimension.get_node(subj_name).visible and subj_name in ["Maths", "Physics", "Chemistry", "Biology", "Engineering"]
		if $ModifyDimension/OPMeter.visible:
			var subject:Dictionary = game.subjects[subj_name.to_lower()]
			$ModifyDimension/OPMeter/OPMeterText.help_text = tr("THE_OPMETER_DESC") % tr(subj_name.to_upper())
			$ModifyDimension/OPMeter/OPMeter.max_value = get_OP_cap(subj_name.to_lower())
			$ModifyDimension/OPMeter/OPMeter.value = self["%s_OP_points" % subj_name.to_lower()]
			calc_OP_points()
	else:
		$ModifyDimension/OPMeter.visible = false

func refresh_univs(reset:bool = false):
	DR_mult = 1 + 0.25 * game.subjects.dimensional_power.lv
	game.PD_panel.editable = reset
	if not reset:
		game.PD_panel.calc_OP_points()
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
		lv_sum += pow(univ.lv, 2.2)
	for node in $Subjects/Grid.get_children():
		node.get_node("HBox/Invest").disabled = game.DRs == 0
	new_dim_DRs = floor(lv_sum / 10000.0 * DR_mult)
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
	$ModifyDimension/Physics/Control/BI.set_value(game.physics_bonus.BI)
	$ModifyDimension/Physics/Control/BI.editable = reset
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
	for biology_bonus in game.biology_bonus:
		if $ModifyDimension/Biology/Control.has_node(biology_bonus):
			$ModifyDimension/Biology/Control.get_node(biology_bonus).set_value(game.biology_bonus[biology_bonus])
			$ModifyDimension/Biology/Control.get_node(biology_bonus).editable = reset
	$ModifyDimension/Biology/Control/Lake/Bonus.editable = reset
	for el in lake_params.keys():
		lake_params[el].value = game.biology_bonus[el]
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
			if subj.name in ["Maths", "Physics", "Chemistry", "Biology", "Engineering", "Dimensional_Power"]:
				subj.get_node("HBox/Invest").connect("pressed", self, "on_invest", [subj])
	$Universes.visible = not reset
	$UnivInfo.visible = not reset
	$ModifyDimension/Reset.visible = reset
	$TopInfo/Reset.visible = not reset
	calc_OP_points()

func set_grid():
	$Subjects/Grid.columns = 3 if game.subjects.dimensional_power.lv >= 2 else 2
	$Subjects/Grid/Physics.visible = game.subjects.dimensional_power.lv >= 2
	$Subjects/Grid/Chemistry.visible = game.subjects.dimensional_power.lv >= 2
	$Subjects/Grid/Biology.visible = game.subjects.dimensional_power.lv >= 2

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
		if $ModifyDimension.get_node(subj_node.name).visible:
			$ModifyDimension/OPMeter/OPMeter.max_value = get_OP_cap(subj_node.name.to_lower())
		if subj_node.name == "Dimensional_Power":
			set_grid()
			refresh_OP_meters()
			if $ModifyDimension/Maths.visible:
				$ModifyDimension/OPMeter/OPMeter.max_value = get_OP_cap("maths")
			elif $ModifyDimension/Physics.visible:
				$ModifyDimension/OPMeter/OPMeter.max_value = get_OP_cap("physics")
			elif $ModifyDimension/Chemistry.visible:
				$ModifyDimension/OPMeter/OPMeter.max_value = get_OP_cap("chemistry")
			elif $ModifyDimension/Biology.visible:
				$ModifyDimension/OPMeter/OPMeter.max_value = get_OP_cap("biology")
			elif $ModifyDimension/Engineering.visible:
				$ModifyDimension/OPMeter/OPMeter.max_value = get_OP_cap("engineering")
			$ModifyDimension/Dimensional_Power/Control/TextureProgress.value = subject.lv + subject.DRs / float(subject.lv + 1)
			if $ModifyDimension/Dimensional_Power/Control.has_node("Label%s" % subject.lv):
				$ModifyDimension/Dimensional_Power/Control.get_node("Label%s" % subject.lv)["custom_colors/font_color"] = Color.white
		subj_node.refresh(subject.DRs, subject.lv)
		

func on_univ_out():
	game.hide_tooltip()
	$UnivInfo.text = ""

func on_univ_over(id:int):
	var u_i = game.universe_data[id] #universe_info
	$UnivInfo.text = "%s (%s %s)\n%s: %s (%s)\n\n" % [u_i.name, tr("LEVEL"), u_i.lv, tr("DR_CONTRIBUTION"), Helper.clever_round(pow(u_i.lv, 2.2) / 10000.0 * DR_mult), tr("PLUS_X_IF").format({"bonus":Helper.clever_round((pow(u_i.lv + 1, 2.2) - pow(u_i.lv, 2.2)) / 10000.0 * DR_mult), "lv":u_i.lv+1})]
	$UnivInfo.text += tr("FUNDAMENTAL_PROPERTIES") + "\n"
	if id == 0:
		$UnivInfo.text += "%s c = %s m·s\u207B\u00B9\n%s h = %s J·s\n%s k = %s J·K\u207B\u00B9\n%s \u03C3 = %s W·m\u207B\u00B2·K\u207B\u2074\n%s G = %s m\u00B3·kg\u207B\u00B9·s\u207B\u00B2\n%s e = %s C\n%s: %s\n" % [
			tr("SPEED_OF_LIGHT"),
			Helper.e_notation(3e8),
			tr("PLANCK"),
			Helper.e_notation(6.626e-34),
			tr("BOLTZMANN"),
			Helper.e_notation(1.381e-23),
			tr("S_B_CTE"),
			Helper.e_notation(5.67e-8),
			tr("GRAVITATIONAL"),
			Helper.e_notation(6.674e-11),
			tr("CHARGE"),
			Helper.e_notation(1.6e-19),
			tr("AGE_OF_THE_UNIVERSE"),
			tr("DEFAULT_UNIVERSE_AGE"),
			]
	else:
		$UnivInfo.text += "%s: %sc\n%s: %sh\n%s: %sk\n%s: %s\u03C3\n%s: %sG\n%s: %se\n%s: %s x %s\n" % [
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
			tr("AGE_OF_THE_UNIVERSE"),
			u_i.age,
			tr("DEFAULT_UNIVERSE_AGE"),
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
#	if game.subjects.dimensional_power.lv > 2:
#		$UnivInfo.text += "\n%s: %s" % [tr("ANTIMATTER"), u_i.antimatter]
#	if game.subjects.dimensional_power.lv > 2:
#		$UnivInfo.text += "\n%s: %s" % [tr("UNIVERSE_VALUE"), u_i.universe_value]

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
	game.help.erase("flash_send_probe_btn")
	$Universes/SendProbes/AnimationPlayer.play("RESET")
	game.toggle_panel(game.send_probes_panel)

func _on_mouse_exited():
	game.hide_tooltip()

func _on_Reset_mouse_entered():
	if $TopInfo/Reset.disabled:
		game.show_tooltip(tr("DIM_RESET_CONDITIONS"))


func _on_Reset_pressed():
	if game.dim_num == 1:
		game.show_YN_panel("reset_dimension", tr("RESET_1ST_DIM_CONFIRM").format({"DRnumber":new_dim_DRs, "DRs":tr("DRs")}), [new_dim_DRs])
	else:
		game.show_YN_panel("reset_dimension", tr("RENEW_DIMENSION_CONFIRM"), [new_dim_DRs])

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
	num_errors.clear()
	chemistry_OP_points = 0
	if game.PD_panel.error:
		num_errors.chemistry = true
	for el_node in $ModifyDimension/Chemistry/Control/OPMeters.get_children():
		var el:String = el_node.name
		el_node.text = "+ " + str(Helper.clever_round(game.PD_panel.op_points[el]))
		chemistry_OP_points += game.PD_panel.op_points[el]
	maths_OP_points = 0
	calc_math_points($ModifyDimension/Maths/Control/CostGrowthFactors/BUCGF, 1.3, -3.0, 1.2)#Building upgrade cost
	calc_math_points($ModifyDimension/Maths/Control/CostGrowthFactors/MUCGF_MV, 1.9, -6.0, 1.2)#Mineral value
	calc_math_points($ModifyDimension/Maths/Control/CostGrowthFactors/MUCGF_MSMB, 1.6, -1.5, 1.2)#Mining speed multiplier
	calc_math_points($ModifyDimension/Maths/Control/CostGrowthFactors/MUCGF_AIE, 2.3, -10.0, 1.5)#Aurora intensity exponent
	calc_math_points($ModifyDimension/Maths/Control/IRM, 1.2, 180.0, 1.0, 3.0)#Infinite research
	calc_math_points($ModifyDimension/Maths/Control/CostGrowthFactors/SLUGF_XP, 1.3, -10.0, 1.1)#Ship level up XP
	calc_math_points($ModifyDimension/Maths/Control/CostGrowthFactors/SLUGF_Stats, 1.15, 200.0, 1.0, 3.0)#Ship stats
	calc_math_points($ModifyDimension/Maths/Control/COSHEF, 1.5, 0.3)#Chance of ship hitting enemy
	calc_math_points($ModifyDimension/Maths/Control/MMBSVR, 10, -50.0, 2)#Material metal buy/sell
	calc_math_points($ModifyDimension/Maths/Control/CostGrowthFactors/ULUGF, 1.63, -40.0, 1.15)#Universe level XP

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
	else:
		$ModifyDimension/Physics/Control/MVOUP["custom_colors/font_color"] = Color.black
		physics_OP_points += 0.5 / min($ModifyDimension/Physics/Control/MVOUP.value, 0.5) - 1.0
	if $ModifyDimension/Physics/Control/BI.value < 0:
		$ModifyDimension/Physics/Control/BI["custom_colors/font_color"] = Color.red
		num_errors.physics = true
	else:
		$ModifyDimension/Physics/Control/BI["custom_colors/font_color"] = Color.black
		physics_OP_points += pow(max(0, 9.0 * ($ModifyDimension/Physics/Control/BI.value - 0.3)), 1.5)
	physics_defaults.get_node("MVOUP").visible = not is_equal_approx($ModifyDimension/Physics/Control/MVOUP.value, float(physics_defaults.get_node("MVOUP").text.right(1)))
	physics_defaults.get_node("BI").visible = not is_equal_approx($ModifyDimension/Physics/Control/BI.value, float(physics_defaults.get_node("BI").text.right(1)))
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
	
	biology_OP_points = 0
	calc_bio_points($ModifyDimension/Biology/Control/PGSM, 0.4)
	calc_bio_points($ModifyDimension/Biology/Control/PYM, 0.6)
	if selected_element != "":
		lake_params[selected_element].value = float($ModifyDimension/Biology/Control/Lake/Bonus.value)
		update_lake_bonus_text(selected_element)
	for el in lake_params.keys():
		calc_bio_points_lake(lake_params[el])
	
	engineering_OP_points = 0
	calc_engi_points($ModifyDimension/Engineering/Control/BCM, 7.0, false)
	calc_engi_points($ModifyDimension/Engineering/Control/PS, 0.15, true)
	calc_engi_points($ModifyDimension/Engineering/Control/RSM, 0.4, true)
	for subj in ["Maths", "Physics", "Chemistry", "Biology", "Engineering"]:
		if $ModifyDimension.get_node(subj).visible:
			if is_zero_approx(self["%s_OP_points" % subj.to_lower()]):
				self["%s_OP_points" % subj.to_lower()] = 0
			$ModifyDimension/OPMeter/OPMeter.value = self["%s_OP_points" % subj.to_lower()]
			$ModifyDimension/OPMeter/TooOP.text = "%s / %s" % [Helper.clever_round(self["%s_OP_points" % subj.to_lower()]), $ModifyDimension/OPMeter/OPMeter.max_value]
			if self["%s_OP_points" % subj.to_lower()] > $ModifyDimension/OPMeter/OPMeter.max_value:
				$Subjects/Grid.get_node(subj + "/Effects")["custom_colors/font_color"] = Color(0.8, 0, 0)
				num_errors[subj.to_lower()] = true
				$ModifyDimension/OPMeter/TooOP.text += " - %s" % tr("TOO_OP")
			else:
				$Subjects/Grid.get_node(subj + "/Effects")["custom_colors/font_color"] = Color(0.8, 0, 0) if num_errors.has(subj.to_lower()) else Color.white
		else:
			if self["%s_OP_points" % subj.to_lower()] > get_OP_cap(subj.to_lower()):
				num_errors[subj.to_lower()] = true
	refresh_OP_meters()
	if $ModifyDimension/Reset.visible:
		$ModifyDimension/Reset/Generate.visible = true
		var disable_button = false
		for subj in ["Maths", "Physics", "Chemistry", "Biology", "Engineering"]:
			if num_errors.has(subj.to_lower()) and $Subjects/Grid.get_node(subj).visible:
				disable_button = true
				break
		$ModifyDimension/Reset/Generate.disabled = disable_button

func get_OP_cap(subj:String):
	var OP_cap_mult:float = 1 + 0.15 * game.subjects.dimensional_power.lv
	return game.subjects[subj].lv * (1.5 if game.subjects.dimensional_power.lv >= 3 else 1.0) * OP_cap_mult

func calc_bio_points(node, op_factor:float):
	if node.value < node.min_value:
		node["custom_colors/font_color"] = Color.red
		num_errors.biology = true
		return
	else:
		node["custom_colors/font_color"] = Color.black
		biology_OP_points += op_factor * (node.value - 1.0)

func calc_bio_points_lake(lake:Dictionary):
	if lake.value < lake.min_value:
		num_errors.biology = true
		$ModifyDimension/Biology/Control/Lake/Bonus["custom_colors/font_color"] = Color.red
		return
	else:
		if lake.has("pw"):
			biology_OP_points += lake.OP_factor * pow(lake.value - lake.min_value, lake.pw)
		else:
			biology_OP_points += lake.OP_factor * (lake.value - lake.min_value)
		$ModifyDimension/Biology/Control/Lake/Bonus["custom_colors/font_color"] = Color.black

func calc_engi_points(node, op_factor:float, growth:bool):
	if node.value <= node.min_value:
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
		if bonus in ["MVOUP", "BI"]:
			game.physics_bonus[bonus] = $ModifyDimension/Physics/Control.get_node(bonus).value
		elif bonus != "antimatter":
			game.physics_bonus[bonus] = $ModifyDimension/Physics/Control/VBox.get_node(bonus).value
	for bonus in game.biology_bonus:
		if $ModifyDimension/Biology/Control.has_node(bonus):
			game.biology_bonus[bonus] = $ModifyDimension/Biology/Control.get_node(bonus).value
		elif $ModifyDimension/Biology/Control/LakeButtons.has_node(bonus):
			game.biology_bonus[bonus] = lake_params[bonus].value
	for bonus in game.engineering_bonus:
		game.engineering_bonus[bonus] = $ModifyDimension/Engineering/Control.get_node(bonus).value

func _on_Generate_pressed():
	game.show_YN_panel("generate_new_univ", tr("GENERATE_STARTING_UNIVERSE_CONFIRM"))


func _on_text_mouse_entered(text:String):
	game.show_tooltip(tr(text))

var DR_help_index:int = 1

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "FadeOut":
		$ColorRect.visible = false
	else:
		show_DR_help()
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
	game.show_tooltip(tr("COST_GROWTH_FACTOR_DESC"))


func _on_ShipHitChance_mouse_entered():
	game.show_tooltip(tr("SHIP_HIT_FORMULA"))

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


func _on_HelpLabel_mouse_entered(extra_arg_0):
	game.show_tooltip(extra_arg_0)


func _on_Lake_mouse_entered(extra_arg_0):
	game.show_tooltip(tr("%s_NAME" % extra_arg_0))

func _on_Lake_pressed(el:String):
	selected_element = el
	$ModifyDimension/Biology/Control/Lake.visible = true
	$ModifyDimension/Biology/Control/Lake/Operator.text = Data.lake_bonus_values[el].operator
	update_lake_bonus_text(el)
	$ModifyDimension/Biology/Control/Lake/Bonus.min_value = lake_params[el].min_value
	$ModifyDimension/Biology/Control/Lake/Bonus.max_value = lake_params[el].max_value
	$ModifyDimension/Biology/Control/Lake/Bonus.is_integer = lake_params[el].has("is_integer")
	$ModifyDimension/Biology/Control/Lake/Bonus.step = 1.0 if lake_params[el].has("is_integer") else 0.2
	$ModifyDimension/Biology/Control/Lake/Bonus.set_value(lake_params[el].value)

func update_lake_bonus_text(el:String):
	if Data.lake_bonus_values[el].operator == "x":
		$ModifyDimension/Biology/Control/Lake/LakeDesc.bbcode_text = tr("%s_LAKE_BONUS" % el.to_upper()) % ("[color=#aeddff]%s[/color]/[color=#c6ffcc]%s[/color]/%s" % [Helper.clever_round(Data.lake_bonus_values[el].s * lake_params[el].value), Helper.clever_round(Data.lake_bonus_values[el].l * lake_params[el].value), Helper.clever_round(Data.lake_bonus_values[el].sc * lake_params[el].value)])
	elif Data.lake_bonus_values[el].operator == "+":
		$ModifyDimension/Biology/Control/Lake/LakeDesc.bbcode_text = tr("%s_LAKE_BONUS" % el.to_upper()) % ("[color=#aeddff]%s[/color]/[color=#c6ffcc]%s[/color]/%s" % [Data.lake_bonus_values[el].s + lake_params[el].value, Data.lake_bonus_values[el].l + lake_params[el].value, Data.lake_bonus_values[el].sc + lake_params[el].value])
	elif Data.lake_bonus_values[el].operator == "÷":
		$ModifyDimension/Biology/Control/Lake/LakeDesc.bbcode_text = tr("%s_LAKE_BONUS" % el.to_upper()) % ("[color=#aeddff]%s[/color]/[color=#c6ffcc]%s[/color]/%s" % [Helper.clever_round(Data.lake_bonus_values[el].s / lake_params[el].value), Helper.clever_round(Data.lake_bonus_values[el].l / lake_params[el].value), Helper.clever_round(Data.lake_bonus_values[el].sc / lake_params[el].value)])

func _on_LakePD_pressed(el:String):
	game.PD_panel.el = el
	game.toggle_panel(game.PD_panel)


func _on_LakeDesc_mouse_entered():
	game.show_adv_tooltip("[color=#aeddff]" + tr("SOLID") + "[/color]/[color=#c6ffcc]" + tr("LIQUID") + "[/color]/" + tr("SUPERCRITICAL"))


func _on_LakeDesc_mouse_exited():
	game.hide_adv_tooltip()


func _on_BSlider_value_changed(value):
	$ModifyDimension/Physics/Control/PDFPlotter.B = value
	$ModifyDimension/Physics/Control/B.text = "for B = %s nT" % Helper.clever_round(value)
	$ModifyDimension/Physics/Control/PDFPlotter.add_points()


func _on_BI_value_changed(value):
	$ModifyDimension/Physics/Control/PDFPlotter.p = float(value)
	$ModifyDimension/Physics/Control/PDFPlotter.add_points()


func _on_EffectsHelp_mouse_entered():
	game.show_tooltip(tr("DIM_POWER_EFFECTS"))
