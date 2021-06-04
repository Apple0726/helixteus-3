extends "Panel.gd"

var item_costs:Dictionary
var item_name = ""
onready var vbox = $ItemInfo/VBoxContainer

func _ready():
	set_polygon($Background.rect_size)
	for MS in $GridContainer.get_children():
		MS.get_node("SmallButton").text = tr("CONSTRUCT")
		MS.item_name = MS.name
		MS.item_dir = "Icons/Megastructures"
		MS.item_desc = tr(MS.name + "_DESC")
		MS.costs = {}
		MS.parent = "megastructures_panel"
		MS.get_node("ItemTexture").texture = load("res://Graphics/Icons/Megastructures/" + MS.name + ".png")

func refresh():
	$GridContainer/M_MPCC.visible = game.science_unlocked.MPCC
	$GridContainer/M_MB.visible = game.science_unlocked.MB
		
func get_MS_name(_name:String):
	return tr("%s_NAME" % _name)

func set_item_info(_name:String, desc:String, costs:Dictionary, _type:String, _dir:String):
	remove_costs()
	vbox.get_node("Name").text = get_MS_name(_name)
	item_name = _name
	vbox.get_node("Description").text = desc
	Helper.put_rsrc(vbox, 36, costs, false, true)
	$ItemInfo.visible = true

func remove_costs():
	for child in vbox.get_children():
		if not child is Label:
			vbox.remove_child(child)

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
