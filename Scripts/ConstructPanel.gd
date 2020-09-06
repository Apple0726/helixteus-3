extends Control

onready var game = get_node("/root/Game")
#Tween for fading in/out panel
var tween:Tween
var tab:String = ""
var item_for_sale_scene = preload("res://Scenes/ItemForSale.tscn")

func _ready():
	$Contents/HBoxContainer/ItemInfo/Construct.text = tr("CONSTRUCT") + " (B)"
	tween = Tween.new()
	add_child(tween)
	var item_container = $Contents/HBoxContainer/Items
	for bldg in game.bldg_info.keys():
		var bldg_info = game.bldg_info[bldg]
		var bldg_btn = item_for_sale_scene.instance()
		bldg_btn.item_name = bldg
		bldg_btn.item_type = "Buildings"
		bldg_btn.item_desc = tr(bldg.to_upper() + "_DESC")
		bldg_btn.costs = bldg_info.costs
		bldg_btn.parent = "construct_panel"
		item_container.get_node(bldg_info.type).add_child(bldg_btn)
	_on_Basic_pressed()

func _on_Basic_pressed():
	tab = "basic"
	$Contents.visible = true
	set_item_visibility("Basic")
	$Contents/Info.text = tr("BASIC_DESC")
	Helper.set_btn_color($Tabs/Basic)

func _on_Storage_pressed():
	tab = "storage"
	$Contents.visible = true
	set_item_visibility("Storage")
	$Contents/Info.text = tr("STORAGE_DESC")
	Helper.set_btn_color($Tabs/Storage)

func _on_Production_pressed():
	tab = "production"
	$Contents.visible = true
	set_item_visibility("Production")
	$Contents/Info.text = tr("PRODUCTION_DESC")
	Helper.set_btn_color($Tabs/Production)

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

var item_costs:Dictionary
var item_name = ""

func set_item_info(name:String, desc:String, costs:Dictionary):
	remove_costs()
	var vbox = $Contents/HBoxContainer/ItemInfo/VBoxContainer
	vbox.get_node("Name").text = get_item_name(name)
	item_costs = costs
	item_name = name
	desc += "\n"
	vbox.get_node("Description").text = desc
	$Contents/HBoxContainer/ItemInfo.visible = true
	Helper.put_rsrc(vbox, 36, costs, false)

func get_item_name(name:String):
	match name:
		"ME":
			return tr("MINERAL_EXTRACTOR")
		"PP":
			return tr("POWER_PLANT")

func _on_Buy_pressed():
	if item_name == "":
		return
	game.toggle_construct_panel()
	game.put_bottom_info(tr("STOP_CONSTRUCTION"))
	game.view.obj.bldg_to_construct = item_name
	game.view.obj.constr_costs = item_costs
