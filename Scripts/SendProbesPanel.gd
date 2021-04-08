extends "Panel.gd"

var costs:Dictionary = {}
var exploring_probe_num:int = 0
var cluster_to_discover:int = -1

func _ready():
	set_process(false)
	set_polygon($Background.rect_size)

func refresh():
	var slider_factor = pow(10, $Control/HSlider.value / 25.0 - 2)
	var probe_num:int = 0
	var undiscovered_clusters:int = 0
	var n:int = len(game.cluster_data)
	exploring_probe_num = 0
	for cluster in game.cluster_data:
		if not cluster.visible:
			undiscovered_clusters += 1
	for probe in game.probe_data:
		if probe.c_sc == game.c_sc:
			probe_num += 1
			if probe.has("start_date"):
				exploring_probe_num += 1
	var dist_mult:float = pow(1.01, n - undiscovered_clusters + exploring_probe_num)
	var clusters:Array = game.cluster_data.duplicate(true)
	clusters.sort_custom(self, "dist_sort")
	var exploring_probe_offset:int = exploring_probe_num
	for i in len(clusters):
		if not clusters[i].visible:
			if exploring_probe_offset == 0:
				cluster_to_discover = clusters[i].l_id
				break
			else:
				exploring_probe_offset -= 1
	if probe_num - exploring_probe_num <= 0:
		$Label.text = tr("NO_PROBES")
		$Control.visible = false
	else:
		$Control.visible = true
		$Label.text = "%s: %s\n%s: %s\n%s: %s" % [tr("PROBE_NUM_IN_SC"), probe_num, tr("EXPLORING_PROBE_NUM"), exploring_probe_num, tr("UNDISCOVERED_CLUSTER_NUM"), undiscovered_clusters]
	costs.energy = 1000000000000 * slider_factor * dist_mult
	costs.Xe = 10000 * slider_factor * dist_mult
	costs.time = 15 / pow(slider_factor, 0.3) * dist_mult
	Helper.put_rsrc($Control/Costs, 36, costs, true, true)

func dist_sort(a:Dictionary, b:Dictionary):
	if a.pos.length() < b.pos.length():
		return true
	return false

func _on_Send_pressed():
	if game.check_enough(costs):
		game.deduct_resources(costs)
		var curr_time = OS.get_system_time_msecs()
		for probe in game.probe_data:
			if probe.c_sc == game.c_sc and not probe.has("start_date"):
				probe.start_date = curr_time
				probe.explore_length = costs.time * 1000
				probe.cluster_to_discover = cluster_to_discover
				break
		game.popup(tr("PROBE_SENT"), 1.5)
		refresh()

func _on_HSlider_value_changed(value):
	refresh()
