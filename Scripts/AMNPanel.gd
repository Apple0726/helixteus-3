extends "Panel.gd"

var tile
var atom_to_MM:bool = true#MM: material or metal
var metal:String
var ratios:Dictionary
var difficulty:float#Amount of time per unit of atom/metal
var energy_cost:float
var MM:String
var reaction:String = ""
var atom_costs:Dictionary = {}
var reactions:Dictionary = {	"diamond":{"MM":"mets", "atoms":["C"]},
								"silicon":{"MM":"mats", "atoms":["Si"]},
								"amethyst":{"MM":"mets", "atoms":["Si", "O"]},
								"emerald":{"MM":"mets", "atoms":["Al", "Si", "O"]},
								"quartz":{"MM":"mets", "atoms":["Si", "O"]},
								"topaz":{"MM":"mets", "atoms":["Al", "Si", "O", "F", "H"]},
								"ruby":{"MM":"mets", "atoms":["Al", "O"]},
								"sapphire":{"MM":"mets", "atoms":["Al", "O"]},
}

func _ready():
	set_process(false)
	set_polygon($Background.rect_size)
	$Title.text = tr("AMN_NAME")
	$Desc.text = tr("REACTIONS_PANEL_DESC")
	for _name in reactions:
		var btn = Button.new()
		btn.name = _name
		btn.rect_min_size.y = 30
		btn.text = tr(_name.to_upper())
		btn.connect("pressed", self, "_on_%s_pressed" % _name, [_name, reactions[_name]])
		$ScrollContainer/VBoxContainer.add_child(btn)

func _on_diamond_pressed(_name:String, dict:Dictionary):
	reset_poses(_name, dict)
	ratios = {"C":1000.0 / 12.011}
	atom_costs = {"C":0}
	Helper.put_rsrc($Control2/From, 32, atom_costs, true, true)
	Helper.put_rsrc($Control2/To, 32, {"diamond":0})
	metal = "diamond"
	energy_cost = 5000
	difficulty = 1.0
	refresh()

func _on_silicon_pressed(_name:String, dict:Dictionary):
	reset_poses(_name, dict)
	ratios = {"Si":1000.0 / 28.085}
	Helper.put_rsrc($Control2/From, 32, atom_costs, true, true)
	Helper.put_rsrc($Control2/To, 32, {"silicon":0})
	metal = "silicon"
	energy_cost = 500
	difficulty = 0.2
	refresh()

func _on_amethyst_pressed(_name:String, dict:Dictionary):
	reset_poses(_name, dict)
	ratios = {"Si":1000.0 / 28.085, "O":1000.0 / (15.999 * 2)}
	atom_costs = {"Si":0, "O":0}
	Helper.put_rsrc($Control2/From, 32, atom_costs, true, true)
	Helper.put_rsrc($Control2/To, 32, {"amethyst":0})
	metal = "amethyst"
	energy_cost = 15000
	difficulty = 20.0
	refresh()

func _on_emerald_pressed(_name:String, dict:Dictionary):
	reset_poses(_name, dict)
	ratios = {"Al":1000.0 / (26.982 * 2), "Si":1000.0 / (28.085 * 6), "O":1000.0 / (15.999 * 12)}
	atom_costs = {"Al":0, "Si":0, "O":0}
	Helper.put_rsrc($Control2/From, 32, atom_costs, true, true)
	Helper.put_rsrc($Control2/To, 32, {"emerald":0})
	metal = "emerald"
	energy_cost = 15000
	difficulty = 20.0
	refresh()

func _on_quartz_pressed(_name:String, dict:Dictionary):
	reset_poses(_name, dict)
	ratios = {"Si":1000.0 / 28.085, "O":1000.0 / (15.999 * 2)}
	atom_costs = {"Si":0, "O":0}
	Helper.put_rsrc($Control2/From, 32, atom_costs, true, true)
	Helper.put_rsrc($Control2/To, 32, {"quartz":0})
	metal = "quartz"
	energy_cost = 16000
	difficulty = 22.0
	refresh()

func _on_topaz_pressed(_name:String, dict:Dictionary):
	reset_poses(_name, dict)
	ratios = {"Al":1000.0 / (26.982 * 2), "Si":1000.0 / (28.085), "O":1000.0 / (15.999 * 6), "F":1000.0 / (18.998 * 2), "H":1000.0 / (1.008 * 2)}
	atom_costs = {"Al":0, "Si":0, "O":0, "F":0, "H":0}
	Helper.put_rsrc($Control2/From, 32, atom_costs, true, true)
	Helper.put_rsrc($Control2/To, 32, {"topaz":0})
	metal = "topaz"
	energy_cost = 15000
	difficulty = 20.0
	refresh()

func _on_ruby_pressed(_name:String, dict:Dictionary):
	reset_poses(_name, dict)
	ratios = {"Al":1000.0 / (26.982 * 2), "O":1000.0 / (15.999 * 3)}
	atom_costs = {"Al":0, "O":0}
	Helper.put_rsrc($Control2/From, 32, atom_costs, true, true)
	Helper.put_rsrc($Control2/To, 32, {"ruby":0})
	metal = "ruby"
	energy_cost = 16000
	difficulty = 22.0
	refresh()

func _on_sapphire_pressed(_name:String, dict:Dictionary):
	reset_poses(_name, dict)
	ratios = {"Al":1000.0 / (26.982 * 2), "O":1000.0 / (15.999 * 3)}
	atom_costs = {"Al":0, "O":0}
	Helper.put_rsrc($Control2/From, 32, atom_costs, true, true)
	Helper.put_rsrc($Control2/To, 32, {"sapphire":0})
	metal = "sapphire"
	energy_cost = 17000
	difficulty = 24.0
	refresh()

func refresh():
	tile = game.tile_data[game.c_t]
	for reaction_name in reactions:
		var disabled:bool = false
		for atom in reactions[reaction_name].atoms:
			if game.atoms[atom] == 0:
				disabled = true
				break
		disabled = disabled and game[reactions[reaction_name].MM][reaction_name] == 0 and (not tile.bldg.has("qty") or not tile.bldg.reaction == reaction_name)
		$ScrollContainer/VBoxContainer.get_node(reaction_name).disabled = disabled
	if reaction == "":
		return
	set_process($Control3.visible)
	var max_value:float = 0.0
	if atom_to_MM:
		for atom in ratios:
			var max_value2 = game.atoms[atom] / ratios[atom]
			if max_value2 < max_value or max_value == 0.0:
				max_value = max_value2
	else:
		max_value = game[MM][metal]
	$Control/HSlider.max_value = max_value
	$Control/HSlider.visible = $Control/HSlider.max_value != 0
	if $Control3.visible:
		$Transform.visible = true
		$Transform.text = "%s (G)" % tr("STOP")
	else:
		$Transform.visible = $Control/HSlider.max_value != 0 and not tile.bldg.has("qty")
		$Transform.text = "%s (G)" % tr("TRANSFORM")

func reset_poses(_name:String, dict:Dictionary):
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
	MM = dict.MM
	atom_to_MM = true
	$Control2.visible = true
	$Control2/From.rect_position = Vector2(480, 240)
	$Control2/To.rect_position = Vector2(772, 240)
	$Control3.visible = tile.bldg.has("qty") and tile.bldg.reaction == reaction
	$Control.visible = not $Control3.visible
	if $Control3.visible and not tile.bldg.atom_to_MM:
		_on_Switch_pressed(false)
	atom_costs.clear()
	for atom in dict.atoms:
		atom_costs[atom] = 0

func _on_Switch_pressed(refresh:bool = true):
	var pos = $Control2/To.rect_position
	$Control2/To.rect_position = $Control2/From.rect_position
	$Control2/From.rect_position = pos
	atom_to_MM = not atom_to_MM
	if refresh:
		_on_HSlider_value_changed($Control/HSlider.value)
		refresh()

func _on_HSlider_value_changed(value):
	var MM_dict = {}
	for atom in atom_costs:
		atom_costs[atom] = value * ratios[atom]
	MM_dict[metal] = value
	Helper.put_rsrc($Control2/From, 32, atom_costs, true, atom_to_MM)
	Helper.put_rsrc($Control2/To, 32, MM_dict, true, not atom_to_MM)
	$Control/EnergyCostText.text = Helper.format_num(round(energy_cost * value))
	$Control/TimeCostText.text = Helper.time_to_str(difficulty * value * 1000)
	refresh()

func _on_Transform_pressed():
	if tile.bldg.has("qty"):
		set_process(false)
		var reaction_info = get_reaction_info(tile)
		var MM_value = reaction_info.MM_value
		var progress = reaction_info.progress
		var rsrc_to_add:Dictionary = atom_costs.duplicate(true)
		if tile.bldg.atom_to_MM:
			for atom in rsrc_to_add:
				rsrc_to_add[atom] = max(0, tile.bldg.qty - MM_value) * ratios[atom]
			rsrc_to_add[metal] = MM_value
		else:
			for atom in rsrc_to_add:
				rsrc_to_add[atom] = MM_value * ratios[atom]
			rsrc_to_add[metal] = max(0, tile.bldg.qty - MM_value)
		rsrc_to_add.energy = round((1 - progress) * energy_cost * tile.bldg.qty)
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
		if atom_to_MM:
			rsrc_to_deduct = atom_costs.duplicate(true)
		else:
			rsrc_to_deduct[metal] = rsrc
		rsrc_to_deduct.energy = round(energy_cost * rsrc)
		game.deduct_resources(rsrc_to_deduct)
		tile.bldg.qty = rsrc
		tile.bldg.start_date = OS.get_system_time_msecs()
		tile.bldg.reaction = reaction
		tile.bldg.atom_to_MM = atom_to_MM
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
	var atom_dict:Dictionary = atom_costs.duplicate(true)
	if tile.bldg.atom_to_MM:
		MM_dict[metal] = MM_value
		for atom in atom_dict:
			atom_dict[atom] = game.clever_round(MM_value * ratios[atom])
	else:
		MM_dict[metal] = max(0, tile.bldg.qty - MM_value)
		for atom in atom_dict:
			atom_dict[atom] = game.clever_round(MM_value * ratios[atom])
	Helper.put_rsrc($Control2/From, 32, atom_dict)
	Helper.put_rsrc($Control2/To, 32, MM_dict)
	$Control3/TimeRemainingText.text = Helper.time_to_str(max(0, difficulty * (tile.bldg.qty - MM_value) * 1000))

func get_reaction_info(tile):
	var MM_value:float = clamp((OS.get_system_time_msecs() - tile.bldg.start_date) / (1000 * difficulty) * tile.bldg.path_1_value, 0, tile.bldg.qty)
	return {"MM_value":MM_value, "progress":MM_value / tile.bldg.qty}

func _on_close_button_pressed():
	game.toggle_panel(self)
