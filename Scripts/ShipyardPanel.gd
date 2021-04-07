extends "Panel.gd"

var strength_mult:float
var costs:Dictionary
var strength:float

func _ready():
	set_polygon(rect_size)

func refresh():
	strength_mult = game.tile_data[game.c_t].bldg.path_1_value
	_on_SpinBox_value_changed($SpinBox.value)

func _on_SpinBox_value_changed(value):
	costs = {"money":500000000}
	for cost in costs:
		costs[cost] *= value
	strength = value * strength_mult
	Helper.put_rsrc($ScrollContainer/HBox, 32, costs)
	$Strength.text = "%s: %s" % [tr("FLEET_STRENGTH"), game.clever_round(strength, 3)]

func _on_Construct_pressed():
	if game.check_enough(costs):
		game.deduct_resources(costs)
		game.popup(tr("FIGHTERS_CONSTRUCTED"), 3)
		game.fighter_data.append({"c_sc":game.c_sc, "c_c_g":game.c_c_g, "c_c":game.c_c, "c_g_g":game.c_g_g, "c_g":game.c_g, "c_s_g":game.c_s_g, "c_p":game.c_p, "strength":strength, "number":$SpinBox.value})
		_on_close_button_pressed()
	else:
		game.popup(tr("NOT_ENOUGH_MONEY"), 1.5)

func _on_Strength_mouse_entered():
	game.show_tooltip(tr("FLEET_STRENGTH_INFO"))

func _on_Strength_mouse_exited():
	game.hide_tooltip()
