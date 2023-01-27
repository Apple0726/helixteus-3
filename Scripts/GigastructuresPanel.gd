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
	$Control/ProdCostMult.bbcode_text = "%s: %s  %s" % [tr("PRODUCTION_COST_MULT"), Helper.clever_round(g_i.system_num * pow(g_i.dark_matter, 3) / 200.0), "[img]Graphics/Icons/help.png[/img]"]
	surface = 4.2e15 * g_i.system_num * game.u_i.gravitational * pow(g_i.dark_matter, 3)
	if bldg != "":
		update_info()

func update_info():
	var error:bool = false
	costs = Data.costs[bldg].duplicate(true)
	$Control/ProdCostMult.visible = bldg != "TP"
	$Control/ProductionPerSec.visible = bldg != "TP"
	$Control/Production.visible = not bldg in ["TP", "GK"]
	$Control/StoneMM.visible = bldg == "GK"
	var prod_mult = 1.0
	if bldg in ["PP", "RL"]:
		var s_b:float = pow(game.u_i.boltzmann, 4) / pow(game.u_i.planck, 3) / pow(game.u_i.speed_of_light, 2)
		prod_mult = sqrt(s_b) * g_i.B_strength * 1e9
		$Control/ProdMult.bbcode_text = "%s: %s  %s" % [tr("PRODUCTION_MULTIPLIER"), Helper.clever_round(prod_mult), "[img]Graphics/Icons/help.png[/img]"]
		$Control/ProdMult.visible = true
	else:
		$Control/ProdMult.visible = false
	if game.c_g_g == game.ships_c_g_coords.g:
		$Control/GalaxyInfo.text = tr("GS_ERROR3")
		$Control/GalaxyInfo["custom_colors/font_color"] = Color.yellow
		error = true
	if not error:
		$Control/GalaxyInfo["custom_colors/font_color"] = Color.white
		if bldg == "TP":
			if g_i.system_num <= 4999:
				$Control/GalaxyInfo.text = tr("TP_ERROR")
				error = true
			else:
				$Control/GalaxyInfo.text = tr("TP_CONFIRM")
		elif bldg != "GK":
			costs.stone = PI * 100
			if bldg == "ME":
				costs.mythril = 1 / 240000.0
			elif bldg in ["MS", "B", "PP"]:
				costs.mythril = 1 / 300000.0
			elif bldg == "RL":
				costs.mythril = 1 / 120000.0
			if costs.has("energy"):
				costs.energy *= 200.0
			costs.erase("time")
			$Control/GalaxyInfo.text = ""
		for cost in costs:
			costs[cost] *= game.engineering_bonus.BCM * (surface if bldg != "TP" else 1.0)
	if bldg == "ME":
		$Control/ProductionPerSec.text = tr("PRODUCTION_PER_SECOND")
		num = surface * 0.01
		Helper.put_rsrc($Control/Production, 32, {"minerals":num * game.u_i.time_speed * Helper.get_IR_mult("ME")})
	elif bldg == "PP":
		$Control/ProductionPerSec.text = tr("PRODUCTION_PER_SECOND")
		num = surface * 20.0 * prod_mult
		Helper.put_rsrc($Control/Production, 32, {"energy":num * game.u_i.time_speed * Helper.get_IR_mult("PP")})
	elif bldg == "RL":
		$Control/ProductionPerSec.text = tr("PRODUCTION_PER_SECOND")
		num = surface * 0.5 * prod_mult
		Helper.put_rsrc($Control/Production, 32, {"SP":num * game.u_i.time_speed * Helper.get_IR_mult("RL")})
	elif bldg == "MS":
		$Control/ProductionPerSec.text = tr("STORAGE")
		num = surface
		Helper.put_rsrc($Control/Production, 32, {"minerals":num * Helper.get_IR_mult("MS")})
	elif bldg == "B":
		$Control/ProductionPerSec.text = tr("STORAGE")
		num = surface * 60000.0
		Helper.put_rsrc($Control/Production, 32, {"energy":num * Helper.get_IR_mult("B")})
	elif bldg == "GK":
		$Control/ProductionPerSec.text = tr("EXPECTED_RESOURCES")
		num = surface
		Helper.put_rsrc($Control/StoneMM, 32, {"stone":num})
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
		if costs.has("money"):
			game.u_i.xp += costs.money
		g_i.GS = bldg
		g_i.prod_num = num
		g_i.surface = surface
		if bldg == "ME":
			game.autocollect.GS.minerals += num
		elif bldg == "PP":
			game.autocollect.GS.energy += num
		elif bldg == "MS":
			game.mineral_capacity += num
		elif bldg == "B":
			game.energy_capacity += num
		elif bldg == "RL":
			game.autocollect.GS.SP += num
		game.toggle_panel(self)
		game.popup(tr("CONVERT_SUCCESS"), 2.0)
		if not game.achievement_data.progression.has("build_GS"):
			game.earn_achievement("progression", "build_GS")
		if g_i.has("bookmarked"):
			game.bookmarks.galaxy.erase(str(game.c_g_g))
			game.HUD.galaxy_grid_btns.remove_child(game.HUD.galaxy_grid_btns.get_node(str(game.c_g_g)))
			g_i.erase("bookmarked")
		game.view_history.pop_back()
		game.view_history_pos -= 1
		if bldg == "TP":
			if not game.achievement_data.random.has("build_tri_probe_in_slow_univ") and game.u_i.time_speed <= 0.2:
				game.earn_achievement("random", "build_tri_probe_in_slow_univ")
			game.show.dimensions = true
			game.probe_data.append({"tier":2})
			game.switch_view("cluster", {"fn":"delete_galaxy"})
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
					if game.MM_data.has(planet_ids.global):
						game.MM_data.erase(planet_ids.global)
			if dir.file_exists("user://%s/Univ%s/Systems/%s.hx3" % [game.c_sv, game.c_u, system.id]):
				dir.remove("user://%s/Univ%s/Systems/%s.hx3" % [game.c_sv, game.c_u, system.id])
		dir2.remove("user://%s/Univ%s/Galaxies/%s.hx3" % [game.c_sv, game.c_u, game.c_g_g])
		game.HUD.refresh()
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)

func _on_mouse_exited():
	game.hide_tooltip()
