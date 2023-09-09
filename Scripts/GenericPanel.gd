extends "Panel.gd"

enum PanelType {SHOP, CRAFT, CONSTRUCT, MEGASTRUCTURES}
var tab:String = ""
var item_for_sale_scene = preload("res://Scenes/ItemForSale.tscn")
@onready var amount_node = $VBox/HBox/ItemInfo/VBox/HBox/BuyAmount
@onready var buy_btn = $VBox/HBox/ItemInfo/VBox/HBox/Buy
@onready var buy_hbox = $VBox/HBox/ItemInfo/VBox/HBox
@onready var grid = $VBox/HBox/Items/Items
@onready var desc_txt = $VBox/HBox/ItemInfo/VBox/Desc
@onready var item_info = $VBox/HBox/ItemInfo
@onready var name_node = $VBox/HBox/ItemInfo/Name
var num:int = 1
var type:int
var locked:bool = false

var item_type:String = ""
var item_dir:String = ""
var item_costs:Dictionary
var item_desc:String = ""
var item_total_costs:Dictionary
var item_name = ""

func _ready():
	$VBox/HBox/ItemInfo/VBox/HBox/BuyAmount.get_line_edit().caret_blink = true
	set_polygon(size)

func _input(event):
	super(event)
	if Input.is_action_just_pressed("shift"):
		if type == PanelType.SHOP and tab != "Pickaxes":
			for grid_el in grid.get_children():
				grid_el.get_node("SmallButton").text = "%s 10" % tr("BUY")
		elif type == PanelType.CRAFT:
			for grid_el in grid.get_children():
				grid_el.get_node("SmallButton").text = "%s 10" % tr("CRAFT")
	elif Input.is_action_just_released("shift"):
		if type == PanelType.SHOP and tab != "Pickaxes":
			for grid_el in grid.get_children():
				grid_el.get_node("SmallButton").text = tr("BUY")
		elif type == PanelType.CRAFT:
			for grid_el in grid.get_children():
				grid_el.get_node("SmallButton").text = tr("CRAFT")

func change_tab(btn_str:String):
	for item in $VBox/HBox/Items/Items.get_children():
		item.free()
	item_name = ""
	if btn_str == "Pickaxes":
		_on_BuyAmount_value_changed(1)
	else:
		_on_BuyAmount_value_changed($VBox/HBox/ItemInfo/VBox/HBox/BuyAmount.value)
	remove_costs()
	item_info.modulate.a = 0
	$Desc.text = tr("%s_DESC" % btn_str.to_upper())
	locked = false
	
func remove_costs():
	var vbox = $VBox/HBox/ItemInfo/VBox/Costs/VBox
	for child in vbox.get_children():
		child.free()

func set_item_info(name:String, desc:String, costs:Dictionary, _type:String, _dir:String):
	remove_costs()
	var vbox = $VBox/HBox/ItemInfo/VBox/Costs/VBox
	if _dir == "Buildings":
		name_node.text = tr("%s_NAME" % name.to_upper())
	else:
		name_node.text = Helper.get_item_name(name)
	item_costs = costs
	item_total_costs = costs.duplicate(true)
	item_name = name
	item_type = _type
	item_desc = desc
	item_dir = _dir
	for cost in costs:
		item_total_costs[cost] = costs[cost] * num
	await get_tree().process_frame
	$VBox/HBox/ItemInfo/VBox/Costs.visible = not costs.is_empty()
	if not costs.is_empty():
		Helper.put_rsrc(vbox, 28, item_total_costs, true, true)

func add_items(not_enough_inv:String, success:String):
	var items_left = game.add_items(item_name, amount_node.value)
	if items_left > 0:
		var refund = item_costs.duplicate(true)
		for rsrc in item_costs:
			refund[rsrc] = item_costs[rsrc] * items_left
		game.add_resources(refund)
		game.popup(not_enough_inv, 2.0)
	else:
		game.popup(success, 1.5)
		set_item_info(item_name, item_desc, item_costs, item_type, item_dir)
	if game.HUD:
		game.HUD.update_hotbar()

func _on_BuyAmount_value_changed(value):
	num = value
	remove_costs()
	for cost in item_costs:
		item_total_costs[cost] = item_costs[cost] * num
	var vbox = $VBox/HBox/ItemInfo/VBox/Costs/VBox
	Helper.put_rsrc(vbox, 36, item_total_costs, false, true)

func refresh():
	$VBox/HBox/ItemInfo/VBox/HBox/BuyAmount.get_line_edit().caret_blink_interval = 0.5 / game.u_i.time_speed
