extends "GenericPanel.gd"

func _ready():
	$Title.text = tr("SHOP")
	for btn_str in ["Speedups", "Overclocks", "Pickaxes"]:
		var btn = Button.new()
		btn.name = btn_str
		btn.text = tr(btn_str.to_upper())
		btn.size_flags_horizontal = Button.SIZE_EXPAND_FILL
		btn.connect("pressed", self, "_on_btn_pressed", [btn_str])
		$Tabs.add_child(btn)
	_on_btn_pressed("Speedups")

func _on_btn_pressed(btn_str:String):
	var btn_str_l:String = btn_str.to_lower()
	var btn_str_u:String = btn_str.to_upper()
	tab = btn_str
	change_tab(btn_str)
	for obj in game["%s_info" % btn_str_l]:
		var obj_info = game["%s_info" % btn_str_l][obj]
		var item = item_for_sale_scene.instance()
		item.get_node("SmallButton").text = tr("BUY")
		item.item_name = obj
		item.item_dir = "Items/%s" % btn_str
		item.item_type = "%s_info" % btn_str_l
		match btn_str_l:
			"speedups":
				item.item_desc = tr("SPEEDUPS_DESC2") % [Helper.time_to_str(obj_info.time)]
			"overclocks":
				item.item_desc = tr("OVERCLOCKS_DESC2") % [obj_info.mult, Helper.time_to_str(obj_info.duration)]
			"pickaxes":
				item.item_desc = "%s\n\n%s: %s\n%s: %s" % [tr("%s_DESC" % obj.to_upper()), tr("MINING_SPEED"), obj_info.speed, tr("DURABILITY"), obj_info.durability]
		item.costs = obj_info.costs
		item.parent = "shop_panel"
		grid.add_child(item)

func set_item_info(_name:String, _desc:String, costs:Dictionary, _type:String, _dir:String):
	.set_item_info(_name, _desc, costs, _type, _dir)
	$Contents/HBoxContainer/ItemInfo/HBoxContainer.visible = tab in ["speedups", "overclocks"]

func _on_Buy_pressed():
	get_item(item_name, item_total_costs, item_type, item_dir)

func get_item(_name, costs, _type, _dir):
	if _name == "":
		return
	item_name = _name
	item_type = _type
	item_dir = _dir
	if game.check_enough(costs):
		if tab == "pickaxes":
			if not game.pickaxe.empty():
				game.show_YN_panel("buy_pickaxe", tr("REPLACE_PICKAXE") % [Helper.get_item_name(game.pickaxe.name).to_lower(), Helper.get_item_name(_name).to_lower()], [costs.duplicate(true)])
			else:
				buy_pickaxe(costs)
		else:
			game.deduct_resources(costs)
			add_items(tr("NOT_ENOUGH_INV_SPACE_BUY"), tr("PURCHASE_SUCCESS"))
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)

func buy_pickaxe(_costs:Dictionary):
	if not game.check_enough(_costs):
		return
	game.deduct_resources(_costs)
	game.show.mining = true
	if game.planet_HUD:
		game.planet_HUD.refresh()
	if game.c_v == "mining":
		game.mining_HUD.get_node("Pickaxe").visible = true
		game.mining_HUD.get_node("Pickaxe/Sprite").texture = load("res://Graphics/Pickaxes/" + item_name + ".png")
	game.pickaxe = {"name":item_name, "speed":game.pickaxes_info[item_name].speed, "durability":game.pickaxes_info[item_name].durability}
	game.popup(tr("BUY_PICKAXE") % [Helper.get_item_name(item_name).to_lower()], 1.0)
