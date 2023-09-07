extends "Panel.gd"

var GS_costs:Dictionary = {}
var costs:Dictionary = {}
var g_i:Dictionary
var galaxy_id_g:int
var tile_num:int
var bldg:String = ""
var surface:float
var num:float
var prod_cost_mult:float
var rsrc_from_GK = {}

func _ready():
	set_polygon(size)

func refresh():
	$ScrollContainer/VBoxContainer/TriangulumProbe.visible = game.science_unlocked.has("TPCC")
	prod_cost_mult = g_i.system_num * game.u_i.gravitational * pow(g_i.dark_matter, 3) / 200.0
	$Control/ProdCostMult.text = "%s: %s  %s" % [tr("PRODUCTION_COST_MULT"), Helper.clever_round(prod_cost_mult), "[img]Graphics/Icons/help.png[/img]"]
	surface = 4.2e15 * prod_cost_mult * 200.0
	if bldg != "":
		update_info()

func update_info():
	var error:bool = false
	costs = Data.costs[bldg].duplicate(true)
	$Control/ProdCostMult.visible = bldg != "TP"
	$Control/VBox/ProductionPerSec.visible = bldg != "TP"
	$Control/VBox/Production.visible = not bldg in ["TP", "GK"]
	$Control/VBox/StoneMM.visible = bldg == "GK"
	$Control/VBox/GalaxyInfo.visible = bldg in ["TP", "GK"]
	var prod_mult = 1.0
	if bldg in ["PP", "RL"]:
		var s_b:float = pow(game.u_i.boltzmann, 4) / pow(game.u_i.planck, 3) / pow(game.u_i.speed_of_light, 2)
		prod_mult = sqrt(s_b) * g_i.B_strength * 1e9
		$Control/ProdMult.text = "%s: %s  %s" % [tr("PRODUCTION_MULTIPLIER"), Helper.clever_round(prod_mult), "[img]Graphics/Icons/help.png[/img]"]
		$Control/ProdMult.visible = true
	else:
		$Control/ProdMult.visible = false
	if galaxy_id_g == game.ships_c_g_coords.g:
		$Control/VBox/GalaxyInfo.visible = true
		$Control/VBox/GalaxyInfo.text = tr("GS_ERROR3")
		$Control/VBox/GalaxyInfo["theme_override_colors/font_color"] = Color.YELLOW
		error = true
	if not error:
		$Control/VBox/GalaxyInfo["theme_override_colors/font_color"] = Color.WHITE
		if bldg == "TP":
			if g_i.system_num <= 4999:
				$Control/VBox/GalaxyInfo.text = tr("TP_ERROR")
				error = true
			else:
				$Control/VBox/GalaxyInfo.text = tr("TP_CONFIRM")
		elif bldg != "GK":
			$Control/VBox/Production.visible = true
			$Control/VBox/GalaxyInfo.visible = false
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
			for cost in costs.keys():
				costs[cost] *= game.engineering_bonus.BCM * surface
		else:
			$Control/VBox/GalaxyInfo.text = tr("GALAXY_KILLER_DESC")
			for cost in costs.keys():
				costs[cost] *= game.engineering_bonus.BCM * prod_cost_mult
	if bldg == "ME":
		$Control/VBox/ProductionPerSec.text = tr("PRODUCTION_PER_SECOND")
		num = surface * 0.01
		Helper.put_rsrc($Control/VBox/Production, 32, {"minerals":num * game.u_i.time_speed * Helper.get_IR_mult("ME")})
	elif bldg == "PP":
		$Control/VBox/ProductionPerSec.text = tr("PRODUCTION_PER_SECOND")
		num = surface * 20.0 * prod_mult
		Helper.put_rsrc($Control/VBox/Production, 32, {"energy":num * game.u_i.time_speed * Helper.get_IR_mult("PP")})
	elif bldg == "RL":
		$Control/VBox/ProductionPerSec.text = tr("PRODUCTION_PER_SECOND")
		num = surface * 0.5 * prod_mult
		Helper.put_rsrc($Control/VBox/Production, 32, {"SP":num * game.u_i.time_speed * Helper.get_IR_mult("RL")})
	elif bldg == "MS":
		$Control/VBox/ProductionPerSec.text = tr("STORAGE")
		num = surface
		Helper.put_rsrc($Control/VBox/Production, 32, {"minerals":num * Helper.get_IR_mult("MS")})
	elif bldg == "B":
		$Control/VBox/ProductionPerSec.text = tr("STORAGE")
		num = surface * 60000.0 * game.u_i.charge
		Helper.put_rsrc($Control/VBox/Production, 32, {"energy":num * Helper.get_IR_mult("B")})
	elif bldg == "GK":
		var stone_from_GK = {}
		$Control/VBox/ProductionPerSec.text = tr("EXPECTED_RESOURCES")
		var num_planets = g_i.system_num * game.u_i.gravitational * pow(g_i.dark_matter, 3) * 8
		var avg_planet_size = 30000
		var R = avg_planet_size * 1000.0 / 2#in meters
		var surface_volume = Helper.get_sph_V(R, R - 250)#in m^3
		var mantle_start_depth = 0.01 * avg_planet_size * 1000
		var core_start_depth = 0.43 * avg_planet_size * 1000
		var crust_volume = Helper.get_sph_V(R - 250, R - mantle_start_depth)
		var mantle_volume = Helper.get_sph_V(R - mantle_start_depth, R - core_start_depth)
		var core_volume = Helper.get_sph_V(R - core_start_depth)
		var crust = game.make_planet_composition(273, "crust", avg_planet_size, false)
		var mantle = game.make_planet_composition(273, "mantle", avg_planet_size, false)
		var core = game.make_planet_composition(273, "core", avg_planet_size, false)
		add_stone(stone_from_GK, crust, num_planets * (surface_volume + crust_volume) * ((5600 + mantle_start_depth * 0.01) / 2.0))
		add_stone(stone_from_GK, mantle, num_planets * mantle_volume * ((5690 + (mantle_start_depth + core_start_depth) * 0.01) / 2.0))
		add_stone(stone_from_GK, core, num_planets * core_volume * ((5700 + (core_start_depth + R) * 0.01) / 2.0))
		rsrc_from_GK = {"stone":stone_from_GK}
		var surface_mat_info = {	"coal":{"chance":1, "amount":100},
									"glass":{"chance":0.1, "amount":4},
									"sand":{"chance":0.8, "amount":50},
									"soil":{"chance":0.45, "amount":65},
									"cellulose":{"chance":1, "amount":30}
		}
		for mat in surface_mat_info.keys():
			rsrc_from_GK[mat] = num_planets * surface_volume * surface_mat_info[mat].chance * surface_mat_info[mat].amount * game.u_i.planck
		for met in game.met_info.keys():
			rsrc_from_GK[met] = num_planets * Helper.get_sph_V(R - game.met_info[met].min_depth, R - game.met_info[met].max_depth) / game.met_info[met].rarity * game.u_i.planck
		Helper.put_rsrc($Control/VBox/StoneMM/GridContainer, 32, rsrc_from_GK)
	$Control/Convert.visible = not error
	$Control/VBox/Costs.visible = not error
	$Control/VBox/CostsHBox.visible = not error
	Helper.put_rsrc($Control/VBox/CostsHBox, 32, costs, true, true)

func add_stone(stone:Dictionary, layer:Dictionary, amount:float):
	for comp in layer:
		if stone.has(comp):
			stone[comp] += layer[comp] * amount * game.u_i.planck
		else:
			stone[comp] = layer[comp] * amount * game.u_i.planck

func _on_GS_pressed(extra_arg_0):
	bldg = extra_arg_0
	if $Control.modulate.a > 0:
		$Control/AnimationPlayer.play_backwards("Fade")
	else:
		$Control/AnimationPlayer.play("Fade")
		update_info()

func _on_Convert_pressed():
	if game.check_enough(costs):
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
			game.bookmarks.galaxy.erase(str(galaxy_id_g))
			game.HUD.galaxy_grid_btns.remove_child(game.HUD.galaxy_grid_btns.get_node(str(galaxy_id_g)))
			g_i.erase("bookmarked")
		game.view_history.pop_back()
		game.view_history_pos -= 1
		if bldg == "TP":
			if not game.achievement_data.random.has("build_tri_probe_in_slow_univ") and game.u_i.time_speed <= 0.2:
				game.earn_achievement("random", "build_tri_probe_in_slow_univ")
			game.show.dimensions = true
			game.probe_data.append({"tier":2})
			game.switch_view("cluster", {"fn":"delete_galaxy", "fn_args":[g_i.l_id]})
		elif bldg == "GK":
			game.add_resources(rsrc_from_GK)
			game.switch_view("cluster", {"fn":"delete_galaxy", "fn_args":[g_i.l_id]})
		else:
			game.switch_view("cluster")
		await game.view_tween.finished
		for system in game.system_data:
			if not system.has("discovered"):
				continue
			var dir = DirAccess.open("user://%s/Univ%s/Planets" % [game.c_sv, game.c_u])
			for planet_ids in system.planets:
				if dir.file_exists("%s.hx3" % planet_ids.global):
					dir.remove("%s.hx3" % planet_ids.global)
					if game.boring_machine_data.has(planet_ids.global):
						game.boring_machine_data.erase(planet_ids.global)
			if dir.file_exists("user://%s/Univ%s/Systems/%s.hx3" % [game.c_sv, game.c_u, system.id]):
				dir.remove("user://%s/Univ%s/Systems/%s.hx3" % [game.c_sv, game.c_u, system.id])
		var dir2 = DirAccess.open("user://%s/Univ%s/Galaxies" % [game.c_sv, game.c_u])
		dir2.remove("%s.hx3" % [galaxy_id_g])
		game.HUD.refresh()
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)

func _on_mouse_exited():
	game.hide_tooltip()


func _on_AnimationPlayer_animation_finished(anim_name):
	if $Control.modulate.a == 0:
		$Control/AnimationPlayer.play("Fade")
		update_info()
