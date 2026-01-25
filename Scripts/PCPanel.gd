extends "Panel.gd"

var costs:Dictionary
var probe_tier:int = 0
var id:int = -1#Used when clicking "view planet" or "view galaxy" button
var l_id:int = -1#Used when clicking "view planet" or "view galaxy" button

func _ready():
	set_polygon(size)

func refresh():
	_on_SpinBox_value_changed($SpinBox.value)
	var probe_num:int = 0
	for i in len(game.probe_data):
		if game.probe_data[i] == null:
			continue
		probe_num += 1
	if probe_tier == 0:
		$Label.text = tr("PROBE_CONSTRUCTION_CENTER_NAME")
	$SpinBox.max_value = max(0, 500 - probe_num)
	$Construct.visible = $SpinBox.max_value > 0
	$TextureRect.texture = load("res://Graphics/Ships/Probe%s.png" % probe_tier)

func _on_SpinBox_value_changed(value):
	if probe_tier == 0:
		costs = {"money":2e12, "nanocrystal":2.7e6}
	elif probe_tier == 1:
		costs = {"money":5e18, "nanocrystal":4.0e13}
	for cost in costs:
		costs[cost] *= value
	Helper.put_rsrc($ScrollContainer/HBox, 32, costs, true, true)

func _on_construct_pressed():
	if game.check_enough(costs):
		game.deduct_resources(costs)
		game.popup(tr("PROBES_CONSTRUCTED"), 3)
		var probes_remaining:int = $SpinBox.value
		for i in len(game.probe_data):
			if game.probe_data[i] == null:
				game.probe_data[i] = {"tier":probe_tier}
				probes_remaining -= 1
			if probes_remaining <= 0:
				break
		for i in probes_remaining:
			game.probe_data.append({"tier":probe_tier})
		_on_close_button_pressed()
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)
