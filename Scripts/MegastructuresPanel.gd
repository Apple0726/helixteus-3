extends "GenericPanel.gd"

var MSes:PoolStringArray = ["M_DS", "M_SE", "M_MME", "M_PK", "M_MB", "M_MPCC"]
func _ready():
	item_info.visible = false
	type = PanelType.MEGASTRUCTURES
	$Title.text = tr("MEGASTRUCTURES")
	$Desc.text = tr("MEGASTRUCTURES_DESC")
	set_polygon(rect_size)
	$VBox/Tabs.visible = false
	for MS in MSes:
		var item = item_for_sale_scene.instance()
		item.get_node("SmallButton").text = tr("CONSTRUCT")
		item.name = MS
		item.item_name = MS
		item.item_dir = "Icons/Megastructures"
		item.item_desc = tr(MS + "_DESC")
		item.costs = {}
		item.parent = "megastructures_panel"
		item.get_node("ItemTexture").texture = load("res://Graphics/Icons/Megastructures/%s.png" % MS)
		grid.add_child(item)
	buy_hbox.visible = false

func refresh():
	grid.get_node("M_MPCC").visible = game.science_unlocked.MPCC
	grid.get_node("M_MB").visible = game.science_unlocked.MB
		
func get_MS_name(_name:String):
	return tr("%s_NAME" % _name)

func set_item_info(_name:String, desc:String, costs:Dictionary, _type:String, _dir:String):
	.set_item_info(_name, desc, costs, _type, _dir)
	name_node.text = get_MS_name(_name)
	desc_txt.text = desc

func get_item(_name, _type, _dir):
	if _name == "" or game.c_v != "system":
		return
	game.toggle_panel(game.megastructures_panel)
	if _name == "M_DS":
		game.put_bottom_info(tr("CLICK_STAR_TO_CONSTRUCT"), "building_DS", "cancel_building_MS")
	elif _name == "M_MB":
		game.put_bottom_info(tr("CLICK_STAR_TO_CONSTRUCT"), "building_MB", "cancel_building_MS")
	elif _name == "M_PK":
		game.put_bottom_info(tr("CLICK_STAR_TO_CONSTRUCT"), "building_PK", "cancel_building_MS")
	elif _name == "M_SE":
		game.put_bottom_info(tr("CLICK_PLANET_TO_CONSTRUCT"), "building-M_SE", "cancel_building_MS")
	elif _name == "M_MME":
		game.put_bottom_info(tr("CLICK_PLANET_TO_CONSTRUCT"), "building-M_MME", "cancel_building_MS")
	elif _name == "M_MPCC":
		game.put_bottom_info(tr("CLICK_PLANET_TO_CONSTRUCT"), "building-M_MPCC", "cancel_building_MS")
	game.view.obj.construct(_name)

