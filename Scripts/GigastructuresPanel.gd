extends "Panel.gd"

var GS_costs:Dictionary = {}
var costs:Dictionary = {}
var g_i:Dictionary
var tile_num:int
var bldg:String = ""
var surface:float
var num:float

func _ready():
	set_polygon($Background.rect_size)

func refresh():
	g_i = game.galaxy_data[game.c_g]
	$ScrollContainer/VBoxContainer/TriangulumProbe.visible = game.science_unlocked.TPCC
	var planet_num:float = round(g_i.system_num * 2 * pow(g_i.dark_matter, 1.1))
	#							 1.3 ~= E(X^2)/E(X)^2
	surface = round(planet_num * 1.3 * 4 * PI * pow((1000000 + 6000000 * 2.5) * g_i.dark_matter, 2))
	if bldg != "":
		update_info()

func update_info():
	var error:bool = false
	costs = Data.costs[bldg].duplicate(true)
	$Control/ProductionPerSec.visible = bldg != "TP"
	$Control/Production.visible = bldg != "TP"
	if game.c_g_g == game.ships_c_g_coords.g:
		$Control/GalaxyInfo.text = tr("GS_ERROR")
		error = true
	if bldg != "TP":
		costs.stone = PI * 100
		costs.mythril = 1 / 10000.0
		costs.erase("time")
		for cost in costs:
			costs[cost] *= surface
		$Control/GalaxyInfo.text = ""
	else:
		if g_i.system_num <= 9000:
			$Control/GalaxyInfo.text = tr("TP_ERROR")
			error = true
		else:
			$Control/GalaxyInfo.text = tr("TP_CONFIRM")
	if bldg == "ME":
		$Control/ProductionPerSec.text = tr("PRODUCTION_PER_SECOND")
		num = Data.path_1.ME.value * surface / 1000.0
		Helper.put_rsrc($Control/Production, 32, {"minerals":num})
	elif bldg == "PP":
		$Control/ProductionPerSec.text = tr("PRODUCTION_PER_SECOND")
		num = Data.path_1.PP.value * surface
		Helper.put_rsrc($Control/Production, 32, {"energy":num})
	elif bldg == "RL":
		$Control/ProductionPerSec.text = tr("PRODUCTION_PER_SECOND")
		num = Data.path_1.RL.value * surface
		Helper.put_rsrc($Control/Production, 32, {"SP":num})
	elif bldg == "MS":
		$Control/ProductionPerSec.text = tr("STORAGE")
		num = Data.path_1.MS.value * surface / 1000.0
		Helper.put_rsrc($Control/Production, 32, {"minerals":num})
	$Control/Convert.visible = not error
	$Control/Costs.visible = not error
	$Control/CostsHBox.visible = not error
	Helper.put_rsrc($Control/CostsHBox, 32, costs, true, true)
	$Control.visible = true

func _on_GS_pressed(extra_arg_0):
	bldg = extra_arg_0
	update_info()

func _on_Convert_pressed():
	if game.check_enough(costs):
		game.deduct_resources(costs)
		g_i.GS = bldg
		g_i.prod_num = num
		g_i.surface = surface
		if bldg == "ME":
			game.autocollect.MS.minerals += num
		elif bldg == "PP":
			game.autocollect.MS.energy += num
		elif bldg == "MS":
			game.mineral_capacity += num
		elif bldg == "RL":
			game.autocollect.MS.SP += num
		game.toggle_panel(self)
		for system in game.system_data:
			if not system.has("discovered"):
				continue
			var dir = Directory.new()
			for planet_ids in system.planets:
				if dir.file_exists("user://Save%s/Univ%s/Planets/%s.hx3" % [game.c_sv, game.c_u, planet_ids.global]):
					dir.remove("user://Save%s/Univ%s/Planets/%s.hx3" % [game.c_sv, game.c_u, planet_ids.global])
			if dir.file_exists("user://Save%s/Univ%s/Systems/%s.hx3" % [game.c_sv, game.c_u, system.id]):
				dir.remove("user://Save%s/Univ%s/Systems/%s.hx3" % [game.c_sv, game.c_u, system.id])
		game.popup(tr("CONVERT_SUCCESS"), 2.0)
		if bldg == "TP":
			game.show.dimensions = true
			game.probe_data.append({"tier":2})
			game.switch_view("cluster", false, "delete_galaxy")
		else:
			game.switch_view("cluster")
		var dir2 = Directory.new()
		dir2.remove("user://Save%s/Univ%s/Galaxies/%s.hx3" % [game.c_sv, game.c_u, game.c_g_g])
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)
