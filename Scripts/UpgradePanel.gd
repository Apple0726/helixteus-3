extends "Panel.gd"

var BASE_PW:float = 1.3
var ids:Array = []
var planet:Dictionary#Only for terraformed planets
var p_i:Dictionary#Information on the planet you're on
var bldg:int = -1#You can mass-upgrade only one type of building
var costs:Dictionary
var path_selected:int = 1
var path_str:String
var new_base_value:float
var set_min_lv:bool = false

@onready var path1 = $PathButtons/Path1
@onready var path2 = $PathButtons/Path2
@onready var path3 = $PathButtons/Path3
@onready var next_lv_spinbox = $NextLv
@onready var current_lv_label = $CurrentLv
@onready var current_and_next_label = $CurrentAndNext
@onready var cost_icons = $ScrollContainer/Costs
@onready var upgrade_btn = $Upgrade

func _ready():
	BASE_PW = game.maths_bonus.BUCGF
	set_polygon(size)
	path1.get_node("Label").text = tr("PATH") + " 1"
	path2.get_node("Label").text = tr("PATH") + " 2"
	path3.get_node("Label").text = tr("PATH") + " 3"

func refresh():
	var building_name:String
	if not planet.is_empty():
		path2.visible = Data.path_2.has(planet.bldg.name)
		path3.visible = Data.path_3.has(planet.bldg.name)
		_on_Path1_pressed()
		path1._on_Button_pressed()
		building_name = Building.names[planet.bldg.name]
		$Label.text = tr("UPGRADE_X_BLDGS").format({"bldg":tr(building_name.to_upper() + "_NAME_S"), "num":Helper.format_num(planet.tile_num)})
	else:
		p_i = game.planet_data[game.c_p]
		if game.view.obj.tiles_selected.is_empty():
			ids = [game.view.obj.tile_over]
		else:
			ids = game.view.obj.tiles_selected.duplicate(true)
		var first_tile_bldg = game.tile_data[ids[0]].bldg
		building_name = Building.names[first_tile_bldg.name]
		if len(ids) == 1:
			$Label.text = tr("UPGRADE_X").format({"bldg":tr(building_name.to_upper() + "_NAME")})
		else:
			$Label.text = tr("UPGRADE_X_BLDGS").format({"bldg":tr(building_name.to_upper() + "_NAME_S"), "num":len(ids)})
		path2.visible = first_tile_bldg.has("path_2")
		path3.visible = first_tile_bldg.has("path_3")
		if first_tile_bldg.has("path_1"):
			_on_Path1_pressed()
			path1._on_Button_pressed()
		else:
			game.popup(tr("NO_UPGRADE"), 1.5)
			game.toggle_panel(self)
	$Building.texture = load("res://Graphics/Buildings/%s.png" % building_name)
	
func geo_seq(q:float, start_n:int, end_n:int):
	return max(0, pow(q, start_n) * (1 - pow(q, end_n - start_n)) / (1 - q))

func get_min_lv():
	if planet.is_empty():
		var min_lv = INF
		for id in ids:
			var tile = game.tile_data[id]
			var lv_curr = tile.bldg[path_str]
			if lv_curr < min_lv:
				min_lv = lv_curr
		return min_lv
	else:
		return planet.bldg[path_str]

func calc_costs(tile_bldg:int, lv_curr:int, lv_to:int, cost_div:float, num:int = 1):
	var base_costs = Data.costs[tile_bldg].duplicate(true)
	var base_metal_costs = Data[path_str][tile_bldg].metal_costs.duplicate(true) if Data[path_str][tile_bldg].has("metal_costs") else {}
	var base_pw:float = Data[path_str][tile_bldg].cost_pw if Data[path_str][tile_bldg].has("cost_pw") else BASE_PW
	if Data[path_str][tile_bldg].has("cost_mult"):
		var mult:float = Data[path_str][tile_bldg].cost_mult
		base_costs.money *= mult
		base_costs.energy *= mult
	if cost_div != 1.0 or game.engineering_bonus.BCM != 1.0:
		for cost in base_costs:
			base_costs[cost] /= cost_div
			base_costs[cost] *= game.engineering_bonus.BCM
		for cost in base_metal_costs:
			base_metal_costs[cost] /= cost_div
			base_metal_costs[cost] *= game.engineering_bonus.BCM
	costs.money += round(base_costs.money * geo_seq(base_pw + 0.05, lv_curr, lv_to) * num)
	if base_costs.has("energy"):
		costs.energy += round(base_costs.energy * geo_seq(base_pw, lv_curr, lv_to) * num)
	if not base_metal_costs.is_empty():
		if lv_curr <= 10 and lv_to >= 11:
			costs.lead += base_metal_costs.lead * num
		if lv_curr <= 20 and lv_to >= 21:
			costs.copper += base_metal_costs.copper * num
		if lv_curr <= 30 and lv_to >= 31:
			costs.iron += base_metal_costs.iron * num
		if lv_curr <= 40 and lv_to >= 41:
			costs.aluminium += base_metal_costs.aluminium * num
		if lv_curr <= 50 and lv_to >= 51:
			costs.silver += base_metal_costs.silver * num
		if lv_curr <= 60 and lv_to >= 61:
			costs.gold += base_metal_costs.gold * num
		if lv_curr <= 71 and lv_to >= 71 and base_metal_costs.has("platinum"):
			costs.platinum += base_metal_costs.platinum * num

func update(changing_paths:bool = false):
	set_min_lv = true
	next_lv_spinbox.min_value = get_min_lv() + 1
	set_min_lv = false
	costs = {"money":0, "energy":0, "lead":0, "copper":0, "iron":0, "aluminium":0, "silver":0, "gold":0, "platinum":0}
	var same_lv = true
	var first_tile:Dictionary
	var first_tile_bldg:Dictionary
	var first_tile_bldg_info:Dictionary
	var num:int = 1
	if planet.is_empty():
		first_tile = game.tile_data[ids[0]]
		first_tile_bldg = game.tile_data[ids[0]].bldg
		bldg = first_tile_bldg.name
		if Data[path_str][bldg].has("cap"):
			next_lv_spinbox.allow_greater = false
			next_lv_spinbox.max_value = Data[path_str][bldg].cap
		else:
			next_lv_spinbox.allow_greater = true
		first_tile_bldg_info = Data[path_str][bldg]
		var lv_to:int = next_lv_spinbox.value
		var a:int = next_lv_spinbox.min_value
		var calculated:bool = false
		while not calculated or lv_to != a:
			if calculated:
				costs = {"money":0, "energy":0, "lead":0, "copper":0, "iron":0, "aluminium":0, "silver":0, "gold":0, "platinum":0}
			var cost_div_sum:float = 0.0
			for id in ids:
				var tile = game.tile_data[id]
				var tile_bldg:int = tile.bldg.name
				var lv_curr = tile.bldg[path_str]
				if lv_curr != first_tile_bldg[path_str]:
					same_lv = false
				if tile.bldg[path_str] >= next_lv_spinbox.value or Data[path_str][bldg].has("cap") and tile.bldg[path_str] >= Data[path_str][bldg].cap:
					continue
				calc_costs(tile_bldg, lv_curr, lv_to, tile.cost_div if tile.has("cost_div") else 1.0, 1)
				cost_div_sum += tile.cost_div if tile.has("cost_div") else 1.0
			cost_div_sum /= len(ids)
			if cost_div_sum > 1.0:
				$DivBy.text = tr("DIV_BY") % Helper.clever_round(cost_div_sum, 4)
			else:
				$DivBy.text = ""
			if not changing_paths:
				break
			if game.check_enough(costs):
				if lv_to == next_lv_spinbox.value:
					break
				a = lv_to
				lv_to = (lv_to + next_lv_spinbox.value) / 2
			else:
				lv_to = (a + lv_to) / 2
			calculated = true
		if changing_paths:
			next_lv_spinbox.value = lv_to
	else:
		if planet.has("cost_div"):
			$DivBy.text = tr("DIV_BY") % Helper.clever_round(planet.cost_div)
		else:
			$DivBy.text = ""
		first_tile = planet
		first_tile_bldg = planet.bldg
		bldg = first_tile_bldg.name
		first_tile_bldg_info = Data[path_str][bldg]
		num = 1 if bldg in [Building.GREENHOUSE, Building.BORING_MACHINE, Building.ATOM_MANIPULATOR, Building.SUBATOMIC_PARTICLE_REACTOR] else planet.tile_num
		var lv_to:int = next_lv_spinbox.value
		var a:int = next_lv_spinbox.min_value
		var calculated:bool = false
		if changing_paths:
			while not calculated or lv_to != a:
				if calculated:
					costs = {"money":0, "energy":0, "lead":0, "copper":0, "iron":0, "aluminium":0, "silver":0, "gold":0, "platinum":0}
				calc_costs(planet.bldg.name, planet.bldg[path_str], lv_to, planet.cost_div if planet.has("cost_div") else 1.0, planet.tile_num)
				if game.check_enough(costs):
					if lv_to == next_lv_spinbox.value:
						break
					a = lv_to
					lv_to = (lv_to + next_lv_spinbox.value) / 2
				else:
					lv_to = (a + lv_to) / 2
				calculated = true
			next_lv_spinbox.value = lv_to
		else:
			calc_costs(planet.bldg.name, planet.bldg[path_str], next_lv_spinbox.value, planet.cost_div if planet.has("cost_div") else 1.0, planet.tile_num)
	if same_lv:
		current_lv_label.text = tr("LEVEL") + " %s" % [first_tile_bldg[path_str]]
		current_and_next_label.text = ""
		#set_bldg_value(first_tile_bldg_info, first_tile, first_tile_bldg[path_str], num, current, false)
	else:
		current_lv_label.text = tr("VARYING_LEVELS")
		current_and_next_label.text = "[center] %s" % tr("VARIES")
	set_bldg_value(first_tile_bldg_info, first_tile, first_tile_bldg[path_str], next_lv_spinbox.value, num)
	var icons = Helper.put_rsrc(cost_icons, 32, costs, true, true)
	for icon in icons:
		if costs[icon.name] == 0:
			icon.rsrc.visible = false

func set_bldg_value(first_tile_bldg_info:Dictionary, first_tile:Dictionary, lv:int, next_lv:int, n:int):
	var rsrc_icon = Data.desc_icons[bldg][path_selected - 1] if Data.desc_icons.has(bldg) and Data.desc_icons[bldg] else []
	var curr_value:float
	var next_value:float
	var IR_mult:float = Helper.get_IR_mult(bldg)
	if bldg == Building.SOLAR_PANEL and path_selected == 1:
		var SP_production = Helper.get_SP_production(p_i.temperature, first_tile_bldg_info.value)
		curr_value = bldg_value(SP_production, lv, first_tile_bldg_info.pw)
		next_value = bldg_value(SP_production, next_lv, first_tile_bldg_info.pw)
	elif bldg == Building.ATMOSPHERE_EXTRACTOR and path_selected == 1:
		var AE_production = Helper.get_AE_production(p_i.pressure if planet.is_empty() else planet.pressure, first_tile_bldg_info.value)
		curr_value = bldg_value(AE_production, lv, first_tile_bldg_info.pw)
		next_value = bldg_value(AE_production, next_lv, first_tile_bldg_info.pw)
	elif bldg == Building.MINERAL_EXTRACTOR and path_selected == 1:
		var ME_production = first_tile_bldg_info.value * (planet.resource_production_bonus.get("minerals", 1) if planet.has("resource_production_bonus") else 1.0)
		curr_value = bldg_value(ME_production, lv, first_tile_bldg_info.pw)
		next_value = bldg_value(ME_production, next_lv, first_tile_bldg_info.pw)
	elif bldg == Building.POWER_PLANT and path_selected == 1:
		var PP_production = first_tile_bldg_info.value * (planet.resource_production_bonus.get("energy", 1) if planet.has("resource_production_bonus") else 1.0)
		curr_value = bldg_value(PP_production, lv, first_tile_bldg_info.pw)
		next_value = bldg_value(PP_production, next_lv, first_tile_bldg_info.pw)
	elif bldg == Building.RESEARCH_LAB and path_selected == 1:
		var RL_production = first_tile_bldg_info.value * (planet.resource_production_bonus.get("SP", 1) if planet.has("resource_production_bonus") else 1.0)
		curr_value = bldg_value(RL_production, lv, first_tile_bldg_info.pw)
		next_value = bldg_value(RL_production, next_lv, first_tile_bldg_info.pw)
	elif bldg in [Building.MINERAL_SILO, Building.BATTERY]:
		curr_value = bldg_value(first_tile_bldg_info.value, lv, first_tile_bldg_info.pw)
		next_value = bldg_value(first_tile_bldg_info.value, next_lv, first_tile_bldg_info.pw)
	else:
		if first_tile_bldg_info.has("pw"):
			curr_value = bldg_value(first_tile_bldg_info.value, lv, first_tile_bldg_info.pw)
			next_value = bldg_value(first_tile_bldg_info.value, next_lv, first_tile_bldg_info.pw)
		elif first_tile_bldg_info.has("step"):
			curr_value = first_tile_bldg_info.value + (lv - 1) * first_tile_bldg_info.step
			next_value = first_tile_bldg_info.value + (next_lv - 1) * first_tile_bldg_info.step
	if bldg == Building.STEAM_ENGINE and path_selected != 3:
		IR_mult = 1.0
	if bldg == Building.BATTERY:
		curr_value *= game.u_i.charge
		next_value *= game.u_i.charge
	curr_value *= IR_mult
	next_value *= IR_mult
	if first_tile_bldg_info.has("time_based"):
		curr_value *= game.u_i.time_speed
		next_value *= game.u_i.time_speed
	if first_tile_bldg_info.has("is_value_integer"):
		curr_value = round(curr_value)
		next_value = round(next_value)
	if first_tile_bldg_info.has("pw"):
		new_base_value = bldg_value(first_tile_bldg_info.value, next_lv, first_tile_bldg_info.pw)
	elif first_tile_bldg_info.has("step"):
		new_base_value = first_tile_bldg_info.value + (next_lv - 1) * first_tile_bldg_info.step
	if not planet.is_empty():
		curr_value *= n
		next_value *= n
	if bldg == Building.CENTRAL_BUSINESS_DISTRICT and path_selected == 3:
		game.add_text_icons(current_and_next_label, ("[center]" + first_tile_bldg_info.desc) % ["{n}x{n} -> {N}x{N}".format({"n":Helper.format_num(curr_value, true), "N":Helper.format_num(next_value, true)})], rsrc_icon, 20)
	else:
		game.add_text_icons(current_and_next_label, ("[center]" + first_tile_bldg_info.desc) % [Helper.format_num(curr_value, true) + " -> " + Helper.format_num(next_value, true)], rsrc_icon, 20)
	
func bldg_value(base_value, lv:int, pw:float = 1.15):
	return base_value * pow((lv - 1) / 10 + 1, pw) * pow(pw, lv - 1)

func _on_Path1_pressed():
	path_selected = 1
	path_str = "path_%s" % [path_selected]
	Helper.set_btn_color(path1)
	update(true)

func _on_Path2_pressed():
	if bldg != -1 and Data.path_2[bldg].has("cap"):
		if len(ids) == 1:
			if game.tile_data[ids[0]].bldg.path_2 >= Data.path_2[bldg].cap:
				game.popup(tr("MAX_LV_REACHED"), 1.5)
				$PathButtons.get_node("Path3D%s" % path_selected).call_deferred("_on_Button_pressed")
				return
		else:
			var all_capped = true
			for i in ids:
				if game.tile_data[i].bldg.path_2 < Data.path_2[bldg].cap:
					all_capped = false
					break
			if all_capped:
				game.popup(tr("MAX_LV_REACHED"), 1.5)
				$PathButtons.get_node("Path3D%s" % path_selected).call_deferred("_on_Button_pressed")
				return
	path_selected = 2
	path_str = "path_%s" % [path_selected]
	Helper.set_btn_color(path2)
	update(true)

func _on_Path3_pressed():
	if bldg != -1 and Data.path_3[bldg].has("cap"):
		if len(ids) == 1:
			if game.tile_data[ids[0]].bldg.path_3 >= Data.path_3[bldg].cap:
				game.popup(tr("MAX_LV_REACHED"), 1.5)
				$PathButtons.get_node("Path3D%s" % path_selected).call_deferred("_on_Button_pressed")
				return
		else:
			var all_capped = true
			for i in ids:
				if game.tile_data[i].bldg.path_3 < Data.path_3[bldg].cap:
					all_capped = false
					break
			if all_capped:
				game.popup(tr("MAX_LV_REACHED"), 1.5)
				$PathButtons.get_node("Path3D%s" % path_selected).call_deferred("_on_Button_pressed")
				return
	path_selected = 3
	path_str = "path_%s" % [path_selected]
	Helper.set_btn_color(path3)
	update(true)


func _on_NextLv_value_changed(_value):
	if not set_min_lv:
		update()


func _on_ScrollContainer_resized():
	$UpgradePanel.visible = false
	$UpgradePanel.visible = true


func _on_Upgrade_pressed():
	if game.c_v != "planet" and planet.is_empty() or game.c_v != "system" and not planet.is_empty():
		return
	update()
	var bldg_info = Data[path_str][bldg]
	var curr_time = Time.get_unix_time_from_system()
	for cost in costs.keys():
		if is_zero_approx(costs[cost]):
			costs.erase(cost)
	if game.check_enough(costs):
		game.deduct_resources(costs)
		var cost_money = costs.get("money", 0.0)
		game.u_i.xp += cost_money / 100.0
		if planet.is_empty():
			for id in ids:
				var tile = game.tile_data[id]
				if tile.bldg[path_str] >= next_lv_spinbox.value or Data[path_str][bldg].has("cap") and tile.bldg[path_str] >= Data[path_str][bldg].cap:
					continue
				var base_costs = Data.costs[bldg].duplicate(true)
				var base_pw:float = Data[path_str][bldg].get("cost_pw", BASE_PW)
				var overclock_mult:float = tile.bldg.get("overclock_mult", 1.0)
				var time_speed_bonus = tile.get("time_speed_bonus", 1.0)
				if tile.bldg.name == Building.MINERAL_EXTRACTOR:
					game.autocollect.rsrc.minerals += (new_base_value - tile.bldg.path_1_value) * overclock_mult * tile.resource_production_bonus.get("minerals", 1.0) * time_speed_bonus
				elif tile.bldg.name == Building.POWER_PLANT:
					var energy_prod = (new_base_value - tile.bldg.path_1_value) * tile.resource_production_bonus.get("energy", 1.0)
					game.autocollect.rsrc.energy += energy_prod * overclock_mult * time_speed_bonus
					if tile.has("substation_tile"):
						var cap_upgrade = energy_prod * tile.substation_bonus * Helper.get_substation_capacity_bonus(game.tile_data[tile.substation_tile].unique_bldg.tier)
						game.tile_data[tile.substation_tile].unique_bldg.capacity_bonus += cap_upgrade
						game.capacity_bonus_from_substation += cap_upgrade
				elif tile.bldg.name == Building.RESEARCH_LAB:
					game.autocollect.rsrc.SP += (new_base_value - tile.bldg.path_1_value) * overclock_mult * tile.resource_production_bonus.get("SP", 1.0) * time_speed_bonus
				elif tile.bldg.name == Building.SOLAR_PANEL:
					var energy_prod = Helper.get_SP_production(p_i.temperature, (new_base_value - tile.bldg.path_1_value) * tile.resource_production_bonus.get("energy", 1.0))
					game.autocollect.rsrc.energy += energy_prod * overclock_mult * time_speed_bonus
					if tile.has("substation_tile"):
						var cap_upgrade = energy_prod * tile.substation_bonus * Helper.get_substation_capacity_bonus(game.tile_data[tile.substation_tile].unique_bldg.tier)
						game.tile_data[tile.substation_tile].unique_bldg.capacity_bonus += cap_upgrade
						game.capacity_bonus_from_substation += cap_upgrade
				elif tile.bldg.name == Building.ATMOSPHERE_EXTRACTOR:
					var base_prod = (new_base_value - tile.bldg.path_1_value) * overclock_mult * p_i.pressure * time_speed_bonus
					for el in p_i.atmosphere:
						Helper.add_atom_production(el, base_prod * p_i.atmosphere[el])
					Helper.add_energy_from_NFR(p_i, base_prod)
					Helper.add_energy_from_CS(p_i, base_prod)
				elif tile.bldg.name == Building.MINERAL_SILO:
					game.mineral_capacity += new_base_value - tile.bldg.path_1_value
				elif tile.bldg.name == Building.BATTERY:
					game.energy_capacity += (new_base_value - tile.bldg.path_1_value) * game.u_i.charge
				elif tile.bldg.name == Building.GREENHOUSE and tile.has("auto_GH"):
					var prod_mult:float
					if path_selected == 1:
						prod_mult = new_base_value / tile.bldg.path_1_value
					elif path_selected == 2:
						prod_mult = new_base_value / tile.bldg.path_2_value
					for p in tile.auto_GH.produce.keys():
						if p == "minerals":
							game.autocollect.mats.minerals += tile.auto_GH.produce[p] * (prod_mult - 1.0)
						elif game.mat_info.has(p):
							game.autocollect.mats[p] += tile.auto_GH.produce[p] * (prod_mult - 1.0)
						elif game.met_info.has(p):
							var met_prod = tile.auto_GH.produce[p] * (tile.get("aurora", 0.0) + 1.0)
							game.autocollect.mets[p] += met_prod * (prod_mult - 1.0)
						tile.auto_GH.produce[p] *= prod_mult
					if path_selected == 1:
						game.autocollect.mats.cellulose -= tile.auto_GH.cellulose_drain * (prod_mult - 1.0)
						tile.auto_GH.cellulose_drain *= prod_mult
						if tile.auto_GH.has("soil_drain"):
							game.autocollect.mats.soil -= tile.auto_GH.soil_drain * (prod_mult - 1.0)
							tile.auto_GH.soil_drain *= prod_mult
				tile.bldg[path_str] = next_lv_spinbox.value
				tile.bldg[path_str + "_value"] = new_base_value
				if tile.bldg.name == Building.CENTRAL_BUSINESS_DISTRICT:
					Helper.update_CBD_affected_tiles(tile, id, p_i)
				game.view.obj.hboxes[id].get_node("Path%s" % path_selected).text = str(next_lv_spinbox.value)
				var bldg_sprite = game.view.obj.bldgs[id]
				bldg_sprite.material = ShaderMaterial.new()
				bldg_sprite.material.shader = preload("res://Shaders/BuildingUpgrade.gdshader")
				bldg_sprite.material.set_shader_parameter("color", Color.CYAN)
				bldg_sprite.material.set_shader_parameter("progress", 0.2)
				var tween = create_tween()
				tween.set_speed_scale(game.u_i.time_speed)
				tween.tween_property(bldg_sprite.material, "shader_parameter/progress", 0.42, 0.6)
				tween.tween_property(bldg_sprite.material, "shader_parameter/color", Color.WHITE, 0.4)
				tween.tween_property(bldg_sprite.material, "shader_parameter/color", Color.CYAN, 0.3)
				tween.tween_property(bldg_sprite.material, "shader_parameter/progress", 0.9, 1.2)
			#if not game.objective.is_empty() and game.objective.type == game.ObjectiveType.UPGRADE:
				#game.objective.current += 1
		else:
			var diff:float = (new_base_value - planet.bldg.path_1_value) * planet.tile_num
			if planet.bldg.name == Building.MINERAL_SILO:
				game.mineral_capacity += diff
			elif planet.bldg.name == Building.BATTERY:
				game.energy_capacity += diff * game.u_i.charge
			elif planet.bldg.name == Building.ATMOSPHERE_EXTRACTOR:
				var base_prod:float = diff * planet.pressure
				for el in planet.atmosphere:
					Helper.add_atom_production(el, base_prod * planet.atmosphere[el])
				Helper.add_energy_from_NFR(planet, base_prod)
				Helper.add_energy_from_CS(planet, base_prod)
			elif planet.bldg.name == Building.RESEARCH_LAB:
				game.autocollect.rsrc.SP += diff * planet.resource_production_bonus.get("SP", 1.0)
			elif planet.bldg.name == Building.MINERAL_EXTRACTOR:
				game.autocollect.rsrc.minerals += diff * planet.resource_production_bonus.get("minerals", 1.0)
			elif planet.bldg.name == Building.POWER_PLANT:
				game.autocollect.rsrc.energy += diff * planet.resource_production_bonus.get("energy", 1.0)
				game.capacity_bonus_from_substation += diff * planet.get("unique_bldg_bonus_cap", 0.0)
			elif planet.has("auto_GH"):
				for p in planet.auto_GH.produce:
					var upgrade_mult:float = new_base_value / planet.bldg["%s_value" % path_str]
					game.autocollect.mets[p] += planet.auto_GH.produce[p] * (upgrade_mult - 1)
					planet.auto_GH.produce[p] *= upgrade_mult
					if path_selected == 1:
						game.autocollect.mats.cellulose -= planet.auto_GH.cellulose_drain * (upgrade_mult - 1)
						planet.auto_GH.cellulose_drain *= upgrade_mult
						if planet.auto_GH.has("soil_drain"):
							game.autocollect.mats.soil -= planet.auto_GH.soil_drain * (upgrade_mult - 1.0)
							planet.auto_GH.soil_drain *= upgrade_mult
			if planet.bldg.has("collect_date"):
				var prod_ratio
				if path_str == "path_1":
					prod_ratio = new_base_value / planet.bldg.path_1_value
				else:
					prod_ratio = 1.0
				var coll_date = planet.bldg.collect_date
				planet.bldg.collect_date = curr_time - (curr_time - coll_date) / prod_ratio
			planet.bldg[path_str] = next_lv_spinbox.value
			planet.bldg[path_str + "_value"] = new_base_value
			game.universe_data[game.c_u].xp += cost_money / 100.0
			game.view.obj.refresh_planets()
		game.HUD.refresh()
		game.toggle_panel("upgrade_panel")
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.2)

func _on_Control_tree_exited():
	queue_free()
