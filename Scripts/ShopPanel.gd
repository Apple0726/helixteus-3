extends "Panel.gd"

enum {
	OVERCLOCK,
	PICKAXE,
}
var tab:int = OVERCLOCK

var item_selected = {
	"id": null,
	"costs": {},
}

func _ready():
	set_polygon(size)
	$Title.text = tr("SHOP")
	_on_overclocks_button_pressed()
	$Tabs/OverclocksButton._on_Button_pressed()
	
func change_tab(_tab:int):
	for item in $Items/Grid.get_children():
		item.free()
	$ItemInfo.hide()
	item_selected.costs.clear()

func _on_btn_pressed(_tab:int):
	tab = _tab
	change_tab(_tab)
	if tab == OVERCLOCK:
		for item_id in [Item.OVERCLOCK1, Item.OVERCLOCK2, Item.OVERCLOCK3, Item.OVERCLOCK4, Item.OVERCLOCK5, Item.OVERCLOCK6]:
			var item_name = Item.name(item_id)
			var item_texture = load("res://Graphics/Items/Overclocks/%s.png" % Item.data[item_id].icon_name)
			var description = Item.description(item_id)
			var tooltip_txt:String = "%s\n%s\n" % [item_name, description]
			var tooltip_icons:Array = []
			var costs:Dictionary = Item.data[item_id].costs
			for cost in costs.keys():
				tooltip_txt += "@i %s" % Helper.format_num(costs[cost])
				if cost == "money":
					tooltip_icons.append(Data.money_icon)
				else:
					tooltip_icons.append(null)
			var item = preload("res://Scenes/ShopItem.tscn").instantiate()
			item.get_node("TextureRect").texture = item_texture
			item.get_node("TextureButton").mouse_entered.connect(Callable(game, "show_adv_tooltip").bind(tooltip_txt, {"imgs": tooltip_icons}))
			item.get_node("TextureButton").mouse_exited.connect(Callable(game, "hide_tooltip"))
			item.get_node("TextureButton").pressed.connect(Callable(self, "set_item_info").bind(item_name, costs, item_texture, item, item_id))
			$Items/Grid.add_child(item)
	elif tab == PICKAXE:
		for pickaxe_name in game.pickaxes_info:
			var item_name = tr(pickaxe_name.to_upper())
			var item_texture = load("res://Graphics//Pickaxes/%s.png" % pickaxe_name)
			var description = "%s\n\n%s: %s\n%s: %s" % [tr("%s_DESC" % pickaxe_name.to_upper()), tr("MINING_SPEED"), game.pickaxes_info[pickaxe_name].speed * game.engineering_bonus.PS, tr("DURABILITY"), game.pickaxes_info[pickaxe_name].durability]
			var tooltip_txt:String = "%s\n%s\n" % [item_name, description]
			var tooltip_icons:Array = []
			var costs:Dictionary = game.pickaxes_info[pickaxe_name].costs
			for cost in costs.keys():
				tooltip_txt += "@i %s" % Helper.format_num(costs[cost])
				if cost == "money":
					tooltip_icons.append(Data.money_icon)
				else:
					tooltip_icons.append(null)
			var item = preload("res://Scenes/ShopItem.tscn").instantiate()
			item.get_node("TextureRect").texture = item_texture
			item.get_node("TextureButton").mouse_entered.connect(Callable(game, "show_adv_tooltip").bind(tooltip_txt, {"imgs": tooltip_icons}))
			item.get_node("TextureButton").mouse_exited.connect(Callable(game, "hide_tooltip"))
			item.get_node("TextureButton").pressed.connect(Callable(self, "set_item_info").bind(item_name, costs, item_texture, item, pickaxe_name))
			$Items/Grid.add_child(item)

func set_item_info(_item_name:String, _item_costs:Dictionary, _item_texture, _item_node, item_id):
	for item in $Items/Grid.get_children():
		item.get_node("Highlight").visible = item == _item_node
	$ItemInfo.show()
	$ItemInfo/ItemName.text = _item_name
	item_selected.id = item_id # item_id can be an int (overclocks) or a string (pickaxe)
	item_selected.costs = _item_costs.duplicate(true)
	$ItemInfo/Panel/TextureRect.texture = _item_texture
	$ItemInfo/BuyAmount.visible = tab == OVERCLOCK
	update_and_check_costs()

func update_and_check_costs():
	var item_total_costs = item_selected.costs.duplicate(true)
	if tab != PICKAXE:
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
		game.mining_HUD.get_node("Pickaxe/Sprite2D").texture = load("res://Graphics/Pickaxes/" + item_selected.id + ".png")
	game.pickaxe.name = item_selected.id
	game.pickaxe.speed = game.pickaxes_info[item_selected.id].speed * game.engineering_bonus.PS
	game.pickaxe.durability = game.pickaxes_info[item_selected.id].durability
	game.popup(tr("BUY_PICKAXE") % [tr(item_selected.id.to_upper())], 1.0)

func _on_overclocks_button_pressed():
	$Desc.text = tr("OVERCLOCKS_DESC")
	_on_btn_pressed(OVERCLOCK)

func _on_pickaxes_button_pressed():
	$Desc.text = tr("PICKAXES_DESC")
	_on_btn_pressed(PICKAXE)


func _on_buy_pressed():
	if item_selected.costs.is_empty():
		return
	var item_total_costs = item_selected.costs.duplicate(true)
	if tab != PICKAXE:
		for cost in item_total_costs.keys():
			item_total_costs[cost] *= $ItemInfo/BuyAmount.value
	if game.check_enough(item_total_costs):
		if tab == PICKAXE:
			if game.pickaxe.has("name"):
				game.show_YN_panel("buy_pickaxe", tr("REPLACE_PICKAXE") % [tr(game.pickaxe.name.to_upper()), tr(item_selected.id.to_upper())], [item_total_costs])
			else:
				buy_pickaxe(item_total_costs)
		elif tab == OVERCLOCK:
			game.deduct_resources(item_total_costs)
			Helper.add_items_to_inventory(item_selected.id, $ItemInfo/BuyAmount.value, item_selected.costs, tr("NOT_ENOUGH_INV_SPACE_BUY"), tr("PURCHASE_SUCCESS"))
			update_and_check_costs()
			game.HUD.refresh()
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)


func _on_buy_amount_value_changed(value):
	update_and_check_costs()
