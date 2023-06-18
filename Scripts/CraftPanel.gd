extends "GenericPanel.gd"

func _ready():
	super()
	type = PanelType.CRAFT
	$Title.text = tr("CRAFT")
	for btn_str in ["Mining", "Cave"]:
		var btn = preload("res://Scenes/AdvButton.tscn").instantiate()
		btn.name = btn_str
		btn.button_text = tr(btn_str.to_upper())
		btn.size_flags_horizontal = Button.SIZE_EXPAND_FILL
		btn.connect("pressed",Callable(self,"_on_btn_pressed").bind(btn_str))
		$VBox/TabBar.add_child(btn)
	_on_btn_pressed("Mining")
	$VBox/TabBar.get_node("Mining")._on_Button_pressed()
	buy_btn.text = tr("CRAFT")
	buy_btn.icon = preload("res://Graphics/Icons/craft.png")
	$VBox/HBox/ItemInfo/VBox/HBox.visible = true

func _on_btn_pressed(btn_str:String):
	var btn_str_l:String = btn_str.to_lower()
	var btn_str_u:String = btn_str.to_upper()
	tab = btn_str
	change_tab("CR_%s" % btn_str)
	var info:String = "craft_%s_info" % btn_str_l
	for craft in game[info]:
		var craft_info = game[info][craft]
		var item = item_for_sale_scene.instantiate()
		item.get_node("SmallButton").text = tr("CRAFT")
		item.item_name = craft
		item.item_dir = btn_str
		item.item_type = info
		var desc:String = get_item_desc(craft, btn_str, craft_info)
		item.item_desc = desc
		item.costs = craft_info.costs.duplicate(true)
		item.parent = "craft_panel"
		grid.add_child(item)

func refresh():
	$VBox/TabBar/Cave.visible = game.science_unlocked.has("RC")
	if item_name != "":
		set_item_info(item_name, get_item_desc(item_name, tab, game["craft_%s_info" % tab.to_lower()][item_name]), item_costs, item_type, item_dir)

func set_item_info(_name:String, _desc:String, costs:Dictionary, _type:String, _dir:String):
	super.set_item_info(_name, _desc, costs, _type, _dir)
	var imgs = []
	game.add_text_icons(desc_txt, _desc + "\n", imgs, 22)

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
	if btn_str == "Mining":
		desc += "%s: %s" % [tr("SPEED_MULTIPLIER"), craft_info.speed_mult]
		desc += "\n%s: %s" % [tr("DURABILITY"), craft_info.durability]
	elif btn_str == "Cave":
		if item.substr(0, 5) == "drill":
			desc += tr("DRILL_DESC") % craft_info.limit
		elif item.substr(0, 17) == "portable_wormhole":
			desc += tr("PORTABLE_WORMHOLE_DESC") % craft_info.limit
		else:
			desc += tr("%s_DESC" % item.to_upper())
	return desc
