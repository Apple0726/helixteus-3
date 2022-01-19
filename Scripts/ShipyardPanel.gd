extends "Panel.gd"

var strength_mult:float
var base_costs:Array = [{"money":1500000000}, {"money":1500000000*5000000, "mythril":2400000000}]
var costs:Dictionary
var fighter_type:int = 0
var strength:float
var strength_div:float = 1.0

func _ready():
	$OptionButton.add_item(tr("FIGHTER"))
	$OptionButton.add_item(tr("FIGHTER_MK2"))
	set_polygon(rect_size)

func refresh():
	$OptionButton.visible = game.science_unlocked.has("FG2")
	strength_mult = game.tile_data[game.c_t].bldg.path_1_value
	_on_SpinBox_value_changed($SpinBox.value)

func _on_SpinBox_value_changed(value):
	costs = base_costs[fighter_type].duplicate(true)
	for cost in costs:
		costs[cost] *= value
	strength = value * strength_mult / strength_div
	Helper.put_rsrc($ScrollContainer/HBox, 32, costs, true, true)
	$Strength.bbcode_text = "%s: %s  %s" % [tr("FLEET_STRENGTH"), Helper.format_num(strength, true), "[img]Graphics/Icons/help.png[/img]"]

func _on_Construct_pressed():
	if game.check_enough(costs):
		game.deduct_resources(costs)
		game.popup(tr("FIGHTERS_CONSTRUCTED"), 3)
		if fighter_type == 0:
			game.fighter_data.append({"c_sc":game.c_sc, "c_c_g":game.c_c_g, "c_c":game.c_c, "c_g_g":game.c_g_g, "c_g":game.c_g, "c_s_g":game.c_s_g, "c_p":game.c_p, "strength":strength, "number":$SpinBox.value, "tier":0})
		elif fighter_type == 1:
			game.fighter_data.append({"c_sc":game.c_sc, "c_c_g":game.c_c_g, "c_c":game.c_c, "strength":strength, "number":$SpinBox.value, "tier":1})
		_on_close_button_pressed()
	else:
		game.popup(tr("NOT_ENOUGH_MONEY"), 1.5)


func _on_OptionButton_item_selected(index):
	fighter_type = index
	if index == 0:
		$Strength.help_text = "FLEET_STRENGTH_INFO"
		$TextureRect.texture = preload("res://Graphics/Ships/Fighter.png")
		strength_div = 1.0
	elif index == 1:
		$Strength.help_text = "FLEET2_STRENGTH_INFO"
		$TextureRect.texture = preload("res://Graphics/Ships/Fighter2.png")
		strength_div = 347800
	_on_SpinBox_value_changed($SpinBox.value)
