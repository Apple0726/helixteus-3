extends "Panel.gd"

var tf_costs:Dictionary = {}
var tf_type = ""
var costs:Dictionary = {}
var pressure:float
var tile_num:int
var lake_num:int

func _ready():
	set_polygon($Background.rect_size)

func refresh():
	if tf_type != "":
		call("_on_%s_pressed" % tf_type)

func update_info():
	tf_costs = {"energy":1000000, "SP":10000}
	var pressure_mult = max(1, pressure)
	var lake_mult = 1 + 9 * lake_num / float(tile_num)
	for cost in tf_costs:
		tf_costs[cost] *= tile_num * pressure_mult * lake_mult
	costs.erase("time")
	for cost in costs:
		costs[cost] *= tile_num
	$Control/CostMult.text = "%s:\n%s: x %s\n%s: x %s\n%s: x %s" % [tr("TF_COST_MULT"), tr("NUMBER_OF_TILES"), tile_num, tr("ATMOSPHERE_PRESSURE"), game.clever_round(pressure_mult, 3), tr("LAKES"), game.clever_round(lake_mult, 3)]
	Helper.put_rsrc($Control/TCVBox, 32, tf_costs, true, true)
	Helper.put_rsrc($Control/BCVBox, 32, costs, true, true)
	$Control.visible = true

func _on_MS_pressed():
	tf_type = "MS"
	$Control/BuildingCosts.text = "%s (%s %s)" % [tr("BUILDING_COSTS"), tile_num, tr("MINERAL_SILOS").to_lower()]
	costs = Data.costs.MS.duplicate(true)
	$Control/Note.visible = false
	update_info()

func _on_AE_pressed():
	tf_type = "AE"
	$Control/BuildingCosts.text = "%s (%s %s)" % [tr("BUILDING_COSTS"), tile_num, tr("ATMOSPHERE_EXTRACTORS").to_lower()]
	costs = Data.costs.AE.duplicate(true)
	$Control/Note.visible = false
	update_info()

func _on_MM_pressed():
	tf_type = "MM"
	$Control/BuildingCosts.text = "%s (%s %s)" % [tr("BUILDING_COSTS"), tile_num, tr("MINING_MACHINES").to_lower()]
	costs = Data.costs.MM.duplicate(true)
	$Control/Note.visible = true
	update_info()

func _on_GH_pressed():
	tf_type = "GH"
	$Control/BuildingCosts.text = "%s (%s %s)" % [tr("BUILDING_COSTS"), tile_num, tr("GREENHOUSES").to_lower()]
	costs = Data.costs.GH.duplicate(true)
	costs.soil = 10
	$Control/Note.visible = false
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
		var planet = game.planet_data[game.c_p]
		planet.tile_num = tile_num
		planet.bldg = {}
		planet.bldg.name = tf_type
		planet.bldg.is_constructing = false
		game.xp += round(total_costs.money / 100.0)
		planet.bldg.path_1 = 1
		planet.bldg.path_1_value = Data.path_1[tf_type].value
		if tf_type in ["MM", "GH", "AE"]:
			planet.bldg.path_2 = 1
			planet.bldg.path_2_value = Data.path_2[tf_type].value
		if tf_type in ["MM", "AE"]:
			planet.bldg.collect_date = OS.get_system_time_msecs()
			planet.bldg.stored = 0
		if tf_type == "MS":
			game.mineral_capacity += Data.path_1.MS.value * tile_num
		if tf_type == "MM" and not planet.has("depth"):
			planet.depth = 0
		if Helper.has_IR(tf_type):
			planet.bldg.IR_mult = Helper.get_IR_mult(planet.bldg.name)
		else:
			planet.bldg.IR_mult = 1
		game.switch_view("system")
		var dir = Directory.new()
		dir.remove("user://Save1/Planets/%s.hx3" % [game.c_p_g])
		game.popup(tr("TF_SUCCESS"), 2)
		game.HUD.refresh()
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.2)
