extends "Panel.gd"
@onready var HX_data_scene = preload("res://Scenes/HXData.tscn")

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
var spaceport_exit_cost_reduction:float = 1.0
var spaceport_travel_cost_reduction:float = 1.0

func _ready():
	set_polygon($Background.size)
	$Drive.add_item(tr("STANDARD_DRIVE"))
	$Drive.add_item(tr("PD_SC"))
	$Panel/TravelCosts.text = "%s:" % [tr("TRAVEL_COSTS")]
	$TotalEnergyCost.text = "%s:" % [tr("COSTS")]
	if game.autocollect.has("ship_XP"):
		game.HUD.set_ship_btn_shader(true, game.autocollect.ship_XP)

func refresh():
	$Drive.visible = game.science_unlocked.has("PD")
	var depart_id:int
	var dest_id:int
	var coords:Dictionary = game.ships_c_coords
	var g_coords:Dictionary = game.ships_c_g_coords
	var g_s:int = game.ships_c_g_coords.s
	var file = FileAccess.open("user://%s/Univ%s/Systems/%s.hx3" % [game.c_sv, game.c_u, g_s], FileAccess.READ)
	planets_in_depart_system = file.get_var()
	file.close()
	depart_planet_data = planets_in_depart_system[coords.p]
	if game.c_s_g == g_coords.s:
		travel_view = "system"
		depart_id = coords.p
		dest_id = dest_p_id
		depart_pos = depart_planet_data.distance * Vector2.from_angle(depart_planet_data.angle)
		dest_pos = game.planet_data[dest_id].distance * Vector2.from_angle(game.planet_data[dest_id].angle)
		distance = depart_pos.distance_to(dest_pos)
	elif game.c_g_g == g_coords.g:
		travel_view = "galaxy"
		distance = 73
		depart_id = coords.s
		dest_id = game.planet_data[dest_p_id].parent
		depart_pos = game.system_data[depart_id].pos
		dest_pos = game.system_data[dest_id].pos
		distance *= depart_pos.distance_to(dest_pos)
	elif game.c_c == coords.c:
		travel_view = "cluster"
		distance = 45454
		depart_id = coords.g
		dest_id = game.system_data[game.planet_data[dest_p_id].parent].parent
		depart_pos = game.galaxy_data[depart_id].pos
		dest_pos = game.galaxy_data[dest_id].pos
		distance *= depart_pos.distance_to(dest_pos)
	else:
		travel_view = "universe"
		distance = 8181818
		depart_id = coords.c
		dest_id = game.galaxy_data[game.system_data[game.planet_data[dest_p_id].parent].parent].parent
		depart_pos = game.u_i.cluster_data[depart_id].pos
		dest_pos = game.u_i.cluster_data[dest_id].pos
		distance *= depart_pos.distance_to(dest_pos)
	if TEST:
		distance = 1
	$EnergyIcon2.visible = $Drive.selected == 0
	$EnergyCost2.visible = $Drive.selected == 0
	$PlanetEECost.visible = $Drive.selected == 0
	$Panel.visible = $Drive.selected == 0
	if $Drive.selected == 1:
		$EnergyIcon3.texture = preload("res://Graphics/Atoms/Pu.png")
		total_energy_cost = distance / 400000.0
		$TotalEnergyCost2.text = "%s/%s mol" % [Helper.format_num(game.atoms.Pu, true), Helper.format_num(total_energy_cost, true)]
		$TotalEnergyCost2["theme_override_colors/font_color"] = Color.GREEN if game.atoms.Pu > total_energy_cost else Color.RED
			
	elif $Drive.selected == 0:
		$TotalEnergyCost2["theme_override_colors/font_color"] = Color.WHITE
		$EnergyIcon3.texture = preload("res://Graphics/Icons/energy.png")
		calc_costs()
		$EnergyCost2.adv_icons = [Data.energy_icon, Data.energy_icon, Data.energy_icon, Data.energy_icon]
		var exit_mult_percentage = spaceport_exit_cost_reduction * (get_entry_exit_multiplier(depart_planet_data.MS_lv) if has_SE(depart_planet_data) else 1.0)
		exit_mult_percentage = 100 - 100 * exit_mult_percentage
		var entry_mult_percentage = get_entry_exit_multiplier(game.planet_data[dest_p_id].MS_lv) if has_SE(game.planet_data[dest_p_id]) else 1.0
		entry_mult_percentage = 100 - 100 * entry_mult_percentage
		$EnergyCost2.help_text = "%s: @i %s%s\n%s: @i %s%s\n%s: @i %s%s\n%s: @i %s%s" % [tr("ATMOSPHERE_EXIT"), Helper.format_num(atm_exit_cost), (" (-%s%%)" % exit_mult_percentage) if exit_mult_percentage > 0 else "", tr("GRAVITY_EXIT"), Helper.format_num(gravity_exit_cost), (" (-%s%%)" % exit_mult_percentage) if exit_mult_percentage > 0 else "", tr("ATMOSPHERE_ENTRY"), Helper.format_num(atm_entry_cost), (" (-%s%%)" % entry_mult_percentage) if entry_mult_percentage > 0 else "", tr("GRAVITY_ENTRY"), Helper.format_num(gravity_entry_cost), (" (-%s%%)" % entry_mult_percentage) if entry_mult_percentage > 0 else ""]
	for child in $Scroll/Enemies.get_children():
		child.queue_free()
	if game.planet_data[dest_p_id].has("HX_data"):
		for HX_data in game.planet_data[dest_p_id].HX_data:
			var HX_data_node = HX_data_scene.instantiate()
			if not HX_data.has("class"):
				HX_data["class"] = 1
			HX_data_node.get_node("HX").texture = load("res://Graphics/HX/%s_%s.png" % [HX_data["class"], HX_data.type])
			HX_data_node.get_node("HP").text = "%s / %s" % [Helper.format_num(HX_data.HP, false, 4), Helper.format_num(HX_data.total_HP, false, 4)]
			HX_data_node.get_node("Lv").text = "%s %s" % [tr("LV"), HX_data.lv]
			HX_data_node.get_node("VBoxContainer/Atk/Label").text = Helper.format_num(HX_data.atk, false, 4)
			HX_data_node.get_node("VBoxContainer/Acc/Label").text = Helper.format_num(HX_data.acc, false, 4)
			HX_data_node.get_node("VBoxContainer2/Def/Label").text = Helper.format_num(HX_data.def, false, 4)
			HX_data_node.get_node("VBoxContainer2/Eva/Label").text = Helper.format_num(HX_data.eva, false, 4)
			$Scroll/Enemies.add_child(HX_data_node)
			HX_data_node.custom_minimum_size.y = 70
		if game.planet_data[dest_p_id].has("conquered"):
			$Enemies.text = tr("ENEMIES")
		else:
			$Enemies.text = "%s (%s)" % [tr("ENEMIES"), len(game.planet_data[dest_p_id].HX_data)]
	else:
		$Enemies.text = tr("ENEMIES")
	$Scroll/Enemies.visible = not game.planet_data[dest_p_id].has("conquered")

func _on_Send_pressed():
	if game.universe_data[game.c_u].lv < 40:
		if not game.science_unlocked.has("MAE") and game.planet_data[dest_p_id].pressure > 10 and game.energy < 7000 * pow(game.planet_data[dest_p_id].pressure, 2):
			game.long_popup(tr("PLANET_PRESSURE_TOO_HIGH"), "")
		elif not game.science_unlocked.has("MAE") and game.planet_data[dest_p_id].pressure > 20:
			game.show_YN_panel("send_ships", tr("HIGH_PRESSURE_PLANET"))
		elif time_cost > 4 * 60 * 60:
			game.show_YN_panel("send_ships", tr("LONG_TRAVEL"))
		else:
			send_ships()
	else:
		send_ships()

func send_ships():
	if game.ships_travel_view == "-":
		if $Drive.selected == 1:
			if game.atoms.Pu >= total_energy_cost:
				game.atoms.Pu -= total_energy_cost
				game.ships_c_coords.p = dest_p_id
				game.ships_dest_coords.p = dest_p_id
				game.ships_c_coords.s = game.c_s
				game.ships_dest_coords.s = game.c_s
				game.ships_c_g_coords.s = game.c_s_g
				game.ships_dest_g_coords.s = game.c_s_g
				game.ships_c_coords.g = game.c_g
				game.ships_dest_coords.g = game.c_g
				game.ships_c_g_coords.g = game.c_g_g
				game.ships_dest_g_coords.g = game.c_g_g
				game.ships_c_coords.c = game.c_c
				game.ships_dest_coords.c = game.c_c
				game.view.obj.refresh_planets()
				game.view.refresh()
				var p_i = game.planet_data[game.ships_c_coords.p]
				if p_i.has("unique_bldgs"):
					if p_i.unique_bldgs.has("spaceport") and not p_i.unique_bldgs.spaceport[0].has("repair_cost"):
						game.autocollect.ship_XP = p_i.unique_bldgs.spaceport[0].tier
						game.HUD.set_ship_btn_shader(true, p_i.unique_bldgs.spaceport[0].tier)
					else:
						game.autocollect.erase("ship_XP")
						game.HUD.set_ship_btn_shader(false)
				game.space_HUD.get_node("ConquerAll").visible = (game.u_i.lv >= 32 or game.subjects.dimensional_power.lv >= 1) and not game.system_data[game.c_s].has("conquered")
				game.HUD.refresh()
				game.toggle_panel(self)
			else:
				game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)
		elif time_cost != 0:
			if game.energy >= total_energy_cost:
				if time_cost >= 365 * 24 * 60 * 60 * 1000:
					if not game.achievement_data.random.has("1000_year_journey"):
						game.earn_achievement("random", "1000_year_journey")
				game.energy -= round(total_energy_cost)
				game.autocollect.erase("ship_XP")
				game.HUD.set_ship_btn_shader(false)
				send_ships2(time_cost)
				if game.c_v == travel_view:
					game.view.refresh()
					game.HUD.refresh()
				else:
					game.switch_view(travel_view)
			else:
				game.popup(tr("NOT_ENOUGH_ENERGY"), 1.5)
	else:
		game.popup(tr("SHIPS_ALREADY_TRAVELLING"), 1.5)

func send_ships2(_time):
	game.ships_depart_pos = depart_pos
	game.ships_dest_pos = dest_pos
	game.ships_dest_coords = {"c":game.c_c, "g":game.c_g, "s":game.c_s, "p":dest_p_id}
	game.ships_dest_g_coords = {"g":game.c_g_g, "s":game.c_s_g}
	game.ships_travel_view = travel_view
	game.ships_travel_start_date = Time.get_unix_time_from_system()
	game.ships_travel_length = time_cost
	game.toggle_panel(self)
	
func _on_HSlider_value_changed(value):
	calc_costs()

func has_SE(p_i:Dictionary):
	return p_i.has("MS") and p_i.MS == "M_SE" and not p_i.bldg.has("is_constructing") and not p_i.has("repair_cost")

func get_atm_exit_cost(pressure:float):
	var res:float = pow(pressure * 10, 2) * 100
	if has_SE(depart_planet_data):
		res *= get_entry_exit_multiplier(depart_planet_data.MS_lv)
	return round(res)

func get_grav_exit_cost(size:float):
	var res:float = pow(size / 250.0, 2.5)
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
	var slider_factor = pow(10, $Panel/HSlider.value / 25.0 - 1)
	atm_exit_cost = get_atm_exit_cost(depart_planet_data.pressure)
	gravity_exit_cost = get_grav_exit_cost(depart_planet_data.size)
	spaceport_exit_cost_reduction = 1.0
	spaceport_travel_cost_reduction = 1.0
	if depart_planet_data.has("unique_bldgs") and depart_planet_data.unique_bldgs.has("spaceport") and not depart_planet_data.unique_bldgs.spaceport[0].has("repair_cost"):
		spaceport_exit_cost_reduction = 1.0 - Helper.get_spaceport_exit_cost_reduction(depart_planet_data.unique_bldgs.spaceport[0].tier)
		spaceport_travel_cost_reduction = 1.0 - Helper.get_spaceport_travel_cost_reduction(depart_planet_data.unique_bldgs.spaceport[0].tier)
		atm_exit_cost *= spaceport_exit_cost_reduction
		gravity_exit_cost *= spaceport_exit_cost_reduction
	atm_entry_cost = get_atm_entry_cost(game.planet_data[dest_p_id].pressure)
	gravity_entry_cost = get_grav_entry_cost(game.planet_data[dest_p_id].size)
	if depart_planet_data.type in [11, 12]:
		atm_exit_cost = 0
		gravity_exit_cost = 0
	if game.planet_data[dest_p_id].type in [11, 12]:
		atm_entry_cost = 0
		gravity_entry_cost = 0
	var entry_exit_cost:float = round(atm_entry_cost + atm_exit_cost + gravity_entry_cost + gravity_exit_cost)
	$EnergyCost2.text = "%s  %s" % [Helper.format_num(entry_exit_cost), "[img]Graphics/Icons/help.png[/img]"]
	var travel_cost_mult = spaceport_travel_cost_reduction * (get_travel_cost_multiplier(depart_planet_data.MS_lv) if has_SE(depart_planet_data) else 1.0)
	travel_energy_cost = slider_factor * distance * 30 / game.u_i.speed_of_light * travel_cost_mult
	time_cost = 5000 / slider_factor * distance / game.u_i.speed_of_light / game.u_i.time_speed
	if game.science_unlocked.has("FTL"):
		time_cost /= 10.0
	if game.science_unlocked.has("IGD"):
		time_cost /= 100.0
	var travel_cost_mult_percentage = 100 - 100 * travel_cost_mult
	$Panel/EnergyCost.text = "%s%s" % [Helper.format_num(round(travel_energy_cost)), (" (-%s%%)" % travel_cost_mult_percentage) if travel_cost_mult_percentage > 0 else ""]
	total_energy_cost = travel_energy_cost + entry_exit_cost
	$TotalEnergyCost2.text = Helper.format_num(round(total_energy_cost))
	$Panel/TimeCost.text = Helper.time_to_str(time_cost)

func _on_close_button_pressed():
	game.toggle_panel(self)


func _on_Drive_item_selected(index):
	refresh()
