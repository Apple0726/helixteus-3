extends "Panel.gd"

var costs:Dictionary
var probe_tier:int = 0
var id:int = -1#Used when clicking "view planet" or "view galaxy" button
var l_id:int = -1#Used when clicking "view planet" or "view galaxy" button

func _ready():
	set_polygon(rect_size)

func refresh():
	_on_SpinBox_value_changed($SpinBox.value)
	if probe_tier == 0:
		$Label.text = tr("PCC_NAME")
		$ViewPlanet.visible = false
	elif probe_tier == 1:
		$Label.text = tr("M_MPCC_NAME")
		$ViewPlanet.visible = true
	$SpinBox.max_value = max(0, 500 - len(game.probe_data))
	$Construct.visible = $SpinBox.max_value > 0
	$TextureRect.texture = load("res://Graphics/Ships/Probe%s.png" % probe_tier)

func e(n, e):
	return n * pow(10, e)

func _on_SpinBox_value_changed(value):
	if probe_tier == 0:
		costs = {"money":e(2, 11), "nanocrystal":2700000}
	elif probe_tier == 1:
		costs = {"money":e(5, 18), "nanocrystal":e(4, 13)}
	for cost in costs:
		costs[cost] *= value
	Helper.put_rsrc($ScrollContainer/HBox, 32, costs, true, true)

func _on_Construct_pressed():
	if game.check_enough(costs):
		game.deduct_resources(costs)
		game.popup(tr("PROBES_CONSTRUCTED"), 3)
		for i in $SpinBox.value:
			game.probe_data.append({"tier":probe_tier})
		_on_close_button_pressed()
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)


func _on_ViewPlanet_pressed():
	game.toggle_panel(self)
	if probe_tier == 1:
		game.c_p_g = id
		game.c_p = l_id
		game.switch_view("planet")


