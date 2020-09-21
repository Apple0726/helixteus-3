extends Control

onready var game = get_node("/root/Game")
#Tween for fading in/out panel
var tween:Tween
var tab:String = ""
var item_for_sale_scene = preload("res://Scenes/ItemForSale.tscn")
var polygon:PoolVector2Array = [Vector2(106.5, 70), Vector2(106.5 + 1067, 70), Vector2(106.5 + 1067, 70 + 600), Vector2(106.5, 70 + 600)]

#Stores basic building information (more in Data.gd)
var bldg_infos = {"ME":{"type":"Basic"},
				 "PP":{"type":"Basic"},
				 "RL":{"type":"Basic"},
				 "MS":{"type":"Storage"},
				}

func _ready():
	tween = Tween.new()
	add_child(tween)
	var item_container = $Contents/HBoxContainer/Items
	for bldg in bldg_infos:
		var bldg_info = bldg_infos[bldg]
		var bldg_btn = item_for_sale_scene.instance()
		bldg_btn.get_node("SmallButton").text = tr("CONSTRUCT")
		bldg_btn.item_name = bldg
		bldg_btn.item_dir = "Buildings"
		bldg_btn.item_desc = tr(bldg.to_upper() + "_DESC")
		bldg_btn.costs = Data.costs[bldg]
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
		if not child is Label and not child is RichTextLabel:
			vbox.remove_child(child)

var item_costs:Dictionary
var item_name = ""

func set_item_info(name:String, desc:String, costs:Dictionary, _type:String, _dir:String):
	remove_costs()
	var vbox = $Contents/HBoxContainer/ItemInfo/VBoxContainer
	vbox.get_node("Name").text = get_item_name(name)
	item_costs = costs
	item_name = name
	desc += "\n"
	vbox.get_node("Description").text = desc
	var rtl = vbox.get_node("RTL")
	rtl.text = ""
	var txt = (Data.path_1[name].desc + "\n") % [Data.path_1[name].value]
	var icons = [Data.icons[name]]
	if Data.path_2.has(name):
		txt += (Data.path_2[name].desc + "\n") % [Data.path_2[name].value]
		icons.append(Data.icons[name])
	game.add_text_icons(rtl, txt, icons, 22)
	Helper.put_rsrc(vbox, 36, costs, false, true)
	$Contents/HBoxContainer/ItemInfo.visible = true

func get_item_name(name:String):
	match name:
		"ME":
			return tr("MINERAL_EXTRACTOR")
		"PP":
			return tr("POWER_PLANT")
		"RL":
			return tr("RESEARCH_LAB")
		"MS":
			return tr("MINERAL_SILO")

func _on_Buy_pressed():
	get_item(item_name, item_costs, null, null)

func get_item(name, costs, _type, _dir):
	if name == "" or game.c_v != "planet":
		return
	yield(get_tree().create_timer(0.01), "timeout")
	game.toggle_construct_panel()
	game.put_bottom_info(tr("STOP_CONSTRUCTION"))
	game.view.obj.construct(name, costs)
