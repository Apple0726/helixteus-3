extends "Panel.gd"

var tile
var atom_to_p:bool = true#MM: material or metal
var difficulty:float#Amount of time per unit of atom/metal
var energy_cost:float
var reaction:String = ""
var Z:int
var atom_costs:Dictionary = {}
var reactions:Dictionary = {	"He":2,
								"Ne":10,
								"Xe":54,
}

func _ready():
	set_process(false)
	set_polygon($Background.rect_size)
	$Title.text = tr("SPR_NAME")
	$Desc.text = tr("REACTIONS_PANEL_DESC")
	for _name in reactions:
		var btn = Button.new()
		btn.name = _name
		btn.rect_min_size.y = 30
		btn.text = tr("%s_NAME" % _name.to_upper())
		btn.connect("pressed", self, "_on_%s_pressed" % _name, [_name, reactions[_name]])
		$ScrollContainer/VBoxContainer.add_child(btn)

func _on_He_pressed(_name:String, Z:int):
	reset_poses(_name, Z)
	energy_cost = 1000
	difficulty = 10.0
	refresh()

func _on_Ne_pressed(_name:String, Z:int):
	reset_poses(_name, Z)
	energy_cost = 10000
	difficulty = 80.0
	refresh()

func _on_Xe_pressed(_name:String, Z:int):
	reset_poses(_name, Z)
	energy_cost = 80000
	difficulty = 400.0
	refresh()

func refresh():
	tile = game.tile_data[game.c_t]
	for reaction_name in reactions:
		var disabled:bool = false
		if game.particles.proton == 0 or game.particles.neutron == 0 or game.particles.electron == 0:
			disabled = true
		disabled = disabled and game.atoms[reaction_name] == 0 and (not tile.bldg.has("qty") or not tile.bldg.reaction == reaction_name)
		$ScrollContainer/VBoxContainer.get_node(reaction_name).disabled = disabled
	if reaction == "":
		return
	set_process($Control3.visible)
	var max_value:float = 0.0
	if atom_to_p:
		max_value = game.atoms[reaction]
	else:
		for particle in game.particles:
			var max_value2 = game.particles[particle] / Z
			if max_value2 < max_value or max_value == 0.0:
				max_value = max_value2
	$Control/HSlider.max_value = max_value
	$Control/HSlider.visible = $Control/HSlider.max_value != 0
	if $Control3.visible:
		$Transform.visible = true
		$Transform.text = "%s (G)" % tr("STOP")
	else:
		$Transform.visible = $Control/HSlider.max_value != 0 and not tile.bldg.has("qty")
		$Transform.text = "%s (G)" % tr("TRANSFORM")

func reset_poses(_name:String, _Z:int):
	for btn in $ScrollContainer/VBoxContainer.get_children():
		btn["custom_colors/font_color"] = null
		btn["custom_colors/font_color_hover"] = null
		btn["custom_colors/font_color_pressed"] = null
		btn["custom_colors/font_color_disabled"] = null
	$ScrollContainer/VBoxContainer.get_node(_name)["custom_colors/font_color"] = Color(0, 1, 1, 1)
	$ScrollContainer/VBoxContainer.get_node(_name)["custom_colors/font_color_hover"] = Color(0, 1, 1, 1)
	$ScrollContainer/VBoxContainer.get_node(_name)["custom_colors/font_color_pressed"] = Color(0, 1, 1, 1)
	$ScrollContainer/VBoxContainer.get_node(_name)["custom_colors/font_color_disabled"] = Color(0, 1, 1, 1)
	reaction = _name
	Z = _Z
	atom_to_p = true
	$Control2.visible = true
	$Control2/From.rect_position = Vector2(480, 240)
	$Control2/To.rect_position = Vector2(772, 240)
	$Control3.visible = tile.bldg.has("qty") and tile.bldg.reaction == reaction
	$Control.visible = not $Control3.visible
	if $Control3.visible and not tile.bldg.atom_to_p:
		_on_Switch_pressed(false)
	_on_HSlider_value_changed(0)

func _on_Switch_pressed(refresh:bool = true):
	var pos = $Control2/To.rect_position
	$Control2/To.rect_position = $Control2/From.rect_position
	$Control2/From.rect_position = pos
	atom_to_p = not atom_to_p
	if refresh:
		_on_HSlider_value_changed($Control/HSlider.value)
		refresh()

func _on_HSlider_value_changed(value):
	var atom_dict = {}
	var p_costs = {"proton":value, "neutron":value, "electron":value}
	for particle in p_costs:
		p_costs[particle] *= Z
	atom_dict[reaction] = value
	Helper.put_rsrc($Control2/From, 32, atom_dict, true, atom_to_p)
	Helper.put_rsrc($Control2/To, 32, p_costs, true, not atom_to_p)
	$Control/EnergyCostText.text = Helper.format_num(round(energy_cost * value))
	$Control/TimeCostText.text = Helper.time_to_str(difficulty * value * 1000)
	refresh()

func _on_Transform_pressed():
	if tile.bldg.has("qty"):
		set_process(false)
		var reaction_info = get_reaction_info(tile)
		var MM_value = reaction_info.MM_value
		var progress = reaction_info.progress
		var rsrc_to_add:Dictionary
		var num
		if tile.bldg.atom_to_p:
			rsrc_to_add[reaction] = max(0, tile.bldg.qty - MM_value)
			num = MM_value * Z
		else:
			rsrc_to_add[reaction] = MM_value
			num = max(0, tile.bldg.qty - MM_value) * Z
		rsrc_to_add.proton = num
		rsrc_to_add.neutron = num
		rsrc_to_add.electron = num
		rsrc_to_add.energy = (1 - progress) * energy_cost
		game.add_resources(rsrc_to_add)
		tile.bldg.erase("qty")
		tile.bldg.erase("start_date")
		tile.bldg.erase("reaction")
		$Control.visible = true
		$Control3.visible = false
		$Transform.text = "%s (G)" % tr("TRANSFORM")
		$ScrollContainer/VBoxContainer.get_node(reaction).icon = null
		_on_HSlider_value_changed($Control/HSlider.value)
	else:
		var rsrc = $Control/HSlider.value
		if rsrc == 0:
			return
		var rsrc_to_deduct = {}
		if atom_to_p:
			rsrc_to_deduct[reaction] = rsrc
		else:
			rsrc_to_deduct = {"proton":rsrc * Z, "neutron":rsrc * Z, "electron":rsrc * Z}
		rsrc_to_deduct.energy = energy_cost
		game.deduct_resources(rsrc_to_deduct)
		tile.bldg.qty = rsrc
		tile.bldg.start_date = OS.get_system_time_msecs()
		tile.bldg.reaction = reaction
		tile.bldg.atom_to_p = atom_to_p
		set_process(true)
		$Control.visible = false
		$Control3.visible = true
		$Transform.text = "%s (G)" % tr("STOP")
		$ScrollContainer/VBoxContainer.get_node(reaction).icon = Data.time_icon
	game.HUD.refresh()

func _process(delta):
	if not tile or tile.empty():
		_on_close_button_pressed()
		set_process(false)
		return
	var reaction_info = get_reaction_info(tile)
	#MM produced or MM used
	var MM_value = reaction_info.MM_value
	$Control3/TextureProgress.value = reaction_info.progress
	var MM_dict = {}
	var atom_dict:Dictionary = {}
	var num
	if tile.bldg.atom_to_p:
		num = MM_value * Z
		atom_dict[reaction] = max(0, tile.bldg.qty - MM_value)
	else:
		num = max(0, tile.bldg.qty - MM_value) * Z
		atom_dict[reaction] = MM_value
	MM_dict = {"proton":num, "neutron":num, "electron":num}
	Helper.put_rsrc($Control2/From, 32, atom_dict)
	Helper.put_rsrc($Control2/To, 32, MM_dict)
	$Control3/TimeRemainingText.text = Helper.time_to_str(max(0, difficulty * (tile.bldg.qty - MM_value) * 1000))

func get_reaction_info(tile):
	var MM_value:float = clamp((OS.get_system_time_msecs() - tile.bldg.start_date) / (1000 * difficulty) * tile.bldg.path_1_value, 0, tile.bldg.qty)
	return {"MM_value":MM_value, "progress":MM_value / tile.bldg.qty}

func _on_close_button_pressed():
	game.toggle_panel(self)
