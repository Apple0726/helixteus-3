extends Control

onready var game = get_node("/root/Game")
#Tween for fading in/out panel
var tween:Tween
var tab:String = "agriculture"
var item_for_sale_scene = preload("res://Scenes/ItemForSale.tscn")
var polygon:PoolVector2Array = [Vector2(106.5, 70), Vector2(106.5 + 1067, 70), Vector2(106.5 + 1067, 70 + 600), Vector2(106.5, 70 + 600)]
onready var craft_btn = $Contents/HBoxContainer/ItemInfo/HBoxContainer/CraftAmount
onready var name_txt = $Contents/HBoxContainer/ItemInfo/VBoxContainer/Name
onready var desc_txt = $Contents/HBoxContainer/ItemInfo/VBoxContainer/Description2
onready var hbox = $Contents/HBoxContainer/
onready var amount_node = $Contents/HBoxContainer/ItemInfo/HBoxContainer/CraftAmount


func _ready():
	tween = Tween.new()
	add_child(tween)
	for craft in game.craft_agric_info:
		var craft_info = game.craft_agric_info[craft]
		var craft_item = item_for_sale_scene.instance()
		craft_item.visible = game.science_unlocked.SA
		craft_item.get_node("SmallButton").text = tr("CRAFT")
		craft_item.item_name = craft
		craft_item.item_dir = "Agriculture"
		craft_item.item_type = "craft_agric_info"
		craft_item.item_desc = craft_info.desc if craft_info.has("desc") else ""
		craft_item.costs = craft_info.costs
		craft_item.parent = "craft_panel"
		hbox.get_node("Items/Agriculture").add_child(craft_item)
	if game.science_unlocked.SA:
		_on_Agric_pressed()

func refresh():
	$Tabs/Agriculture.visible = game.science_unlocked.SA
	for node in hbox.get_node("Items/Agriculture").get_children():
		node.visible = game.science_unlocked.SA
	if tab == "agriculture" and item_name != "":
		set_item_info(item_name, get_item_desc(item_name), item_costs, item_type, item_dir)

func _on_Agric_pressed():
	remove_costs()
	name_txt.text = ""
	desc_txt.text = ""
	$Contents/HBoxContainer/ItemInfo.visible = false
	tab = "agriculture"
	$Contents.visible = true
	Helper.set_visibility($Contents/HBoxContainer/Items/Agriculture)
	$Contents/Info.text = tr("CRAFT_AGRIC_DESC")
	Helper.set_btn_color($Tabs/Agriculture)
#
func remove_costs():
	var vbox = $Contents/HBoxContainer/ItemInfo/VBoxContainer
	for child in vbox.get_children():
		if child is HBoxContainer:
			vbox.remove_child(child)

var item_costs
var item_total_costs
var item_type
var item_dir
var item_name = ""
var item_num:int = 1

func set_item_info(name:String, desc:String, costs:Dictionary, type:String, dir:String):
	remove_costs()
	var vbox = $Contents/HBoxContainer/ItemInfo/VBoxContainer
	vbox.get_node("Name").text = Helper.get_item_name(name)
	item_costs = costs
	item_type = type
	item_dir = dir
	item_total_costs = costs.duplicate(true)
	for cost in costs:
		item_total_costs[cost] = costs[cost] * item_num
	item_name = name
	desc = get_item_desc(name)
	var imgs = []
	if tab == "agriculture":
		var agric_info = game.craft_agric_info[name]
		if agric_info.has("grow_time"):
			imgs = [load("res://Graphics/Metals/" + Helper.get_plant_produce(name) + ".png")]
			desc += ("\n" + tr("GROWTH_TIME") + ": %s\n") % [Helper.time_to_str(agric_info.grow_time)]
			desc += tr("GROWS_NEXT_TO") % [tr(agric_info.lake.to_upper())]
	desc += "\n"
	desc_txt.text = ""
	game.add_text_icons(desc_txt, desc, imgs, 22)
	$Contents/HBoxContainer/ItemInfo.visible = true
	Helper.put_rsrc(vbox, 32, item_total_costs, false, true)

func get_item(name, costs, type, dir):
	if game.check_enough(costs):
		game.deduct_resources(costs)
		var items_left = game.add_items(name, craft_btn.value)
		if items_left > 0:
			var refund = item_costs.duplicate(true)
			for rsrc in item_costs:
				refund[rsrc] = item_costs[rsrc] * items_left
			game.add_resources(refund)
			game.popup(tr("NOT_ENOUGH_INV_SPACE_CRAFT"), 2.0)
		else:
			game.popup(tr("CRAFT_SUCCESS"), 1.5)
			set_item_info(item_name, get_item_desc(item_name), item_costs, item_type, item_dir)
			if game.HUD:
				game.HUD.update_hotbar()
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)

func _on_Craft_pressed():
	get_item(item_name, item_total_costs, item_type, item_dir)


func _on_BuyAmount_value_changed(value):
	item_num = value
	remove_costs()
	for cost in item_costs:
		item_total_costs[cost] = item_costs[cost] * value
	var vbox = $Contents/HBoxContainer/ItemInfo/VBoxContainer
	Helper.put_rsrc(vbox, 32, item_total_costs, false, true)

func get_item_desc(item:String):
	match item:
		"fertilizer":
			return tr("FERTILIZER_DESC")
	if item.split("_")[1] == "seeds":
		return tr("SEEDS_DESC") % [game.craft_agric_info[item].produce]

func _on_close_button_pressed():
	game.toggle_panel(self)
