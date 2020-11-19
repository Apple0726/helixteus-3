extends "Panel.gd"

var travel_view:String
var energy_cost:float = 0
var time_cost:float = 0
var depart_id:int
var dest_id:int
var depart_p_id:int
var dest_p_id:int
var distance:int

func _ready():
	set_polygon($Background.rect_size)
	$PlanetEECost.text = "%s:" % [tr("PLANET_EE_COST")]
	refresh()

func refresh():
	var s_c_p = game.ships_c_p
	var s_c_s = game.planet_data[s_c_p].parent
	var s_c_g = game.system_data[s_c_s].parent
	var s_c_c = game.galaxy_data[s_c_g].parent
	var s_c_sc = game.cluster_data[s_c_c].parent
	if game.c_s == s_c_s:
		travel_view = "system"
		depart_id = s_c_p
		dest_id = dest_p_id
		var depart_pos:Vector2 = polar2cartesian(game.planet_data[depart_id].distance, game.planet_data[depart_id].angle)
		var dest_pos:Vector2 = polar2cartesian(game.planet_data[dest_id].distance, game.planet_data[dest_id].angle)
		distance = depart_pos.distance_to(dest_pos)
	elif game.c_g == s_c_g:
		travel_view = "galaxy"
		distance = 373
		depart_id = s_c_s
		dest_id = game.planet_data[dest_p_id].parent
		distance *= game.system_data[depart_id].pos.distance_to(game.system_data[dest_id].pos)
	elif game.c_c == s_c_c:
		travel_view = "cluster"
		distance = 54545
		depart_id = s_c_g
		dest_id = game.system_data[game.planet_data[dest_p_id].parent].parent
		distance *= game.galaxy_data[depart_id].pos.distance_to(game.galaxy_data[dest_id].pos)
	elif game.c_sc == s_c_sc:
		travel_view = "supercluster"
		distance = 7171717
		depart_id = s_c_c
		dest_id = game.galaxy_data[game.system_data[game.planet_data[dest_p_id].parent].parent].parent
		distance *= game.cluster_data[depart_id].pos.distance_to(game.cluster_data[dest_id].pos)
	else:
		travel_view = "universe"
		distance = 969696969
		depart_id = s_c_sc
		dest_id = game.cluster_data[game.galaxy_data[game.system_data[game.planet_data[dest_p_id].parent].parent].parent].parent
		distance *= game.supercluster_data[depart_id].pos.distance_to(game.supercluster_data[dest_id].pos)
	depart_p_id = game.ships_c_p
	calc_costs()

func _on_Send_pressed():
	pass # Replace with function body.

func _on_HSlider_value_changed(value):
	calc_costs()

func calc_costs():
	var slider_factor = pow(10, $HSlider.value / 25.0 - 2)
	var atm_exit_cost = pow(game.planet_data[depart_p_id].pressure, 1.5) * 10000
	var gravity_exit_cost = pow(game.planet_data[depart_p_id].size / 600.0, 2.5) * 50
	var atm_entry_cost = 8000 / clamp(game.planet_data[dest_p_id].pressure, 0.1, 10)
	var gravity_entry_cost = pow(game.planet_data[dest_p_id].size / 600.0, 2.5) * 6
	$EnergyCost2.text = String(round(atm_entry_cost + atm_exit_cost + gravity_entry_cost + gravity_exit_cost))
	energy_cost = slider_factor * distance * 80
	time_cost = 15000 / slider_factor * distance
	$EnergyCost.text = String(game.clever_round(energy_cost))
	$TimeCost.text = Helper.time_to_str(time_cost)

func _on_EnergyCost2_mouse_entered():
	var atm_exit_cost = round(pow(game.planet_data[depart_p_id].pressure, 1.5) * 10000)
	var gravity_exit_cost = round(pow(game.planet_data[depart_p_id].size / 600.0, 2.5) * 50)
	var atm_entry_cost = round(8000 / clamp(game.planet_data[dest_p_id].pressure, 0.1, 10))
	var gravity_entry_cost = round(pow(game.planet_data[dest_p_id].size / 600.0, 2.5) * 6)
	game.show_adv_tooltip("%s: @i %s\n%s: @i %s\n%s: @i %s\n%s: @i %s" % [tr("ATMOSPHERE_EXIT"), atm_exit_cost, tr("GRAVITY_EXIT"), gravity_exit_cost, tr("ATMOSPHERE_ENTRY"), atm_entry_cost, tr("GRAVITY_ENTRY"), gravity_entry_cost], [Data.icons.PP, Data.icons.PP, Data.icons.PP, Data.icons.PP])

func _on_EnergyCost2_mouse_exited():
	game.hide_adv_tooltip()

func _on_PlanetEECost_mouse_entered():
	game.show_tooltip(tr("PLANET_EE_COST_DESC"))

func _on_PlanetEECost_mouse_exited():
	game.hide_tooltip()
