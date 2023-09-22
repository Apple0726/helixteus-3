extends "GenericPanel.gd"

var MSes:PackedStringArray = ["DS", "SE", "MME", "CBS", "PK", "MB"]
var build_all:bool = false

func _ready():
	$VBox/CheckBox.visible = true
	$VBox/CheckBox.text = tr("BUILD_ALL_AT_ONCE")
	$VBox/CheckBox.connect("toggled",Callable(self,"on_checkbox_toggle"))
	type = PanelType.MEGASTRUCTURES
	$Title.text = tr("MEGASTRUCTURES")
	$Desc.text = tr("MEGASTRUCTURES_DESC")
	set_polygon(size)
	$VBox/TabBar.visible = false
	for MS in MSes:
		var item = item_for_sale_scene.instantiate()
		item.get_node("SmallButton").text = tr("CONSTRUCT")
		item.name = MS
		item.item_name = MS
		item.item_dir = "Icons/Megastructures"
		item.item_desc = tr(MS + "_DESC")
		item.costs = {}
		item.use_expanded_texture = MS in ["DS", "SE"]
		item.parent = "megastructures_panel"
		#item.get_node("ItemTexture").texture = load("res://Graphics/Icons/Megastructures/%s.png" % MS)
		grid.add_child(item)
	buy_hbox.visible = false

func on_checkbox_toggle(button_pressed:bool):
	build_all = button_pressed

func refresh():
	grid.get_node("MB").visible = game.science_unlocked.has("MB")
		
func get_MS_name(_name:String):
	return tr("%s_NAME" % _name)

func set_item_info(_name:String, desc:String, costs:Dictionary, _type:String, _dir:String):
	super.set_item_info(_name, desc, costs, _type, _dir)
	name_node.text = get_MS_name(_name)
	desc_txt.text = desc

func get_item(_name, _type, _dir):
	if _name == "" or game.c_v != "system":
		return
	if _name == "DS":
		if not build_all or build_all and game.science_unlocked.has("DS1") and game.science_unlocked.has("DS2") and game.science_unlocked.has("DS3") and game.science_unlocked.has("DS4"):
			game.put_bottom_info(tr("CLICK_STAR_TO_CONSTRUCT"), "building_DS", "cancel_building_MS")
		else:
			game.popup(tr("NOT_ALL_STAGES_UNLOCKED"), 2.0)
			return
	elif _name == "CBS":
		if not build_all or build_all and game.science_unlocked.has("CBS1") and game.science_unlocked.has("CBS2") and game.science_unlocked.has("CBS3"):
			game.put_bottom_info(tr("CLICK_STAR_TO_CONSTRUCT"), "building_CBS", "cancel_building_MS")
		else:
			game.popup(tr("NOT_ALL_STAGES_UNLOCKED"), 2.0)
			return
	elif _name == "MB":
		game.put_bottom_info(tr("CLICK_STAR_TO_CONSTRUCT"), "building_MB", "cancel_building_MS")
	elif _name == "PK":
		if not build_all or build_all and game.science_unlocked.has("PK1") and game.science_unlocked.has("PK2"):
			game.put_bottom_info(tr("CLICK_STAR_TO_CONSTRUCT"), "building_PK", "cancel_building_MS")
		else:
			game.popup(tr("NOT_ALL_STAGES_UNLOCKED"), 2.0)
			return
	elif _name == "SE":
		if not build_all or build_all and game.science_unlocked.has("SE1"):
			game.put_bottom_info(tr("CLICK_PLANET_TO_CONSTRUCT"), "building-SE", "cancel_building_MS")
		else:
			game.popup(tr("NOT_ALL_STAGES_UNLOCKED"), 2.0)
			return
	elif _name == "MME":
		if not build_all or build_all and game.science_unlocked.has("MME1") and game.science_unlocked.has("MME2") and game.science_unlocked.has("MME3"):
			game.put_bottom_info(tr("CLICK_PLANET_TO_CONSTRUCT"), "building-MME", "cancel_building_MS")
		else:
			game.popup(tr("NOT_ALL_STAGES_UNLOCKED"), 2.0)
			return
	game.toggle_panel(game.megastructures_panel)
	game.view.obj.build_all_MS_stages = build_all

