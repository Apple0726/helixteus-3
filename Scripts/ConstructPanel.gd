extends "GenericPanel.gd"

var basic_bldgs:Array = ["ME", "PP", "RL", "MM", "SP", "AE", "PC", "NC", "EC"]
var storage_bldgs:Array = ["MS"]
var production_bldgs:Array = ["SC", "GF", "SE", "AMN", "SPR"]
var support_bldgs:Array = ["GH", "CBD"]
var vehicles_bldgs:Array = ["RCC", "SY", "PCC"]

func _ready():
	type = PanelType.CONSTRUCT
	tab = "Basic"
	$Title.text = tr("CONSTRUCT")
	for btn_str in ["Basic", "Storage", "Production", "Support", "Vehicles"]:
		var btn = preload("res://Scenes/AdvButton.tscn").instance()
		btn.name = btn_str
		btn.button_text = tr(btn_str.to_upper())
		btn.size_flags_horizontal = Button.SIZE_EXPAND_FILL
		btn.connect("pressed", self, "_on_btn_pressed", [btn_str])
		$VBox/Tabs.add_child(btn)
	buy_hbox.visible = false
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
		var txt:String = ""
		var time_speed:float = game.u_i.time_speed if Data.path_1.has(bldg) and Data.path_1[bldg].has("time_based") else 1.0
		if bldg == "SP":
			txt = (Data.path_1[bldg].desc + "\n") % [Helper.format_num(Helper.get_SP_production(game.planet_data[game.c_p].temperature, Data.path_1[bldg].value * Helper.get_IR_mult(bldg) * time_speed))]
		elif bldg == "AE":
			txt = (Data.path_1[bldg].desc + "\n") % [Helper.format_num(Helper.get_AE_production(game.planet_data[game.c_p].pressure, Data.path_1[bldg].value * Helper.get_IR_mult(bldg) * time_speed))]
		elif bldg in ["PC", "NC"]:
			txt = (Data.path_1[bldg].desc + "\n") % [Helper.format_num(Data.path_1[bldg].value / game.planet_data[game.c_p].pressure * time_speed, true)]
		elif Data.path_1.has(bldg):
			txt = (Data.path_1[bldg].desc + "\n") % [Helper.format_num(Data.path_1[bldg].value * Helper.get_IR_mult(bldg) * time_speed, true)]
		if Data.path_2.has(bldg):
			if Data.path_2[bldg].is_value_integer:
				txt += (Data.path_2[bldg].desc + "\n") % [Helper.format_num(round(Data.path_2[bldg].value * Helper.get_IR_mult(bldg)))]
			else:
				txt += (Data.path_2[bldg].desc + "\n") % [Helper.format_num(Data.path_2[bldg].value * Helper.get_IR_mult(bldg), true)]
		if Data.path_3.has(bldg):
			if bldg == "CBD":
				txt += Data.path_3[bldg].desc.format({"n":Data.path_3[bldg].value}) + "\n"
			else:
				txt += (Data.path_3[bldg].desc + "\n") % [Data.path_3[bldg].value]
		item.item_desc = "%s\n\n%s" % [tr("%s_DESC" % bldg), txt]
		item.costs = Data.costs[bldg].duplicate(true)
		for cost in item.costs:
			item.costs[cost] *= game.engineering_bonus.BCM
		if bldg == "GH":
			item.costs.energy = round(item.costs.energy * (1 + abs(game.planet_data[game.c_p].temperature - 273) / 10.0))
		if item.costs.has("time"):
			item.costs.time /= game.u_i.time_speed
		item.parent = "construct_panel"
		item.add_to_group("bldgs")
		grid.add_child(item)
	for bldg in get_tree().get_nodes_in_group("bldgs"):
		if bldg.item_name == "PP":
			bldg.visible = game.tutorial and game.stats_univ.bldgs_built >= 5 or not game.tutorial and game.stats_univ.bldgs_built >= 1
		elif bldg.item_name == "MS":
			bldg.visible = game.stats_univ.bldgs_built >= 5
		elif bldg.item_name == "RL":
			bldg.visible = not game.tutorial or game.stats_univ.bldgs_built >= 18
		elif bldg.item_name == "CBD":
			bldg.visible = not game.tutorial or game.stats_univ.bldgs_built >= 18
		elif bldg.item_name == "GF":
			bldg.visible = game.show.sand
		elif bldg.item_name == "SE":
			bldg.visible = game.show.coal
		elif bldg.item_name == "MM":
			bldg.visible = game.science_unlocked.has("AM")
		elif bldg.item_name == "SP":
			bldg.visible = game.stats_global.planets_conquered > 1
		elif bldg.item_name in ["AE", "AMN"]:
			bldg.visible = game.science_unlocked.has("ATM")
		elif bldg.item_name in ["SPR", "PC", "NC", "EC"]:
			bldg.visible = game.science_unlocked.has("SAP")
		elif bldg.item_name == "SY":
			bldg.visible = game.science_unlocked.has("FG")
		elif bldg.item_name == "PCC":
			bldg.visible = game.universe_data[game.c_u].lv >= 50
		elif bldg.item_name == "GH":
			bldg.visible = game.science_unlocked.has("EGH")
	$VBox/Tabs/Production.visible = game.show.stone
	$VBox/Tabs/Support.visible = not game.tutorial or game.stats_univ.bldgs_built >= 18
	$VBox/Tabs/Vehicles.visible = game.show.vehicles_button

func set_item_info(_name:String, desc:String, costs:Dictionary, _type:String, _dir:String):
	.set_item_info(_name, desc, costs, _type, _dir)
	desc_txt.text = ""
	var icons = []
	var has_icon = Data.desc_icons.has(_name)# and txt.find("@i") != -1
	if has_icon:
		icons = Data.desc_icons[_name]
	game.add_text_icons(desc_txt, desc, icons, 22)

func _on_Buy_pressed():
	get_item(item_name, null, null)

func get_item(_name, _type, _dir):
	if _name == "" or game.c_v != "planet":
		return
	yield(get_tree().create_timer(0.01), "timeout")
	game.toggle_panel(game.construct_panel)
	game.put_bottom_info(tr("CLICK_TILE_TO_CONSTRUCT"), "building", "cancel_building")
	var base_cost = Data.costs[_name].duplicate(true)
	for cost in base_cost:
		base_cost[cost] *= game.engineering_bonus.BCM
	if _name == "GH":
		base_cost.energy = round(base_cost.energy * (1 + abs(game.planet_data[game.c_p].temperature - 273) / 10.0))
	game.view.obj.construct(_name, base_cost)
	if game.tutorial and game.tutorial.tut_num in [3, 5]:
		game.tutorial.fade(0.15, false)

func refresh():
	if game.c_v == "planet":
		$VBox/Tabs.get_node(tab)._on_Button_pressed()
		_on_btn_pressed(tab)

func _on_close_button_pressed():
	if not game.tutorial or game.tutorial and not game.tutorial.BG_blocked:
		._on_close_button_pressed()
