extends "GenericPanel.gd"

var basic_bldgs:Array = ["ME", "PP", "RL", "MM", "SP", "AE"]
var storage_bldgs:Array = ["MS"]
var production_bldgs:Array = ["SC", "GF", "SE", "AMN", "SPR"]
var support_bldgs:Array = ["GH"]
var vehicles_bldgs:Array = ["RCC"]

func _ready():
	tab = "Basic"
	$Title.text = tr("CONSTRUCT")
	for btn_str in ["Basic", "Storage", "Production", "Support", "Vehicles"]:
		var btn = Button.new()
		btn.name = btn_str
		btn.text = tr(btn_str.to_upper())
		btn.size_flags_horizontal = Button.SIZE_EXPAND_FILL
		btn.connect("pressed", self, "_on_btn_pressed", [btn_str])
		$Tabs.add_child(btn)
	refresh()

func _on_btn_pressed(btn_str:String):
	var btn_str_l:String = btn_str.to_lower()
	var btn_str_u:String = btn_str.to_upper()
	tab = btn_str
	change_tab(btn_str)
	for bldg in self["%s_bldgs" % btn_str_l]:
		var item = item_for_sale_scene.instance()
		item.get_node("SmallButton").text = tr("CONSTRUCT")
		item.item_name = bldg
		item.item_dir = "Buildings"
		var txt
		if bldg == "SP":
			txt = (Data.path_1[bldg].desc + "\n") % [game.clever_round(Helper.get_SP_production(game.planet_data[game.c_p].temperature, Data.path_1[bldg].value) * Helper.get_IR_mult(bldg), 3)]
		elif bldg == "AE":
			txt = (Data.path_1[bldg].desc + "\n") % [game.clever_round(Helper.get_AE_production(game.planet_data[game.c_p].pressure, Data.path_1[bldg].value) * Helper.get_IR_mult(bldg), 3)]
		else:
			txt = (Data.path_1[bldg].desc + "\n") % [game.clever_round(Data.path_1[bldg].value * Helper.get_IR_mult(bldg), 3)]
		if Data.path_2.has(bldg):
			var txt2:String
			if Data.path_2[bldg].is_value_integer:
				txt2 = (Data.path_2[bldg].desc + "\n") % [round(Data.path_2[bldg].value * Helper.get_IR_mult(bldg))]
			else:
				txt2 = (Data.path_2[bldg].desc + "\n") % [Data.path_2[bldg].value * Helper.get_IR_mult(bldg)]
			txt += txt2
		if Data.path_3.has(bldg):
			var txt2:String = (Data.path_3[bldg].desc + "\n") % [Data.path_3[bldg].value]
			txt += txt2
		item.item_desc = "%s\n\n%s" % [tr("%s_DESC" % bldg), txt]
		item.costs = Data.costs[bldg].duplicate(true)
		if bldg == "GH":
			item.costs.energy *= 1 + abs(game.planet_data[game.c_p].temperature - 273) / 10.0
		item.parent = "construct_panel"
		item.add_to_group("bldgs")
		grid.add_child(item)
	for bldg in get_tree().get_nodes_in_group("bldgs"):
		if bldg.item_name == "GF":
			bldg.visible = game.show.sand
		if bldg.item_name == "SE":
			bldg.visible = game.show.coal
		if bldg.item_name == "MM":
			bldg.visible = game.science_unlocked.AM
		if bldg.item_name in ["AE", "AMN"]:
			bldg.visible = game.science_unlocked.ATM
	$Tabs/Production.visible = game.show.stone
	$Tabs/Support.visible = game.science_unlocked.EGH
	$Tabs/Vehicles.visible = game.show.vehicles_button

func set_item_info(_name:String, desc:String, costs:Dictionary, _type:String, _dir:String):
	.set_item_info(_name, desc, costs, _type, _dir)
	desc_txt.text = ""
	var icons = []
	var has_icon = Data.desc_icons.has(_name)# and txt.find("@i") != -1
	if has_icon:
		icons = Data.desc_icons[_name]
	game.add_text_icons(desc_txt, desc, icons, 22)

func _on_Buy_pressed():
	get_item(item_name, item_costs, null, null)

func get_item(_name, costs, _type, _dir):
	if _name == "" or game.c_v != "planet":
		return
	yield(get_tree().create_timer(0.01), "timeout")
	game.toggle_panel(game.construct_panel)
	game.put_bottom_info(tr("CLICK_TILE_TO_CONSTRUCT"), "building", "cancel_building")
	game.view.obj.construct(_name, costs)

func refresh():
	_on_btn_pressed(tab)
