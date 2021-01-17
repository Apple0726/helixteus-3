extends "Panel.gd"

var tab:String = ""
var item_for_sale_scene = preload("res://Scenes/ItemForSale.tscn")
onready var amount_node = $Contents/HBoxContainer/ItemInfo/HBoxContainer/BuyAmount
onready var buy_btn = $Contents/HBoxContainer/ItemInfo/HBoxContainer/Buy
var num:int = 1

func _ready():
	set_polygon($Background.rect_size)

func _on_Speedups_pressed():
	change_tab()
	for speedup in game.speedup_info:
		var speedup_info = game.speedup_info[speedup]
		var speedup_item = item_for_sale_scene.instance()
		speedup_item.get_node("SmallButton").text = tr("BUY")
		speedup_item.item_name = speedup
		speedup_item.item_dir = "Items/Speedups"
		speedup_item.item_type = "speedup_info"
		speedup_item.item_desc = tr("SPEED_UP_DESC") % [Helper.time_to_str(speedup_info.time)]
		speedup_item.costs = speedup_info.costs
		speedup_item.parent = "shop_panel"
		$Contents/HBoxContainer/Items/Items.add_child(speedup_item)
	tab = "speedups"
	$Contents/Info.text = tr("SPEED_UP_INFO")
	Helper.set_btn_color($Tabs/Speedups)
	$Contents/HBoxContainer/ItemInfo/HBoxContainer/BuyAmount.visible = true
	buy_btn.visible = true

func _on_Overclocks_pressed():
	change_tab()
	for overclock in game.overclock_info:
		var overclock_info = game.overclock_info[overclock]
		var overclock_item = item_for_sale_scene.instance()
		overclock_item.get_node("SmallButton").text = tr("BUY")
		overclock_item.item_name = overclock
		overclock_item.item_dir = "Items/Overclocks"
		overclock_item.item_type = "overclock_info"
		overclock_item.item_desc = tr("OVERCLOCK_DESC") % [overclock_info.mult, Helper.time_to_str(overclock_info.duration)]
		overclock_item.costs = overclock_info.costs
		overclock_item.parent = "shop_panel"
		$Contents/HBoxContainer/Items/Items.add_child(overclock_item)
	tab = "overclocks"
	$Contents/Info.text = tr("OVERCLOCK_INFO")
	Helper.set_btn_color($Tabs/Overclocks)
	$Contents/HBoxContainer/ItemInfo/HBoxContainer/BuyAmount.visible = true
	buy_btn.visible = true

func _on_Pickaxes_pressed():
	change_tab()
	for pickaxe in game.pickaxe_info:
		var pickaxe_info = game.pickaxe_info[pickaxe]
		var pickaxe_item = item_for_sale_scene.instance()
		pickaxe_item.get_node("SmallButton").text = tr("BUY")
		pickaxe_item.item_name = pickaxe
		pickaxe_item.item_dir = "Pickaxes"
		pickaxe_item.item_type = "pickaxe_info"
		pickaxe_item.item_desc = tr(pickaxe.to_upper() + "_DESC")
		pickaxe_item.costs = pickaxe_info.costs
		pickaxe_item.parent = "shop_panel"
		$Contents/HBoxContainer/Items/Items.add_child(pickaxe_item)
	tab = "pickaxes"
	$Contents/Info.text = tr("PICKAXE_DESC")
	Helper.set_btn_color($Tabs/Pickaxes)
	$Contents/HBoxContainer/ItemInfo/HBoxContainer/BuyAmount.visible = false
	buy_btn.visible = false

func change_tab():
	for item in $Contents/HBoxContainer/Items/Items.get_children():
		$Contents/HBoxContainer/Items/Items.remove_child(item)
	item_name = ""
	remove_costs()
	$Contents/HBoxContainer/ItemInfo/HBoxContainer.visible = false
	$Contents/HBoxContainer/ItemInfo/VBoxContainer.visible = false
	$Contents.visible = true
	
func remove_costs():
	var vbox = $Contents/HBoxContainer/ItemInfo/VBoxContainer
	for child in vbox.get_children():
		if not child is Label:
			vbox.remove_child(child)

var item_type:String = ""
var item_dir:String = ""
var item_costs:Dictionary
var item_total_costs:Dictionary
var item_name = ""

func set_item_info(name:String, desc:String, costs:Dictionary, _type:String, _dir:String):
	remove_costs()
	var vbox = $Contents/HBoxContainer/ItemInfo/VBoxContainer
	vbox.get_node("Name").text = Helper.get_item_name(name)
	item_costs = costs
	item_total_costs = costs.duplicate(true)
	item_name = name
	item_type = _type
	item_dir = _dir
	if tab == "pickaxes":
		var pickaxe_info = game.pickaxe_info[name]
		desc += ("\n\n" + tr("MINING_SPEED") + ": %s\n" + tr("DURABILITY") + ": %s") % [pickaxe_info.speed, pickaxe_info.durability]
	else:
		for cost in costs:
			item_total_costs[cost] = costs[cost] * num
	desc += "\n"
	vbox.get_node("Description").text = desc
	$Contents/HBoxContainer/ItemInfo/HBoxContainer.visible = true
	$Contents/HBoxContainer/ItemInfo/VBoxContainer.visible = true
	Helper.put_rsrc(vbox, 36, item_total_costs, false)

func _on_Buy_pressed():
	get_item(item_name, item_total_costs, item_type, item_dir)

func get_item(_name, costs, _type, _dir):
	if _name == "":
		return
	item_name = _name
	item_total_costs = costs.duplicate(true)
	if game.check_enough(item_total_costs):
		if tab == "pickaxes":
			if not game.pickaxe.empty():
				game.show_YN_panel("buy_pickaxe", tr("REPLACE_PICKAXE") % [Helper.get_item_name(game.pickaxe.name).to_lower(), Helper.get_item_name(item_name).to_lower()], [costs.duplicate(true)])
			else:
				buy_pickaxe(costs)
		else:
			game.deduct_resources(item_total_costs)
			var items_left = game.add_items(item_name, amount_node.value)
			if items_left > 0:
				var refund = item_costs.duplicate(true)
				for rsrc in item_costs:
					refund[rsrc] = item_costs[rsrc] * items_left
				game.add_resources(refund)
				game.popup(tr("NOT_ENOUGH_INV_SPACE_BUY"), 2.0)
			else:
				game.popup(tr("PURCHASE_SUCCESS"), 1.5)
			if game.HUD:
				game.HUD.update_hotbar()
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)

func buy_pickaxe(_costs:Dictionary):
	if not game.check_enough(_costs):
		return
	game.deduct_resources(_costs)
	if game.c_v == "mining":
		game.mining_HUD.get_node("Pickaxe").visible = true
		game.mining_HUD.get_node("Pickaxe/Sprite").texture = load("res://Graphics/Pickaxes/" + item_name + ".png")
	game.pickaxe = {"name":item_name, "speed":game.pickaxe_info[item_name].speed, "durability":game.pickaxe_info[item_name].durability}
	game.popup(tr("BUY_PICKAXE") % [Helper.get_item_name(item_name).to_lower()], 1.0)


func _on_BuyAmount_value_changed(value):
	num = value
	remove_costs()
	for cost in item_costs:
		item_total_costs[cost] = item_costs[cost] * num
	var vbox = $Contents/HBoxContainer/ItemInfo/VBoxContainer
	Helper.put_rsrc(vbox, 36, item_total_costs, false)

func refresh():
	pass


func _on_close_button_pressed():
#	game.view.move_view = true
#	game.view.scroll_view = true
	game.toggle_panel(self)
