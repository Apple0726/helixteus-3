extends Control

onready var game = get_node("/root/Game")
var ids:Array
var bldg:String#You can mass-upgrade only one type of building
var costs
var path_selected = 1

func _ready():
	if game.tile_data[ids[0]].bldg_info.has("path_2"):
		$PathButtons/Path2.visible = true
	if game.tile_data[ids[0]].bldg_info.has("path_3"):
		$PathButtons/Path3.visible = true
	update()

func geo_seq(q:float, start_n:int, end_n:int):
	return pow(q, start_n) * (1 - pow(q, end_n - start_n)) / (1 - q)

func update():
	costs = {"money":0, "energy":0, "lead":0, "copper":0, "iron":0}
	var same_lv = true
	var path_str = "path_%s" % [path_selected]
	var first_tile = game.tile_data[ids[0]].bldg_info
	for id in ids:
		var tile = game.tile_data[id].bldg_info
		var bldg_info = game.bldg_info[game.tile_data[id].bldg_str]
		var lv_curr = tile[path_str]
		if lv_curr != first_tile[path_str]:
			same_lv = false
		var lv_to = $NextLv.value
		costs.money += round(bldg_info.costs.money * geo_seq(1.2, lv_curr, lv_to))
		if bldg_info.costs.has("energy"):
			costs.energy += round(bldg_info.costs.energy * geo_seq(1.2, lv_curr, lv_to))
		if lv_to >= 10:
			costs.lead += round(bldg_info.base_metal_costs.lead * geo_seq(1.2, max(0, lv_curr - 10), min(lv_to, 20) - 10))
		if lv_to >= 20:
			costs.copper += round(bldg_info.base_metal_costs.copper * geo_seq(1.2, max(0, lv_curr - 20), min(lv_to, 30) - 20))
		if lv_to >= 30:
			costs.iron += round(bldg_info.base_metal_costs.iron * geo_seq(1.2, max(0, lv_curr - 30), min(lv_to, 40) - 30))
	if same_lv:
		$CurrentLv.text = tr("LEVEL") + " %s" % [first_tile[path_str]]
	else:
		$CurrentLv.text = tr("VARYING_LEVELS")
	var icons = Helper.put_rsrc($ScrollContainer/Costs, 32, costs)
	for icon in icons:
		if costs[icon.name] == 0:
			icon.rsrc.visible = false

func _on_Path1_pressed():
	path_selected = 1
	Helper.set_btn_color($PathButtons/Path1)

func _on_Path2_pressed():
	path_selected = 2
	Helper.set_btn_color($PathButtons/Path2)

func _on_Path3_pressed():
	path_selected = 3
	Helper.set_btn_color($PathButtons/Path3)


func _on_NextLv_value_changed(value):
	update()
