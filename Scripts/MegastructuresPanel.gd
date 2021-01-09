extends "Panel.gd"

var item_costs:Dictionary
var item_name = ""
onready var vbox = $ItemInfo/VBoxContainer

func _ready():
	set_polygon($Background.rect_size)
	for MS in $GridContainer.get_children():
		MS.get_node("SmallButton").text = tr("CONSTRUCT")
		MS.item_name = MS.name
		MS.item_dir = "Megastructures"
		MS.item_desc = tr(MS.name.to_upper() + "_DESC")
		MS.costs = {}
		MS.parent = "megastructures_panel"
		MS.get_node("ItemTexture").texture = load("res://Graphics/Megastructures/" + MS.name + ".png")

func get_MS_name(_name:String):
	match _name:
		"M_DS":
			return tr("DYSON_SPHERE")
		"M_SE":
			return tr("SPACE_ELEVATOR")

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

func get_item(_name, costs, _type, _dir):
	if _name == "" or game.c_v != "system":
		return
	game.toggle_panel(game.construct_panel)
	if _name == "M_DS":
		game.put_bottom_info(tr("CLICK_STAR_TO_CONSTRUCT"), "building", "cancel_building")
	elif _name == "M_SE":
		game.put_bottom_info(tr("CLICK_PLANET_TO_CONSTRUCT"), "building", "cancel_building")
	#game.view.obj.construct(_name, costs)
