extends Control

onready var game = get_node("/root/Game")
#Tween for fading in/out panel
var tween:Tween
var tab:String = ""
var item_for_sale_scene = preload("res://Scenes/ItemForSale.tscn")
var polygon:PoolVector2Array = [Vector2(106.5, 70), Vector2(106.5 + 1067, 70), Vector2(106.5 + 1067, 70 + 600), Vector2(106.5, 70 + 600)]
onready var buy_amount = $Contents/HBoxContainer/ItemInfo/HBoxContainer/BuyAmount
onready var buy_btn = $Contents/HBoxContainer/ItemInfo/HBoxContainer/Buy
var num:int = 1

func _ready():
	tween = Tween.new()
	add_child(tween)
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
		$Contents/HBoxContainer/Items/Speedups.add_child(speedup_item)
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
		$Contents/HBoxContainer/Items/Overclocks.add_child(overclock_item)
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
		$Contents/HBoxContainer/Items/Pickaxes.add_child(pickaxe_item)

func _on_Speedups_pressed():
	buy_btn.visible = true
	tab = "speedups"
	$Contents.visible = true
	set_item_visibility("Speedups")
	$Contents/Info.text = tr("SPEED_UP_INFO")
	Helper.set_btn_color($Tabs/Speedups)
	$Contents/HBoxContainer/ItemInfo/HBoxContainer/BuyAmount.visible = true

func _on_Overclocks_pressed():
	buy_btn.visible = true
	tab = "overclocks"
	$Contents.visible = true
	set_item_visibility("Overclocks")
	$Contents/Info.text = tr("OVERCLOCK_INFO")
	Helper.set_btn_color($Tabs/Overclocks)
	$Contents/HBoxContainer/ItemInfo/HBoxContainer/BuyAmount.visible = true

func _on_Pickaxes_pressed():
	buy_btn.visible = false
	tab = "pickaxes"
	$Contents.visible = true
	set_item_visibility("Pickaxes")
	$Contents/Info.text = tr("PICKAXE_DESC")
	Helper.set_btn_color($Tabs/Pickaxes)
	$Contents/HBoxContainer/ItemInfo/HBoxContainer/BuyAmount.visible = false

func set_item_visibility(type:String):
	for other_type in $Contents/HBoxContainer/Items.get_children():
		other_type.visible = false
	remove_costs()
	$Contents/HBoxContainer/Items.get_node(type).visible = true
	$Contents/HBoxContainer/ItemInfo.visible = false
	item_name = ""

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
	$Contents/HBoxContainer/ItemInfo.visible = true
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
				YNPanel(tr("REPLACE_PICKAXE") % [Helper.get_item_name(game.pickaxe.name).to_lower(), Helper.get_item_name(item_name).to_lower()], costs.duplicate(true))
			else:
				buy_pickaxe(costs)
		else:
			game.deduct_resources(item_total_costs)
			var items_left = game.add_items(item_name, buy_amount.value)
			if items_left > 0:
				var refund = item_total_costs.duplicate(true)
				for rsrc in item_total_costs:
					refund[rsrc] = item_total_costs[rsrc] * items_left
				game.add_resources(refund)
				game.popup(tr("NOT_ENOUGH_INV_SPACE_BUY"), 2.0)
			else:
				game.popup(tr("PURCHASE_SUCCESS"), 1.5)
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)

func YNPanel(text:String, _costs:Dictionary):
	$ConfirmationDialog.dialog_text = text
	$ConfirmationDialog.popup_centered()
	if $ConfirmationDialog.is_connected("confirmed", self, "buy_pickaxe_confirm"):
		$ConfirmationDialog.disconnect("confirmed", self, "buy_pickaxe_confirm")
	$ConfirmationDialog.connect("confirmed", self, "buy_pickaxe_confirm", [_costs])

func buy_pickaxe_confirm(_costs:Dictionary):
	buy_pickaxe(_costs)
	$ConfirmationDialog.disconnect("confirmed", self, "buy_pickaxe_confirm")

func buy_pickaxe(_costs:Dictionary):
	if not game.check_enough(_costs):
		return
	game.deduct_resources(_costs)
	if game.c_v == "mining":
		game.mining_HUD.get_node("Pickaxe").visible = true
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
	game.toggle_panel(self)
