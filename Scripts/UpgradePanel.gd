extends "Panel.gd"

const BASE_PW:float = 1.3
var ids:Array = []
var planet:Dictionary#Only for terraformed planets
var bldg:String = ""#You can mass-upgrade only one type of building
var costs:Dictionary
var path_selected:int = 1
var path_str:String
var auto_speedup:bool = false
var new_value:float
var new_base_value:float
var set_min_lv:bool = false

onready var path1 = $PathButtons/Path1
onready var path2 = $PathButtons/Path2
onready var path3 = $PathButtons/Path3
onready var next_lv = $NextLv
onready var current_lv = $CurrentLv
onready var next = $Next
onready var current = $Current
onready var cost_icons = $ScrollContainer/Costs
onready var upgrade_btn = $Upgrade

func _ready():
	set_polygon(rect_size)
	path1.text = tr("PATH") + " 1"
	path2.text = tr("PATH") + " 2"
	path3.text = tr("PATH") + " 3"

func refresh():
	if not planet.empty():
		path2.visible = Data.path_2.has(planet.bldg.name)
		path3.visible = Data.path_3.has(planet.bldg.name)
		$AutoSpeedup.visible = false
		$AutoSpeedup.pressed = true
		auto_speedup = true
		_on_Path1_pressed()
	else:
		path2.visible = game.tile_data[ids[0]].bldg.has("path_2")
		path3.visible = game.tile_data[ids[0]].bldg.has("path_3")
		$AutoSpeedup.visible = game.universe_data[game.c_u].lv >= 30
		$AutoSpeedup.pressed = $AutoSpeedup.visible
		if game.tile_data[ids[0]].bldg.has("path_1"):
			_on_Path1_pressed()
		else:
			game.popup(tr("NO_UPGRADE"), 1.5)
			game.toggle_panel(self)
	
func geo_seq(q:float, start_n:int, end_n:int):
	return max(0, pow(q, start_n) * (1 - pow(q, end_n - start_n)) / (1 - q))

func get_min_lv():
	if planet.empty():
		var min_lv = INF
		for id in ids:
			var tile = game.tile_data[id]
			var lv_curr = tile.bldg[path_str]
			if lv_curr < min_lv:
				min_lv = lv_curr
		return min_lv
	else:
		return planet.bldg[path_str]

func calc_costs(tile_bldg:String, lv_curr:int, lv_to:int, cost_div:float, num:int = 1):
	var base_costs = Data.costs[tile_bldg].duplicate(true)
	var base_metal_costs = Data[path_str][tile_bldg].metal_costs.duplicate(true) if Data[path_str][tile_bldg].has("metal_costs") else {}
	var base_pw:float = Data[path_str][tile_bldg].cost_pw if Data[path_str][tile_bldg].has("cost_pw") else BASE_PW
	if Data[path_str][tile_bldg].has("cost_mult"):
		var mult:float = Data[path_str][tile_bldg].cost_mult
		base_costs.money *= mult
		base_costs.time *= mult
		base_costs.energy *= mult
	if cost_div != 1.0:
		for cost in base_costs:
			base_costs[cost] /= cost_div
		for cost in base_metal_costs:
			base_metal_costs[cost] /= cost_div
	costs.money += round(base_costs.money * geo_seq(base_pw + 0.05, lv_curr, lv_to) * num)
	costs.time = round(base_costs.time * geo_seq(base_pw, lv_curr, lv_to) / game.u_i.time_speed)
	if base_costs.has("energy"):
		costs.energy += round(base_costs.energy * geo_seq(base_pw, lv_curr, lv_to) * num)
	if not base_metal_costs.empty():
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
	if auto_speedup:
		costs.money += costs.time * 10 * num
		costs.time = 0

func update(changing_paths:bool = false):
	set_min_lv = true
	next_lv.min_value = get_min_lv() + 1
	set_min_lv = false
	auto_speedup = $AutoSpeedup.pressed
	costs = {"money":0, "energy":0, "lead":0, "copper":0, "iron":0, "aluminium":0, "silver":0, "gold":0, "platinum":0, "time":0.0}
	var same_lv = true
	var first_tile
	var first_tile_bldg_info
	var all_tiles_constructing = true
	var num:int = 1
	if planet.empty():
		first_tile = game.tile_data[ids[0]].bldg
		bldg = first_tile.name
		if Data[path_str][bldg].has("cap"):
			next_lv.allow_greater = false
			next_lv.max_value = Data[path_str][bldg].cap
		else:
			next_lv.allow_greater = true
		first_tile_bldg_info = Data[path_str][bldg]
		var lv_to:int = next_lv.value
		var a:int = next_lv.min_value
		var calculated:bool = false
		while not calculated or lv_to != a:
			if calculated:
				costs = {"money":0, "energy":0, "lead":0, "copper":0, "iron":0, "aluminium":0, "silver":0, "gold":0, "platinum":0, "time":0.0}
			for id in ids:
				var tile = game.tile_data[id]
				var tile_bldg:String = tile.bldg.name
				var lv_curr = tile.bldg[path_str]
				if lv_curr != first_tile[path_str]:
					same_lv = false
				if tile.bldg.is_constructing or tile.bldg[path_str] >= next_lv.value or Data[path_str][bldg].has("cap") and tile.bldg[path_str] >= Data[path_str][bldg].cap:
					continue
				all_tiles_constructing = false
				calc_costs(tile_bldg, lv_curr, lv_to, tile.cost_div if tile.has("cost_div") else 1.0, 1)
			if not changing_paths:
				break
			if game.check_enough(costs):
				if lv_to == next_lv.value:
					break
				a = lv_to
				lv_to = (lv_to + next_lv.value) / 2
			else:
				lv_to = (a + lv_to) / 2
			calculated = true
		if changing_paths:
			next_lv.value = lv_to
	else:
		first_tile = planet.bldg
		bldg = first_tile.name
		first_tile_bldg_info = Data[path_str][bldg]
		all_tiles_constructing = false
		num = 1 if bldg in ["GH", "MM", "AMN", "SPR"] else planet.tile_num
		var lv_to:int = next_lv.value
		var a:int = next_lv.min_value
		var calculated:bool = false
		if changing_paths:
			while not calculated or lv_to != a:
				if calculated:
					costs = {"money":0, "energy":0, "lead":0, "copper":0, "iron":0, "aluminium":0, "silver":0, "gold":0, "platinum":0, "time":0.0}
				calc_costs(planet.bldg.name, planet.bldg[path_str], lv_to, 1.0, planet.tile_num)
				if game.check_enough(costs):
					if lv_to == next_lv.value:
						break
					a = lv_to
					lv_to = (lv_to + next_lv.value) / 2
				else:
					lv_to = (a + lv_to) / 2
				calculated = true
			next_lv.value = lv_to
		else:
			calc_costs(planet.bldg.name, planet.bldg[path_str], next_lv.value, 1.0, planet.tile_num)
	var rsrc_icon = [Data.desc_icons[bldg][path_selected - 1]] if Data.desc_icons.has(bldg) and Data.desc_icons[bldg] else []
	if same_lv:
		current_lv.text = tr("LEVEL") + " %s" % [first_tile[path_str]]
		current.text = ""
		var curr_value:float
		if bldg == "SP" and path_selected == 1:
			curr_value = bldg_value(Helper.get_SP_production(game.planet_data[game.c_p].temperature, first_tile_bldg_info.value), first_tile[path_str], first_tile_bldg_info.pw) * first_tile.IR_mult
		elif bldg == "AE" and path_selected == 1:
			curr_value = bldg_value(Helper.get_AE_production(game.planet_data[game.c_p].pressure, first_tile_bldg_info.value), first_tile[path_str], first_tile_bldg_info.pw)
		else:
			if first_tile_bldg_info.has("pw"):
				curr_value = bldg_value(first_tile_bldg_info.value, first_tile[path_str], first_tile_bldg_info.pw) * first_tile.IR_mult
			elif first_tile_bldg_info.has("step"):
				curr_value = first_tile_bldg_info.value + (first_tile[path_str] - 1) * first_tile_bldg_info.step
		if first_tile_bldg_info.is_value_integer:
			curr_value = round(curr_value)
		else:
			curr_value = Helper.clever_round(curr_value)
		if first_tile_bldg_info.has("time_based"):
			curr_value *= game.u_i.time_speed
		if not planet.empty():
			curr_value *= num
		if bldg == "CBD" and path_selected == 3:
			game.add_text_icons(current, "[center]" + first_tile_bldg_info.desc.format({"n":Helper.format_num(curr_value)}), rsrc_icon, 20)
		else:
			game.add_text_icons(current, ("[center]" + first_tile_bldg_info.desc) % [Helper.format_num(curr_value)], rsrc_icon, 20)
	else:
		costs.erase("time")
		current_lv.text = tr("VARYING_LEVELS")
		current.bbcode_text = "[center] %s" % tr("VARIES")
	if all_tiles_constructing:
		game.popup(tr("SELECTED_BLDGS_UNDER_CONSTR"), 2)
		game.toggle_panel(self)
		return
	next.text = ""
	if bldg == "SP" and path_selected == 1:
		new_base_value = bldg_value(Helper.get_SP_production(game.planet_data[game.c_p].temperature, first_tile_bldg_info.value), next_lv.value, first_tile_bldg_info.pw)
		new_value = new_base_value * first_tile.IR_mult
	elif bldg == "AE" and path_selected == 1:
		new_base_value = bldg_value(Helper.get_AE_production(game.planet_data[game.c_p].pressure, first_tile_bldg_info.value), next_lv.value, first_tile_bldg_info.pw)
		new_value = new_base_value
	else:
		if first_tile_bldg_info.has("pw"):
			new_base_value = bldg_value(first_tile_bldg_info.value, next_lv.value, first_tile_bldg_info.pw)
			new_value = new_base_value * first_tile.IR_mult
		elif first_tile_bldg_info.has("step"):
			new_base_value = first_tile_bldg_info.value + (next_lv.value - 1) * first_tile_bldg_info.step
			new_value = new_base_value
	if first_tile_bldg_info.is_value_integer:
		new_base_value = round(new_base_value)
		new_value = round(new_value)
	else:
		new_base_value = Helper.clever_round(new_base_value)
		new_value = Helper.clever_round(new_value)
	if first_tile_bldg_info.has("time_based"):
		new_value *= game.u_i.time_speed
	if not planet.empty():
		new_value *= num
	if bldg == "CBD" and path_selected == 3:
		game.add_text_icons(next, "[center]" + first_tile_bldg_info.desc.format({"n":Helper.format_num(new_value)}), rsrc_icon, 20)
	else:
		game.add_text_icons(next, ("[center]" + first_tile_bldg_info.desc) % [Helper.format_num(new_value)], rsrc_icon, 20)
	var icons = Helper.put_rsrc(cost_icons, 32, costs, true, true)
	for icon in icons:
		if costs[icon.name] == 0:
			icon.rsrc.visible = false

func bldg_value(base_value, lv:int, pw:float = 1.15):
	return Helper.clever_round(base_value * pow((lv - 1) / 10 + 1, pw) * pow(pw, lv - 1))

func _on_Path1_pressed():
#	if bldg != "" and len(ids) == 1 and Data.path_1[bldg].has("cap") and game.tile_data[ids[0]].bldg.path_1 == Data.path_1[bldg].cap:
#		game.popup(tr("MAX_LV_REACHED"), 1.5)
#		return
	path_selected = 1
	path_str = "path_%s" % [path_selected]
	Helper.set_btn_color(path1)
	update(true)

func _on_Path2_pressed():
#	if bldg != "" and len(ids) == 1 and Data.path_2[bldg].has("cap") and game.tile_data[ids[0]].bldg.path_2 == Data.path_2[bldg].cap:
#		game.popup(tr("MAX_LV_REACHED"), 1.5)
#		return
	path_selected = 2
	path_str = "path_%s" % [path_selected]
	Helper.set_btn_color(path2)
	update(true)

func _on_Path3_pressed():
	if bldg != "" and Data.path_3[bldg].has("cap"):
		if len(ids) == 1:
			if game.tile_data[ids[0]].bldg.path_3 >= Data.path_3[bldg].cap:
				game.popup(tr("MAX_LV_REACHED"), 1.5)
				return
		else:
			var all_capped = true
			for i in ids:
				if game.tile_data[i].bldg.path_3 < Data.path_3[bldg].cap:
					all_capped = false
					break
			if all_capped:
				game.popup(tr("MAX_LV_REACHED"), 1.5)
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
	if game.c_v != "planet" and planet.empty() or game.c_v != "system" and not planet.empty():
		return
	update()
	var bldg_info = Data[path_str][bldg]
	var curr_time = OS.get_system_time_msecs()
	if game.check_enough(costs):
		game.deduct_resources(costs)
		var cost_money = costs.money
		if planet.empty():
			var cost_time
			for id in ids:
				var tile = game.tile_data[id]
				if tile.bldg.is_constructing or tile.bldg[path_str] >= next_lv.value or Data[path_str][bldg].has("cap") and tile.bldg[path_str] >= Data[path_str][bldg].cap:
					continue
				var base_costs = Data.costs[bldg].duplicate(true)
				if Data[path_str][bldg].has("cost_mult"):
					base_costs.time *= Data[path_str][bldg].cost_mult
				var base_pw:float = Data[path_str][bldg].cost_pw if Data[path_str][bldg].has("cost_pw") else BASE_PW
				cost_time = round(base_costs.time * geo_seq(base_pw, tile.bldg[path_str], next_lv.value) / game.u_i.time_speed)
				if tile.has("cost_div"):
					cost_time /= tile.cost_div
				if auto_speedup:
					cost_time = 1
				if tile.bldg.has("collect_date"):
					var mult:float = tile.bldg.overclock_mult if tile.bldg.has("overclock_mult") else 1.0
					if tile.has("auto_collect"):
						if tile.bldg.name == "ME":
							game.autocollect.rsrc_list[String(game.c_p_g)].minerals -= tile.bldg.path_1_value * tile.auto_collect / 100.0 * mult
							game.autocollect.rsrc.minerals -= tile.bldg.path_1_value * tile.auto_collect / 100.0 * mult
						elif tile.bldg.name in ["PP", "SP"]:
							game.autocollect.rsrc_list[String(game.c_p_g)].energy -= tile.bldg.path_1_value * tile.auto_collect / 100.0 * mult
							game.autocollect.rsrc.energy -= tile.bldg.path_1_value * tile.auto_collect / 100.0 * mult
					if tile.bldg.name == "RL":
						game.autocollect.rsrc_list[String(game.c_p_g)].SP -= tile.bldg.path_1_value
						game.autocollect.rsrc.SP -= tile.bldg.path_1_value
					var prod_ratio
					if path_str == "path_1":
						prod_ratio = new_base_value / tile.bldg.path_1_value
					else:
						prod_ratio = 1.0
					var coll_date = tile.bldg.collect_date
					tile.bldg.collect_date = curr_time - (curr_time - coll_date) / prod_ratio + cost_time * 1000.0
				elif tile.bldg.name == "MS":
					tile.bldg.mineral_cap_upgrade = new_base_value - tile.bldg.path_1_value
				elif tile.bldg.name == "GH" and game.science_unlocked.GHA and tile.has("auto_GH"):
					for p in tile.auto_GH.produce:
						game.autocollect.mets[p] -= tile.auto_GH.produce[p]
					game.autocollect.mats.cellulose += tile.auto_GH.cellulose_drain
				if tile.bldg.has("start_date"):
					tile.bldg.start_date += cost_time * 1000
				if tile.bldg.has("overclock_mult"):
					tile.bldg.overclock_date += cost_time * 1000
				tile.bldg[path_str] = next_lv.value
				tile.bldg[path_str + "_value"] = new_base_value
				tile.bldg.construction_date = curr_time
				tile.bldg.XP = round(cost_money / 100.0)
				tile.bldg.construction_length = cost_time * 1000.0
				tile.bldg.is_constructing = true
				game.view.obj.add_time_bar(id, "bldg")
			if not game.objective.empty() and game.objective.type == game.ObjectiveType.UPGRADE:
				game.objective.current += 1
		else:
			if planet.bldg.name == "MS":
				game.mineral_capacity += (new_base_value - planet.bldg.path_1_value) * planet.tile_num
			elif planet.bldg.name == "RL":
				game.autocollect.rsrc.SP += (new_base_value - planet.bldg.path_1_value) * planet.tile_num
			elif planet.has("auto_GH"):
				for p in planet.auto_GH.produce:
					game.autocollect.mets[p] += planet.auto_GH.produce[p] * (new_base_value / planet.bldg["%s_value" % path_str] - 1)
					planet.auto_GH.produce[p] *= new_base_value / planet.bldg["%s_value" % path_str]
					if path_selected == 1:
						game.autocollect.mats.cellulose -= planet.auto_GH.cellulose_drain * (new_base_value / planet.bldg["%s_value" % path_str] - 1)
						planet.auto_GH.cellulose_drain *= new_base_value / planet.bldg["%s_value" % path_str]
			if planet.bldg.has("collect_date"):
				var prod_ratio
				if path_str == "path_1":
					prod_ratio = new_base_value / planet.bldg.path_1_value
				else:
					prod_ratio = 1.0
				var coll_date = planet.bldg.collect_date
				planet.bldg.collect_date = curr_time - (curr_time - coll_date) / prod_ratio
			planet.bldg[path_str] = next_lv.value
			planet.bldg[path_str + "_value"] = new_base_value
			game.universe_data[game.c_u].xp += round(cost_money / 100.0)
			game.view.obj.refresh_planets()
		game.HUD.refresh()
		game.toggle_panel(self)
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.2)

func _on_close_button_pressed():
	game.toggle_panel(self)

func _on_AutoSpeedup_mouse_entered():
	game.show_tooltip(tr("AUTO_SPEEDUP_DESC"))

func _on_AutoSpeedup_pressed():
	update()


func _on_AutoSpeedup_mouse_exited():
	game.hide_tooltip()


func _on_Control_tree_exited():
	queue_free()
