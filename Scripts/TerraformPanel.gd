extends "Panel.gd"

var tf_costs:Dictionary = {}
var tf_type = ""
var costs:Dictionary = {}
var pressure:float
var tile_num:int
var surface:float
var lake_num:int
var p_i:Dictionary
var cost_div:float

func _ready():
	set_polygon(rect_size)

func refresh():
	p_i = game.planet_data[game.c_p]
	cost_div = Helper.clever_round(p_i.cost_div) if p_i.has("cost_div") else 1.0
	$ScrollContainer/VBoxContainer/AtmosphereExtraction.visible = game.science_unlocked.has("ATM")
	$ScrollContainer/VBoxContainer/AtomManipulation.visible = game.science_unlocked.has("ATM")
	$ScrollContainer/VBoxContainer/SubatomicParticles.visible = game.science_unlocked.has("SAP")
	$ScrollContainer/VBoxContainer/NeutronStorage.visible = game.science_unlocked.has("SAP")
	$ScrollContainer/VBoxContainer/ElectronStorage.visible = game.science_unlocked.has("SAP")
	if tf_type != "":
		call("_on_%s_pressed" % tf_type)

func update_info():
	tf_costs = {"SP":2}
	var pressure_mult = max(1, pressure)
	var lake_mult = 1 + 9 * lake_num / float(tile_num)
	for cost in tf_costs:
		tf_costs[cost] *= surface * pressure_mult * lake_mult
	costs.erase("time")
	for cost in costs:
		costs[cost] *= surface * game.engineering_bonus.BCM / cost_div
	var gradient:Gradient = preload("res://Resources/IntensityGradient.tres")
	var pressure_mult_color = gradient.interpolate(inverse_lerp(1.0, 100.0, pressure_mult)).to_html(false)
	var lake_mult_color = gradient.interpolate(inverse_lerp(1.0, 10.0, lake_mult)).to_html(false)
	$Panel/CostMult.bbcode_text = "%s:\n%s: x %s\n[color=#%s]%s: x %s[/color]\n[color=#%s]%s: x %s[/color]" % [tr("TF_COST_MULT"), tr("SURFACE_AREA"), Helper.format_num(surface), pressure_mult_color, tr("ATMOSPHERE_PRESSURE"), Helper.clever_round(pressure_mult), lake_mult_color, tr("LAKES"), Helper.clever_round(lake_mult)]
	Helper.put_rsrc($Panel/TCVBox, 32, tf_costs, true, true)
	Helper.put_rsrc($Panel/BCVBox, 32, costs, true, true)
	$Panel.visible = true

func set_bldg_cost_txt():
	if cost_div > 1.0:
		$Panel/BuildingCosts.text = "%s (%s %s) (%s)" % [tr("BUILDING_COSTS"), Helper.format_num(surface), tr("%s_NAME_S" % tf_type).to_lower(), tr("CBD_PATH_1") % cost_div]
	else:
		$Panel/BuildingCosts.text = "%s (%s %s)" % [tr("BUILDING_COSTS"), Helper.format_num(surface), tr("%s_NAME_S" % tf_type).to_lower()]

func _on_MS_pressed():
	tf_type = "MS"
	set_bldg_cost_txt()
	costs = Data.costs.MS.duplicate(true)
	$Panel/Note.visible = false
	update_info()

func _on_AE_pressed():
	tf_type = "AE"
	set_bldg_cost_txt()
	costs = Data.costs.AE.duplicate(true)
	$Panel/Note.visible = false
	update_info()

func _on_MM_pressed():
	tf_type = "MM"
	set_bldg_cost_txt()
	costs = Data.costs.MM.duplicate(true)
	$Panel/Note.visible = true
	update_info()

func _on_GH_pressed():
	tf_type = "GH"
	set_bldg_cost_txt()
	costs = Data.costs.GH.duplicate(true)
	costs.soil = 10
	$Panel/Note.visible = false
	update_info()


func _on_Terraform_pressed():
	var total_costs = costs.duplicate(true)
	for cost in tf_costs:
		if total_costs.has(cost):
			total_costs[cost] += tf_costs[cost]
		else:
			total_costs[cost] = tf_costs[cost]
	if game.check_enough(total_costs):
		game.toggle_panel(self)
		game.deduct_resources(total_costs)
		if p_i.has("bookmarked"):
			game.bookmarks.planet.erase(str(game.c_p_g))
			game.HUD.planet_grid_btns.remove_child(game.HUD.planet_grid_btns.get_node(str(game.c_p_g)))
			p_i.erase("bookmarked")
		p_i.tile_num = surface
		game.stats_univ.bldgs_built += floor(surface)
		game.stats_dim.bldgs_built += floor(surface)
		game.stats_global.bldgs_built += floor(surface)
		p_i.bldg = {}
		p_i.bldg.name = tf_type
		p_i.bldg.is_constructing = false
		game.universe_data[game.c_u].xp += round(total_costs.money / 100.0)
		p_i.bldg.path_1 = 1
		p_i.bldg.path_1_value = Data.path_1[tf_type].value
		if tf_type in ["MM", "GH", "AE", "ME", "PP", "AMN", "SPR"]:
			p_i.bldg.path_2 = 1
			p_i.bldg.path_2_value = Data.path_2[tf_type].value
		if tf_type in ["MM", "AE", "PP", "ME"]:
			p_i.bldg.collect_date = OS.get_system_time_msecs()
			p_i.bldg.stored = 0
		if tf_type == "RL":
			game.autocollect.rsrc.SP += Data.path_1.RL.value * surface
		elif tf_type == "MS":
			game.mineral_capacity += Data.path_1.MS.value * surface
		elif tf_type == "NSF":
			game.neutron_cap += Data.path_1.NSF.value * surface
		elif tf_type == "ESF":
			game.electron_cap += Data.path_1.ESF.value * surface
		elif tf_type == "MM" and not p_i.has("depth"):
			p_i.depth = 0
		if Helper.has_IR(tf_type):
			p_i.bldg.IR_mult = Helper.get_IR_mult(p_i.bldg.name)
		else:
			p_i.bldg.IR_mult = 1
		if p_i.has("autocollect"):
			if tf_type == "ME":
				game.autocollect.rsrc.minerals += Data.path_1[tf_type].value
			elif tf_type == "PP":
				game.autocollect.rsrc.energy += Data.path_1[tf_type].value
		game.switch_view("system")
		var dir = Directory.new()
		dir.remove("user://%s/Univ%s/Planets/%s.hx3" % [game.c_sv, game.c_u, game.c_p_g])
		game.popup(tr("TF_SUCCESS"), 2)
		if not game.objective.empty() and game.objective.type == game.ObjectiveType.TERRAFORM:
			game.objective.current += 1
		game.HUD.refresh()
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.2)


func _on_PP_pressed():
	tf_type = "PP"
	set_bldg_cost_txt()
	costs = Data.costs.PP.duplicate(true)
	$Panel/Note.visible = false
	update_info()


func _on_ME_pressed():
	tf_type = "ME"
	set_bldg_cost_txt()
	costs = Data.costs.ME.duplicate(true)
	$Panel/Note.visible = false
	update_info()


func _on_RL_pressed():
	tf_type = "RL"
	set_bldg_cost_txt()
	costs = Data.costs.RL.duplicate(true)
	$Panel/Note.visible = false
	update_info()


func _on_AMN_pressed():
	tf_type = "AMN"
	set_bldg_cost_txt()
	costs = Data.costs.AMN.duplicate(true)
	$Panel/Note.visible = false
	update_info()


func _on_SPR_pressed():
	tf_type = "SPR"
	set_bldg_cost_txt()
	costs = Data.costs.SPR.duplicate(true)
	$Panel/Note.visible = false
	update_info()


func _on_NSF_pressed():
	tf_type = "NSF"
	set_bldg_cost_txt()
	costs = Data.costs.NSF.duplicate(true)
	$Panel/Note.visible = false
	update_info()


func _on_ESF_pressed():
	tf_type = "ESF"
	set_bldg_cost_txt()
	costs = Data.costs.ESF.duplicate(true)
	$Panel/Note.visible = false
	update_info()
