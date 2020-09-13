extends Control

onready var game = get_node("/root/Game")
var ids:Array
var bldg:String#You can mass-upgrade only one type of building
var costs:Dictionary
var path_selected:int = 1
var path_str:String

onready var path1 = $UpgradePanel/VBoxContainer/PathButtons/Path1
onready var path2 = $UpgradePanel/VBoxContainer/PathButtons/Path2
onready var path3 = $UpgradePanel/VBoxContainer/PathButtons/Path3
onready var next_lv = $UpgradePanel/VBoxContainer/Control2/NextLv
onready var current_lv = $UpgradePanel/VBoxContainer/Control2/CurrentLv
onready var next = $UpgradePanel/VBoxContainer/HBoxContainer2/Next
onready var current = $UpgradePanel/VBoxContainer/HBoxContainer2/Current
onready var cost_icons = $UpgradePanel/VBoxContainer/HBoxContainer3/ScrollContainer/Costs
onready var upgrade_btn = $UpgradePanel/VBoxContainer/HBoxContainer3/Upgrade

func _ready():
	if game.tile_data[ids[0]].has("path_2"):
		path2.visible = true
	if game.tile_data[ids[0]].has("path_3"):
		path3.visible = true
	_on_Path1_pressed()
	path1.text = tr("PATH") + " 1"
	path2.text = tr("PATH") + " 2"
	path3.text = tr("PATH") + " 3"
	update()

func geo_seq(q:float, start_n:int, end_n:int):
	return pow(q, start_n) * (1 - pow(q, end_n - start_n)) / (1 - q)

func get_min_lv():
	var min_lv = INF
	for id in ids:
		var tile = game.tile_data[id]
		var lv_curr = tile[path_str]
		if lv_curr < min_lv:
			min_lv = lv_curr
	return min_lv

func update():
	costs = {"money":0, "energy":0, "lead":0, "copper":0, "iron":0, "time":0.0}
	var same_lv = true
	path_str = "path_%s" % [path_selected]
	var first_tile = game.tile_data[ids[0]]
	bldg = first_tile.bldg_str
	var first_tile_bldg_info = Data[path_str][bldg]
	var min_lv = get_min_lv()
	var lv_to = next_lv.value
	if lv_to < min_lv + 1:
		lv_to = min_lv + 1
	var all_tiles_constructing = true
	for id in ids:
		var tile = game.tile_data[id]
		var lv_curr = tile[path_str]
		if lv_curr != first_tile[path_str]:
			same_lv = false
		if tile.is_constructing:
			continue
		all_tiles_constructing = false
		#var bldg_info = game.bldg_info[game.tile_data[id].bldg_str]
		var base_costs = Data.costs[tile.bldg_str]
		var base_metal_costs = Data[path_str][tile.bldg_str].metal_costs
		costs.money += round(base_costs.money * geo_seq(1.25, lv_curr, lv_to))
		costs.time += round(base_costs.time * geo_seq(1.25, lv_curr, lv_to))
		if base_costs.has("energy"):
			costs.energy += round(base_costs.energy * geo_seq(1.2, lv_curr, lv_to))
		if lv_to >= 10:
			costs.lead += round(base_metal_costs.lead * geo_seq(1.2, max(0, lv_curr - 10), min(lv_to, 20) - 10))
		if lv_to >= 20:
			costs.copper += round(base_metal_costs.copper * geo_seq(1.2, max(0, lv_curr - 20), min(lv_to, 30) - 20))
		if lv_to >= 30:
			costs.iron += round(base_metal_costs.iron * geo_seq(1.2, max(0, lv_curr - 30), min(lv_to, 40) - 30))
	if same_lv:
		current_lv.text = tr("LEVEL") + " %s" % [first_tile[path_str]]
		current.text = ""
		game.add_text_icons(current, ("[center]" + first_tile_bldg_info.desc) % [bldg_value(first_tile_bldg_info.value, min_lv)],  [Data.icons[bldg]], 20)
	else:
		current_lv.text = tr("VARYING_LEVELS")
		current.text = tr("VARIES")
	if all_tiles_constructing:
		game.popup(tr("SELECTED_BLDGS_UNDER_CONSTR"), 2)
		game.remove_upgrade_panel()
		return
	next_lv.min_value = min_lv
	next.text = ""
	game.add_text_icons(next, ("[center]" + first_tile_bldg_info.desc) % [bldg_value(first_tile_bldg_info.value, lv_to)], [Data.icons[bldg]], 20)
	var icons = Helper.put_rsrc(cost_icons, 32, costs)
	for icon in icons:
		if costs[icon.name] == 0:
			icon.rsrc.visible = false
	if lv_to == min_lv:
		upgrade_btn.visible = false
	else:
		upgrade_btn.visible = true
	
func bldg_value(base_value, lv):
	return game.clever_round(base_value * pow((lv - 1) / 10 + 1, 2) * pow(1.2, lv - 1), 3)

func _on_Path1_pressed():
	path_selected = 1
	Helper.set_btn_color(path1)
	update()

func _on_Path2_pressed():
	path_selected = 2
	Helper.set_btn_color(path2)
	update()

func _on_Path3_pressed():
	path_selected = 3
	Helper.set_btn_color(path3)
	update()


func _on_NextLv_value_changed(value):
	update()


func _on_ScrollContainer_resized():
	$UpgradePanel.visible = false
	$UpgradePanel.visible = true


func _on_Upgrade_pressed():
	if game.c_v != "planet":
		return
	update()
	if game.check_enough(costs):
		game.deduct_resources(costs)
		for id in ids:
			if game.tile_data[id].is_constructing:
				continue
			var curr_time = OS.get_system_time_msecs()
			if game.tile_data[id].has("collect_date"):
				var prod = 1000 / game.tile_data[id].path_1_value
				var prod_ratio
				if path_str == "path_1":
					prod_ratio = bldg_value(Data[path_str][bldg].value, next_lv.value) / game.tile_data[id].path_1_value
				else:
					prod_ratio = 1.0
				var coll_date = game.tile_data[id].collect_date
				game.tile_data[id].collect_date = curr_time - (curr_time - coll_date) / prod_ratio + costs.time * 1000.0
			game.tile_data[id][path_str] = next_lv.value
			game.tile_data[id][path_str + "_value"] = bldg_value(Data[path_str][bldg].value, next_lv.value)
			game.tile_data[id].construction_date = curr_time
			game.tile_data[id].construction_length = costs.time * 1000.0
			game.tile_data[id].is_constructing = true
			game.view.obj.add_time_bar(id)
		game.remove_upgrade_panel()
