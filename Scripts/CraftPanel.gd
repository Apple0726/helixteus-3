extends "Panel.gd"

enum {
	MINING,
	CAVE,
}
var tab:int = MINING

var item_selected = {
	"id": null,
	"costs": {},
}

func _ready():
	set_polygon(size)
	$Title.text = tr("CRAFT")
	_on_mining_button_pressed()
	$Tabs/MiningButton._on_Button_pressed()
	
func change_tab(_tab:int):
	for item in $Items/Grid.get_children():
		item.free()
	$ItemInfo.hide()
	item_selected.costs.clear()
	if _tab == MINING:
		$Desc.text = tr("CRAFT_MINING_DESC")
	elif _tab == CAVE:
		$Desc.text = tr("CRAFT_CAVE_DESC")

func _on_btn_pressed(_tab:int):
	tab = _tab
	change_tab(tab)
	if tab == MINING:
		add_items_to_panel([Item.MINING_LIQUID, Item.PURPLE_MINING_LIQUID], "Mining liquids")
	elif tab == CAVE:
		add_items_to_panel([Item.DRILL1, Item.DRILL2, Item.DRILL3], "Drills")

func add_items_to_panel(items:Array, items_directory:String):
	for item_id in items:
		var item_name = Item.name(item_id)
		var item_texture = load("res://Graphics/Items/%s/%s.png" % [items_directory, Item.data[item_id].icon_name])
		var description = Item.description(item_id)
		var tooltip_txt:String = "%s\n%s\n" % [item_name, description]
		var costs:Dictionary = Item.data[item_id].costs
		var item = preload("res://Scenes/ShopItem.tscn").instantiate()
		item.get_node("TextureRect").texture = item_texture
		item.get_node("TextureButton").mouse_entered.connect(Callable(game, "show_tooltip").bind(tooltip_txt))
		item.get_node("TextureButton").mouse_exited.connect(Callable(game, "hide_tooltip"))
		item.get_node("TextureButton").pressed.connect(Callable(self, "set_item_info").bind(item_name, costs, item_texture, item, item_id))
		$Items/Grid.add_child(item)
	
func set_item_info(_item_name:String, _item_costs:Dictionary, _item_texture, _item_node, item_id:int):
	for item in $Items/Grid.get_children():
		item.get_node("Highlight").visible = item == _item_node
	$ItemInfo.show()
	$ItemInfo/ItemName.text = _item_name
	item_selected.id = item_id
	item_selected.costs = _item_costs.duplicate(true)
	$ItemInfo/Panel/TextureRect.texture = _item_texture
	update_and_check_costs()

func update_and_check_costs():
	var item_total_costs = item_selected.costs.duplicate(true)
	for cost in item_total_costs.keys():
		item_total_costs[cost] *= $ItemInfo/BuyAmount.value
	Helper.put_rsrc($ItemInfo/ScrollContainer/Costs, 28, item_total_costs, true, true)
	$ItemInfo/Buy.disabled = not game.check_enough(item_total_costs)

func _on_mining_button_pressed():
	_on_btn_pressed(MINING)

func _on_cave_button_pressed():
	_on_btn_pressed(CAVE)


func _on_buy_pressed():
	if item_selected.costs.is_empty():
		return
	var item_total_costs = item_selected.costs.duplicate(true)
	for cost in item_total_costs.keys():
		item_total_costs[cost] *= $ItemInfo/BuyAmount.value
	if game.check_enough(item_total_costs):
		game.deduct_resources(item_total_costs)
		Helper.add_items_to_inventory(item_selected.id, $ItemInfo/BuyAmount.value, item_selected.costs, tr("NOT_ENOUGH_INV_SPACE_BUY"), tr("PURCHASE_SUCCESS"))
		update_and_check_costs()
		game.HUD.refresh()
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)


func _on_buy_amount_value_changed(value):
	update_and_check_costs()
