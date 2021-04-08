extends "Panel.gd"

var costs:Dictionary

func _ready():
	set_polygon(rect_size)

func refresh():
	_on_SpinBox_value_changed($SpinBox.value)

func e(n, e):
	return n * pow(10, e)

func _on_SpinBox_value_changed(value):
	costs = {"money":e(2, 11), "nanocrystal":2700000}
	for cost in costs:
		costs[cost] *= value
	Helper.put_rsrc($ScrollContainer/HBox, 32, costs, true, true)

func _on_Construct_pressed():
	if game.check_enough(costs):
		game.deduct_resources(costs)
		game.popup(tr("PROBES_CONSTRUCTED"), 3)
		for i in $SpinBox.value:
			game.probe_data.append({"c_sc":game.c_sc})
		_on_close_button_pressed()
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)
