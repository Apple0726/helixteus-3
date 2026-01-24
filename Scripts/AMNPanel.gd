extends "Panel.gd"

var obj:Dictionary
var tile_num
var tf:bool = false#whether this panel is opened by clicking a tile or a planet
var atom_to_MM:bool = true#MM: material or metal
var metal:String
var ratios:Dictionary
var difficulty:float#Amount of time per unit of atom/metal
var energy_cost:float
var au_mult:float
var au_int:float
var MM:String
var reaction:String = ""
var atom_costs:Dictionary = {}
var reactions:Dictionary = {	"stone":{"MM":"", "atoms":["H", "He", "C", "N", "O", "F", "Ne", "Na", "Mg", "Al", "Si", "P", "S", "K", "Ca", "Ti", "Cr", "Mn", "Fe", "Co", "Ni", "Xe", "Ta", "W", "Os", "Ir", "U", "Np", "Pu"]},
								"iron":{"MM":"mets", "atoms":["Fe"]},
								"aluminium":{"MM":"mets", "atoms":["Al"]},
								"silicon":{"MM":"mats", "atoms":["Si"]},
								"titanium":{"MM":"mets", "atoms":["Ti"]},
								"platinum":{"MM":"mets", "atoms":["Pt"]},
								"diamond":{"MM":"mets", "atoms":["C"]},
								"nanocrystal":{"MM":"mets", "atoms":["Si", "O", "Na"]},
								"quillite":{"MM":"mats", "atoms":["Si", "O", "Ne"]},
								"mythril":{"MM":"mets", "atoms":["W", "Os", "Ta"]},
}
var rsrc_nodes_from:Array
var rsrc_nodes_to:Array
var path_2_value:float = 1.0

func _ready():
	set_process(false)
	set_polygon(size)
	$Title.text = tr("ATOM_MANIPULATOR_NAME")
	$Desc.text = tr("REACTIONS_PANEL_DESC")
	for _name in reactions:
		var btn = preload("res://Scenes/AdvButton.tscn").instantiate()
		if _name in ["nanocrystal", "mythril", "quillite"] and not game.science_unlocked.has("AMM"):
			btn.visible = false
		btn.name = _name
		btn.icon_texture = Data.time_icon
		btn.button_text = tr(_name.to_upper())
		btn.connect("pressed",Callable(self,"_on_%s_pressed" % _name).bind(_name, reactions[_name]))
		$ScrollContainer/VBoxContainer.add_child(btn)

func _on_stone_pressed(_name:String, dict:Dictionary):
	reset_poses(_name, dict)
	ratios.clear()
	for atom in Data.molar_mass:
		ratios[atom] = 1000.0 / Data.molar_mass[atom]
	atom_costs = {}
	for el in ratios:
		if game.stone.has(el):
			atom_costs[el] = 0
	metal = "stone"
	energy_cost = 1
	difficulty = 0.01
	_on_HSlider_value_changed(0.0)
	_on_Switch_pressed()
	$Control/Switch.visible = false

func _on_iron_pressed(_name:String, dict:Dictionary):
	reset_poses(_name, dict)
	ratios = {"Fe":1000.0 / 55.845}
	atom_costs = {"Fe":0}
	rsrc_nodes_from = Helper.put_rsrc($Control2/ScrollContainer/From, 32, atom_costs, true, true)
	rsrc_nodes_to = Helper.put_rsrc($Control2/To, 32, {"iron":0})
	metal = "iron"
	energy_cost = 30
	difficulty = 0.03
	refresh()
	$Control/Switch.visible = true

func _on_silicon_pressed(_name:String, dict:Dictionary):
	reset_poses(_name, dict)
	ratios = {"Si":1000.0 / 28.085}
	rsrc_nodes_from = Helper.put_rsrc($Control2/ScrollContainer/From, 32, atom_costs, true, true)
	rsrc_nodes_to = Helper.put_rsrc($Control2/To, 32, {"silicon":0})
	metal = "silicon"
	energy_cost = 15
	difficulty = 0.005
	refresh()
	$Control/Switch.visible = true

func _on_quillite_pressed(_name:String, dict:Dictionary):
	reset_poses(_name, dict)
	ratios = {"Si":1000.0 / 28.085, "O":1000.0 / (15.999 * 2), "Ne":1000.0 / 20.1797}
	atom_costs = {"Si":0, "O":0, "Ne":0}
	rsrc_nodes_from = Helper.put_rsrc($Control2/ScrollContainer/From, 32, atom_costs, true, true)
	rsrc_nodes_to = Helper.put_rsrc($Control2/To, 32, {"quillite":0})
	metal = "quillite"
	energy_cost = 1900000
	difficulty = 3.2
	refresh()
	$Control/Switch.visible = true

func _on_titanium_pressed(_name:String, dict:Dictionary):
	reset_poses(_name, dict)
	ratios = {"Ti":1000.0 / 47.867}
	atom_costs = {"Ti":0}
	rsrc_nodes_from = Helper.put_rsrc($Control2/ScrollContainer/From, 32, atom_costs, true, true)
	rsrc_nodes_to = Helper.put_rsrc($Control2/To, 32, {"titanium":0})
	metal = "titanium"
	energy_cost = 12000
	difficulty = 0.5
	refresh()
	$Control/Switch.visible = true

func _on_platinum_pressed(_name:String, dict:Dictionary):
	reset_poses(_name, dict)
	ratios = {"Pt":1000.0 / 195.084}
	atom_costs = {"Pt":0}
	rsrc_nodes_from = Helper.put_rsrc($Control2/ScrollContainer/From, 32, atom_costs, true, true)
	rsrc_nodes_to = Helper.put_rsrc($Control2/To, 32, {"platinum":0})
	metal = "platinum"
	energy_cost = 40000
	difficulty = 2.0
	refresh()
	$Control/Switch.visible = true

func _on_diamond_pressed(_name:String, dict:Dictionary):
	reset_poses(_name, dict)
	ratios = {"C":1000.0 / 12.011}
	atom_costs = {"C":0}
	rsrc_nodes_from = Helper.put_rsrc($Control2/ScrollContainer/From, 32, atom_costs, true, true)
	rsrc_nodes_to = Helper.put_rsrc($Control2/To, 32, {"diamond":0})
	metal = "diamond"
	energy_cost = 85000
	difficulty = 2.2
	refresh()
	$Control/Switch.visible = true

func _on_nanocrystal_pressed(_name:String, dict:Dictionary):
	reset_poses(_name, dict)
	ratios = {"Si":1000.0 / 28.085, "O":1000.0 / (15.999 * 2), "Na":1000 / 22.99}
	atom_costs = {"Si":0.0, "O":0.0, "Na":0.0}
	rsrc_nodes_from = Helper.put_rsrc($Control2/ScrollContainer/From, 32, atom_costs, true, true)
	rsrc_nodes_to = Helper.put_rsrc($Control2/To, 32, {"nanocrystal":0})
	metal = "nanocrystal"
	energy_cost = 1330000
	difficulty = 2.9
	refresh()
	$Control/Switch.visible = true

func _on_mythril_pressed(_name:String, dict:Dictionary):
	reset_poses(_name, dict)
	ratios = {"W":1000 / (183.84 * 2.0), "Os":1000 / 190.23, "Ta":1000 / (180.95 * 2.0)}
	atom_costs = {"W":0.0, "Os":0.0, "Ta":0.0}
	rsrc_nodes_from = Helper.put_rsrc($Control2/ScrollContainer/From, 32, atom_costs, true, true)
	rsrc_nodes_to = Helper.put_rsrc($Control2/To, 32, {"mythril":0})
	metal = "mythril"
	energy_cost = 8970000
	difficulty = 4.8
	refresh()
	$Control/Switch.visible = true

func refresh():
	for btn in $ScrollContainer/VBoxContainer.get_children():
		btn.visible = not btn.name in ["nanocrystal", "mythril", "quillite"] or game.science_unlocked.has("AMM")
	if tf:
		$Title.text = "%s %s" % [Helper.format_num(tile_num), tr("ATOM_MANIPULATOR_NAME_S").to_lower(),]
		var max_star_temp = game.get_max_star_prop(game.c_s, "temperature")
		au_int = 12000.0 * game.galaxy_data[game.c_g].B_strength * max_star_temp
		au_mult = 1.0 + au_int
	else:
		tile_num = 1
		$Title.text = tr("ATOM_MANIPULATOR_NAME")
		obj = game.tile_data[game.c_t]
		au_int = obj.get("aurora", 0.0)
		au_mult = au_int + 1.0
	path_2_value = obj.bldg.path_2_value * Helper.get_IR_mult(Building.ATOM_MANIPULATOR)
	$Control/EnergyCostText.text = Helper.format_num(round(energy_cost * $Control/HSlider.value / au_mult / path_2_value)) + "  [img]Graphics/Icons/help.png[/img]"
	if au_mult > 1:
		$Control/EnergyCostText.help_text = ("[aurora au_int=%s]" % au_int) + tr("MORE_ENERGY_EFFICIENT") % Helper.clever_round(au_mult)
	else:
		$Control/EnergyCostText.help_text = tr("AMN_TIP")
	$Control3.visible = obj.bldg.has("qty") and reaction == obj.bldg.reaction
	$Control.visible = not $Control3.visible and reaction != ""
	$Transform3D.visible = $Control3.visible or $Control.visible
	refresh_time_icon()
	$Control/TimeCostText.text = Helper.time_to_str(difficulty * $Control/HSlider.value / obj.bldg.path_1_value / tile_num / Helper.get_IR_mult(Building.ATOM_MANIPULATOR) / game.u_i.time_speed / obj.get("time_speed_bonus", 1.0))
	for reaction_name in reactions:
		var disabled:bool = false
		for atom in reactions[reaction_name].atoms:
			if game.atoms.has(atom) and game.atoms[atom] == 0:
				disabled = true
				break
		if reaction_name == "stone":
			disabled = disabled and Helper.get_sum_of_dict(game.stone) == 0 and (not obj.bldg.has("qty") or not obj.bldg.reaction == reaction_name)
		else:
			disabled = disabled and game[reactions[reaction_name].MM][reaction_name] == 0 and (not obj.bldg.has("qty") or not obj.bldg.reaction == reaction_name)
		$ScrollContainer/VBoxContainer.get_node(reaction_name).disabled = disabled
	if reaction == "":
		return
	set_process($Control3.visible)
	var max_value:float = 0.0
	if atom_to_MM:
		for atom in ratios:
			if ratios[atom] == 0 or not game.atoms.has(atom):
				continue
			var max_value2 = game.atoms[atom] / ratios[atom]
			if max_value2 < max_value or max_value == 0.0:
				max_value = max_value2
	else:
		if metal == "stone":
			max_value = Helper.get_sum_of_dict(game.stone)
		else:
			max_value = game[MM][metal]
	$Control/HSlider.max_value = min(game.energy * au_mult / energy_cost * path_2_value, max_value)
	$Control/HSlider.step = int($Control/HSlider.max_value / 500)
	$Control/HSlider.visible = not is_equal_approx($Control/HSlider.max_value, 0)
	if $Control3.visible:
		set_text_to_white()
		$Transform3D.visible = true
		$Transform3D.text = "%s (G)" % tr("STOP")
	else:
		$Transform3D.visible = $Control/HSlider.max_value != 0 and not obj.bldg.has("qty")
		$Transform3D.text = "%s (G)" % tr("TRANSFORM")

func reset_poses(_name:String, dict:Dictionary):
	for btn in $ScrollContainer/VBoxContainer.get_children():
		btn["theme_override_colors/font_color"] = null
		btn["theme_override_colors/font_color_hover"] = null
		btn["theme_override_colors/font_color_pressed"] = null
		btn["theme_override_colors/font_color_disabled"] = null
	$ScrollContainer/VBoxContainer.get_node(_name)["theme_override_colors/font_color"] = Color(0, 1, 1, 1)
	$ScrollContainer/VBoxContainer.get_node(_name)["theme_override_colors/font_color_hover"] = Color(0, 1, 1, 1)
	$ScrollContainer/VBoxContainer.get_node(_name)["theme_override_colors/font_color_pressed"] = Color(0, 1, 1, 1)
	$ScrollContainer/VBoxContainer.get_node(_name)["theme_override_colors/font_color_disabled"] = Color(0, 1, 1, 1)
	reaction = _name
	MM = dict.MM
	atom_to_MM = true
	$Control2.visible = true
	$Control2/ScrollContainer.position = Vector2(480, 240)
	$Control2/To.position = Vector2(772, 240)
	$Control3.visible = obj.bldg.has("qty") and obj.bldg.reaction == reaction
	$Control.visible = not $Control3.visible
	if $Control3.visible and not obj.bldg.atom_to_MM and reaction != "stone":
		_on_Switch_pressed(false)
	atom_costs.clear()
	for atom in dict.atoms:
		atom_costs[atom] = 0

func _on_Switch_pressed(refresh:bool = true):
	var pos = $Control2/To.position
	$Control2/To.position = $Control2/ScrollContainer.position
	$Control2/ScrollContainer.position = pos
	atom_to_MM = not atom_to_MM
	if refresh:
		_on_HSlider_value_changed($Control/HSlider.value)

func _on_HSlider_value_changed(value):
	var MM_dict = {}
	if metal == "stone":
		var sum = Helper.get_sum_of_dict(game.stone)
		for atom in atom_costs:
			if game.stone.has(atom):
				atom_costs[atom] = value * ratios[atom] * game.stone[atom] / sum if sum != 0 else 0
	else:
		for atom in atom_costs:
			atom_costs[atom] = value * ratios[atom]
	MM_dict[metal] = value
	rsrc_nodes_from = Helper.put_rsrc($Control2/ScrollContainer/From, 32, atom_costs, true, atom_to_MM)
	rsrc_nodes_to = Helper.put_rsrc($Control2/To, 32, MM_dict, true, not atom_to_MM)
	refresh()

func _on_Transform_pressed():
	if obj.bldg.has("qty"):
		set_process(false)
		var reaction_info = get_reaction_info(obj)
		var MM_value = reaction_info.MM_value
		var progress = reaction_info.progress
		var rsrc_to_add:Dictionary = atom_costs.duplicate(true)
		if obj.bldg.atom_to_MM:
			for atom in rsrc_to_add:
				rsrc_to_add[atom] = max(0, obj.bldg.qty - MM_value) * ratios[atom]
			rsrc_to_add[metal] = MM_value
		else:
			var sum = Helper.get_sum_of_dict(obj.bldg.AMN_stone)
			if sum != 0:
				for atom in rsrc_to_add:
					if obj.bldg.AMN_stone.has(atom):
						rsrc_to_add[atom] = MM_value * ratios[atom] * obj.bldg.AMN_stone[atom] / sum
			if metal == "stone":
				rsrc_to_add[metal] = {}
				for atom in rsrc_to_add:
					if atom == "stone":
						continue
					if obj.bldg.AMN_stone.has(atom) and sum != 0:
						rsrc_to_add[metal][atom] = max(0, obj.bldg.qty - MM_value) * obj.bldg.AMN_stone[atom] / sum
			else:
				rsrc_to_add[metal] = max(0, obj.bldg.qty - MM_value)
		rsrc_to_add.energy = round((1 - progress) * energy_cost / au_mult * obj.bldg.qty / path_2_value)
		game.add_resources(rsrc_to_add)
		obj.bldg.erase("qty")
		obj.bldg.erase("start_date")
		obj.bldg.erase("reaction")
		obj.bldg.erase("AMN_stone")
		$Control.visible = true
		$Control3.visible = false
		$Transform3D.text = "%s (G)" % tr("TRANSFORM")
		refresh_time_icon()
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
		rsrc_to_deduct.energy = round(energy_cost * rsrc / au_mult / path_2_value)
		if not game.check_enough(rsrc_to_deduct):
			game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)
			return
		obj.bldg.qty = rsrc
		obj.bldg.AMN_stone = game.stone.duplicate(true)
		obj.bldg.start_date = Time.get_unix_time_from_system()
		obj.bldg.reaction = reaction
		obj.bldg.atom_to_MM = atom_to_MM
		game.deduct_resources(rsrc_to_deduct)
		set_text_to_white()
		set_process(true)
		$Control.visible = false
		$Control3.visible = true
		$Transform3D.text = "%s (G)" % tr("STOP")
		refresh_time_icon()
	game.HUD.refresh()

func set_text_to_white():
	for hbox in rsrc_nodes_from:
		hbox.rsrc.get_node("Text")["theme_override_colors/font_color"] = Color.WHITE
	for hbox in rsrc_nodes_to:
		hbox.rsrc.get_node("Text")["theme_override_colors/font_color"] = Color.WHITE

func refresh_time_icon():
	for r in $ScrollContainer/VBoxContainer.get_children():
		var icon = r.get_node("Icon")
		icon.visible = obj.bldg.has("reaction") and r.name == obj.bldg.reaction

func _process(delta):
	if obj == null or obj.is_empty():
		_on_close_button_pressed()
		set_process(false)
		return
	if not obj.bldg.has("start_date") or not visible:
		set_process(false)
		return
	var reaction_info = get_reaction_info(obj)
	#MM produced or MM used
	var MM_value = reaction_info.MM_value
	$Control3/TextureProgressBar.value = reaction_info.progress
	var MM_dict = {}
	var atom_dict:Dictionary = atom_costs.duplicate(true)
	if obj.bldg.atom_to_MM:
		MM_dict[metal] = MM_value
		for atom in atom_dict:
			atom_dict[atom] = Helper.clever_round(max(0, obj.bldg.qty - MM_value) * ratios[atom])
	else:
		MM_dict[metal] = max(0, obj.bldg.qty - MM_value)
		if metal == "stone":
			var sum = Helper.get_sum_of_dict(obj.bldg.AMN_stone)
			for atom in atom_costs:
				if obj.bldg.AMN_stone.has(atom) and sum != 0:
					atom_dict[atom] = Helper.clever_round(MM_value * ratios[atom] * obj.bldg.AMN_stone[atom] / sum)
		else:
			for atom in atom_dict:
				atom_dict[atom] = Helper.clever_round(MM_value * ratios[atom])
	for hbox in rsrc_nodes_from:
		hbox.rsrc.get_node("Text").text = "%s mol" % [Helper.format_num(atom_dict[hbox.name])]
	for hbox in rsrc_nodes_to:
		hbox.rsrc.get_node("Text").text = "%s kg" % [Helper.format_num(round(MM_dict[hbox.name]))]
	#Helper.put_rsrc($Control2/ScrollContainer/From, 32, atom_dict)
	#Helper.put_rsrc($Control2/To, 32, MM_dict)
	$Control3/TimeRemainingText.text = Helper.time_to_str(max(0, difficulty * (obj.bldg.qty - MM_value) / obj.bldg.path_1_value / tile_num / Helper.get_IR_mult(Building.ATOM_MANIPULATOR) / game.u_i.time_speed / obj.get("time_speed_bonus", 1.0)))

func get_reaction_info(obj):
	var MM_value:float = clamp((Time.get_unix_time_from_system() - obj.bldg.start_date) / difficulty * obj.bldg.path_1_value * tile_num * Helper.get_IR_mult(Building.ATOM_MANIPULATOR) * game.u_i.time_speed * obj.get("time_speed_bonus", 1.0), 0, obj.bldg.qty)
	return {"MM_value":MM_value, "progress":MM_value / obj.bldg.qty}

func _on_EnergyCostText_mouse_entered():
	if au_mult > 1:
		game.show_tooltip(("[aurora au_int=%s]" % au_int) + tr("MORE_ENERGY_EFFICIENT") % Helper.clever_round(au_mult))


func _on_EnergyCostText_mouse_exited():
	if au_mult > 1:
		game.hide_tooltip()
