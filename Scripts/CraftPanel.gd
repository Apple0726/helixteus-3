extends Control

onready var game = get_node("/root/Game")
#Tween for fading in/out panel
var tween:Tween
var tab:String
var item_for_sale_scene = preload("res://Scenes/ItemForSale.tscn")
var polygon:PoolVector2Array = [Vector2(106.5, 70), Vector2(106.5 + 1067, 70), Vector2(106.5 + 1067, 70 + 600), Vector2(106.5, 70 + 600)]
onready var craft_btn = $Contents/HBoxContainer/ItemInfo/HBoxContainer/CraftAmount
onready var desc_txt = $Contents/HBoxContainer/ItemInfo/VBoxContainer/Description2


func _ready():
	tween = Tween.new()
	add_child(tween)
	for craft in game.craft_agric_info:
		var craft_info = game.craft_agric_info[craft]
		var craft_item = item_for_sale_scene.instance()
		craft_item.get_node("SmallButton").text = tr("CRAFT")
		craft_item.item_name = craft
		craft_item.item_dir = "Agriculture"
		craft_item.item_type = "craft_agric_info"
		craft_item.item_desc = craft_info.desc if craft_info.has("desc") else ""
		craft_item.costs = craft_info.costs
		craft_item.parent = "craft_panel"
		$Contents/HBoxContainer/Items/Agriculture.add_child(craft_item)
	_on_Agric_pressed()

func refresh_values():
	if tab == "agriculture":
		_on_Agric_pressed()

func _on_Agric_pressed():
	if tab != "agriculture":
		remove_costs()
	tab = "agriculture"
	$Contents.visible = true
	Helper.set_visibility($Contents/HBoxContainer/Items/Agriculture)
	$Contents/Info.text = tr("CRAFT_AGRIC_DESC")
	Helper.set_btn_color($Tabs/Agriculture)
#
func remove_costs():
	var vbox = $Contents/HBoxContainer/ItemInfo/VBoxContainer
	for child in vbox.get_children():
		if not child is Label and not child is RichTextLabel:
			vbox.remove_child(child)

var item_costs
var item_total_costs
var item_type
var item_dir
var item_name
var item_num

func set_item_info(name:String, desc:String, costs:Dictionary, type:String, dir:String):
	remove_costs()
	var vbox = $Contents/HBoxContainer/ItemInfo/VBoxContainer
	vbox.get_node("Name").text = Helper.get_item_name(name)
	item_costs = costs
	item_type = type
	item_dir = dir
	$Contents/HBoxContainer/ItemInfo/HBoxContainer/CraftAmount.value = 1
	item_total_costs = costs.duplicate(true)
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
	Helper.put_rsrc(vbox, 32, costs, false, true)

func get_item(name, costs, type, dir):
	if game.check_enough(costs):
		game.deduct_resources(costs)
		var items_left = game.add_items(name, type, dir, craft_btn.value)
		if items_left > 0:
			var refund = item_costs.duplicate(true)
			for rsrc in item_costs:
				refund[rsrc] = item_costs[rsrc] * items_left
			game.add_resources(refund)
			game.popup(tr("NOT_ENOUGH_INV_SPACE"), 2.0)
		else:
			game.popup(tr("CRAFT_SUCCESS"), 1.5)
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)

func _on_Craft_pressed():
	get_item(item_name, item_total_costs, item_type, item_dir)


func _on_CraftAmount_value_changed(value):
	remove_costs()
	for cost in item_costs:
		item_total_costs[cost] = item_costs[cost] * value
	var vbox = $Contents/HBoxContainer/ItemInfo/VBoxContainer
	Helper.put_rsrc(vbox, 36, item_total_costs, false, true)

func get_item_desc(item:String):
	var output = ""
	match item:
		"lead_seeds":
			output = tr("SEEDS_DESC") % [game.craft_agric_info.lead_seeds.produce]
		"fertilizer":
			output = tr("FERTILIZER_DESC")
	return output
