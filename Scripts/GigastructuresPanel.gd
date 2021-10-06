extends "Panel.gd"

var GS_costs:Dictionary = {}
var costs:Dictionary = {}
var g_i:Dictionary
var tile_num:int
var bldg:String = ""
var surface:float
var num:float

func _ready():
	set_polygon(rect_size)

func refresh():
	g_i = game.galaxy_data[game.c_g]
	$ScrollContainer/VBoxContainer/TriangulumProbe.visible = game.science_unlocked.has("TPCC")
	var cte:float = 4.0 * 1.3 * 4.0 * PI * pow(1000000.0 + 6000000.0 * 2.5, 2)
	surface = cte * g_i.system_num * pow(g_i.dark_matter, 3)
	$Control/ProdCostMult.bbcode_text = "%s: %s  %s" % [tr("PRODUCTION_COST_MULT"), Helper.clever_round(surface / cte / 200.0), "[img]Graphics/Icons/help.png[/img]"]
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
	if not error:
		if bldg != "TP":
			costs.stone = PI * 100
			if bldg in ["ME", "MS", "RL"]:
				costs.mythril = 1 / 80000.0
			elif bldg == "PP":
				costs.mythril = 1 / 500000.0
			if costs.has("energy"):
				costs.energy *= 200.0
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
		num = surface * 0.01
		Helper.put_rsrc($Control/Production, 32, {"minerals":num * game.u_i.time_speed * Helper.get_IR_mult("ME")})
	elif bldg == "PP":
		$Control/ProductionPerSec.text = tr("PRODUCTION_PER_SECOND")
		num = surface * 15.0
		Helper.put_rsrc($Control/Production, 32, {"energy":num * game.u_i.time_speed * Helper.get_IR_mult("PP")})
	elif bldg == "RL":
		$Control/ProductionPerSec.text = tr("PRODUCTION_PER_SECOND")
		num = surface * 1.5
		Helper.put_rsrc($Control/Production, 32, {"SP":num * game.u_i.time_speed * Helper.get_IR_mult("RL")})
	elif bldg == "MS":
		$Control/ProductionPerSec.text = tr("STORAGE")
		num = surface
		Helper.put_rsrc($Control/Production, 32, {"minerals":num * Helper.get_IR_mult("MS")})
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
		var dir2 = Directory.new()
		game.deduct_resources(costs)
		g_i.GS = bldg
		g_i.prod_num = num
		g_i.surface = surface
		if bldg == "ME":
			game.autocollect.GS.minerals += num
		elif bldg == "PP":
			game.autocollect.GS.energy += num
		elif bldg == "MS":
			game.mineral_capacity += num
		elif bldg == "RL":
			game.autocollect.GS.SP += num
		game.toggle_panel(self)
		game.popup(tr("CONVERT_SUCCESS"), 2.0)
		if g_i.has("bookmarked"):
			game.bookmarks.galaxy.erase(str(game.c_g_g))
			game.HUD.galaxy_grid_btns.remove_child(game.HUD.galaxy_grid_btns.get_node(str(game.c_g_g)))
			g_i.erase("bookmarked")
		if bldg == "TP":
			game.show.dimensions = true
			game.probe_data.append({"tier":2})
			game.switch_view("cluster", false, "delete_galaxy")
		else:
			game.switch_view("cluster")
		yield(game.view_tween, "tween_all_completed")
		for system in game.system_data:
			if not system.has("discovered"):
				continue
			var dir = Directory.new()
			for planet_ids in system.planets:
				if dir.file_exists("user://%s/Univ%s/Planets/%s.hx3" % [game.c_sv, game.c_u, planet_ids.global]):
					dir.remove("user://%s/Univ%s/Planets/%s.hx3" % [game.c_sv, game.c_u, planet_ids.global])
			if dir.file_exists("user://%s/Univ%s/Systems/%s.hx3" % [game.c_sv, game.c_u, system.id]):
				dir.remove("user://%s/Univ%s/Systems/%s.hx3" % [game.c_sv, game.c_u, system.id])
		dir2.remove("user://%s/Univ%s/Galaxies/%s.hx3" % [game.c_sv, game.c_u, game.c_g_g])
		game.HUD.refresh()
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)

func _on_mouse_exited():
	game.hide_tooltip()
