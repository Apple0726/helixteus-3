extends "GenericPanel.gd"

var basic_bldgs:Array = ["ME", "PP", "RL", "MM"]
var storage_bldgs:Array = ["MS"]
var production_bldgs:Array = ["SC", "GF", "SE"]
var support_bldgs:Array = ["GH"]
var vehicles_bldgs:Array = ["RCC"]

func _ready():
	$Title.text = tr("CONSTRUCT")
	for btn_str in ["Basic", "Storage", "Production", "Support", "Vehicles"]:
		var btn = Button.new()
		btn.name = btn_str
		btn.text = tr(btn_str.to_upper())
		btn.size_flags_horizontal = Button.SIZE_EXPAND_FILL
		btn.connect("pressed", self, "_on_btn_pressed", [btn_str])
		$Tabs.add_child(btn)

func _on_btn_pressed(btn_str:String):
	var btn_str_l:String = btn_str.to_lower()
	var btn_str_u:String = btn_str.to_upper()
	tab = btn_str_l
	change_tab(btn_str)
	for bldg in self["%s_bldgs" % btn_str_l]:
		var item = item_for_sale_scene.instance()
		item.get_node("SmallButton").text = tr("CONSTRUCT")
		item.item_name = bldg
		item.item_dir = "Buildings"
		#item.item_type = "%s_info" % btn_str_l
		var txt = (Data.path_1[bldg].desc + "\n") % [Data.path_1[bldg].value]
		if Data.path_2.has(bldg):
			var txt2:String = (Data.path_2[bldg].desc + "\n") % [Data.path_2[bldg].value]
			txt += txt2
		if Data.path_3.has(bldg):
			var txt2:String = (Data.path_3[bldg].desc + "\n") % [Data.path_3[bldg].value]
			txt += txt2
		item.item_desc = "%s\n\n%s" % [tr("%s_DESC" % bldg), txt]
		item.costs = Data.costs[bldg]
		item.parent = "construct_panel"
		grid.add_child(item)

func set_item_info(_name:String, desc:String, costs:Dictionary, _type:String, _dir:String):
	.set_item_info(_name, desc, costs, _type, _dir)
	desc_txt.text = ""
	var icons = []
	var has_icon = Data.desc_icons.has(_name)# and txt.find("@i") != -1
	if has_icon:
		icons = Data.desc_icons[_name]
	game.add_text_icons(desc_txt, desc, icons, 22)

func _on_Buy_pressed():
	get_item(item_name, item_costs, null, null)

func get_item(_name, costs, _type, _dir):
	if _name == "" or game.c_v != "planet":
		return
	yield(get_tree().create_timer(0.01), "timeout")
	game.toggle_panel(game.construct_panel)
	game.put_bottom_info(tr("CLICK_TILE_TO_CONSTRUCT"), "building", "cancel_building")
	game.view.obj.construct(_name, costs)

func refresh():
	$Tabs/Vehicles.visible = game.science_unlocked.RC
	$Tabs/Production.visible = game.show.stone
	for bldg in get_tree().get_nodes_in_group("bldgs"):
		if bldg.item_name == "GF":
			bldg.visible = game.show.sand
		if bldg.item_name == "SE":
			bldg.visible = game.show.coal
		if bldg.item_name == "MM":
			bldg.visible = game.science_unlocked.AM
