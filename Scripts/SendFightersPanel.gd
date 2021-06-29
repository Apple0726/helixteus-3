extends "Panel.gd"

var sys_num:int = 0
var time_for_one_sys:float = 0
var total_energy_cost:float = 0
var combined_strength:float = 0
var base_travel_costs:float = 0
var planet_exit_costs:float = 0
var unconquered_sys:int = 0
var strength_required:float = 0
var sorted_systems:Array = []
onready var RTL:RichTextLabel = $Label
onready var time_left:Label = $Control2/TimeLeft
onready var progress:TextureProgress = $Control2/TextureProgress

func _ready():
	set_process(false)
	set_polygon($Background.rect_size)

func refresh_energy():
	var slider_factor = pow(10, $Control/HSlider.value / 50.0 - 1)
	$Control/EnergyCost.text = Helper.format_num(base_travel_costs * slider_factor + planet_exit_costs)
	time_for_one_sys = 2 * 1200.0 / slider_factor
	game.add_text_icons(RTL, "%s: %s\n%s: %s\n%s: %s\n%s: %s\n%s: @i %s\n%s: @i %s" % [tr("COMBINED_STRENGTH"), Helper.format_num(ceil(combined_strength)), tr("STRENGTH_REQUIRED"), Helper.format_num(ceil(strength_required)), tr("NUMBER_OF_SYS_BEFORE_REKT"), sys_num, tr("NUMBER_OF_UNCONQUERED_SYS"), unconquered_sys, tr("PLANET_EXIT_COST"), Helper.format_num(planet_exit_costs), tr("TIME_TO_CONQUER_ALL_SYS"), Helper.time_to_str(time_for_one_sys * sys_num)], [Data.energy_icon, Data.time_icon], 19)

func refresh():
	if game.galaxy_data[game.c_g].has("conquer_start_date"):
		$Send.text = tr("DISBAND")
		sort_systems(game.galaxy_data[game.c_g].conquer_order)
		set_process(true)
		$Control.visible = false
		$Control2.visible = true
	else:
		if game.galaxy_data[game.c_g].has("conquered"):
			$Control.visible = false
			$Control2.visible = false
			$Send.visible = false
			$Label.text = tr("GALAXY_FULLY_CONQUERED")
			return
		$Control.visible = true
		$Control2.visible = false
		$Send.text = tr("SEND")
		set_process(false)
		var fighter_num:int = 0
		var combined_strength2:float = 0
		strength_required = 0
		planet_exit_costs = 0
		unconquered_sys = 0
		base_travel_costs = 0
		combined_strength = 0
		for sys in game.system_data:
			if not sys.has("conquered"):
				strength_required += sys.diff
				unconquered_sys += 1
		for fighter in game.fighter_data:
			if fighter.c_g_g == game.c_g_g:
				var file = File.new()
				file.open("user://Save1/Systems/%s.hx3" % [fighter.c_s_g], File.READ)
				var planets_in_depart_system = file.get_var()
				combined_strength += fighter.strength
				fighter_num += fighter.number
				planet_exit_costs += get_atm_exit_cost(planets_in_depart_system[fighter.c_p]) + get_grav_exit_cost(planets_in_depart_system[fighter.c_p]) * fighter.number
				base_travel_costs += 50000000 * fighter.number * (get_travel_cost_multiplier(planets_in_depart_system[fighter.c_p].MS_lv) if has_SE(planets_in_depart_system[fighter.c_p]) else 1)
		combined_strength2 = combined_strength
		sort_systems($Control/CheckBox2.pressed)
		sys_num = 0
		for system in sorted_systems:
			if system.has("conquered"):
				continue
			if combined_strength2 < system.diff:
				if sys_num == 0:
					continue
				else:
					break
			else:
				combined_strength2 -= system.diff
				sys_num += 1
		base_travel_costs *= sys_num
		refresh_energy()
		if unconquered_sys == 0:
			game.galaxy_data[game.c_g].conquered = true

func sort_systems(invert:bool):
	sorted_systems = game.system_data.duplicate(true)
	sorted_systems.sort_custom(self, "diff_sort")
	if invert:
		sorted_systems.invert()
	
func diff_sort(a:Dictionary, b:Dictionary):
	if a.diff < b.diff:
		return true
	return false

func has_SE(p_i:Dictionary):
	return p_i.has("MS") and p_i.MS == "M_SE" and not p_i.bldg.is_constructing

func get_atm_exit_cost(p_i:Dictionary):
	var res:float = pow(p_i.pressure * 10, 1.5) * 300000
	if has_SE(p_i):
		res *= get_entry_exit_multiplier(p_i.MS_lv)
	return round(res)

func get_grav_exit_cost(p_i:Dictionary):
	var res:float = pow(p_i.size / 180.0, 2.5) * 1000
	if has_SE(p_i):
		res *= get_entry_exit_multiplier(p_i.MS_lv)
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

func _on_CheckBox_pressed():
	$Control/CheckBox.pressed = true
	$Control/CheckBox2.pressed = false
	refresh()

func _on_CheckBox2_pressed():
	$Control/CheckBox2.pressed = true
	$Control/CheckBox.pressed = false
	refresh()

func _on_Send_pressed():
	if not game.galaxy_data[game.c_g].has("conquer_start_date"):
		if sys_num > 0 and game.energy >= total_energy_cost:
			game.energy -= total_energy_cost
			var curr_time = OS.get_system_time_msecs()
			for fighter in game.fighter_data:
				if fighter.c_g_g == game.c_g_g:
					game.fighter_data.erase(fighter)
			game.galaxy_data[game.c_g].conquer_start_date = curr_time
			game.galaxy_data[game.c_g].time_for_one_sys = time_for_one_sys
			game.galaxy_data[game.c_g].sys_num = sys_num
			game.galaxy_data[game.c_g].sys_conquered = 0
			game.galaxy_data[game.c_g].combined_strength = combined_strength
			game.galaxy_data[game.c_g].conquer_order = $Control/CheckBox.pressed#true: ascending difficulty
			refresh()
	else:
		game.galaxy_data[game.c_g].erase("conquer_start_date")
		game.galaxy_data[game.c_g].erase("time_for_one_sys")
		game.galaxy_data[game.c_g].erase("sys_num")
		game.galaxy_data[game.c_g].erase("sys_conquered")
		game.galaxy_data[game.c_g].erase("combined_strength")
		game.galaxy_data[game.c_g].erase("conquer_order")
		var galaxy_conquered = true
		for system in sorted_systems:
			if not system.has("conquered"):
				galaxy_conquered = false
				break
		if galaxy_conquered:
			game.galaxy_data[game.c_g].conquered = true
		refresh()

func _process(delta):
	if game.c_v != "galaxy" or not game.galaxy_data[game.c_g].has("conquer_start_date"):
		set_process(false)
		return
	var curr_time = OS.get_system_time_msecs()
	progress.value = (curr_time - game.galaxy_data[game.c_g].conquer_start_date) / game.galaxy_data[game.c_g].time_for_one_sys * 100
	var fighters_rekt = game.galaxy_data[game.c_g].combined_strength <= 0
	var galaxy_conquered = true
	var breaker:int = 0
	while breaker < 50:
		breaker += 1
		if not fighters_rekt and progress.value >= 100:
			for system in sorted_systems:
				if system.has("conquered"):
					continue
				galaxy_conquered = false
				if game.galaxy_data[game.c_g].combined_strength < system.diff:
					game.galaxy_data[game.c_g].combined_strength = 0
					fighters_rekt = true
					breaker = 50
					break
				if not system.has("conquered"):
					game.galaxy_data[game.c_g].combined_strength -= system.diff
					game.system_data[system.l_id].conquered = true
					system.conquered = true
					game.galaxy_data[game.c_g].sys_conquered += 1
					game.galaxy_data[game.c_g].conquer_start_date += game.galaxy_data[game.c_g].time_for_one_sys
					progress.value = (curr_time - game.galaxy_data[game.c_g].conquer_start_date) / game.galaxy_data[game.c_g].time_for_one_sys * 100
					break
		elif not fighters_rekt:
			galaxy_conquered = false
			breaker = 50
	RTL.text = "%s: %s / %s" % [tr("SYSTEMS_CONQUERED"), game.galaxy_data[game.c_g].sys_conquered, game.galaxy_data[game.c_g].sys_num]
	if fighters_rekt:
		RTL.text += "\n%s" % tr("ALL_FIGHTERS_REKT")
		$Control2.visible = false
	elif galaxy_conquered:
		RTL.text += "\n%s" % tr("CONQUERED_GALAXY")
		$Control2.visible = false
	else:
		time_left.text = Helper.time_to_str(game.galaxy_data[game.c_g].time_for_one_sys - OS.get_system_time_msecs() + game.galaxy_data[game.c_g].conquer_start_date)
	
func _on_HSlider_value_changed(value):
	refresh_energy()
