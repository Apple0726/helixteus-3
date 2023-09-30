extends "Panel.gd"

var costs:Dictionary = {}
var probe_num:int = 0
var exploring_probe_num:int = 0
var sorted_objs:Array = []
var n:int = 0
var obj_index:int = -1
var obj_to_discover:int = -1
var undiscovered_obj_num:int = 0
var dist_mult:float = 1
var PP:float
var init_PP:float
var PP_multiplier:float = 1.0
var dist_exp:int

var units:Dictionary = {
	"speed_of_light":"c",
	"planck":"h",
	"boltzmann":"k",
	"s_b":"σ",
	"gravitational":"G",
	"charge":"e",
	"dark_energy":"",
	"difficulty":"",
	"time_speed":"",
	"age":"x " + tr("DEFAULT_UNIVERSE_AGE"),
	"antimatter":"",
	}

var point_distribution:Dictionary = {
	"speed_of_light":0,
	"planck":0,
	"boltzmann":0,
	"gravitational":0,
	"charge":0,
	"dark_energy":0,
	"difficulty":0,
	"time_speed":0,
	"age":0,
	"antimatter":0,
	}


func _ready():
	set_polygon(size)

func refresh():
	for prop in point_distribution.keys():
		if prop == "age":
			$TP/VBox.get_node(prop + "/Label").text = "%s [img]Graphics/Icons/help.png[/img]" % tr("AGE_OF_THE_UNIVERSE")
		else:
			$TP/VBox.get_node(prop + "/Label").text = "%s [img]Graphics/Icons/help.png[/img]" % tr(prop.to_upper())
		_on_TP_value_changed(float(get_node("TP/VBox/%s/Label2" % prop).text), prop)
	$TP/VBox/s_b/Label.text = "%s [img]Graphics/Icons/help.png[/img]" % tr("S_B_CTE")
	probe_num = 0
	exploring_probe_num = 0
	costs.clear()
	if game.viewing_dimension:
		init_PP = get_lv_sum()
		if game.subject_levels.dimensional_power >= 5:
			init_PP += 150
		var ok:bool = false
		if len(game.universe_data) == 0 and game.subject_levels.dimensional_power >= 5:
			ok = true
		PP_multiplier = 1.0
		for probe in game.probe_data:
			if probe and probe.tier == 2:
				ok = true
				PP_multiplier = probe.get("PP_multiplier", 1.0)
				break
		PP = init_PP * PP_multiplier + Helper.get_sum_of_dict(point_distribution)
		$Control.visible = false
		$Send.visible = ok
		$SendAll.visible = false
		$TP.visible = ok
		$Label.text = ""
		if ok:
			for prop in $TP/VBox.get_children():
				prop.get_node("Unit").text = units[prop.name]
				if prop.name == "time_speed" and game.subject_levels.dimensional_power >= 4:
					var cave_battle_time_speed:float = log(prop.get_node("HSlider").value - 1.0 + exp(1.0))
					prop.get_node("Unit").text = " (%s)" % [tr("TIME_SPEED_IN_BATTLES_CAVES") % cave_battle_time_speed]
				if prop.has_node("HSlider"):
					prop.get_node("HSlider").min_value = game.physics_bonus.MVOUP
					prop.get_node("HSlider").max_value = ceil(init_PP * PP_multiplier / Data.univ_prop_weights[prop.name] / 2.0)
					prop.get_node("HSlider").step = 0.1
					var value_range = prop.get_node("HSlider").max_value - prop.get_node("HSlider").min_value
					if value_range > 10:
						prop.get_node("HSlider").step = 0.2
						if value_range > 30:
							prop.get_node("HSlider").step = 0.5
			$TP/Points.text = "%s: %s [img]Graphics/Icons/help.png[/img]" % [tr("PROBE_POINTS"), Helper.format_num(PP, true)]
			$NoProbes.visible = false
		else:
			$NoProbes.text = tr("NO_TRI_PROBES")
			$NoProbes.visible = true
	elif game.c_v == "universe":
		undiscovered_obj_num = 0
		n = len(game.u_i.cluster_data)
		for cluster in game.u_i.cluster_data:
			if not cluster.visible:
				undiscovered_obj_num += 1
		for probe in game.probe_data:
			if probe and probe.tier == 0:
				probe_num += 1
				if probe.has("start_date"):
					exploring_probe_num += 1
		dist_exp = n - undiscovered_obj_num + exploring_probe_num
		dist_mult = pow(1.01, dist_exp)
		sorted_objs = game.u_i.cluster_data.duplicate(true)
		sorted_objs.sort_custom(Callable(self,"dist_sort"))
		var exploring_probe_offset:int = exploring_probe_num
		for i in len(sorted_objs):
			if not sorted_objs[i].visible:
				if exploring_probe_offset == 0:
					obj_to_discover = sorted_objs[i].id
					obj_index = i
					break
				else:
					exploring_probe_offset -= 1
		if probe_num - exploring_probe_num <= 0:
			$NoProbes.text = tr("NO_PROBES")
			$NoProbes.visible = true
			$Control.visible = false
			$Send.visible = false
			$SendAll.visible = false
		else:
			$NoProbes.visible = false
			$Control.visible = true
			$Send.visible = true
			$SendAll.visible = true
		$Label.text = "%s: %s\n%s: %s\n%s: %s" % [tr("PROBE_NUM_IN_SC"), probe_num, tr("EXPLORING_PROBE_NUM"), exploring_probe_num, tr("UNDISCOVERED_CLUSTER_NUM"), undiscovered_obj_num]
		refresh_energy()
		$TP.visible = false
		$SendAll.text = "%s (x %s)" % [tr("SEND_ALL_PROBES"), min(probe_num - exploring_probe_num, undiscovered_obj_num - exploring_probe_num)]
	
func refresh_energy(send_all:bool = false):
	fill_costs(dist_mult)
	var costs2:Dictionary = costs.duplicate(true)
	costs2.erase("time")
	if not send_all:
		Helper.put_rsrc($Control/Costs, 36, costs2, true, true)
	$Control/Time.text = Helper.time_to_str(costs.time)
	
func dist_sort(a:Dictionary, b:Dictionary):
	if a.pos.length() < b.pos.length():
		return true
	return false

func discover_univ():
	if len(game.universe_data) > 0:
		for probe in game.probe_data:
			if probe and probe.tier == 2:
				game.probe_data.erase(probe)
				break
	var id:int = len(game.universe_data)
	var u_i:Dictionary = {"id":id, "lv":1, "xp":0, "xp_to_lv":10, "shapes":[], "name":"%s %s" % [tr("UNIVERSE"), id], "cluster_num":1000, "view":{"pos":Vector2(640, 360), "zoom":2, "sc_mult":0.1}}
	for prop in $TP/VBox.get_children():
		if prop.name == "s_b":
			continue
		u_i[prop.name] = float(prop.get_node("Label2").text)
	if not game.achievement_data.is_empty() and not game.achievement_data.progression.has("new_universe"):
		game.earn_achievement("progression", "new_universe")
	game.universe_data.append(u_i)
	if len(game.universe_data) == 1:
		game.dimension.set_bonuses()
		Data.MUs.MV.pw = game.maths_bonus.MUCGF_MV
		Data.MUs.MSMB.pw = game.maths_bonus.MUCGF_MSMB
		for el in game.PD_panel.bonuses.keys():
			game.chemistry_bonus[el] = game.PD_panel.bonuses[el]
	game.dimension.refresh_univs()
	if visible:
		game.toggle_panel(self)

func _on_Send_pressed(send_all:bool = false):
	if game.viewing_dimension:
		if PP >= 0:
			for prop in $TP/VBox.get_children():
				if prop.get_node("Label2")["theme_override_colors/font_color"] == Color.RED:
					game.popup(tr("INVALID_INPUT"), 1.5)
					return false
			if PP >= 5:
				game.show_YN_panel("discover_univ", tr("TP_CONFIRM2"))
			else:
				discover_univ()
		else:
			game.popup(tr("NOT_ENOUGH_PP"), 2.0)
		return false
	else:
		if game.check_enough(costs):
			var curr_time = Time.get_unix_time_from_system()
			var probe_sent:bool = false
			if game.c_v == "universe":
				for probe in game.probe_data:
					if probe and probe.tier == 0 and not probe.has("start_date"):
						probe.start_date = curr_time
						probe.explore_length = costs.time
						probe.obj_to_discover = obj_to_discover
						probe_sent = true
						break
			if not probe_sent and send_all:
				game.popup(tr("PROBE_SENT"), 1.5)
				refresh()
				return false
			game.deduct_resources(costs)
			if send_all:
				dist_exp += 1
				dist_mult = pow(1.01, dist_exp)
				if obj_index < n:
					obj_index += 1
					obj_to_discover = sorted_objs[obj_index].id
					refresh_energy(true)
				else:
					return false
			else:
				game.popup(tr("PROBE_SENT"), 1.5)
				refresh()
		else:
			game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)
			if send_all:
				refresh()
			return false
	return true

func _on_HSlider_value_changed(value):
	refresh_energy()

func e(n, e):
	return n * pow(10, e)
	
func _on_TP_value_changed(value:float, prop:String):
	var text_node:LineEdit = get_node("TP/VBox/%s/Label2" % prop)
	if get_viewport().gui_get_focus_owner() is HSlider:
		text_node["theme_override_colors/font_color"] = Color.WHITE
		text_node.text = str(value)
	else:
		value = float(text_node.text)
		get_node("TP/VBox/%s/HSlider" % prop).value = value
	if prop == "antimatter":
		point_distribution.antimatter = value * -game.physics_bonus[prop]
	else:
		if prop == "time_speed" and game.subject_levels.dimensional_power >= 4:
			var cave_battle_time_speed:float = log($TP/VBox/time_speed/HSlider.value - 1.0 + exp(1.0))
			$TP/VBox/time_speed/Unit.text = " (%.2f in battles/caves)" % [cave_battle_time_speed]
		if value >= 1:
			point_distribution[prop] = (value - 1) * -game.physics_bonus[prop]
		else:
			point_distribution[prop] = (1 / value - 1) * min(game.physics_bonus[prop], Data.univ_prop_weights[prop])
	PP = init_PP * PP_multiplier + Helper.get_sum_of_dict(point_distribution)
	if is_equal_approx(PP, 0):
		PP = 0
	var s_b:float = pow(float($TP/VBox/boltzmann/Label2.text), 4) / pow(float($TP/VBox/planck/Label2.text), 3) / pow(float($TP/VBox/speed_of_light/Label2.text), 2)
	if s_b >= 1000:
		$TP/VBox/s_b/Label2.text = Helper.format_num(round(s_b))
	else:
		$TP/VBox/s_b/Label2.text = str(Helper.clever_round(s_b))
	$TP/Points.text = "%s: %s [img]Graphics/Icons/help.png[/img]" % [tr("PROBE_POINTS"), Helper.format_num(PP, true)]

func get_lv_sum():
	var lv:float = 0
	for univ in game.universe_data:
		lv += pow(univ.lv, 2.2)
	lv /= 200
	return lv

func _on_Points_mouse_entered():
	game.show_adv_tooltip(tr("TP_POINTS_INFO"), [preload("res://Graphics/Formulas/PPs.png")], 80)

func _on_mouse_exited():
	game.hide_tooltip()


func _on_Label_mouse_entered(extra_arg_0):
	game.show_tooltip(tr(extra_arg_0))


func _on_Label2_text_changed(new_text, prop:String):
	var new_value:float = float(new_text)
	if prop == "antimatter" and new_value >= 0 or new_value >= 0.5:
		_on_TP_value_changed(new_value, prop)
		get_node("TP/VBox/%s/Label2" % prop)["theme_override_colors/font_color"] = Color.WHITE
	else:
		get_node("TP/VBox/%s/Label2" % prop)["theme_override_colors/font_color"] = Color.RED


func _on_SendAll_pressed():
	refresh_energy()
	while _on_Send_pressed(true):
		pass
	refresh()

func fill_costs(_dist_mult:float):
	var slider_factor = pow(10, $Control/HSlider.value / 25.0 - 2)
	if game.c_v == "universe":
		costs.energy = 2e18 * slider_factor * _dist_mult / game.u_i.speed_of_light
		costs.Pu = 1000 * slider_factor * _dist_mult / game.u_i.speed_of_light
		costs.time = 1500 / pow(slider_factor, 0.4) * _dist_mult / game.u_i.time_speed / game.u_i.speed_of_light
	
func _on_SendAll_mouse_entered():
	var costs2:Dictionary = {}
	var min_time:int = 0
	var max_time:int = 0
	var temp_dist_exp = dist_exp
	var temp_dist_mult = pow(1.01, temp_dist_exp)
	for i in int(min(probe_num - exploring_probe_num, undiscovered_obj_num)):
		fill_costs(temp_dist_mult)
		temp_dist_exp += 1
		temp_dist_mult = pow(1.01, temp_dist_exp)
		if costs2.is_empty():
			costs2 = costs.duplicate(true)
		else:
			for cost in costs2:
				if cost != "time":
					costs2[cost] += costs[cost]
		if min_time == 0:
			min_time = costs.time
		max_time = costs.time
	costs2.erase("time")
	Helper.put_rsrc($Control/Costs, 36, costs2, true, true)
	$Control/Time.text = "%s - %s"% [Helper.time_to_str(min_time), Helper.time_to_str(max_time)]

func _on_SendAll_mouse_exited():
	refresh_energy()


func _on_TierDistribution_mouse_entered():
	var st = tr("UNIQUE_BLDG_TIER_DISTRIBUTION")
	for tier in range(1, 7):
		var age = float($TP/VBox/age/Label2.text)
		var prob:float
		if tier == 1:
			prob = max(1 - age * exp(-3 * tier), 0)
		else:
			prob = max(min(age * exp(-3 * (tier-1)), 1) - age * exp(-3 * tier), 0)
		st += "\n" + tr("TIER_X") % tier + ": " + str(Helper.clever_round(100 * prob)) + "%"
	game.show_tooltip(st)

func _on_TierDistribution_mouse_exited():
	game.hide_tooltip()
