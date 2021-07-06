extends "Panel.gd"

var costs:Dictionary = {}
var exploring_probe_num:int = 0
var obj_to_discover:int = -1
var dist_mult:float = 1
var PP:float

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
	"value":"",
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
	"value":0,
	}

var weights:Dictionary = {
	"speed_of_light":20,
	"planck":30,
	"boltzmann":20,
	"gravitational":30,
	"charge":20,
	"dark_energy":30,
	"difficulty":20,
	"time_speed":50,
	"antimatter":20,
	"value":100,
	}


func _ready():
	set_process(false)
	set_polygon($Background.rect_size)

func refresh():
	var probe_num:int = 0
	exploring_probe_num = 0
	costs.clear()
	if game.c_v == "supercluster":
		var undiscovered_clusters:int = 0
		var n:int = len(game.cluster_data)
		for cluster in game.cluster_data:
			if not cluster.visible:
				undiscovered_clusters += 1
		for probe in game.probe_data:
			if probe.tier == 0:
				probe_num += 1
				if probe.has("start_date"):
					exploring_probe_num += 1
		dist_mult = pow(1.01, n - undiscovered_clusters + exploring_probe_num)
		var clusters:Array = game.cluster_data.duplicate(true)
		clusters.sort_custom(self, "dist_sort")
		var exploring_probe_offset:int = exploring_probe_num
		for i in len(clusters):
			if not clusters[i].visible:
				if exploring_probe_offset == 0:
					obj_to_discover = clusters[i].l_id
					break
				else:
					exploring_probe_offset -= 1
		if probe_num - exploring_probe_num <= 0:
			$Label.text = tr("NO_PROBES")
			$Control.visible = false
			$Send.visible = false
		else:
			$Control.visible = true
			$Send.visible = true
			$Label.text = "%s: %s\n%s: %s\n%s: %s" % [tr("PROBE_NUM_IN_SC"), probe_num, tr("EXPLORING_PROBE_NUM"), exploring_probe_num, tr("UNDISCOVERED_CLUSTER_NUM"), undiscovered_clusters]
		refresh_energy()
	elif game.c_v == "universe":
		var undiscovered_sc:int = 0
		var n:int = len(game.supercluster_data)
		for sc in game.supercluster_data:
			if not sc.visible:
				undiscovered_sc += 1
		for probe in game.probe_data:
			if probe.tier == 1:
				probe_num += 1
				if probe.has("start_date"):
					exploring_probe_num += 1
		dist_mult = pow(1.01, n - undiscovered_sc + exploring_probe_num)
		var scs:Array = game.supercluster_data.duplicate(true)
		scs.sort_custom(self, "dist_sort")
		var exploring_probe_offset:int = exploring_probe_num
		for i in len(scs):
			if not scs[i].visible:
				if exploring_probe_offset == 0:
					obj_to_discover = scs[i].id
					break
				else:
					exploring_probe_offset -= 1
		if probe_num - exploring_probe_num <= 0:
			$Label.text = tr("NO_MEGA_PROBES")
			$Control.visible = false
			$Send.visible = false
		else:
			$Control.visible = true
			$Send.visible = true
			$Label.text = "%s: %s\n%s: %s\n%s: %s" % [tr("PROBE_NUM_IN_U"), probe_num, tr("EXPLORING_PROBE_NUM"), exploring_probe_num, tr("UNDISCOVERED_SC_NUM"), undiscovered_sc]
			refresh_energy()
	elif game.c_v == "dimension":
		PP = get_lv_sum() + Helper.get_sum_of_dict(point_distribution)
		var ok:bool = false
		for probe in game.probe_data:
			if probe.tier == 2:
				ok = true
		$Control.visible = false
		$Send.visible = ok
		$TP.visible = ok
		if ok:
			for prop in $TP/VBox.get_children():
				prop.get_node("Unit").text = units[prop.name]
			$TP/Points.text = "%s: %s" % [tr("PROBE_POINTS"), PP]
			$Label.text = ""
		else:
			$Label.text = tr("NO_TRI_PROBES")

func refresh_energy():
	var slider_factor = pow(10, $Control/HSlider.value / 50.0 - 1)
	if game.c_v == "supercluster":
		costs.energy = 1000000000000 * slider_factor * dist_mult
		costs.Xe = 10000 * slider_factor * dist_mult
		costs.time = 1500 / pow(slider_factor, 0.4) * dist_mult
	elif game.c_v == "universe":
		costs.energy = 10000000000000000000.0 * slider_factor * dist_mult
		costs.Pu = 1000 * slider_factor * dist_mult
		costs.time = 15 / pow(slider_factor, 0.4) * dist_mult
	Helper.put_rsrc($Control/Costs, 36, costs, true, true)
	
func dist_sort(a:Dictionary, b:Dictionary):
	if a.pos.length() < b.pos.length():
		return true
	return false

func discover_univ():
	for probe in game.probe_data:
		if probe.tier == 2:
			game.probe_data.erase(probe)
	var id:int = len(game.universe_data)
	var u_i:Dictionary = {"id":id, "lv":1, "xp":0, "xp_to_lv":10, "shapes":[], "name":"%s %s" % [tr("UNIVERSE"), id], "supercluster_num":8000, "view":{"pos":Vector2(640 * 0.5, 360 * 0.5), "zoom":2, "sc_mult":0.1}}
	for prop in $TP/VBox.get_children():
		if prop.name == "s_b":
			continue
		u_i[prop.name] = float(prop.get_node("Label2").text)
	game.universe_data.append(u_i)
	if visible:
		game.toggle_panel(self)
	game.dimension.refresh_univs()

func _on_Send_pressed():
	if game.c_v == "dimension":
		if PP >= 0:
			for prop in $TP/VBox.get_children():
				if prop.get_node("Label2")["custom_colors/font_color"] == Color.red:
					game.popup(tr("INVALID_INPUT"), 1.5)
					return
			if PP >= 5:
				game.show_YN_panel("discover_univ", tr("TP_CONFIRM2"))
			else:
				discover_univ()
		else:
			game.popup(tr("NOT_ENOUGH_PP"), 2.0)
			return
			
	else:
		if game.check_enough(costs):
			game.deduct_resources(costs)
			var curr_time = OS.get_system_time_msecs()
			if game.c_v == "supercluster":
				for probe in game.probe_data:
					if probe.tier == 0 and not probe.has("start_date"):
						probe.start_date = curr_time
						probe.explore_length = costs.time * 1000
						probe.obj_to_discover = obj_to_discover
						break
			elif game.c_v == "universe":
				for probe in game.probe_data:
					if probe.tier == 1 and not probe.has("start_date"):
						probe.start_date = curr_time
						probe.explore_length = costs.time * 1000
						probe.obj_to_discover = obj_to_discover
						break
			game.popup(tr("PROBE_SENT"), 1.5)
			refresh()
		else:
			game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)

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
		point_distribution.antimatter = value * -weights[prop]
	else:
		if value >= 1:
			point_distribution[prop] = (value - 1) * -weights[prop]
		else:
			point_distribution[prop] = (1 / value - 1) * weights[prop]
	PP = get_lv_sum() + Helper.get_sum_of_dict(point_distribution)
	if is_equal_approx(PP, 0):
		PP = 0
	var s_b:float = pow(float($TP/VBox/boltzmann/Label2.text), 4) / pow(float($TP/VBox/planck/Label2.text), 3) / pow(float($TP/VBox/speed_of_light/Label2.text), 2)
	if s_b >= 1000:
		$TP/VBox/s_b/Label2.text = Helper.format_num(round(s_b))
	else:
		$TP/VBox/s_b/Label2.text = String(Helper.clever_round(s_b))
	$TP/Points.text = "%s: %s" % [tr("PROBE_POINTS"), PP]

func get_lv_sum():
	var lv:int = 0
	for univ in game.universe_data:
		lv += univ.lv
	return lv

func _on_Points_mouse_entered():
	game.show_tooltip(tr("TP_POINTS_INFO"))

func _on_mouse_exited():
	game.hide_tooltip()


func _on_Label_mouse_entered(extra_arg_0):
	game.show_tooltip(tr(extra_arg_0))


func _on_Label2_text_changed(new_text, prop:String):
	var new_value:float = float(new_text)
	if prop == "antimatter" and new_value >= 0 or new_value > 0:
		_on_TP_value_changed(new_value, prop)
		get_node("TP/VBox/%s/Label2" % prop)["custom_colors/font_color"] = Color.white
	else:
		get_node("TP/VBox/%s/Label2" % prop)["custom_colors/font_color"] = Color.red
