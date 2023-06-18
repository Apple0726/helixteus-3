extends "GenericPanel.gd"

func _ready():
	super()
	type = PanelType.SHOP
	$Title.text = tr("SHOP")
	for btn_str in ["Speedups", "Overclocks", "Pickaxes"]:
		var btn = preload("res://Scenes/AdvButton.tscn").instantiate()
		btn.name = btn_str
		btn.button_text = tr(btn_str.to_upper())
		btn.size_flags_horizontal = Button.SIZE_EXPAND_FILL
		btn.connect("pressed",Callable(self,"_on_btn_pressed").bind(btn_str))
		$VBox/TabBar.add_child(btn)
	_on_btn_pressed("Speedups")
	$VBox/TabBar.get_node("Speedups")._on_Button_pressed()

func _on_btn_pressed(btn_str:String):
	var btn_str_l:String = btn_str.to_lower()
	var btn_str_u:String = btn_str.to_upper()
	tab = btn_str
	change_tab(btn_str)
	for obj in game["%s_info" % btn_str_l]:
		var obj_info = game["%s_info" % btn_str_l][obj]
		var item = item_for_sale_scene.instantiate()
		item.get_node("SmallButton").text = tr("BUY")
		item.item_name = obj
		item.item_dir = "Items/%s" % btn_str
		item.item_type = "%s_info" % btn_str_l
		match btn_str_l:
			"speedups":
				item.item_desc = tr("SPEEDUPS_DESC2") % [Helper.time_to_str(obj_info.time)]
			"overclocks":
				item.item_desc = tr("OVERCLOCKS_DESC2") % [obj_info.mult, Helper.time_to_str(obj_info.duration / game.u_i.time_speed)]
			"pickaxes":
				item.item_desc = "%s\n\n%s: %s\n%s: %s" % [tr("%s_DESC" % obj.to_upper()), tr("MINING_SPEED"), obj_info.speed * game.engineering_bonus.PS, tr("DURABILITY"), obj_info.durability]
		item.costs = obj_info.costs
		item.parent = "shop_panel"
		grid.add_child(item)

func set_item_info(_name:String, _desc:String, costs:Dictionary, _type:String, _dir:String):
	super.set_item_info(_name, _desc, costs, _type, _dir)
	desc_txt.text = _desc
	$VBox/HBox/ItemInfo/VBox/HBox.visible = tab in ["Speedups", "Overclocks"]

func _on_Buy_pressed():
	get_item(item_name, item_type, item_dir)

func get_item(_name, _type, _dir):
	if _name == "":
		return
	item_name = _name
	item_type = _type
	item_dir = _dir
	if game.check_enough(item_total_costs):
		if tab == "Pickaxes":
			if game.pickaxe.has("name"):
				game.show_YN_panel("buy_pickaxe", tr("REPLACE_PICKAXE") % [Helper.get_item_name(game.pickaxe.name).to_lower(), Helper.get_item_name(_name).to_lower()], [item_total_costs.duplicate(true)])
			else:
				buy_pickaxe(item_total_costs)
		else:
			game.deduct_resources(item_total_costs)
			add_items(tr("NOT_ENOUGH_INV_SPACE_BUY"), tr("PURCHASE_SUCCESS"))
			game.HUD.refresh()
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)

func buy_pickaxe(_costs:Dictionary):
	if not game.check_enough(_costs):
		return
	game.deduct_resources(_costs)
	game.show.mining = true
	if is_instance_valid(game.planet_HUD):
		game.planet_HUD.refresh()
	if game.c_v == "mining":
		game.mining_HUD.get_node("Pickaxe").visible = true
		game.mining_HUD.get_node("Pickaxe/Sprite2D").texture = load("res://Graphics/Items/Pickaxes/" + item_name + ".png")
	game.pickaxe.name = item_name
	game.pickaxe.speed = game.pickaxes_info[item_name].speed * game.engineering_bonus.PS
	game.pickaxe.durability = game.pickaxes_info[item_name].durability
	game.popup(tr("BUY_PICKAXE") % [Helper.get_item_name(item_name).to_lower()], 1.0)

func _on_close_button_pressed():
	super._on_close_button_pressed()

func _on_BuyAmount_value_changed(value):
	super._on_BuyAmount_value_changed(value)
