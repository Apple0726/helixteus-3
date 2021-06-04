extends "Panel.gd"

var tile
var atom_to_MM:bool = true#MM: material or metal
var metal:String
var ratios:Dictionary
var difficulty:float#Amount of time per unit of atom/metal
var energy_cost:float
var au_mult:float
var MM:String
var reaction:String = ""
var atom_costs:Dictionary = {}
var reactions:Dictionary = {	"stone":{"MM":"", "atoms":["H", "He", "C", "N", "O", "F", "Ne", "Na", "Mg", "Al", "Si", "P", "S", "K", "Ca", "Ti", "Cr", "Mn", "Fe", "Co", "Ni", "Xe", "Ta", "W", "Os", "Ir", "U", "Np", "Pu"]},
								"iron":{"MM":"mets", "atoms":["Fe"]},
								"aluminium":{"MM":"mets", "atoms":["Al"]},
								"silicon":{"MM":"mats", "atoms":["Si"]},
								"amethyst":{"MM":"mets", "atoms":["Si", "O"]},
								"emerald":{"MM":"mets", "atoms":["Al", "Si", "O"]},
								"quartz":{"MM":"mets", "atoms":["Si", "O"]},
								"topaz":{"MM":"mets", "atoms":["Al", "Si", "O", "F", "H"]},
								"ruby":{"MM":"mets", "atoms":["Al", "O"]},
								"sapphire":{"MM":"mets", "atoms":["Al", "O"]},
								"titanium":{"MM":"mets", "atoms":["Ti"]},
								"diamond":{"MM":"mets", "atoms":["C"]},
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
		btn.expand_icon = true
		btn.text = tr(_name.to_upper())
		btn.connect("pressed", self, "_on_%s_pressed" % _name, [_name, reactions[_name]])
		$ScrollContainer/VBoxContainer.add_child(btn)

func _on_stone_pressed(_name:String, dict:Dictionary):
	reset_poses(_name, dict)
	ratios = {	"H":1000 / 1.008,
				"He":1000 / 4.0026,
				"C":1000 / 12.011,
				"O":1000 / 15.999,
				"F":1000 / 18.998,
				"Ne":1000 / 20.18,
				"Na":1000 / 22.99,
				"Mg":1000 / 24.305,
				"Al":1000 / 26.982,
				"Si":1000 / 28.085,
				"P":1000 / 30.974,
				"S":1000 / 32.06,
				"K":1000 / 39.098,
				"Ca":1000 / 40.078,
				"Ti":1000 / 47.867,
				"Cr":1000 / 51.996,
				"Mn":1000 / 54.938,
				"Fe":1000 / 55.845,
				"Co":1000 / 58.933,
				"Ni":1000 / 58.693,
				"Ta":1000 / 180.95,
				"W":1000 / 183.84,
				"Os":1000 / 190.23,
				"Ir":1000 / 192.22,
				"U":1000 / 238.03,
				"Np":1000 / 237,
				"Pu":1000 / 244,
	}
	atom_costs = {}
	for el in ratios:
		if game.stone.has(el):
			atom_costs[el] = 0
	Helper.put_rsrc($Control2/ScrollContainer/From, 32, atom_costs, true, true)
	Helper.put_rsrc($Control2/To, 32, {"stone":0})
	metal = "stone"
	energy_cost = 100
	difficulty = 0.001
	_on_Switch_pressed()
	$Control/Switch.visible = false
	
func _on_diamond_pressed(_name:String, dict:Dictionary):
	reset_poses(_name, dict)
	ratios = {"C":1000.0 / 12.011}
	atom_costs = {"C":0}
	Helper.put_rsrc($Control2/ScrollContainer/From, 32, atom_costs, true, true)
	Helper.put_rsrc($Control2/To, 32, {"diamond":0})
	metal = "diamond"
	energy_cost = 25000
	difficulty = 1.0
	refresh()
	$Control/Switch.visible = true

func _on_iron_pressed(_name:String, dict:Dictionary):
	reset_poses(_name, dict)
	ratios = {"Fe":1000.0 / 55.845}
	atom_costs = {"Fe":0}
	Helper.put_rsrc($Control2/ScrollContainer/From, 32, atom_costs, true, true)
	Helper.put_rsrc($Control2/To, 32, {"iron":0})
	metal = "iron"
	energy_cost = 300
	difficulty = 0.2
	refresh()
	$Control/Switch.visible = true

func _on_silicon_pressed(_name:String, dict:Dictionary):
	reset_poses(_name, dict)
	ratios = {"Si":1000.0 / 28.085}
	Helper.put_rsrc($Control2/ScrollContainer/From, 32, atom_costs, true, true)
	Helper.put_rsrc($Control2/To, 32, {"silicon":0})
	metal = "silicon"
	energy_cost = 500
	difficulty = 0.2
	refresh()
	$Control/Switch.visible = true

func _on_aluminium_pressed(_name:String, dict:Dictionary):
	reset_poses(_name, dict)
	ratios = {"Al":1000.0 / 26.982}
	Helper.put_rsrc($Control2/ScrollContainer/From, 32, atom_costs, true, true)
	Helper.put_rsrc($Control2/To, 32, {"aluminium":0})
	metal = "aluminium"
	energy_cost = 50
	difficulty = 0.1
	refresh()
	$Control/Switch.visible = true

func _on_amethyst_pressed(_name:String, dict:Dictionary):
	reset_poses(_name, dict)
	ratios = {"Si":1000.0 / 28.085, "O":1000.0 / (15.999 * 2)}
	atom_costs = {"Si":0, "O":0}
	Helper.put_rsrc($Control2/ScrollContainer/From, 32, atom_costs, true, true)
	Helper.put_rsrc($Control2/To, 32, {"amethyst":0})
	metal = "amethyst"
	energy_cost = 1500
	difficulty = 2.0
	refresh()
	$Control/Switch.visible = true

func _on_emerald_pressed(_name:String, dict:Dictionary):
	reset_poses(_name, dict)
	ratios = {"Al":1000.0 / (26.982 * 2), "Si":1000.0 / (28.085 * 6), "O":1000.0 / (15.999 * 12)}
	atom_costs = {"Al":0, "Si":0, "O":0}
	Helper.put_rsrc($Control2/ScrollContainer/From, 32, atom_costs, true, true)
	Helper.put_rsrc($Control2/To, 32, {"emerald":0})
	metal = "emerald"
	energy_cost = 1500
	difficulty = 2.0
	refresh()
	$Control/Switch.visible = true

func _on_quartz_pressed(_name:String, dict:Dictionary):
	reset_poses(_name, dict)
	ratios = {"Si":1000.0 / 28.085, "O":1000.0 / (15.999 * 2)}
	atom_costs = {"Si":0, "O":0}
	Helper.put_rsrc($Control2/ScrollContainer/From, 32, atom_costs, true, true)
	Helper.put_rsrc($Control2/To, 32, {"quartz":0})
	metal = "quartz"
	energy_cost = 1600
	difficulty = 2.0
	refresh()
	$Control/Switch.visible = true

func _on_topaz_pressed(_name:String, dict:Dictionary):
	reset_poses(_name, dict)
	ratios = {"Al":1000.0 / (26.982 * 2), "Si":1000.0 / (28.085), "O":1000.0 / (15.999 * 6), "F":1000.0 / (18.998 * 2), "H":1000.0 / (1.008 * 2)}
	atom_costs = {"Al":0, "Si":0, "O":0, "F":0, "H":0}
	Helper.put_rsrc($Control2/ScrollContainer/From, 32, atom_costs, true, true)
	Helper.put_rsrc($Control2/To, 32, {"topaz":0})
	metal = "topaz"
	energy_cost = 1500
	difficulty = 2.0
	refresh()
	$Control/Switch.visible = true

func _on_ruby_pressed(_name:String, dict:Dictionary):
	reset_poses(_name, dict)
	ratios = {"Al":1000.0 / (26.982 * 2), "O":1000.0 / (15.999 * 3)}
	atom_costs = {"Al":0, "O":0}
	Helper.put_rsrc($Control2/ScrollContainer/From, 32, atom_costs, true, true)
	Helper.put_rsrc($Control2/To, 32, {"ruby":0})
	metal = "ruby"
	energy_cost = 1600
	difficulty = 2.0
	refresh()
	$Control/Switch.visible = true

func _on_sapphire_pressed(_name:String, dict:Dictionary):
	reset_poses(_name, dict)
	ratios = {"Al":1000.0 / (26.982 * 2), "O":1000.0 / (15.999 * 3)}
	atom_costs = {"Al":0, "O":0}
	Helper.put_rsrc($Control2/ScrollContainer/From, 32, atom_costs, true, true)
	Helper.put_rsrc($Control2/To, 32, {"sapphire":0})
	metal = "sapphire"
	energy_cost = 1700
	difficulty = 2.0
	refresh()
	$Control/Switch.visible = true

func _on_titanium_pressed(_name:String, dict:Dictionary):
	reset_poses(_name, dict)
	ratios = {"Ti":1000.0 / 47.867}
	atom_costs = {"Ti":0}
	Helper.put_rsrc($Control2/ScrollContainer/From, 32, atom_costs, true, true)
	Helper.put_rsrc($Control2/To, 32, {"titanium":0})
	metal = "titanium"
	energy_cost = 2500
	difficulty = 2.5
	refresh()
	$Control/Switch.visible = true

func refresh():
	tile = game.tile_data[game.c_t]
	au_mult = Helper.get_au_mult(tile)
	$Control3.visible = tile.bldg.has("qty") and reaction == tile.bldg.reaction
	$Control.visible = not $Control3.visible and reaction != ""
	refresh_icon()
	$Control/EnergyCostText.text = Helper.format_num(round(energy_cost * $Control/HSlider.value / au_mult))
	$Control/TimeCostText.text = Helper.time_to_str(difficulty * $Control/HSlider.value * 1000 / tile.bldg.path_1_value)
	for reaction_name in reactions:
		var disabled:bool = false
		for atom in reactions[reaction_name].atoms:
			if game.atoms.has(atom) and game.atoms[atom] == 0:
				disabled = true
				break
		if reaction_name == "stone":
			disabled = disabled and Helper.get_sum_of_dict(game.stone) == 0 and (not tile.bldg.has("qty") or not tile.bldg.reaction == reaction_name)
		else:
			disabled = disabled and game[reactions[reaction_name].MM][reaction_name] == 0 and (not tile.bldg.has("qty") or not tile.bldg.reaction == reaction_name)
		$ScrollContainer/VBoxContainer.get_node(reaction_name).disabled = disabled
	if reaction == "":
		return
	set_process($Control3.visible)
	var max_value:float = 0.0
	if atom_to_MM:
		for atom in ratios:
			if ratios[atom] == 0:
				continue
			var max_value2 = game.atoms[atom] / ratios[atom]
			if max_value2 < max_value or max_value == 0.0:
				max_value = max_value2
	else:
		if metal == "stone":
			max_value = Helper.get_sum_of_dict(game.stone)
		else:
			max_value = game[MM][metal]
	$Control/HSlider.max_value = max_value
	$Control/HSlider.step = int(max_value / 100)
	$Control/HSlider.visible = not is_equal_approx($Control/HSlider.max_value, 0)
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
	$Control2/ScrollContainer.rect_position = Vector2(480, 240)
	$Control2/To.rect_position = Vector2(772, 240)
	$Control3.visible = tile.bldg.has("qty") and tile.bldg.reaction == reaction
	$Control.visible = not $Control3.visible
	if $Control3.visible and not tile.bldg.atom_to_MM and reaction != "stone":
		_on_Switch_pressed(false)
	atom_costs.clear()
	for atom in dict.atoms:
		atom_costs[atom] = 0

func _on_Switch_pressed(refresh:bool = true):
	var pos = $Control2/To.rect_position
	$Control2/To.rect_position = $Control2/ScrollContainer.rect_position
	$Control2/ScrollContainer.rect_position = pos
	atom_to_MM = not atom_to_MM
	if refresh:
		_on_HSlider_value_changed($Control/HSlider.value)
		#refresh()

func _on_HSlider_value_changed(value):
	var MM_dict = {}
	if metal == "stone":
		var sum = Helper.get_sum_of_dict(game.stone)
		for atom in atom_costs:
			if game.stone.has(atom):
				atom_costs[atom] = value * ratios[atom] * game.stone[atom] / sum
	else:
		for atom in atom_costs:
			atom_costs[atom] = value * ratios[atom]
	MM_dict[metal] = value
	Helper.put_rsrc($Control2/ScrollContainer/From, 32, atom_costs, true, atom_to_MM)
	Helper.put_rsrc($Control2/To, 32, MM_dict, true, not atom_to_MM)
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
			var sum = Helper.get_sum_of_dict(tile.bldg.AMN_stone)
			for atom in rsrc_to_add:
				rsrc_to_add[atom] = MM_value * ratios[atom] * tile.bldg.AMN_stone[atom] / sum
			if metal == "stone":
				rsrc_to_add[metal] = {}
				for atom in rsrc_to_add:
					if atom == "stone":
						continue
					rsrc_to_add[metal][atom] = max(0, tile.bldg.qty - MM_value) * tile.bldg.AMN_stone[atom] / sum
			else:
				rsrc_to_add[metal] = max(0, tile.bldg.qty - MM_value)
		rsrc_to_add.energy = round((1 - progress) * energy_cost / au_mult * tile.bldg.qty)
		game.add_resources(rsrc_to_add)
		tile.bldg.erase("qty")
		tile.bldg.erase("start_date")
		tile.bldg.erase("reaction")
		tile.bldg.erase("AMN_stone")
		$Control.visible = true
		$Control3.visible = false
		$Transform.text = "%s (G)" % tr("TRANSFORM")
		refresh_icon()
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
		rsrc_to_deduct.energy = round(energy_cost * rsrc / au_mult)
		if not game.check_enough(rsrc_to_deduct):
			game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)
			return
		game.deduct_resources(rsrc_to_deduct)
		tile.bldg.qty = rsrc
		tile.bldg.AMN_stone = game.stone.duplicate(true)
		tile.bldg.start_date = OS.get_system_time_msecs()
		tile.bldg.reaction = reaction
		tile.bldg.atom_to_MM = atom_to_MM
		set_process(true)
		$Control.visible = false
		$Control3.visible = true
		$Transform.text = "%s (G)" % tr("STOP")
		refresh_icon()
	game.HUD.refresh()

func refresh_icon():
	for r in $ScrollContainer/VBoxContainer.get_children():
		r.icon = Data.time_icon if tile.bldg.has("reaction") and r.name == tile.bldg.reaction else null

func _process(delta):
	if not tile or tile.empty():
		_on_close_button_pressed()
		set_process(false)
		return
	if not tile.bldg.has("start_date"):
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
			atom_dict[atom] = Helper.clever_round(max(0, tile.bldg.qty - MM_value) * ratios[atom])
	else:
		MM_dict[metal] = max(0, tile.bldg.qty - MM_value)
		if metal == "stone":
			var sum = Helper.get_sum_of_dict(tile.bldg.AMN_stone)
			for atom in atom_costs:
				if game.stone.has(atom):
					atom_dict[atom] = Helper.clever_round(MM_value * ratios[atom] * tile.bldg.AMN_stone[atom] / sum)
		else:
			for atom in atom_dict:
				atom_dict[atom] = Helper.clever_round(MM_value * ratios[atom])
	Helper.put_rsrc($Control2/ScrollContainer/From, 32, atom_dict)
	Helper.put_rsrc($Control2/To, 32, MM_dict)
	$Control3/TimeRemainingText.text = Helper.time_to_str(max(0, difficulty * (tile.bldg.qty - MM_value) * 1000 / tile.bldg.path_1_value))

func get_reaction_info(tile):
	var MM_value:float = clamp((OS.get_system_time_msecs() - tile.bldg.start_date) / (1000 * difficulty) * tile.bldg.path_1_value, 0, tile.bldg.qty)
	return {"MM_value":MM_value, "progress":MM_value / tile.bldg.qty}
