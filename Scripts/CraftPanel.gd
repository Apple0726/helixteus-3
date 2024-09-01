extends "Panel.gd"

var tab:String = ""
var item_name:String = ""
var item_costs:Dictionary = {}

func _ready():
	set_polygon(size)
	$Title.text = tr("CRAFT")
	_on_mining_button_pressed()
	$Tabs/MiningButton._on_Button_pressed()
	
func change_tab(btn_str:String):
	for item in $Items/Grid.get_children():
		item.free()
	item_name = ""
	item_costs.clear()
	$Desc.text = tr("CRAFT_%s_DESC" % btn_str.to_upper())

func _on_btn_pressed(btn_str:String):
	var btn_str_l:String = btn_str.to_lower()
	var btn_str_u:String = btn_str.to_upper()
	tab = btn_str
	change_tab(btn_str)
	for _item_name in game["craft_%s_info" % btn_str_l]:
		var item_info = game["craft_%s_info" % btn_str_l][_item_name]
		var item = preload("res://Scenes/ShopItem.tscn").instantiate()
		var _item_texture = load("res://Graphics/%s/%s.png" % [btn_str, _item_name])
		item.get_node("TextureRect").texture = _item_texture
		var item_description:String = ""
		if btn_str == "Mining":
			item_description += "%s: %s" % [tr("SPEED_MULTIPLIER"), item_info.speed_mult]
			item_description += "\n%s: %s" % [tr("DURABILITY"), item_info.durability]
		elif btn_str == "Cave":
			if _item_name.substr(0, 5) == "drill":
				item_description += tr("DRILL_DESC") % item_info.limit
			elif _item_name.substr(0, 17) == "portable_wormhole":
				item_description += tr("PORTABLE_WORMHOLE_DESC") % item_info.limit
			else:
				item_description += tr("%s_DESC" % _item_name.to_upper())
		$Items/Grid.add_child(item)
		var _tooltip_text:String = "%s\n%s\n" % [Helper.get_item_name(_item_name), item_description]
		item.get_node("TextureButton").mouse_entered.connect(Callable(game, "show_tooltip").bind(_tooltip_text))
		item.get_node("TextureButton").mouse_exited.connect(Callable(game, "hide_tooltip"))
		item.get_node("TextureButton").pressed.connect(Callable(self, "set_item_info").bind(_item_name, item_info.costs, _item_texture, item))

func set_item_info(_item_name:String, _item_costs:Dictionary, _item_texture, _item_node):
	for item in $Items/Grid.get_children():
		item.get_node("Highlight").visible = item == _item_node
	item_name = _item_name
	$ItemInfo.show()
	$ItemInfo/ItemName.text = Helper.get_item_name(_item_name)
	item_costs = _item_costs.duplicate(true)
	$ItemInfo/Panel/TextureRect.texture = _item_texture
	$ItemInfo/BuyAmount.visible = true
	update_and_check_costs()

func update_and_check_costs():
	var item_total_costs = item_costs.duplicate(true)
	for cost in item_total_costs.keys():
		item_total_costs[cost] *= $ItemInfo/BuyAmount.value
	Helper.put_rsrc($ItemInfo/ScrollContainer/Costs, 28, item_total_costs, true, true)
	$ItemInfo/Buy.disabled = not game.check_enough(item_total_costs)

func _on_mining_button_pressed():
	_on_btn_pressed("Mining")

func _on_cave_button_pressed():
	_on_btn_pressed("Cave")


func _on_buy_pressed():
	if item_name == "":
		return
	var item_total_costs = item_costs.duplicate(true)
	for cost in item_total_costs.keys():
		item_total_costs[cost] *= $ItemInfo/BuyAmount.value
	if game.check_enough(item_total_costs):
		game.deduct_resources(item_total_costs)
		Helper.add_items_to_inventory(item_name, $ItemInfo/BuyAmount.value, item_costs, tr("NOT_ENOUGH_INV_SPACE_BUY"), tr("PURCHASE_SUCCESS"))
		update_and_check_costs()
		game.HUD.refresh()
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)


func _on_buy_amount_value_changed(value):
	update_and_check_costs()
