extends "Panel.gd"

var tf_costs:Dictionary = {}
var tf_type = ""
var costs:Dictionary = {}
var pressure:float
var tile_num:int
var surface:float
var lake_num:int
var ash_mult:float
var p_i:Dictionary
var cost_div:float
var unique_bldg_str:String
var unique_bldg_bonus:float
var unique_bldg_bonus_cap:float

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
	Helper.put_rsrc($Panel/BCGrid, 32, costs, true, true)
	$Panel.visible = true

func set_bldg_cost_txt():
	unique_bldg_str = ""
	if cost_div > 1.0:
		$Panel/BuildingCosts.text = "%s (%s) (%s %s)" % [tr("BUILDING_COSTS"), tr("DIV_BY") % cost_div, Helper.format_num(surface), tr("%s_NAME_S" % tf_type).to_lower()]
	else:
		$Panel/BuildingCosts.text = "%s (%s %s)" % [tr("BUILDING_COSTS"), Helper.format_num(surface), tr("%s_NAME_S" % tf_type).to_lower()]


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
		for id in len(game.tile_data):
			if game.tile_data[id] and game.tile_data[id].has("bldg"):
				game.view.obj.destroy_bldg(id, true)
		p_i.tile_num = surface
		game.stats_univ.bldgs_built += floor(surface)
		game.stats_dim.bldgs_built += floor(surface)
		game.stats_global.bldgs_built += floor(surface)
		p_i.bldg = {}
		p_i.bldg.name = tf_type
		p_i.bldg.erase("is_constructing")
		game.universe_data[game.c_u].xp += round(total_costs.money / 100.0)
		p_i.bldg.path_1 = 1
		p_i.bldg.path_1_value = Data.path_1[tf_type].value
		if unique_bldg_str in ["mineral_replicator", "observatory", "substation", "mining_outpost"]:
			p_i[unique_bldg_str + "_bonus"] = unique_bldg_bonus
			if unique_bldg_str == "substation":
				p_i.unique_bldg_bonus_cap = unique_bldg_bonus_cap
				game.capacity_bonus_from_substation += Data.path_1.PP.value * surface * p_i.unique_bldg_bonus_cap
		elif unique_bldg_str == "nuclear_fusion_reactor":
			for nfr in p_i.unique_bldgs.nuclear_fusion_reactor:
				if not nfr.has("repair_cost"):
					Helper.add_energy_from_NFR(p_i, p_i.bldg.path_1_value * Helper.get_NFR_prod_mult(nfr.tier))
		elif unique_bldg_str == "cellulose_synthesizer":
			for cs in p_i.unique_bldgs.cellulose_synthesizer:
				if not cs.has("repair_cost"):
					Helper.add_energy_from_CS(p_i, p_i.bldg.path_1_value * Helper.get_CS_prod_mult(cs.tier))
		if tf_type in ["GH", "AMN", "SPR"]:
			p_i.bldg.path_2 = 1
			p_i.bldg.path_2_value = Data.path_2[tf_type].value
		if tf_type == "RL":
			game.autocollect.rsrc.SP += Data.path_1.RL.value * surface * p_i.get("observatory_bonus", 1)
		elif tf_type == "GH":
			p_i.ash = {"richness":ash_mult}
		elif tf_type == "PP":
			game.autocollect.rsrc.energy += Data.path_1.PP.value * surface * p_i.get("substation_bonus", 1)
		elif tf_type == "ME":
			game.autocollect.rsrc.minerals += Data.path_1.ME.value * surface * p_i.get("mineral_replicator_bonus", 1)
			p_i.ash = {"richness":ash_mult}
		elif tf_type == "MS":
			game.mineral_capacity += Data.path_1.MS.value * surface
		elif tf_type == "B":
			game.energy_capacity += Data.path_1.B.value * surface
		elif tf_type == "NSF":
			game.neutron_cap += Data.path_1.NSF.value * surface
		elif tf_type == "ESF":
			game.electron_cap += Data.path_1.ESF.value * surface
		elif tf_type == "AE":
			for el in p_i.atmosphere:
				var base_prod:float = p_i.bldg.path_1_value * p_i.atmosphere[el] * p_i.pressure * surface
				game.show[el] = true
				Helper.add_atom_production(el, base_prod)
		elif tf_type == "MM" and not p_i.has("depth"):
			p_i.depth = 0
			p_i.bldg.collect_date = OS.get_system_time_msecs()
			game.MM_data[game.c_p_g] = {"c_s_g":game.c_s_g, "c_p":game.c_p}
		game.view_history.pop_back()
		game.view_history_pos -= 1
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
	var st = ""
	if p_i.unique_bldgs.has("substation"):
		unique_bldg_bonus = 0
		unique_bldg_bonus_cap = 0
		var n_total = 0
		for sub in p_i.unique_bldgs.substation:
			if not sub.has("repair_cost"):
				var n = (pow(Helper.get_unique_bldg_area(sub.tier), 2) - 1)
				unique_bldg_bonus += Helper.get_substation_prod_mult(sub.tier) * n
				unique_bldg_bonus_cap += Helper.get_substation_capacity_bonus(sub.tier) * n
				n_total += n
		unique_bldg_bonus += len(game.tile_data) - n_total
		unique_bldg_bonus /= len(game.tile_data)
		if unique_bldg_bonus > 1:
			unique_bldg_str = "substation"
		unique_bldg_bonus_cap /= len(game.tile_data)
		st += tr("ENERGY_MULT_FROM_SUBSTATION") + " " + str(Helper.clever_round(unique_bldg_bonus))
		st += "\n" + tr("ENERGY_STORAGE_BONUS_FROM_SUBSTATION") % Helper.time_to_str(unique_bldg_bonus_cap * 1000)
	$Panel/Note.text = st
	update_info()


func _on_ME_pressed():
	tf_type = "ME"
	set_bldg_cost_txt()
	costs = Data.costs.ME.duplicate(true)
	var st = ""
	if p_i.unique_bldgs.has("mineral_replicator"):
		unique_bldg_bonus = 0
		var n_total = 0
		for mr in p_i.unique_bldgs.mineral_replicator:
			if not mr.has("repair_cost"):
				var n = (pow(Helper.get_unique_bldg_area(mr.tier), 2) - 1)
				unique_bldg_bonus += Helper.get_MR_Obs_Outpost_prod_mult(mr.tier) * n
				n_total += n
		unique_bldg_bonus += len(game.tile_data) - n_total
		unique_bldg_bonus /= len(game.tile_data)
		if unique_bldg_bonus > 1:
			unique_bldg_str = "mineral_replicator"
		st += tr("MIN_MULT_FROM_MR") + " " + str(Helper.clever_round(unique_bldg_bonus))
	if ash_mult > 1:
		st += "\n" + tr("MIN_MULT_FROM_ASH") % ash_mult
	$Panel/Note.text = st
	update_info()


func _on_RL_pressed():
	tf_type = "RL"
	set_bldg_cost_txt()
	costs = Data.costs.RL.duplicate(true)
	var st = ""
	if p_i.unique_bldgs.has("observatory"):
		unique_bldg_bonus = 0
		var n_total = 0
		for obs in p_i.unique_bldgs.observatory:
			if not obs.has("repair_cost"):
				var n = (pow(Helper.get_unique_bldg_area(obs.tier), 2) - 1)
				unique_bldg_bonus += Helper.get_MR_Obs_Outpost_prod_mult(obs.tier) * n
				n_total += n
		unique_bldg_bonus += len(game.tile_data) - n_total
		unique_bldg_bonus /= len(game.tile_data)
		if unique_bldg_bonus > 1:
			unique_bldg_str = "observatory"
		st += tr("SP_MULT_FROM_OBS") + " " + str(Helper.clever_round(unique_bldg_bonus))
	$Panel/Note.text = st
	update_info()


func _on_AMN_pressed():
	tf_type = "AMN"
	set_bldg_cost_txt()
	costs = Data.costs.AMN.duplicate(true)
	$Panel/Note.text = ""
	update_info()


func _on_SPR_pressed():
	tf_type = "SPR"
	set_bldg_cost_txt()
	costs = Data.costs.SPR.duplicate(true)
	$Panel/Note.text = ""
	update_info()


func _on_NSF_pressed():
	tf_type = "NSF"
	set_bldg_cost_txt()
	costs = Data.costs.NSF.duplicate(true)
	$Panel/Note.text = ""
	update_info()


func _on_ESF_pressed():
	tf_type = "ESF"
	set_bldg_cost_txt()
	costs = Data.costs.ESF.duplicate(true)
	$Panel/Note.text = ""
	update_info()


func _on_B_pressed():
	tf_type = "B"
	set_bldg_cost_txt()
	costs = Data.costs.B.duplicate(true)
	$Panel/Note.text = ""
	update_info()

func _on_MS_pressed():
	tf_type = "MS"
	set_bldg_cost_txt()
	costs = Data.costs.MS.duplicate(true)
	$Panel/Note.text = ""
	update_info()

func _on_AE_pressed():
	tf_type = "AE"
	set_bldg_cost_txt()
	costs = Data.costs.AE.duplicate(true)
	var st = ""
	if p_i.unique_bldgs.has("nuclear_fusion_reactor"):
		var needs_repair = false
		for nfr in p_i.unique_bldgs.nuclear_fusion_reactor:
			if nfr.has("repair_cost"):
				needs_repair = true
				break
		if needs_repair:
			st += tr("REPAIR_NFR_TO_GET_ENERGY")
		else:
			st += tr("WILL_PROVIDE_EXTRA_ENERGY")
			unique_bldg_str = "nuclear_fusion_reactor"
		st += "\n"
	if p_i.unique_bldgs.has("cellulose_synthesizer"):
		var needs_repair = false
		for cs in p_i.unique_bldgs.cellulose_synthesizer:
			if cs.has("repair_cost"):
				needs_repair = true
				break
		if needs_repair:
			st += tr("REPAIR_CS_TO_GET_CELLULOSE")
		else:
			st += tr("WILL_PROVIDE_EXTRA_CELLULOSE")
			unique_bldg_str = "cellulose_synthesizer"
	$Panel/Note.text = st
	update_info()

func _on_MM_pressed():
	tf_type = "MM"
	set_bldg_cost_txt()
	costs = Data.costs.MM.duplicate(true)
	var st = ""
	if p_i.unique_bldgs.has("mining_outpost"):
		unique_bldg_bonus = 0
		var n_total = 0
		for sub in p_i.unique_bldgs.mining_outpost:
			if not sub.has("repair_cost"):
				var n = (pow(Helper.get_unique_bldg_area(sub.tier), 2) - 1)
				unique_bldg_bonus += Helper.get_MR_Obs_Outpost_prod_mult(sub.tier) * n
				n_total += n
		unique_bldg_bonus += len(game.tile_data) - n_total
		unique_bldg_bonus /= len(game.tile_data)
		if unique_bldg_bonus > 1:
			unique_bldg_str = "mining_outpost"
		st += tr("MINING_MULT_FROM_OUTPOST") + " " + str(Helper.clever_round(unique_bldg_bonus))
	$Panel/Note.text = st
	update_info()

func _on_GH_pressed():
	tf_type = "GH"
	set_bldg_cost_txt()
	costs = Data.costs.GH.duplicate(true)
	costs.soil = 10
	$Panel/Note.text = tr("MIN_MULT_FROM_ASH") % ash_mult
	update_info()
