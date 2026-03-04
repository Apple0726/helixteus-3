extends "Panel.gd"

var obj_num:int = 0
var sys_num:int = 0#Only for MK2
var time_for_one_obj:float = 0
var total_energy_cost:float = 0
var combined_strength:float = 0
var base_travel_costs:float = 0
var planet_exit_costs:float = 0
var unconquered_obj:int = 0
var strength_required:float = 0
var sorted_objs:Array = []
var start_index:int = 0
var fighter_type:int = 0
@onready var RTL:RichTextLabel = $Panel/Label
@onready var time_left:Label = $Control2/TimeLeft
@onready var progress:TextureProgressBar = $Control2/TextureProgressBar

func _ready():
	set_process(false)
	set_polygon($GUI.size, $GUI.position)

func refresh_energy():
	var slider_factor = pow(10, $Control/EnergyPanel/HSlider.value / 25.0 - 1)
	total_energy_cost = base_travel_costs * slider_factor + planet_exit_costs
	$Control/EnergyPanel/EnergyCost.text = Helper.format_num(total_energy_cost)
	if fighter_type == 0:
		time_for_one_obj = 2 * 1.2 / sqrt(slider_factor) / game.u_i.time_speed / game.u_i.speed_of_light#Calculate time for one system/galaxy	
		Helper.add_text_to_RTL(RTL, "%s: %s\n%s: %s\n%s: %s\n%s: %s\n%s: @i %s\n%s: @i %s" % [tr("COMBINED_STRENGTH_F1"), Helper.format_num(ceil(combined_strength)), tr("STRENGTH_REQUIRED_F1"), Helper.format_num(ceil(strength_required)), tr("NUMBER_OF_SYS_BEFORE_REKT"), obj_num, tr("NUMBER_OF_UNCONQUERED_SYS"), unconquered_obj, tr("PLANET_EXIT_COST"), Helper.format_num(planet_exit_costs), tr("TIME_TO_CONQUER_ALL_SYS"), Helper.time_to_str(time_for_one_obj * obj_num)], [Data.energy_icon, Data.time_icon], 19)
	elif fighter_type == 1:
		time_for_one_obj = 50 * 1.2 / sqrt(slider_factor) / game.u_i.time_speed / game.u_i.speed_of_light#Calculate time for one system/galaxy	
		Helper.add_text_to_RTL(RTL, "%s: %s\n%s: %s\n%s: %s\n%s: %s\n%s: @i %s" % [tr("COMBINED_STRENGTH_F2"), Helper.format_num(ceil(combined_strength)), tr("STRENGTH_REQUIRED_F2"), Helper.format_num(ceil(strength_required)), tr("NUMBER_OF_GAL_BEFORE_REKT"), obj_num, tr("NUMBER_OF_UNCONQUERED_GAL"), unconquered_obj, tr("TIME_TO_CONQUER_ALL_GAL"), Helper.time_to_str(time_for_one_obj * obj_num)], [Data.time_icon], 19)

func refresh():
	planet_exit_costs = 0
	unconquered_obj = 0
	strength_required = 0
	base_travel_costs = 0
	combined_strength = 0
	obj_num = 0
	sys_num = 0
	start_index = 0
	var fighter_num:int = 0
	var combined_strength2:float = 0
	if fighter_type == 0:
		$Control/EnergyPanel/SE_Hint.visible = true
		if game.galaxy_data[game.c_g].has("conquer_start_date"):
			$Send.hide()
			sort_systems(game.galaxy_data[game.c_g].conquer_order)
			set_process(true)
			$Control.visible = false
			$Control2.visible = true
		else:
			if game.galaxy_data[game.c_g].has("conquered"):
				$Control.visible = false
				$Control2.visible = false
				$Send.visible = false
				RTL.text = tr("GALAXY_FULLY_CONQUERED")
				return
			$Control.visible = true
			$Control2.visible = false
			$Send.text = tr("SEND")
			$Send.visible = true
			set_process(false)
			for sys in game.system_data:
				if not sys.has("conquered"):
					strength_required += sys.diff
					unconquered_obj += 1
			for fighter in game.fighter_data:
				if fighter == null or fighter.has("exploring"):
					continue
				if fighter.tier == 0 and fighter.c_g_g == game.c_g_g:
					var file = FileAccess.open("user://%s/Univ%s/Systems/%s.hx3" % [game.c_sv, game.c_u, fighter.c_s_g], FileAccess.READ)
					var planets_in_depart_system = file.get_var()
					combined_strength += fighter.strength
					fighter_num += fighter.number
					planet_exit_costs += get_atm_exit_cost(planets_in_depart_system[fighter.c_p]) + get_grav_exit_cost(planets_in_depart_system[fighter.c_p]) * fighter.number
					base_travel_costs += 5e7 * fighter.number * (get_travel_cost_multiplier(planets_in_depart_system[fighter.c_p].MS_lv) if has_SE(planets_in_depart_system[fighter.c_p]) else 1) / game.u_i.speed_of_light
			if combined_strength == 0:
				RTL.text = "%s\n%s: %s" % [tr("NO_FIGHTERS"), tr("STRENGTH_REQUIRED_F1"), Helper.format_num(ceil(strength_required))]
				$Send.visible = false
				$Control.visible = false
				return
			combined_strength2 = combined_strength
			sort_systems($Control/ConquerOrderPanel/CheckBox.button_pressed)
			for system in sorted_objs:#Calculates the actual number of systems the fighters will conquer
				if system.has("conquered"):
					continue
				if combined_strength2 < system.diff:
					if obj_num == 0:
						continue
					else:
						break
				else:
					combined_strength2 -= system.diff
					obj_num += 1
			base_travel_costs *= obj_num
			refresh_energy()
			if unconquered_obj == 0:
				game.galaxy_data[game.c_g].conquered = true
	elif fighter_type == 1:
		$Control/EnergyPanel/SE_Hint.visible = false
		if game.u_i.cluster_data[game.c_c].has("conquer_start_date"):
			$Send.text = tr("DISBAND")
			$Send.visible = true
			sort_galaxies(game.u_i.cluster_data[game.c_c].conquer_order)
			set_process(true)
			$Control.visible = false
			$Control2.visible = true
		else:
			if game.u_i.cluster_data[game.c_c].has("conquered"):
				$Control.visible = false
				$Control2.visible = false
				$Send.visible = false
				RTL.text = tr("CLUSTER_FULLY_CONQUERED")
				return
			$Control.visible = true
			$Control2.visible = false
			$Send.text = tr("SEND")
			$Send.visible = true
			set_process(false)
			for gal in game.galaxy_data:
				if gal.is_empty():
					continue
				if not gal.has("conquered"):
					strength_required += gal.diff
					sys_num += gal.system_num
					unconquered_obj += 1
			for fighter in game.fighter_data:
				if fighter == null or fighter.has("exploring"):
					continue
				if fighter.tier == 1 and fighter.c_c == game.c_c:
					combined_strength += fighter.strength
					fighter_num += fighter.number
					base_travel_costs += 5e13 * fighter.number * sys_num / game.u_i.speed_of_light
			if combined_strength == 0:
				RTL.text = "%s\n%s: %s" % [tr("NO_FIGHTERS"), tr("STRENGTH_REQUIRED_F2"), Helper.format_num(ceil(strength_required))]
				$Send.visible = false
				$Control.visible = false
				return
			combined_strength2 = combined_strength
			sort_galaxies($Control/ConquerOrderPanel/CheckBox.button_pressed)
			for galaxy in sorted_objs:
				if galaxy.is_empty() or galaxy.has("conquered"):
					continue
				if combined_strength2 < galaxy.diff:
					if obj_num == 0:
						continue
					else:
						break
				else:
					combined_strength2 -= galaxy.diff
					obj_num += 1
			base_travel_costs *= obj_num
			refresh_energy()
			if unconquered_obj == 0:
				game.u_i.cluster_data[game.c_c].conquered = true

func sort_systems(ascending:bool):
	sorted_objs = game.system_data.duplicate(true)
	sorted_objs.sort_custom(Callable(self,"diff_sort"))
	if not ascending:
		sorted_objs.reverse()
	
func sort_galaxies(ascending:bool):
	sorted_objs = game.galaxy_data.duplicate(true)
	sorted_objs.sort_custom(Callable(self,"diff_sort"))
	if not ascending:
		sorted_objs.reverse()

func diff_sort(a:Dictionary, b:Dictionary):
	if b.is_empty():
		return false
	if a.is_empty() or a.diff < b.diff:
		return true
	return false

func has_SE(p_i:Dictionary):
	return p_i.get("MS") == "SE"

func get_atm_exit_cost(p_i:Dictionary):
	var res:float = pow(p_i.pressure * 10, 1.5) * 300000
	if has_SE(p_i):
		res *= get_entry_exit_multiplier(p_i.MS_lv)
	return round(res)

func get_grav_exit_cost(p_i:Dictionary):
	var res:float = pow(p_i.size / 180.0, 2.5) * 1000 * game.u_i.gravitational
	if has_SE(p_i):
		res *= get_entry_exit_multiplier(p_i.MS_lv)
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

func _on_CheckBox_pressed():
	$Control/ConquerOrderPanel/CheckBox.button_pressed = true
	$Control/ConquerOrderPanel/CheckBox2.button_pressed = false
	refresh()

func _on_CheckBox2_pressed():
	$Control/ConquerOrderPanel/CheckBox2.button_pressed = true
	$Control/ConquerOrderPanel/CheckBox.button_pressed = false
	refresh()

func _on_Send_pressed():
	if obj_num <= 0:
		return
	if fighter_type == 0:
		if not game.galaxy_data[game.c_g].has("conquer_start_date"):
			if game.energy >= total_energy_cost:
				game.energy -= total_energy_cost
				var curr_time = Time.get_unix_time_from_system()
				for i in len(game.fighter_data):
					if game.fighter_data[i] != null and game.fighter_data[i].tier == 0 and game.fighter_data[i].c_g_g == game.c_g_g:
						game.fighter_data[i]["exploring"] = true
				game.galaxy_data[game.c_g].conquer_start_date = curr_time
				game.galaxy_data[game.c_g].time_for_one_sys = time_for_one_obj
				game.galaxy_data[game.c_g].sys_num = obj_num
				game.galaxy_data[game.c_g].sys_conquered = 0
				game.galaxy_data[game.c_g].combined_strength = combined_strength
				game.galaxy_data[game.c_g].conquer_order = $Control/ConquerOrderPanel/CheckBox.button_pressed#true: ascending difficulty
				game.HUD.refresh()
				game.view.obj.set_process(true)
			else:
				game.popup(tr("NOT_ENOUGH_ENERGY"), 1.5)
	elif fighter_type == 1:
		if not game.u_i.cluster_data[game.c_c].has("conquer_start_date"):
			if game.energy >= total_energy_cost:
				game.energy -= total_energy_cost
				var curr_time = Time.get_unix_time_from_system()
				for i in len(game.fighter_data):
					if game.fighter_data[i] != null and game.fighter_data[i].tier == 1 and game.fighter_data[i].c_c == game.c_c:
						game.fighter_data[i]["exploring"] = true
				game.u_i.cluster_data[game.c_c].conquer_start_date = curr_time
				game.u_i.cluster_data[game.c_c].time_for_one_gal = time_for_one_obj
				game.u_i.cluster_data[game.c_c].gal_num = obj_num
				game.u_i.cluster_data[game.c_c].gal_conquered = 0
				game.u_i.cluster_data[game.c_c].combined_strength = combined_strength
				game.u_i.cluster_data[game.c_c].conquer_order = $Control/ConquerOrderPanel/CheckBox.button_pressed#true: ascending difficulty
				game.HUD.refresh()
				game.view.obj.set_process(true)
			else:
				game.popup(tr("NOT_ENOUGH_ENERGY"), 1.5)
	refresh()

func _process(delta):
	if not visible:
		set_process(false)
		return
	if game.c_v == "galaxy" and not game.galaxy_data[game.c_g].has("conquer_start_date"):
		set_process(false)
		refresh()
		return
	if game.c_v == "cluster" and not game.u_i.cluster_data[game.c_c].has("conquer_start_date"):
		set_process(false)
		refresh()
		return
	var curr_time = Time.get_unix_time_from_system()
	if fighter_type == 0:
		var g_i = game.galaxy_data[game.c_g]
		progress.value = (curr_time - g_i.conquer_start_date) / g_i.time_for_one_sys * 100
		RTL.text = "%s: %s / %s" % [tr("SYSTEMS_CONQUERED"), g_i.sys_conquered, g_i.sys_num]
		$Control2/TimeLeft2.text = tr("TIME_TO_NEXT_CONQUER_F1")
		time_left.text = Helper.time_to_str(game.galaxy_data[game.c_g].time_for_one_sys - Time.get_unix_time_from_system() + game.galaxy_data[game.c_g].conquer_start_date)
	elif fighter_type == 1:
		var c_i = game.u_i.cluster_data[game.c_c]
		progress.value = (curr_time - c_i.conquer_start_date) / c_i.time_for_one_gal * 100
		RTL.text = "%s: %s / %s" % [tr("GALAXIES_CONQUERED"), c_i.gal_conquered, c_i.gal_num]
		$Control2/TimeLeft2.text = tr("TIME_TO_NEXT_CONQUER_F2")
		time_left.text = Helper.time_to_str(c_i.time_for_one_gal - Time.get_unix_time_from_system() + c_i.conquer_start_date)


func _on_mouse_exited():
	game.hide_tooltip()


func _on_h_slider_value_changed(value: float) -> void:
	refresh_energy()


func _on_se_hint_mouse_entered() -> void:
	game.show_tooltip(tr("SE_HINT"))
