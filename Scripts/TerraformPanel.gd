extends "Panel.gd"

var tf_costs:Dictionary = {}
var tf_type:int = -1
var costs:Dictionary = {}
var total_costs:Dictionary
var pressure:float
var tile_num:int
var surface:float
var lake_num:int
var ash_mult:float
var SP_feature_mult:float
var energy_feature_mult:float
var p_i:Dictionary
var cost_div:float
var unique_bldg_id:int
var unique_bldg_bonus:float
var unique_bldg_bonus_cap:float

func _ready():
	set_polygon(size)

func refresh():
	p_i = game.planet_data[game.c_p]
	cost_div = Helper.clever_round(p_i.cost_div) if p_i.has("cost_div") else 1.0
	$ScrollContainer/VBoxContainer/AtmosphereExtraction.visible = game.science_unlocked.has("ATM")
	$ScrollContainer/VBoxContainer/AtomManipulation.visible = game.science_unlocked.has("ATM")
	$ScrollContainer/VBoxContainer/SubatomicParticles.visible = game.science_unlocked.has("SAP")
	if tf_type != -1:
		call("_on_%s_pressed" % Building.names[tf_type])

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
	var pressure_mult_color = gradient.sample(inverse_lerp(1.0, 100.0, pressure_mult)).to_html(false)
	var lake_mult_color = gradient.sample(inverse_lerp(1.0, 10.0, lake_mult)).to_html(false)
	$Panel/CostMult.text = "%s:\n%s: x %s\n[color=#%s]%s: x %s[/color]\n[color=#%s]%s: x %s[/color]" % [tr("TF_COST_MULT"), tr("SURFACE_AREA"), Helper.format_num(surface), pressure_mult_color, tr("ATMOSPHERE_PRESSURE"), Helper.clever_round(pressure_mult), lake_mult_color, tr("LAKES"), Helper.clever_round(lake_mult)]
	Helper.put_rsrc($Panel/TCVBox, 32, tf_costs, true, true)
	Helper.put_rsrc($Panel/BCGrid, 32, costs, true, true)
	$Panel.visible = true

func set_bldg_cost_txt():
	unique_bldg_id = -1
	if cost_div > 1.0:
		$Panel/BuildingCosts.text = "%s (%s) (%s %s)" % [tr("BUILDING_COSTS"), tr("DIV_BY") % cost_div, Helper.format_num(surface), tr("%s_NAME_S" % Building.names[tf_type].to_upper()).to_lower()]
	else:
		$Panel/BuildingCosts.text = "%s (%s %s)" % [tr("BUILDING_COSTS"), Helper.format_num(surface), tr("%s_NAME_S" % Building.names[tf_type].to_upper()).to_lower()]

func terraform_planet():
	game.toggle_panel(self)
	game.deduct_resources(total_costs)
	if p_i.has("bookmarked"):
		game.bookmarks.planet.erase(str(game.c_p_g))
		p_i.erase("bookmarked")
		game.HUD.refresh_bookmarks()
	for id in len(game.tile_data):
		if game.tile_data[id] and game.tile_data[id].has("bldg"):
			game.view.obj.destroy_bldg(id, true)
	p_i.tile_num = surface
	game.stats_univ.bldgs_built += floor(surface)
	game.stats_dim.bldgs_built += floor(surface)
	game.stats_global.bldgs_built += floor(surface)
	p_i.resource_production_bonus = {}
	p_i.bldg = {}
	p_i.bldg.name = tf_type
	p_i.bldg.erase("is_constructing")
	game.universe_data[game.c_u].xp += round(total_costs.money / 100.0)
	p_i.bldg.path_1 = 1
	p_i.bldg.path_1_value = Data.path_1[tf_type].value
	var building_to_resource = {
		UniqueBuilding.MINERAL_REPLICATOR:"minerals",
		UniqueBuilding.OBSERVATORY:"SP",
		UniqueBuilding.SUBSTATION:"energy",
	}
	if unique_bldg_id in [UniqueBuilding.MINERAL_REPLICATOR, UniqueBuilding.OBSERVATORY, UniqueBuilding.SUBSTATION, UniqueBuilding.MINING_OUTPOST]:
		p_i.resource_production_bonus[building_to_resource[unique_bldg_id]] = unique_bldg_bonus
		if unique_bldg_id == UniqueBuilding.SUBSTATION:
			p_i.unique_bldg_bonus_cap = unique_bldg_bonus_cap
			game.capacity_bonus_from_substation += Data.path_1[Building.POWER_PLANT].value * surface * p_i.unique_bldg_bonus_cap
	elif unique_bldg_id == UniqueBuilding.NUCLEAR_FUSION_REACTOR:
		for nfr in p_i.unique_bldgs[UniqueBuilding.NUCLEAR_FUSION_REACTOR]:
			if not nfr.has("repair_cost"):
				Helper.add_energy_from_NFR(p_i, p_i.bldg.path_1_value * Helper.get_NFR_prod_mult(nfr.tier))
	elif unique_bldg_id == UniqueBuilding.CELLULOSE_SYNTHESIZER:
		for cs in p_i.unique_bldgs[UniqueBuilding.CELLULOSE_SYNTHESIZER]:
			if not cs.has("repair_cost"):
				Helper.add_energy_from_CS(p_i, p_i.bldg.path_1_value * Helper.get_CS_prod_mult(cs.tier))
	if tf_type in [Building.GREENHOUSE, Building.ATOM_MANIPULATOR, Building.SUBATOMIC_PARTICLE_REACTOR]:
		p_i.bldg.path_2 = 1
		p_i.bldg.path_2_value = Data.path_2[tf_type].value
	if tf_type == Building.RESEARCH_LAB:
		game.autocollect.rsrc.SP += Data.path_1[Building.RESEARCH_LAB].value * surface * p_i.resource_production_bonus.get("SP", 1)
	elif tf_type == Building.GREENHOUSE:
		p_i.ash = {"richness":ash_mult}
	elif tf_type == Building.POWER_PLANT:
		game.autocollect.rsrc.energy += Data.path_1[Building.POWER_PLANT].value * surface * p_i.resource_production_bonus.get("energy", 1)
	elif tf_type == Building.MINERAL_EXTRACTOR:
		game.autocollect.rsrc.minerals += Data.path_1[Building.MINERAL_EXTRACTOR].value * surface * p_i.resource_production_bonus.get("minerals", 1)
		p_i.ash = {"richness":ash_mult}
	elif tf_type == Building.MINERAL_SILO:
		game.mineral_capacity += Data.path_1[Building.MINERAL_SILO].value * surface
	elif tf_type == Building.BATTERY:
		game.energy_capacity += Data.path_1[Building.BATTERY].value * surface
	elif tf_type == Building.ATMOSPHERE_EXTRACTOR:
		for el in p_i.atmosphere:
			var base_prod:float = p_i.bldg.path_1_value * p_i.atmosphere[el] * p_i.pressure * surface
			game.show[el] = true
			Helper.add_atom_production(el, base_prod)
	elif tf_type == Building.BORING_MACHINE and not p_i.has("depth"):
		p_i.depth = 0
		p_i.bldg.collect_date = Time.get_unix_time_from_system()
		game.boring_machine_data[game.c_p_g] = {"c_s_g":game.c_s_g, "c_p":game.c_p}
	game.view_history.pop_back()
	game.view_history_pos -= 1
	game.switch_view("system")
	var dir = DirAccess.open("user://%s/Univ%s/Planets" % [game.c_sv, game.c_u])
	dir.remove("%s.hx3" % game.c_p_g)
	game.popup(tr("TF_SUCCESS"), 2)
	if not game.objective.is_empty() and game.objective.type == game.ObjectiveType.TERRAFORM:
		game.objective.current += 1
	game.HUD.refresh()

func _on_Terraform_pressed():
	total_costs = costs.duplicate(true)
	for cost in tf_costs:
		if total_costs.has(cost):
			total_costs[cost] += tf_costs[cost]
		else:
			total_costs[cost] = tf_costs[cost]
	if game.check_enough(total_costs):
		if p_i.has("bookmarked"):
			game.show_YN_panel("terraform_planet", tr("TF_CONFIRM"))
		else:
			terraform_planet()
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.2)


func _on_mineral_extractor_pressed():
	tf_type = Building.MINERAL_EXTRACTOR
	set_bldg_cost_txt()
	costs = Data.costs[Building.MINERAL_EXTRACTOR].duplicate(true)
	var st = ""
	if p_i.unique_bldgs.has(UniqueBuilding.MINERAL_REPLICATOR):
		unique_bldg_bonus = 0
		var n_total = 0
		for mr in p_i.unique_bldgs[UniqueBuilding.MINERAL_REPLICATOR]:
			if not mr.has("repair_cost"):
				var n = (pow(Helper.get_unique_bldg_area(mr.tier), 2) - 1)
				unique_bldg_bonus += Helper.get_MR_Obs_Outpost_prod_mult(mr.tier) * n
				n_total += n
		unique_bldg_bonus += len(game.tile_data) - n_total
		unique_bldg_bonus /= len(game.tile_data)
		if unique_bldg_bonus > 1:
			unique_bldg_id = UniqueBuilding.MINERAL_REPLICATOR
		st += tr("MIN_MULT_FROM_MR") + " " + str(Helper.clever_round(unique_bldg_bonus))
	if ash_mult > 1:
		st += "\n" + tr("MIN_MULT_FROM_ASH") % ash_mult
	$Panel/Note.text = st
	update_info()


func _on_power_plant_pressed():
	tf_type = Building.POWER_PLANT
	set_bldg_cost_txt()
	costs = Data.costs[Building.POWER_PLANT].duplicate(true)
	var st = ""
	if p_i.unique_bldgs.has(UniqueBuilding.SUBSTATION):
		unique_bldg_bonus = 0
		unique_bldg_bonus_cap = 0
		var n_total = 0
		for sub in p_i.unique_bldgs[UniqueBuilding.SUBSTATION]:
			if not sub.has("repair_cost"):
				var n = (pow(Helper.get_unique_bldg_area(sub.tier), 2) - 1)
				unique_bldg_bonus += Helper.get_substation_prod_mult(sub.tier) * n
				unique_bldg_bonus_cap += Helper.get_substation_capacity_bonus(sub.tier) * n
				n_total += n
		unique_bldg_bonus += len(game.tile_data) - n_total
		unique_bldg_bonus /= len(game.tile_data)
		if unique_bldg_bonus > 1:
			unique_bldg_id = UniqueBuilding.SUBSTATION
		unique_bldg_bonus_cap /= len(game.tile_data)
		st += tr("ENERGY_MULT_FROM_SUBSTATION") + " " + str(Helper.clever_round(unique_bldg_bonus))
		st += "\n" + tr("ENERGY_STORAGE_BONUS_FROM_SUBSTATION") % Helper.time_to_str(unique_bldg_bonus_cap)
	$Panel/Note.text = st
	update_info()


func _on_mineral_silo_pressed():
	tf_type = Building.MINERAL_SILO
	set_bldg_cost_txt()
	costs = Data.costs[Building.MINERAL_SILO].duplicate(true)
	$Panel/Note.text = ""
	update_info()


func _on_battery_pressed():
	tf_type = Building.BATTERY
	set_bldg_cost_txt()
	costs = Data.costs[Building.BATTERY].duplicate(true)
	$Panel/Note.text = ""
	update_info()


func _on_research_lab_pressed():
	tf_type = Building.RESEARCH_LAB
	set_bldg_cost_txt()
	costs = Data.costs[Building.RESEARCH_LAB].duplicate(true)
	var st = ""
	if SP_feature_mult > 1:
		unique_bldg_bonus = SP_feature_mult
		unique_bldg_id = UniqueBuilding.OBSERVATORY
		st += "\n" + tr("SP_MULT_FROM_FEATURES") + " " + str(Helper.clever_round(SP_feature_mult))
	$Panel/Note.text = st
	update_info()


func _on_atmosphere_extractor_pressed():
	tf_type = Building.ATMOSPHERE_EXTRACTOR
	set_bldg_cost_txt()
	costs = Data.costs[Building.ATMOSPHERE_EXTRACTOR].duplicate(true)
	var st = ""
	if p_i.unique_bldgs.has(UniqueBuilding.NUCLEAR_FUSION_REACTOR):
		var needs_repair = false
		for nfr in p_i.unique_bldgs[UniqueBuilding.NUCLEAR_FUSION_REACTOR]:
			if nfr.has("repair_cost"):
				needs_repair = true
				break
		if needs_repair:
			st += tr("REPAIR_NFR_TO_GET_ENERGY")
		else:
			st += tr("WILL_PROVIDE_EXTRA_ENERGY")
			unique_bldg_id = UniqueBuilding.NUCLEAR_FUSION_REACTOR
		st += "\n"
	if p_i.unique_bldgs.has(UniqueBuilding.CELLULOSE_SYNTHESIZER):
		var needs_repair = false
		for cs in p_i.unique_bldgs[UniqueBuilding.CELLULOSE_SYNTHESIZER]:
			if cs.has("repair_cost"):
				needs_repair = true
				break
		if needs_repair:
			st += tr("REPAIR_CS_TO_GET_CELLULOSE")
		else:
			st += tr("WILL_PROVIDE_EXTRA_CELLULOSE")
			unique_bldg_id = UniqueBuilding.CELLULOSE_SYNTHESIZER
	$Panel/Note.text = st
	update_info()


func _on_boring_machine_pressed():
	tf_type = Building.BORING_MACHINE
	set_bldg_cost_txt()
	costs = Data.costs[Building.BORING_MACHINE].duplicate(true)
	var st = ""
	if p_i.unique_bldgs.has(UniqueBuilding.MINING_OUTPOST):
		unique_bldg_bonus = 0
		var n_total = 0
		for sub in p_i.unique_bldgs[UniqueBuilding.MINING_OUTPOST]:
			if not sub.has("repair_cost"):
				var n = (pow(Helper.get_unique_bldg_area(sub.tier), 2) - 1)
				unique_bldg_bonus += Helper.get_MR_Obs_Outpost_prod_mult(sub.tier) * n
				n_total += n
		unique_bldg_bonus += len(game.tile_data) - n_total
		unique_bldg_bonus /= len(game.tile_data)
		if unique_bldg_bonus > 1:
			unique_bldg_id = UniqueBuilding.MINING_OUTPOST
		st += tr("MINING_MULT_FROM_OUTPOST") + " " + str(Helper.clever_round(unique_bldg_bonus))
	$Panel/Note.text = st
	update_info()


func _on_greenhouse_pressed():
	tf_type = Building.GREENHOUSE
	set_bldg_cost_txt()
	costs = Data.costs[Building.GREENHOUSE].duplicate(true)
	costs.soil = 10
	$Panel/Note.text = tr("MIN_MULT_FROM_ASH") % ash_mult
	update_info()


func _on_atom_manipulator_pressed():
	tf_type = Building.ATOM_MANIPULATOR
	set_bldg_cost_txt()
	costs = Data.costs[Building.ATOM_MANIPULATOR].duplicate(true)
	$Panel/Note.text = ""
	update_info()


func _on_subatomic_particle_reactor_pressed():
	tf_type = Building.SUBATOMIC_PARTICLE_REACTOR
	set_bldg_cost_txt()
	costs = Data.costs[Building.SUBATOMIC_PARTICLE_REACTOR].duplicate(true)
	$Panel/Note.text = ""
	update_info()
