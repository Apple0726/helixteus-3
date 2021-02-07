extends "Panel.gd"

var ids:Array
var bldg:String#You can mass-upgrade only one type of building
var costs:Dictionary
var path_selected:int = 1
var path_str:String

onready var path1 = $UpgradePanel/PathButtons/Path1
onready var path2 = $UpgradePanel/PathButtons/Path2
onready var path3 = $UpgradePanel/PathButtons/Path3
onready var next_lv = $UpgradePanel/Control2/NextLv
onready var current_lv = $UpgradePanel/Control2/CurrentLv
onready var next = $UpgradePanel/Next
onready var current = $UpgradePanel/Current
onready var cost_icons = $UpgradePanel/ScrollContainer/Costs
onready var upgrade_btn = $UpgradePanel/Upgrade

func _ready():
	set_polygon($UpgradePanel.rect_size)
	if game.tile_data[ids[0]].bldg.has("path_2"):
		path2.visible = true
	if game.tile_data[ids[0]].bldg.has("path_3"):
		path3.visible = true
	_on_Path1_pressed()
	path1.text = tr("PATH") + " 1"
	path2.text = tr("PATH") + " 2"
	path3.text = tr("PATH") + " 3"

func geo_seq(q:float, start_n:int, end_n:int):
	return max(0, pow(q, start_n) * (1 - pow(q, end_n - start_n)) / (1 - q))

func get_min_lv():
	var min_lv = INF
	for id in ids:
		var tile = game.tile_data[id]
		var lv_curr = tile.bldg[path_str]
		if lv_curr < min_lv:
			min_lv = lv_curr
	return min_lv

func update():
	costs = {"money":0, "energy":0, "lead":0, "copper":0, "iron":0, "aluminium":0, "silver":0, "gold":0, "time":0.0}
	var same_lv = true
	var first_tile = game.tile_data[ids[0]].bldg
	bldg = first_tile.name
	var first_tile_bldg_info = Data[path_str][bldg]
	var lv_to = next_lv.value
	var all_tiles_constructing = true
	for id in ids:
		var tile = game.tile_data[id]
		var tile_bldg:String = tile.bldg.name
		var lv_curr = tile.bldg[path_str]
		if lv_curr != first_tile[path_str]:
			same_lv = false
		if tile.bldg.is_constructing or tile.bldg[path_str] >= next_lv.value:
			continue
		all_tiles_constructing = false
		var base_costs = Data.costs[tile_bldg]
		var base_metal_costs = Data[path_str][tile_bldg].metal_costs
		costs.money += round(base_costs.money * geo_seq(1.25, lv_curr, lv_to))
		costs.time = round(base_costs.time * geo_seq(1.24, lv_curr, lv_to))
		if base_costs.has("energy"):
			costs.energy += round(base_costs.energy * geo_seq(1.2, lv_curr, lv_to))
		if lv_curr <= 10 and lv_to >= 11:
			costs.lead += base_metal_costs.lead
		if lv_curr <= 20 and lv_to >= 21:
			costs.copper += base_metal_costs.copper
		if lv_curr <= 30 and lv_to >= 31:
			costs.iron += base_metal_costs.iron
		if lv_curr <= 40 and lv_to >= 41:
			costs.aluminium += base_metal_costs.aluminium
		if lv_curr <= 50 and lv_to >= 51:
			costs.silver += base_metal_costs.silver
		if lv_curr <= 60 and lv_to >= 61:
			costs.gold += base_metal_costs.gold
	var rsrc_icon = [Data.desc_icons[bldg][path_selected - 1]] if Data.desc_icons.has(bldg) and Data.desc_icons[bldg] else []
	if same_lv:
		current_lv.text = tr("LEVEL") + " %s" % [first_tile[path_str]]
		current.text = ""
		var curr_value = bldg_value(first_tile_bldg_info.value, first_tile[path_str], first_tile_bldg_info.pw) * Helper.get_IR_mult(bldg)
		if bldg == "SP":
			curr_value = bldg_value(Helper.get_SP_production(game.planet_data[game.c_p].temperature, first_tile_bldg_info.value), first_tile[path_str], first_tile_bldg_info.pw)
		elif bldg == "AE":
			curr_value = bldg_value(Helper.get_AE_production(game.planet_data[game.c_p].pressure, first_tile_bldg_info.value), first_tile[path_str], first_tile_bldg_info.pw)
		if first_tile_bldg_info.is_value_integer:
			curr_value = round(curr_value)
		else:
			curr_value = game.clever_round(curr_value, 3)
		game.add_text_icons(current, ("[center]" + first_tile_bldg_info.desc) % [curr_value], rsrc_icon, 20)
	else:
		costs.erase("time")
		current_lv.text = tr("VARYING_LEVELS")
		current.text = tr("VARIES")
	if all_tiles_constructing:
		game.popup(tr("SELECTED_BLDGS_UNDER_CONSTR"), 2)
		game.remove_upgrade_panel()
		return
	next.text = ""
	var next_value = bldg_value(first_tile_bldg_info.value, lv_to, first_tile_bldg_info.pw) * Helper.get_IR_mult(bldg)
	if bldg == "SP":
		next_value = bldg_value(Helper.get_SP_production(game.planet_data[game.c_p].temperature, first_tile_bldg_info.value), lv_to, first_tile_bldg_info.pw)
	elif bldg == "AE":
		next_value = bldg_value(Helper.get_AE_production(game.planet_data[game.c_p].pressure, first_tile_bldg_info.value), lv_to, first_tile_bldg_info.pw)
	if first_tile_bldg_info.is_value_integer:
		next_value = round(next_value)
	else:
		next_value = game.clever_round(next_value, 3)
	game.add_text_icons(next, ("[center]" + first_tile_bldg_info.desc) % [next_value], rsrc_icon, 20)
	var icons = Helper.put_rsrc(cost_icons, 32, costs)
	for icon in icons:
		if costs[icon.name] == 0:
			icon.rsrc.visible = false
	
func bldg_value(base_value, lv:int, pw:float = 1.15):
	return game.clever_round(base_value * pow((lv - 1) / 10 + 1, pw * pw) * pow(pw, lv - 1), 3)

func _on_Path1_pressed():
	path_selected = 1
	path_str = "path_%s" % [path_selected]
	next_lv.min_value = get_min_lv() + 1
	Helper.set_btn_color(path1)
	update()

func _on_Path2_pressed():
	path_selected = 2
	path_str = "path_%s" % [path_selected]
	next_lv.min_value = get_min_lv() + 1
	Helper.set_btn_color(path2)
	update()

func _on_Path3_pressed():
	path_selected = 3
	path_str = "path_%s" % [path_selected]
	next_lv.min_value = get_min_lv() + 1
	Helper.set_btn_color(path3)
	update()


func _on_NextLv_value_changed(_value):
	update()


func _on_ScrollContainer_resized():
	$UpgradePanel.visible = false
	$UpgradePanel.visible = true


func _on_Upgrade_pressed():
	if game.c_v != "planet":
		return
	update()
	var bldg_info = Data[path_str][bldg]
	if game.check_enough(costs):
		game.deduct_resources(costs)
		for id in ids:
			var tile = game.tile_data[id]
			if tile.bldg.is_constructing or tile.bldg[path_str] >= next_lv.value:
				continue
			var curr_time = OS.get_system_time_msecs()
			var new_value = bldg_value(bldg_info.value, next_lv.value, bldg_info.pw)
			var base_costs = Data.costs[tile.bldg.name]
			var cost_time = round(base_costs.time * geo_seq(1.24, tile.bldg[path_str], next_lv.value))
			var cost_money = round(base_costs.money * geo_seq(1.25, tile.bldg[path_str], next_lv.value))
			if tile.bldg.has("collect_date"):
				var prod_ratio
				if path_str == "path_1":
					prod_ratio = new_value / game.tile_data[id].bldg.path_1_value
				else:
					prod_ratio = 1.0
				var coll_date = tile.bldg.collect_date
				tile.bldg.collect_date = curr_time - (curr_time - coll_date) / prod_ratio + cost_time * 1000.0
			elif tile.bldg.name == "MS":
				tile.bldg.mineral_cap_upgrade = new_value - tile.bldg.path_1_value
			if tile.bldg.has("start_date"):
				tile.bldg.start_date += cost_time * 1000
			if tile.bldg.has("overclock_mult"):
				tile.bldg.overclock_date += cost_time * 1000
			tile.bldg[path_str] = next_lv.value
			tile.bldg[path_str + "_value"] = new_value
			tile.bldg.construction_date = curr_time
			tile.bldg.XP = round(cost_money / 100.0)
			tile.bldg.construction_length = cost_time * 1000.0
			tile.bldg.is_constructing = true
			game.view.obj.add_time_bar(id, "bldg")
		game.remove_upgrade_panel()
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.2)


func _on_close_button_pressed():
	game.remove_upgrade_panel()
