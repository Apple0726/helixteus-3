extends "Panel.gd"
onready var HX_data_scene = preload("res://Scenes/HXData.tscn")

var travel_view:String
var energy_cost:float = 0
var time_cost:float = 0
var depart_pos:Vector2
var dest_pos:Vector2
var depart_p_id:int
var dest_p_id:int
var distance:int

func _ready():
	set_polygon($Background.rect_size)
	$PlanetEECost.text = "%s:" % [tr("PLANET_EE_COST")]
	$TravelCosts.text = "%s:" % [tr("TRAVEL_COSTS")]
	$VBoxContainer/HBoxContainer/ScrollContainer.get_v_scrollbar().connect("mouse_entered", self, "on_mouse_entered")
	$VBoxContainer/HBoxContainer/ScrollContainer.get_v_scrollbar().connect("mouse_exited", self, "on_mouse_entered")
	refresh()

func on_mouse_entered():
	game.view.move_view = false

func on_mouse_exited():
	game.view.move_view = true

func refresh():
	var depart_id:int
	var dest_id:int
	var s_c_p:int = game.ships_c_p
	var s_c_s:int = game.planet_data[s_c_p].parent
	var s_c_g:int = game.system_data[s_c_s].parent
	var s_c_c:int = game.galaxy_data[s_c_g].parent
	var s_c_sc:int = game.cluster_data[s_c_c].parent
	if game.c_s == s_c_s:
		travel_view = "system"
		depart_id = s_c_p
		dest_id = dest_p_id
		depart_pos = polar2cartesian(game.planet_data[depart_id].distance, game.planet_data[depart_id].angle)
		dest_pos = polar2cartesian(game.planet_data[dest_id].distance, game.planet_data[dest_id].angle)
		distance = depart_pos.distance_to(dest_pos)
	elif game.c_g == s_c_g:
		travel_view = "galaxy"
		distance = 373
		depart_id = s_c_s
		dest_id = game.planet_data[dest_p_id].parent
		depart_pos = game.system_data[depart_id].pos
		dest_pos = game.system_data[dest_id].pos
		distance *= depart_pos.distance_to(dest_pos)
	elif game.c_c == s_c_c:
		travel_view = "cluster"
		distance = 54545
		depart_id = s_c_g
		dest_id = game.system_data[game.planet_data[dest_p_id].parent].parent
		depart_pos = game.galaxy_data[depart_id].pos
		dest_pos = game.galaxy_data[dest_id].pos
		distance *= depart_pos.distance_to(dest_pos)
	elif game.c_sc == s_c_sc:
		travel_view = "supercluster"
		distance = 7171717
		depart_id = s_c_c
		dest_id = game.galaxy_data[game.system_data[game.planet_data[dest_p_id].parent].parent].parent
		depart_pos = game.cluster_data[depart_id].pos
		dest_pos = game.cluster_data[dest_id].pos
		distance *= depart_pos.distance_to(dest_pos)
	else:
		travel_view = "universe"
		distance = 969696969
		depart_id = s_c_sc
		dest_id = game.cluster_data[game.galaxy_data[game.system_data[game.planet_data[dest_p_id].parent].parent].parent].parent
		depart_pos = game.supercluster_data[depart_id].pos
		dest_pos = game.supercluster_data[dest_id].pos
		distance *= depart_pos.distance_to(dest_pos)
	if game.TEST:
		distance = 1
	depart_p_id = game.ships_c_p
	calc_costs()
	for child in $VBoxContainer/HBoxContainer/ScrollContainer/Enemies.get_children():
		if not child is Label:
			$VBoxContainer/HBoxContainer/ScrollContainer/Enemies.remove_child(child)
	for HX_data in game.HX_data[dest_p_id]:
		var HX_data_node = HX_data_scene.instance()
		HX_data_node.get_node("HX").texture = load("res://Graphics/HX/%s.png" % [HX_data.type])
		HX_data_node.get_node("HP").text = "%s / %s" % [HX_data.HP, HX_data.total_HP]
		HX_data_node.get_node("Lv").text = "%s %s" % [tr("LV"), HX_data.lv]
		HX_data_node.get_node("VBoxContainer/Atk/Label").text = String(HX_data.atk)
		HX_data_node.get_node("VBoxContainer/Acc/Label").text = String(HX_data.acc)
		HX_data_node.get_node("VBoxContainer2/Def/Label").text = String(HX_data.def)
		HX_data_node.get_node("VBoxContainer2/Eva/Label").text = String(HX_data.eva)
		$VBoxContainer/HBoxContainer/ScrollContainer/Enemies.add_child(HX_data_node)

func _on_Send_pressed():
	if game.energy >= energy_cost:
		game.energy -= round(energy_cost)
		game.ships_depart_pos = depart_pos
		game.ships_dest_pos = dest_pos
		game.ships_dest_p_id = dest_p_id
		game.ships_travel_view = travel_view
		game.ships_travel_start_date = OS.get_system_time_msecs()
		game.ships_travel_length = time_cost
		game.toggle_panel(self)
		game.view.refresh()
	else:
		game.popup(tr("NOT_ENOUGH_ENERGY"), 1.5)
	game.HUD.refresh()

func _on_HSlider_value_changed(value):
	calc_costs()

func calc_costs():
	var slider_factor = pow(10, $HSlider.value / 25.0 - 2)
	var atm_exit_cost = pow(game.planet_data[depart_p_id].pressure, 1.5) * 10000
	var gravity_exit_cost = pow(game.planet_data[depart_p_id].size / 600.0, 2.5) * 50
	var atm_entry_cost = 8000 / clamp(game.planet_data[dest_p_id].pressure, 0.1, 10)
	var gravity_entry_cost = pow(game.planet_data[dest_p_id].size / 600.0, 2.5) * 6
	$EnergyCost2.text = String(round(atm_entry_cost + atm_exit_cost + gravity_entry_cost + gravity_exit_cost))
	energy_cost = slider_factor * distance * 60
	time_cost = 5000 / slider_factor * distance
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

func _on_close_button_pressed():
	game.toggle_panel(self)

func _on_ScrollContainer_mouse_entered():
	game.view.scroll_view = false


func _on_ScrollContainer_mouse_exited():
	game.view.scroll_view = true
