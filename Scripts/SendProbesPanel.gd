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
var dist_exp:int

var units:Dictionary = {
	"speed_of_light":"c",
	"planck":"h",
	"boltzmann":"k",
	"s_b":"\u03C3",
	"gravitational":"G",
	"charge":"e",
	"dark_energy":"",
	"difficulty":"",
	"time_speed":"",
	"antimatter":"",
	"universe_value":"",
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
	"antimatter":0,
	"universe_value":0,
	}


func _ready():
	set_process(false)
	set_polygon(rect_size)

func refresh():
	$TP/VBox/speed_of_light/Label.bbcode_text = "%s [img]Graphics/Icons/help.png[/img]" % tr("SPEED_OF_LIGHT")
	$TP/VBox/planck/Label.bbcode_text = "%s [img]Graphics/Icons/help.png[/img]" % tr("PLANCK")
	$TP/VBox/boltzmann/Label.bbcode_text = "%s [img]Graphics/Icons/help.png[/img]" % tr("BOLTZMANN")
	$TP/VBox/s_b/Label.bbcode_text = "%s [img]Graphics/Icons/help.png[/img]" % tr("S_B_CTE")
	$TP/VBox/gravitational/Label.bbcode_text = "%s [img]Graphics/Icons/help.png[/img]" % tr("GRAVITATIONAL")
	$TP/VBox/charge/Label.bbcode_text = "%s [img]Graphics/Icons/help.png[/img]" % tr("CHARGE")
	$TP/VBox/dark_energy/Label.bbcode_text = "%s [img]Graphics/Icons/help.png[/img]" % tr("DARK_ENERGY")
	$TP/VBox/difficulty/Label.bbcode_text = "%s [img]Graphics/Icons/help.png[/img]" % tr("DIFFICULTY")
	$TP/VBox/time_speed/Label.bbcode_text = "%s [img]Graphics/Icons/help.png[/img]" % tr("TIME_SPEED")
	$TP/VBox/antimatter/Label.bbcode_text = "%s [img]Graphics/Icons/help.png[/img]" % tr("ANTIMATTER")
	$TP/VBox/universe_value/Label.bbcode_text = "%s [img]Graphics/Icons/help.png[/img]" % tr("UNIVERSE_VALUE")
	probe_num = 0
	exploring_probe_num = 0
	costs.clear()
	if game.viewing_dimension:
		PP = get_lv_sum() + Helper.get_sum_of_dict(point_distribution)
		var ok:bool = false
		for probe in game.probe_data:
			if probe and probe.tier == 2:
				ok = true
		$Control.visible = false
		$Send.visible = ok
		$SendAll.visible = false
		$TP.visible = ok
		$Label.text = ""
		if ok:
			for prop in $TP/VBox.get_children():
				prop.get_node("Unit").text = units[prop.name]
				if prop.name == "universe_value" and game.subjects.dimensional_power.lv > 0:
					var UV_mult = 1.5 + game.subjects.dimensional_power.lv * 0.2
					prop.get_node("Unit").text = " (x %s) = %s" % [UV_mult, prop.get_node("HSlider").value * UV_mult]
				if prop.has_node("HSlider"):
					prop.get_node("HSlider").min_value = game.physics_bonus.MVOUP
					prop.get_node("HSlider").max_value = ceil(get_lv_sum() / 25.0)
			$TP/Points.bbcode_text = "%s: %s [img]Graphics/Icons/help.png[/img]" % [tr("PROBE_POINTS"), PP]
			$NoProbes.visible = false
		else:
			$NoProbes.text = tr("NO_TRI_PROBES")
			$NoProbes.visible = true
	elif game.c_v == "supercluster":
		undiscovered_obj_num = 0
		n = len(game.cluster_data)
		for cluster in game.cluster_data:
			if not cluster.visible:
				undiscovered_obj_num += 1
		for probe in game.probe_data:
			if probe and probe.tier == 0:
				probe_num += 1
				if probe.has("start_date"):
					exploring_probe_num += 1
		dist_exp = n - undiscovered_obj_num + exploring_probe_num
		dist_mult = pow(1.01, dist_exp)
		sorted_objs = game.cluster_data.duplicate(true)
		sorted_objs.sort_custom(self, "dist_sort")
		var exploring_probe_offset:int = exploring_probe_num
		for i in len(sorted_objs):
			if not sorted_objs[i].visible:
				if exploring_probe_offset == 0:
					obj_to_discover = sorted_objs[i].l_id
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
	elif game.c_v == "universe":
		undiscovered_obj_num = 0
		n = len(game.supercluster_data)
		for sc in game.supercluster_data:
			if not sc.visible:
				undiscovered_obj_num += 1
		for probe in game.probe_data:
			if probe and probe.tier == 1:
				probe_num += 1
				if probe.has("start_date"):
					exploring_probe_num += 1
		dist_exp = n - undiscovered_obj_num + exploring_probe_num
		dist_mult = pow(1.01, dist_exp)
		sorted_objs = game.supercluster_data.duplicate(true)
		sorted_objs.sort_custom(self, "dist_sort")
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
			$NoProbes.text = tr("NO_MEGA_PROBES")
			$NoProbes.visible = true
			$Control.visible = false
			$Send.visible = false
			$SendAll.visible = false
		else:
			$NoProbes.visible = false
			$Control.visible = true
			$Send.visible = true
			$SendAll.visible = true
			refresh_energy()
		$Label.text = "%s: %s\n%s: %s\n%s: %s" % [tr("PROBE_NUM_IN_U"), probe_num, tr("EXPLORING_PROBE_NUM"), exploring_probe_num, tr("UNDISCOVERED_SC_NUM"), undiscovered_obj_num]
		$TP.visible = false
		$SendAll.text = "%s (x %s)" % [tr("SEND_ALL_PROBES"), probe_num - exploring_probe_num]

func refresh_energy(send_all:bool = false):
	fill_costs(dist_mult)
	var costs2:Dictionary = costs.duplicate(true)
	costs2.erase("time")
	if not send_all:
		Helper.put_rsrc($Control/Costs, 36, costs2, true, true)
	$Control/Time.text = Helper.time_to_str(costs.time * 1000.0)
	
func dist_sort(a:Dictionary, b:Dictionary):
	if a.pos.length() < b.pos.length():
		return true
	return false

func discover_univ():
	for probe in game.probe_data:
		if probe and probe.tier == 2:
			game.probe_data.erase(probe)
			break
	var id:int = len(game.universe_data)
	var u_i:Dictionary = {"id":id, "lv":1, "xp":0, "xp_to_lv":10, "shapes":[], "name":"%s %s" % [tr("UNIVERSE"), id], "supercluster_num":1000, "view":{"pos":Vector2(640 * 0.5, 360 * 0.5), "zoom":2, "sc_mult":0.1}}
	for prop in $TP/VBox.get_children():
		if prop.name == "s_b":
			continue
		if prop.name == "universe_value":
			var UV_mult = (1.5 + game.subjects.dimensional_power.lv * 0.2) if game.subjects.dimensional_power.lv > 0 else 1.0
			u_i.universe_value = UV_mult * float(prop.get_node("Label2").text)
		else:
			u_i[prop.name] = float(prop.get_node("Label2").text)
	if not game.achievement_data.progression[2]:
		game.earn_achievement("progression", 2)
	game.universe_data.append(u_i)
	if visible:
		game.toggle_panel(self)
	game.dimension.refresh_univs()

func _on_Send_pressed(send_all:bool = false):
	if game.viewing_dimension:
		if PP >= 0:
			for prop in $TP/VBox.get_children():
				if prop.get_node("Label2")["custom_colors/font_color"] == Color.red:
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
			var curr_time = OS.get_system_time_msecs()
			var probe_sent:bool = false
			if game.c_v == "supercluster":
				for probe in game.probe_data:
					if probe and probe.tier == 0 and not probe.has("start_date"):
						probe.start_date = curr_time
						probe.explore_length = costs.time * 1000
						probe.obj_to_discover = obj_to_discover
						probe_sent = true
						break
			elif game.c_v == "universe":
				for probe in game.probe_data:
					if probe and probe.tier == 1 and not probe.has("start_date"):
						probe.start_date = curr_time
						probe.explore_length = costs.time * 1000
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
					if game.c_v == "supercluster":
						obj_to_discover = sorted_objs[obj_index].l_id
					elif game.c_v == "universe":
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
	if get_focus_owner() is HSlider:
		text_node["custom_colors/font_color"] = Color.white
		text_node.text = String(value)
	else:
		value = float(text_node.text)
		get_node("TP/VBox/%s/HSlider" % prop).value = value
	if prop == "antimatter":
		point_distribution.antimatter = value * -game.physics_bonus[prop]
	else:
		if prop == "universe_value" and game.subjects.dimensional_power.lv > 0:
			var UV_mult = 1.5 + game.subjects.dimensional_power.lv * 0.2
			$TP/VBox/universe_value/Unit.text = " (x %s) = %s" % [UV_mult, value * UV_mult]
		if value >= 1:
			point_distribution[prop] = (value - 1) * -game.physics_bonus[prop]
		else:
			point_distribution[prop] = (1 / value - 1) * game.physics_bonus[prop]
	PP = get_lv_sum() + Helper.get_sum_of_dict(point_distribution)
	if is_equal_approx(PP, 0):
		PP = 0
	var s_b:float = pow(float($TP/VBox/boltzmann/Label2.text), 4) / pow(float($TP/VBox/planck/Label2.text), 3) / pow(float($TP/VBox/speed_of_light/Label2.text), 2)
	if s_b >= 1000:
		$TP/VBox/s_b/Label2.text = Helper.format_num(round(s_b))
	else:
		$TP/VBox/s_b/Label2.text = String(Helper.clever_round(s_b))
	$TP/Points.bbcode_text = "%s: %s [img]Graphics/Icons/help.png[/img]" % [tr("PROBE_POINTS"), PP]

func get_lv_sum():
	var lv:int = 0
	for univ in game.universe_data:
		lv += univ.lv * univ.universe_value
	return lv

func _on_Points_mouse_entered():
	game.show_tooltip(tr("TP_POINTS_INFO"))

func _on_mouse_exited():
	game.hide_tooltip()


func _on_Label_mouse_entered(extra_arg_0):
	game.show_tooltip(tr(extra_arg_0))


func _on_Label2_text_changed(new_text, prop:String):
	var new_value:float = float(new_text)
	if prop == "antimatter" and new_value >= 0 or new_value >= 0.5:
		_on_TP_value_changed(new_value, prop)
		get_node("TP/VBox/%s/Label2" % prop)["custom_colors/font_color"] = Color.white
	else:
		get_node("TP/VBox/%s/Label2" % prop)["custom_colors/font_color"] = Color.red


func _on_SendAll_pressed():
	refresh_energy()
	while _on_Send_pressed(true):
		pass
	refresh()

func fill_costs(_dist_mult:float):
	var slider_factor = pow(10, $Control/HSlider.value / 25.0 - 2)
	if game.c_v == "supercluster":
		costs.energy = 50000000000000.0 * slider_factor * _dist_mult
		costs.Xe = 100000 * slider_factor * _dist_mult
		costs.time = 1200 / pow(slider_factor, 0.4) * _dist_mult / game.u_i.time_speed
	elif game.c_v == "universe":
		costs.energy = 10000000000000000000.0 * slider_factor * _dist_mult
		costs.Pu = 10000 * slider_factor * _dist_mult
		costs.time = 4500 / pow(slider_factor, 0.4) * _dist_mult / game.u_i.time_speed
	
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
		if costs2.empty():
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
	$Control/Time.text = "%s - %s"% [Helper.time_to_str(min_time * 1000.0), Helper.time_to_str(max_time * 1000.0)]

func _on_SendAll_mouse_exited():
	refresh_energy()
