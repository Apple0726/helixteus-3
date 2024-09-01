extends "Panel.gd"

var tab:String = ""
var item_name:String = ""
var item_costs:Dictionary = {}

func _ready():
	set_polygon(size)
	$Title.text = tr("SHOP")
	_on_overclocks_button_pressed()
	$Tabs/OverclocksButton._on_Button_pressed()
	
func change_tab(btn_str:String):
	for item in $Items/Grid.get_children():
		item.free()
	item_name = ""
	item_costs.clear()
	$Desc.text = tr("%s_DESC" % btn_str.to_upper())

func _on_btn_pressed(btn_str:String):
	var btn_str_l:String = btn_str.to_lower()
	var btn_str_u:String = btn_str.to_upper()
	tab = btn_str
	change_tab(btn_str)
	for _item_name in game["%s_info" % btn_str_l]:
		var _item_info = game["%s_info" % btn_str_l][_item_name]
		var item = preload("res://Scenes/ShopItem.tscn").instantiate()
		var _item_texture = load("res://Graphics/Items/%s/%s.png" % [btn_str, _item_name])
		item.get_node("TextureRect").texture = _item_texture
		var item_description:String = ""
		match btn_str_l:
			"overclocks":
				item_description = tr("OVERCLOCKS_DESC2") % [_item_info.mult, Helper.time_to_str(_item_info.duration / game.u_i.get("time_speed", 1.0))]
			"pickaxes":
				item_description = "%s\n\n%s: %s\n%s: %s" % [tr("%s_DESC" % _item_name.to_upper()), tr("MINING_SPEED"), _item_info.speed * game.engineering_bonus.PS, tr("DURABILITY"), _item_info.durability]
		$Items/Grid.add_child(item)
		var _tooltip_text:String = "%s\n%s\n" % [Helper.get_item_name(_item_name), item_description]
		var _tooltip_icons:Array = []
		for cost in _item_info.costs.keys():
			_tooltip_text += "@i %s" % Helper.format_num(_item_info.costs[cost])
			if cost == "money":
				_tooltip_icons.append(Data.money_icon)
			else:
				_tooltip_icons.append(null)
		item.get_node("TextureButton").mouse_entered.connect(Callable(game, "show_adv_tooltip").bind(_tooltip_text, _tooltip_icons))
		item.get_node("TextureButton").mouse_exited.connect(Callable(game, "hide_tooltip"))
		item.get_node("TextureButton").pressed.connect(Callable(self, "set_item_info").bind(_item_name, _item_info.costs, _item_texture, item))

func set_item_info(_item_name:String, _item_costs:Dictionary, _item_texture, _item_node):
	for item in $Items/Grid.get_children():
		item.get_node("Highlight").visible = item == _item_node
	item_name = _item_name
	$ItemInfo.show()
	$ItemInfo/ItemName.text = Helper.get_item_name(_item_name)
	item_costs = _item_costs.duplicate(true)
	$ItemInfo/Panel/TextureRect.texture = _item_texture
	if tab == "Overclocks":
		$ItemInfo/BuyAmount.visible = true
	elif tab == "Pickaxes":
		$ItemInfo/BuyAmount.visible = false
	update_and_check_costs()

func update_and_check_costs():
	var item_total_costs = item_costs.duplicate(true)
	for cost in item_total_costs.keys():
		item_total_costs[cost] *= $ItemInfo/BuyAmount.value
	Helper.put_rsrc($ItemInfo/ScrollContainer/Costs, 28, item_total_costs, true, true)
	$ItemInfo/Buy.disabled = not game.check_enough(item_total_costs)
	
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

func _on_overclocks_button_pressed():
	_on_btn_pressed("Overclocks")

func _on_pickaxes_button_pressed():
	_on_btn_pressed("Pickaxes")


func _on_buy_pressed():
	if item_name == "":
		return
	var item_total_costs = item_costs.duplicate(true)
	for cost in item_total_costs.keys():
		item_total_costs[cost] *= $ItemInfo/BuyAmount.value
	if game.check_enough(item_total_costs):
		if tab == "Pickaxes":
			if game.pickaxe.has("name"):
				game.show_YN_panel("buy_pickaxe", tr("REPLACE_PICKAXE") % [Helper.get_item_name(game.pickaxe.name).to_lower(), Helper.get_item_name(item_name).to_lower()], [item_total_costs.duplicate(true)])
			else:
				buy_pickaxe(item_total_costs)
		else:
			game.deduct_resources(item_total_costs)
			Helper.add_items_to_inventory(item_name, $ItemInfo/BuyAmount.value, item_costs, tr("NOT_ENOUGH_INV_SPACE_BUY"), tr("PURCHASE_SUCCESS"))
			update_and_check_costs()
			game.HUD.refresh()
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)


func _on_buy_amount_value_changed(value):
	update_and_check_costs()
