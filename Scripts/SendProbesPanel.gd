extends "Panel.gd"

var costs:Dictionary = {}
var exploring_probe_num:int = 0
var obj_to_discover:int = -1
var dist_mult:float = 1

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
		else:
			$Control.visible = true
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
		else:
			$Control.visible = true
			$Label.text = "%s: %s\n%s: %s\n%s: %s" % [tr("PROBE_NUM_IN_U"), probe_num, tr("EXPLORING_PROBE_NUM"), exploring_probe_num, tr("UNDISCOVERED_SC_NUM"), undiscovered_sc]
			refresh_energy()

func refresh_energy():
	var slider_factor = pow(10, $Control/HSlider.value / 50.0 - 1)
	if game.c_v == "supercluster":
		costs.energy = 1000000000000 * slider_factor * dist_mult
		costs.Xe = 10000 * slider_factor * dist_mult
		costs.time = 1500 / pow(slider_factor, 0.4) * dist_mult
	elif game.c_v == "universe":
		costs.energy = 10000000000000000000000.0 * slider_factor * dist_mult
		costs.Pu = 1000000 * slider_factor * dist_mult
		costs.time = 15000 / pow(slider_factor, 0.4) * dist_mult
	Helper.put_rsrc($Control/Costs, 36, costs, true, true)
	
func dist_sort(a:Dictionary, b:Dictionary):
	if a.pos.length() < b.pos.length():
		return true
	return false

func _on_Send_pressed():
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

func _on_HSlider_value_changed(value):
	refresh_energy()
