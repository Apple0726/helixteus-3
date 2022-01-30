extends "Panel.gd"
onready var HX_data_scene = preload("res://Scenes/HXData.tscn")

const TEST:bool = false
var travel_view:String
var travel_energy_cost:float = 0
var total_energy_cost:float = 0
var time_cost:float = 0
var depart_pos:Vector2
var dest_pos:Vector2
var dest_p_id:int
var distance:int
var planets_in_depart_system:Array
var depart_planet_data:Dictionary
var atm_exit_cost:float
var gravity_exit_cost:float
var atm_entry_cost:float
var gravity_entry_cost:float

func _ready():
	set_polygon($Background.rect_size)
	$Panel/TravelCosts.text = "%s:" % [tr("TRAVEL_COSTS")]
	$TotalEnergyCost.text = "%s:" % [tr("TOTAL_ENERGY_COST")]

func refresh():
	var depart_id:int
	var dest_id:int
	var coords:Dictionary = game.ships_c_coords
	var g_coords:Dictionary = game.ships_c_g_coords
	var g_s:int = game.ships_c_g_coords.s
	var file = File.new()
	file.open("user://%s/Univ%s/Systems/%s.hx3" % [game.c_sv, game.c_u, g_s], File.READ)
	planets_in_depart_system = file.get_var()
	file.close()
	depart_planet_data = planets_in_depart_system[coords.p]
	if game.c_s_g == g_coords.s:
		travel_view = "system"
		depart_id = coords.p
		dest_id = dest_p_id
		depart_pos = polar2cartesian(depart_planet_data.distance, depart_planet_data.angle)
		dest_pos = polar2cartesian(game.planet_data[dest_id].distance, game.planet_data[dest_id].angle)
		distance = depart_pos.distance_to(dest_pos)
	elif game.c_g_g == g_coords.g:
		travel_view = "galaxy"
		distance = 73
		depart_id = coords.s
		dest_id = game.planet_data[dest_p_id].parent
		depart_pos = game.system_data[depart_id].pos
		dest_pos = game.system_data[dest_id].pos
		distance *= depart_pos.distance_to(dest_pos)
	elif game.c_c_g == g_coords.c:
		travel_view = "cluster"
		distance = 45454
		depart_id = coords.g
		dest_id = game.system_data[game.planet_data[dest_p_id].parent].parent
		depart_pos = game.galaxy_data[depart_id].pos
		dest_pos = game.galaxy_data[dest_id].pos
		distance *= depart_pos.distance_to(dest_pos)
	elif game.c_sc == coords.sc:
		travel_view = "supercluster"
		distance = 818181
		depart_id = coords.c
		dest_id = game.galaxy_data[game.system_data[game.planet_data[dest_p_id].parent].parent].parent
		depart_pos = game.cluster_data[depart_id].pos
		dest_pos = game.cluster_data[dest_id].pos
		distance *= depart_pos.distance_to(dest_pos)
	else:
		travel_view = "universe"
		distance = 96969696
		depart_id = coords.sc
		dest_id = game.cluster_data[game.galaxy_data[game.system_data[game.planet_data[dest_p_id].parent].parent].parent].parent
		depart_pos = game.supercluster_data[depart_id].pos
		dest_pos = game.supercluster_data[dest_id].pos
		distance *= depart_pos.distance_to(dest_pos)
	if TEST:
		distance = 1
	calc_costs()
	for child in $Scroll/Enemies.get_children():
		$Scroll/Enemies.remove_child(child)
		child.free()
	if game.planet_data[dest_p_id].has("HX_data"):
		for HX_data in game.planet_data[dest_p_id].HX_data:
			var HX_data_node = HX_data_scene.instance()
			if not HX_data.has("class"):
				HX_data.class = 1
			HX_data_node.get_node("HX").texture = load("res://Graphics/HX/%s_%s.png" % [HX_data.class, HX_data.type])
			HX_data_node.get_node("HP").text = "%s / %s" % [Helper.format_num(HX_data.HP, false, 4), Helper.format_num(HX_data.total_HP, false, 4)]
			HX_data_node.get_node("Lv").text = "%s %s" % [tr("LV"), HX_data.lv]
			HX_data_node.get_node("VBoxContainer/Atk/Label").text = Helper.format_num(HX_data.atk, false, 4)
			HX_data_node.get_node("VBoxContainer/Acc/Label").text = Helper.format_num(HX_data.acc, false, 4)
			HX_data_node.get_node("VBoxContainer2/Def/Label").text = Helper.format_num(HX_data.def, false, 4)
			HX_data_node.get_node("VBoxContainer2/Eva/Label").text = Helper.format_num(HX_data.eva, false, 4)
			$Scroll/Enemies.add_child(HX_data_node)
			HX_data_node.rect_min_size.y = 70
		$Enemies.text = "%s (%s)" % [tr("ENEMIES"), len(game.planet_data[dest_p_id].HX_data)]
	else:
		$Enemies.text = tr("ENEMIES")
	$Scroll/Enemies.visible = not game.planet_data[dest_p_id].has("conquered")
	$EnergyCost2.adv_icons = [Data.energy_icon, Data.energy_icon, Data.energy_icon, Data.energy_icon]
	$EnergyCost2.help_text = "%s: @i %s%s\n%s: @i %s%s\n%s: @i %s%s\n%s: @i %s%s" % [tr("ATMOSPHERE_EXIT"), atm_exit_cost, (" (-%s%%)" % (100 - 100 * get_entry_exit_multiplier(depart_planet_data.MS_lv))) if has_SE(depart_planet_data) else "", tr("GRAVITY_EXIT"), gravity_exit_cost, (" (-%s%%)" % (100 - 100 * get_entry_exit_multiplier(depart_planet_data.MS_lv))) if has_SE(depart_planet_data) else "", tr("ATMOSPHERE_ENTRY"), atm_entry_cost, (" (-%s%%)" % (100 - 100 * get_entry_exit_multiplier(game.planet_data[dest_p_id].MS_lv))) if has_SE(game.planet_data[dest_p_id]) else "", tr("GRAVITY_ENTRY"), gravity_entry_cost,  (" (-%s%%)" % (100 - 100 * get_entry_exit_multiplier(game.planet_data[dest_p_id].MS_lv))) if has_SE(game.planet_data[dest_p_id]) else ""]

func _on_Send_pressed():
	if game.universe_data[game.c_u].lv < 35:
		if not game.science_unlocked.has("MAE") and game.planet_data[dest_p_id].pressure > 10 and game.planet_data[dest_p_id].pressure > sqrt(game.energy / 10000.0):
			game.long_popup(tr("PLANET_PRESSURE_TOO_HIGH"), "")
		elif game.planet_data[dest_p_id].pressure > 20:
			game.show_YN_panel("send_ships", tr("HIGH_PRESSURE_PLANET"))
		elif time_cost > 4 * 60 * 60 * 1000:
			game.show_YN_panel("send_ships", tr("LONG_TRAVEL"))
		else:
			send_ships()
	else:
		send_ships()

func send_ships():
	if game.ships_travel_view == "-":
		if time_cost != 0:
			if game.energy >= total_energy_cost:
				if time_cost >= 1000 * 365 * 24 * 60 * 60 * 1000:
					if not game.achievement_data.random[2]:
						game.earn_achievement("random", 2)
				game.energy -= round(total_energy_cost)
				game.ships_depart_pos = depart_pos
				game.ships_dest_pos = dest_pos
				game.ships_dest_coords = {"sc":game.c_sc, "c":game.c_c, "g":game.c_g, "s":game.c_s, "p":dest_p_id}
				game.ships_dest_g_coords = {"c":game.c_c_g, "g":game.c_g_g, "s":game.c_s_g}
				game.ships_travel_view = travel_view
				game.ships_travel_start_date = OS.get_system_time_msecs()
				game.ships_travel_length = time_cost
				game.toggle_panel(self)
				if game.c_v == travel_view:
					game.view.refresh()
					game.HUD.refresh()
				else:
					game.switch_view(travel_view)
			else:
				game.popup(tr("NOT_ENOUGH_ENERGY"), 1.5)
	else:
		game.popup(tr("SHIPS_ALREADY_TRAVELLING"), 1.5)
	
func _on_HSlider_value_changed(value):
	calc_costs()

func has_SE(p_i:Dictionary):
	return p_i.has("MS") and p_i.MS == "M_SE" and not p_i.bldg.is_constructing

func get_atm_exit_cost(pressure:float):
	var res:float = pow(pressure * 10, 2) * 100
	if has_SE(depart_planet_data):
		res *= get_entry_exit_multiplier(depart_planet_data.MS_lv)
	return round(res)

func get_grav_exit_cost(size:float):
	var res:float = pow(size / 250.0, 2.5) * game.u_i.gravitational
	if has_SE(depart_planet_data):
		res *= get_entry_exit_multiplier(depart_planet_data.MS_lv)
	return round(res)

func get_atm_entry_cost(pressure:float):
	var res:float = 500 / clamp(pressure, 0.1, 10)
	if has_SE(game.planet_data[dest_p_id]):
		res *= get_entry_exit_multiplier(game.planet_data[dest_p_id].MS_lv)
	return round(res)

func get_grav_entry_cost(size:float):
	var res:float = pow(size / 600.0, 2.5) * 3 * game.u_i.gravitational
	if has_SE(game.planet_data[dest_p_id]):
		res *= get_entry_exit_multiplier(game.planet_data[dest_p_id].MS_lv)
	return round(res)

func get_entry_exit_multiplier(lv:int):
	if lv > 0:
		return 0
	else:
		return 0.5

func get_travel_cost_multiplier(lv:int):
	if lv > 0:
		return 0.5
	else:
		return 0.75

func calc_costs():
	var slider_factor = pow(10, $Panel/HSlider.value / 25.0 - 2)
	atm_exit_cost = get_atm_exit_cost(depart_planet_data.pressure)
	gravity_exit_cost = get_grav_exit_cost(depart_planet_data.size)
	atm_entry_cost = get_atm_entry_cost(game.planet_data[dest_p_id].pressure)
	gravity_entry_cost = get_grav_entry_cost(game.planet_data[dest_p_id].size)
	if depart_planet_data.type in [11, 12]:
		atm_exit_cost = 0
		gravity_exit_cost = 0
	if game.planet_data[dest_p_id].type in [11, 12]:
		atm_entry_cost = 0
		gravity_entry_cost = 0
	var entry_exit_cost:float = round(atm_entry_cost + atm_exit_cost + gravity_entry_cost + gravity_exit_cost)
	$EnergyCost2.bbcode_text = "%s  %s" % [Helper.format_num(entry_exit_cost), "[img]Graphics/Icons/help.png[/img]"]
	travel_energy_cost = slider_factor * distance * 30 / game.u_i.speed_of_light
	time_cost = 5000 / slider_factor * distance / game.u_i.speed_of_light / game.u_i.time_speed
	if game.science_unlocked.has("FTL"):
		time_cost /= 10.0
	if game.science_unlocked.has("IGD"):
		time_cost /= 100.0
	$Panel/EnergyCost.text = "%s%s" % [Helper.format_num(round(travel_energy_cost)), (" (-%s%%)" % (100 - 100 * get_travel_cost_multiplier(depart_planet_data.MS_lv))) if has_SE(depart_planet_data) else ""]
	total_energy_cost = travel_energy_cost + entry_exit_cost
	$TotalEnergyCost2.text = Helper.format_num(round(total_energy_cost))
	$Panel/TimeCost.text = Helper.time_to_str(time_cost)

func _on_close_button_pressed():
	game.toggle_panel(self)
