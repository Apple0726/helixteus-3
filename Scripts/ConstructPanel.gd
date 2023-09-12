extends "GenericPanel.gd"

var basic_bldgs:Array = [Building.MINERAL_EXTRACTOR, Building.POWER_PLANT, Building.RESEARCH_LAB, Building.BORING_MACHINE, Building.SOLAR_PANEL, Building.ATMOSPHERE_EXTRACTOR]
var storage_bldgs:Array = [Building.MINERAL_SILO, Building.BATTERY]
var production_bldgs:Array = [Building.STONE_CRUSHER, Building.GLASS_FACTORY, Building.STEAM_ENGINE, Building.ATOM_MANIPULATOR, Building.SUBATOMIC_PARTICLE_REACTOR]
var support_bldgs:Array = [Building.GREENHOUSE, Building.CENTRAL_BUSINESS_DISTRICT]
var vehicles_bldgs:Array = [Building.ROVER_CONSTRUCTION_CENTER, Building.SHIPYARD, Building.PROBE_CONSTRUCTION_CENTER]

func _ready():
	super()
	var added_buildings = Mods.added_buildings
	for key in added_buildings:
		match added_buildings[key].type:
			"basic":
				basic_bldgs.append(key)
			"storage":
				storage_bldgs.append(key)
			"production":
				production_bldgs.append(key)
			"support":
				support_bldgs.append(key)
			"vehicles":
				vehicles_bldgs.append(key)
	
	type = PanelType.CONSTRUCT
	tab = "Basic"
	$Title.text = tr("CONSTRUCT")
	for btn_str in ["Basic", "Storage", "Production", "Support", "Vehicles"]:
		var btn = preload("res://Scenes/AdvButton.tscn").instantiate()
		btn.name = btn_str
		btn.button_text = tr(btn_str.to_upper())
		btn.size_flags_horizontal = Button.SIZE_EXPAND_FILL
		btn.connect("pressed",Callable(self,"_on_btn_pressed").bind(btn_str))
		$VBox/TabBar.add_child(btn)
	buy_hbox.visible = false
	refresh()

func _on_btn_pressed(btn_str:String):
	var btn_str_l:String = btn_str.to_lower()
	var btn_str_u:String = btn_str.to_upper()
	tab = btn_str
	change_tab(btn_str)
	for bldg in self["%s_bldgs" % btn_str_l]:
		var item = item_for_sale_scene.instantiate()
		item.get_node("SmallButton").text = tr("CONSTRUCT")
		item.item_name = Building.names[bldg]
		item.item_dir = "Buildings"
		var txt:String = ""
		var time_speed:float = game.u_i.time_speed if Data.path_1.has(bldg) and Data.path_1[bldg].has("time_based") else 1.0
		item.get_node("New").visible = game.new_bldgs.has(bldg) and game.new_bldgs[bldg]
		var IR_mult = Helper.get_IR_mult(bldg)
		if bldg == Building.SOLAR_PANEL:
			txt = (Data.path_1[bldg].desc + "\n") % [Helper.format_num(Helper.get_SP_production(game.planet_data[game.c_p].temperature, Data.path_1[bldg].value * IR_mult * time_speed), true)]
		elif bldg == Building.ATMOSPHERE_EXTRACTOR:
			txt = (Data.path_1[bldg].desc + "\n") % [Helper.format_num(Helper.get_AE_production(game.planet_data[game.c_p].pressure, Data.path_1[bldg].value * IR_mult * time_speed), true)]
#		elif bldg in ["PC", "NC"]:
#			txt = (Data.path_1[bldg].desc + "\n") % [Helper.format_num(Data.path_1[bldg].value / game.planet_data[game.c_p].pressure * time_speed, true)]
#		elif bldg in ["MS", "NSF", "ESF"]:
#			txt = (Data.path_1[bldg].desc + "\n") % [Helper.format_num(round(Data.path_1[bldg].value * IR_mult))]
		elif bldg == Building.BATTERY:
			txt = (Data.path_1[bldg].desc + "\n") % [Helper.format_num(round(Data.path_1[bldg].value * IR_mult * game.u_i.charge))]
		elif Data.path_1.has(bldg):
			txt = (Data.path_1[bldg].desc + "\n") % [Helper.format_num(Data.path_1[bldg].value * IR_mult * time_speed, true)]
		if Data.path_2.has(bldg):
			if Data.path_2[bldg].has("is_value_integer"):
				txt += (Data.path_2[bldg].desc + "\n") % [Helper.format_num(round(Data.path_2[bldg].value * IR_mult))]
			else:
				txt += (Data.path_2[bldg].desc + "\n") % [Helper.format_num(Data.path_2[bldg].value * IR_mult, true)]
		if Data.path_3.has(bldg):
			if bldg == Building.CENTRAL_BUSINESS_DISTRICT:
				txt += Data.path_3[bldg].desc.format({"n":Data.path_3[bldg].value}) + "\n"
			else:
				txt += (Data.path_3[bldg].desc + "\n") % [Data.path_3[bldg].value]
		item.item_desc = "%s\n\n%s" % [tr("%s_DESC" % Building.names[bldg].to_upper()), txt]
		item.costs = Data.costs[bldg].duplicate(true)
		for cost in item.costs:
			item.costs[cost] *= game.engineering_bonus.BCM
		if bldg == Building.GREENHOUSE:
			item.costs.energy = round(item.costs.energy * (1 + abs(game.planet_data[game.c_p].temperature - 273) / 10.0))
		if item.costs.has("time"):
			if game.subject_levels.dimensional_power >= 1:
				item.costs.time = 0.2
			else:
				item.costs.time /= game.u_i.time_speed
		item.parent = "construct_panel"
		item.add_to_group("bldgs")
		grid.add_child(item)
	for bldg in get_tree().get_nodes_in_group("bldgs"):
		if bldg.item_name == "mineral_extractor":
			bldg.visible = true
		else:
			bldg.visible = game.new_bldgs.has(Building.names.find(bldg.item_name))

func set_item_info(_name:String, desc:String, costs:Dictionary, _type:String, _dir:String):
	super.set_item_info(_name, desc, costs, _type, _dir)
	desc_txt.text = ""
	var icons = []
	var building_id = Building.names.find(_name)
	var has_theme_icon = Data.desc_icons.has(building_id)
	if has_theme_icon:
		icons = Helper.flatten(Data.desc_icons[building_id])
	game.add_text_icons(desc_txt, desc, icons, 22)

func _on_Buy_pressed():
	get_item(item_name, null, null)

func get_item(_name, _type, _dir):
	if _name == "" or game.c_v != "planet":
		return
	await get_tree().create_timer(0.01).timeout
	game.toggle_panel(game.construct_panel)
	game.put_bottom_info(tr("CLICK_TILE_TO_CONSTRUCT"), "building", "cancel_building")
	var building_name:int = Building.names.find(_name)
	var base_cost = Data.costs[building_name].duplicate(true)
	for cost in base_cost:
		base_cost[cost] *= game.engineering_bonus.BCM
	if building_name == Building.GREENHOUSE:
		base_cost.energy = round(base_cost.energy * (1 + abs(game.planet_data[game.c_p].temperature - 273) / 10.0))
	game.view.obj.construct(building_name, base_cost)

func refresh():
	if game.c_v == "planet":
		$VBox/TabBar/Production.visible = game.show.has("stone")
		$VBox/TabBar/Support.visible = game.stats_univ.bldgs_built >= 18
		$VBox/TabBar/Vehicles.visible = game.show.has("vehicles_button")
		for btn_str in ["Basic", "Storage", "Production", "Support", "Vehicles"]:
			$VBox/TabBar.get_node(btn_str + "/Label/Notification").visible = false
			for bldg in self[btn_str.to_lower() + "_bldgs"]:
				if bldg in game.new_bldgs.keys() and game.new_bldgs[bldg]:
					$VBox/TabBar.get_node(btn_str + "/Label/Notification").visible = true
					break
		if $VBox/TabBar.get_node(tab).visible:
			$VBox/TabBar.get_node(tab)._on_Button_pressed()
			_on_btn_pressed(tab)
		else:
			$VBox/TabBar.get_node("Basic")._on_Button_pressed()
			_on_btn_pressed("Basic")

func _on_close_button_pressed():
	super._on_close_button_pressed()
