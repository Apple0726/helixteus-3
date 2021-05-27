extends "GenericPanel.gd"

func _ready():
	type = PanelType.CRAFT
	$Title.text = tr("CRAFT")
	for btn_str in ["Mining", "Agriculture"]:
		var btn = Button.new()
		btn.name = btn_str
		btn.text = tr(btn_str.to_upper())
		btn.size_flags_horizontal = Button.SIZE_EXPAND_FILL
		btn.connect("pressed", self, "_on_btn_pressed", [btn_str])
		$Tabs.add_child(btn)
	_on_btn_pressed("Mining")
	buy_btn.text = tr("CRAFT")
	buy_btn.icon = load("res://Graphics/Icons/craft.png")

func _on_btn_pressed(btn_str:String):
	var btn_str_l:String = btn_str.to_lower()
	var btn_str_u:String = btn_str.to_upper()
	tab = btn_str
	change_tab(btn_str)
	var info:String = "craft_%s_info" % btn_str_l
	for craft in game[info]:
		var craft_info = game[info][craft]
		var item = item_for_sale_scene.instance()
		item.get_node("SmallButton").text = tr("CRAFT")
		item.item_name = craft
		item.item_dir = btn_str
		item.item_type = info
		var desc:String = get_item_desc(craft, btn_str, craft_info)
		item.item_desc = desc
		item.costs = craft_info.costs
		item.parent = "craft_panel"
		grid.add_child(item)

func refresh():
	$Tabs/Agriculture.visible = game.science_unlocked.SA
	if item_name != "":
		set_item_info(item_name, get_item_desc(item_name, tab, game["craft_%s_info" % tab.to_lower()][item_name]), item_costs, item_type, item_dir)

func set_item_info(_name:String, _desc:String, costs:Dictionary, _type:String, _dir:String):
	.set_item_info(_name, _desc, costs, _type, _dir)
	var imgs = []
	if tab == "Agriculture":
		var agric_info = game.craft_agriculture_info[_name]
		if agric_info.has("grow_time"):
			imgs = [load("res://Graphics/Metals/" + Helper.get_plant_produce(_name) + ".png")]
	game.add_text_icons(desc_txt, _desc + "\n", imgs, 22)
	$Contents/HBoxContainer/ItemInfo/HBoxContainer.visible = true

func get_item(_name, _type, _dir):
	item_name = _name
	item_type = _type
	item_dir = _dir
	if game.check_enough(item_total_costs):
		game.deduct_resources(item_total_costs)
		add_items(tr("NOT_ENOUGH_INV_SPACE_CRAFT"), tr("CRAFT_SUCCESS"))
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)

func _on_Buy_pressed():
	get_item(item_name, item_type, item_dir)

func get_item_desc(item:String, btn_str:String, craft_info:Dictionary):
	var desc:String = ""
	if item == "fertilizer":
		desc = tr("FERTILIZER_DESC")
	else:
		var item_arr = item.split("_")
		if len(item_arr) > 1 and item_arr[1] == "seeds":
			desc = tr("SEEDS_DESC") % [game.craft_agriculture_info[item].produce]
	if btn_str == "Agriculture":
		if craft_info.has("grow_time"):
			desc += ("\n" + tr("GROWTH_TIME") + ": %s\n") % [Helper.time_to_str(craft_info.grow_time)]
			desc += tr("GROWS_NEXT_TO") % [tr("%s_NAME" % craft_info.lake.to_upper())]
	elif btn_str == "Mining":
		desc += "%s: %s" % [tr("SPEED_MULTIPLIER"), craft_info.speed_mult]
		desc += "\n%s: %s" % [tr("DURABILITY"), craft_info.durability]
	return desc
