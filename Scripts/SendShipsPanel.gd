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

func _ready():
	set_polygon($Background.rect_size)
	$PlanetEECost.text = "%s:" % [tr("PLANET_EE_COST")]
	$TravelCosts.text = "%s:" % [tr("TRAVEL_COSTS")]
	$TotalEnergyCost.text = "%s:" % [tr("TOTAL_ENERGY_COST")]

func refresh():
	var depart_id:int
	var dest_id:int
	var coords:Dictionary = game.ships_c_coords
	var g_coords:Dictionary = game.ships_c_g_coords
	var g_s:int = game.ships_c_g_coords.s
	var file = File.new()
	file.open("user://Save1/Systems/%s.hx3" % [g_s], File.READ)
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
	for child in $VBox/HBox/VBox/Scroll/Enemies.get_children():
		$VBox/HBox/VBox/Scroll/Enemies.remove_child(child)
		child.free()
	if game.planet_data[dest_p_id].has("HX_data"):
		for HX_data in game.planet_data[dest_p_id].HX_data:
			var HX_data_node = HX_data_scene.instance()
			HX_data_node.get_node("HX").texture = load("res://Graphics/HX/%s.png" % [HX_data.type])
			HX_data_node.get_node("HP").text = "%s / %s" % [Helper.format_num(HX_data.HP, 4), Helper.format_num(HX_data.total_HP, 4)]
			HX_data_node.get_node("Lv").text = "%s %s" % [tr("LV"), HX_data.lv]
			HX_data_node.get_node("VBoxContainer/Atk/Label").text = Helper.format_num(HX_data.atk, 4)
			HX_data_node.get_node("VBoxContainer/Acc/Label").text = Helper.format_num(HX_data.acc, 4)
			HX_data_node.get_node("VBoxContainer2/Def/Label").text = Helper.format_num(HX_data.def, 4)
			HX_data_node.get_node("VBoxContainer2/Eva/Label").text = Helper.format_num(HX_data.eva, 4)
			$VBox/HBox/VBox/Scroll/Enemies.add_child(HX_data_node)
			HX_data_node.rect_min_size.y = 70
	$VBox/HBox/VBox/Scroll/Enemies.visible = not game.planet_data[dest_p_id].conquered

func _on_Send_pressed():
	if game.lv < 35:
		if game.c_g_g == 0 and game.planet_data[dest_p_id].pressure > 30:
			game.show_YN_panel("send_ships", tr("HIGH_PRESSURE_PLANET"), [])
		elif time_cost > 4 * 60 * 60 * 1000:
			game.show_YN_panel("send_ships", tr("LONG_TRAVEL"), [])
		else:
			send_ships()
	else:
		send_ships()

func send_ships():
	if game.ships_travel_view == "-":
		if time_cost != 0:
			if game.energy >= total_energy_cost:
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
	var res:float = pow(pressure * 10, 2) * 150
	if has_SE(depart_planet_data):
		res *= get_entry_exit_multiplier(depart_planet_data.MS_lv)
	return round(res)

func get_grav_exit_cost(size:float):
	var res:float = pow(size / 200.0, 2.5)
	if has_SE(depart_planet_data):
		res *= get_entry_exit_multiplier(depart_planet_data.MS_lv)
	return round(res)

func get_atm_entry_cost(pressure:float):
	var res:float = 500 / clamp(pressure, 0.1, 10)
	if has_SE(game.planet_data[dest_p_id]):
		res *= get_entry_exit_multiplier(game.planet_data[dest_p_id].MS_lv)
	return round(res)

func get_grav_entry_cost(size:float):
	var res:float = pow(size / 600.0, 2.5) * 3
	if has_SE(game.planet_data[dest_p_id]):
		res *= get_entry_exit_multiplier(game.planet_data[dest_p_id].MS_lv)
	return round(res)

func get_entry_exit_multiplier(lv:int):
	match lv:
		0:
			return 0.9
		1:
			return 0.6
		2:
			return 0.3
		3:
			return 0

func get_travel_cost_multiplier(lv:int):
	match lv:
		0:
			return 0.95
		1:
			return 0.8
		2:
			return 0.65
		3:
			return 0.5

func calc_costs():
	var slider_factor = pow(10, $HSlider.value / 25.0 - 2)
	var atm_exit_cost = get_atm_exit_cost(depart_planet_data.pressure)
	var gravity_exit_cost = get_grav_exit_cost(depart_planet_data.size)
	var atm_entry_cost = get_atm_entry_cost(game.planet_data[dest_p_id].pressure)
	var gravity_entry_cost = get_grav_entry_cost(game.planet_data[dest_p_id].size)
	if depart_planet_data.type in [11, 12]:
		atm_exit_cost = 0
		gravity_exit_cost = 0
	if game.planet_data[dest_p_id].type in [11, 12]:
		atm_entry_cost = 0
		gravity_entry_cost = 0
	var entry_exit_cost:float = round(atm_entry_cost + atm_exit_cost + gravity_entry_cost + gravity_exit_cost)
	$EnergyCost2.text = Helper.format_num(entry_exit_cost)
	travel_energy_cost = slider_factor * distance * 30
	time_cost = 5000 / slider_factor * distance
	if game.science_unlocked.FTL:
		time_cost /= 10.0
	if game.science_unlocked.IGD:
		time_cost /= 100.0
	$EnergyCost.text = "%s%s" % [Helper.format_num(round(travel_energy_cost)), (" (-%s%%)" % (100 - 100 * get_travel_cost_multiplier(depart_planet_data.MS_lv))) if has_SE(depart_planet_data) else ""]
	total_energy_cost = travel_energy_cost + entry_exit_cost
	$TotalEnergyCost2.text = Helper.format_num(round(total_energy_cost))
	$TimeCost.text = Helper.time_to_str(time_cost)

func _on_EnergyCost2_mouse_entered():
	var atm_exit_cost = Helper.format_num(get_atm_exit_cost(depart_planet_data.pressure))
	var gravity_exit_cost = Helper.format_num(get_grav_exit_cost(depart_planet_data.size))
	var atm_entry_cost = Helper.format_num(get_atm_entry_cost(game.planet_data[dest_p_id].pressure))
	var gravity_entry_cost = Helper.format_num(get_grav_entry_cost(game.planet_data[dest_p_id].size))
	if depart_planet_data.type in [11, 12]:
		atm_exit_cost = 0
		gravity_exit_cost = 0
	if game.planet_data[dest_p_id].type in [11, 12]:
		atm_entry_cost = 0
		gravity_entry_cost = 0
	game.show_adv_tooltip("%s: @i %s%s\n%s: @i %s%s\n%s: @i %s%s\n%s: @i %s%s" % [tr("ATMOSPHERE_EXIT"), atm_exit_cost, (" (-%s%%)" % (100 - 100 * get_entry_exit_multiplier(depart_planet_data.MS_lv))) if has_SE(depart_planet_data) else "", tr("GRAVITY_EXIT"), gravity_exit_cost, (" (-%s%%)" % (100 - 100 * get_entry_exit_multiplier(depart_planet_data.MS_lv))) if has_SE(depart_planet_data) else "", tr("ATMOSPHERE_ENTRY"), atm_entry_cost, (" (-%s%%)" % (100 - 100 * get_entry_exit_multiplier(game.planet_data[dest_p_id].MS_lv))) if has_SE(game.planet_data[dest_p_id]) else "", tr("GRAVITY_ENTRY"), gravity_entry_cost,  (" (-%s%%)" % (100 - 100 * get_entry_exit_multiplier(game.planet_data[dest_p_id].MS_lv))) if has_SE(game.planet_data[dest_p_id]) else ""], [Data.energy_icon, Data.energy_icon, Data.energy_icon, Data.energy_icon])

func _on_EnergyCost2_mouse_exited():
	game.hide_adv_tooltip()

func _on_PlanetEECost_mouse_entered():
	game.show_tooltip(tr("PLANET_EE_COST_DESC"))

func _on_PlanetEECost_mouse_exited():
	game.hide_tooltip()

func _on_close_button_pressed():
	game.toggle_panel(self)
