extends "Panel.gd"

var obj:Dictionary
var tile_num
var tf:bool = false#whether this panel is opened by clicking a tile or a planet
var atom_to_rsrc:bool = true
var resource_selected:String = ""
var ratios:Dictionary
var difficulty:float#Amount of time per unit of atom/metal
var energy_cost:float
var au_mult:float
var rsrc_type:String
var atom_costs:Dictionary = {}
var reactions:Dictionary = {
	"stone":{"energy_cost":1.0, "difficulty":0.01, "atoms":["H", "He", "C", "N", "O", "F", "Ne", "Na", "Mg", "Al", "Si", "P", "S", "K", "Ca", "Ti", "Cr", "Mn", "Fe", "Co", "Ni", "Xe", "Ta", "W", "Os", "Ir", "U", "Np", "Pu"]},
	"iron":{"type":"mets", "atoms":{"Fe":1}, "energy_cost":30.0, "difficulty":0.03},
	"aluminium":{"type":"mets", "atoms":{"Al":1}, "energy_cost":30.0, "difficulty":0.03},
	"silicon":{"type":"mats", "atoms":{"Si":1}, "energy_cost":15.0, "difficulty":0.005},
	"titanium":{"type":"mets", "atoms":{"Ti":1}, "energy_cost":12000.0, "difficulty":0.5},
	"platinum":{"type":"mets", "atoms":{"Pt":1}, "energy_cost":40000.0, "difficulty":2.0},
	"diamond":{"type":"mets", "atoms":{"C":1}, "energy_cost":85000.0, "difficulty":2.2},
	"nanocrystal":{"type":"mets", "atoms":{"Si":1, "O":2, "Na":1}, "energy_cost":1.3e11, "difficulty":350.0},
	"quillite":{"type":"mats", "atoms":{"Si":1, "O":2, "Ne":1}, "energy_cost":1.9e11, "difficulty":250.0},
	"mythril":{"type":"mets", "atoms":{"W":2, "Os":1, "Ta":2}, "energy_cost":4.0e13, "difficulty":6000.0},
}
var rsrc_nodes_from:Array
var rsrc_nodes_to:Array
var path_2_value:float = 1.0

func _ready():
	set_polygon($GUI.size, $GUI.position)
	$Panel.hide()
	$Title.text = tr("ATOM_MANIPULATOR_NAME")
	$Desc.text = tr("REACTIONS_PANEL_DESC")
	for _name in reactions:
		var btn = preload("res://Scenes/ReactionButton.tscn").instantiate()
		if _name == "stone":
			btn.get_node("TextureRect").texture = Data.stone_icon
		elif reactions[_name].type == "mats":
			btn.get_node("TextureRect").texture = load("res://Graphics/Materials/%s.png" % _name)
		elif reactions[_name].type == "mets":
			btn.get_node("TextureRect").texture = load("res://Graphics/Metals/%s.png" % _name)
		btn.name = _name
		btn.custom_minimum_size = Vector2.ONE * 100.0
		btn.mouse_entered.connect(show_recipe_tooltip.bind(_name))
		btn.mouse_exited.connect(game.hide_tooltip)
		btn.pressed.connect(on_rsrc_pressed.bind(_name))
		btn.get_node("Label").label_settings.font_size = 14
		$ScrollContainer/GridContainer.add_child(btn)

func show_recipe_tooltip(rsrc:String):
	if (rsrc in ["platinum", "diamond"] and not game.science_unlocked.has("AMM")
	or rsrc in ["nanocrystal", "mythril", "quillite"] and not game.science_unlocked.has("EMM")):
		game.show_tooltip(tr("LOCKED"))
	else:
		game.show_tooltip(tr(rsrc.to_upper()))

func on_rsrc_pressed(rsrc:String):
	reset_poses(rsrc)
	resource_selected = rsrc
	_on_HSlider_value_changed($Panel/Control/HSlider.value)
	$Panel.show()

func refresh():
	set_process(true)
	for btn in $ScrollContainer/GridContainer.get_children():
		if (btn.name in ["platinum", "diamond"] and not game.science_unlocked.has("AMM")
			or btn.name in ["nanocrystal", "mythril", "quillite"] and not game.science_unlocked.has("EMM")):
			btn.modulate = Color(0.2, 0.2, 0.2)
			btn.disabled = true
		else:
			btn.modulate = Color.WHITE
			btn.disabled = false
	if tf:
		$Title.text = "%s %s" % [Helper.format_num(tile_num), tr("ATOM_MANIPULATOR_NAME_S").to_lower(),]
		au_mult = obj.get("EE_mult", 1.0)
	else:
		tile_num = 1
		$Title.text = tr("ATOM_MANIPULATOR_NAME")
		obj = game.tile_data[game.c_t]
		au_mult = obj.get("aurora", 0.0) + 1.0
	refresh_time_icon()
	path_2_value = obj.bldg.path_2_value * Helper.get_IR_mult(Building.ATOM_MANIPULATOR)
	for reaction_name in reactions:
		if $ScrollContainer/GridContainer.get_node(reaction_name).disabled:
			continue
		var disabled:bool = false
		for atom in reactions[reaction_name].atoms:
			if game.atoms.has(atom) and game.atoms[atom] == 0:
				disabled = true
				break
		if reaction_name == "stone":
			disabled = disabled and Helper.get_sum_of_dict(game.stone) == 0 and (not obj.bldg.has("qty") or not obj.bldg.reaction == reaction_name)
		else:
			disabled = disabled and game[reactions[reaction_name].type][reaction_name] == 0 and (not obj.bldg.has("qty") or not obj.bldg.reaction == reaction_name)
		$ScrollContainer/GridContainer.get_node(reaction_name).disabled = disabled
		if disabled:
			$ScrollContainer/GridContainer.get_node(reaction_name).modulate = Color(0.4, 0.4, 0.4)
		else:
			$ScrollContainer/GridContainer.get_node(reaction_name).modulate = Color.WHITE
	if resource_selected == "":
		return
	energy_cost = reactions[resource_selected].energy_cost
	difficulty = reactions[resource_selected].difficulty
	ratios.clear()
	atom_costs.clear()
	if resource_selected == "stone":
		for atom in Data.molar_mass:
			ratios[atom] = 1000.0 / Data.molar_mass[atom]
		for el in ratios:
			if game.stone.has(el):
				atom_costs[el] = 0
		$Panel/Control/Switch.hide()
		if atom_to_rsrc:
			_on_Switch_pressed()
	else:
		for atom in reactions[resource_selected].atoms:
			ratios[atom] = 1000.0 / (Data.molar_mass[atom] * reactions[resource_selected].atoms[atom])
			atom_costs[atom] = 0.0
		$Panel/Control/Switch.show()
	var max_slider_value = get_max_slider_value()
	var rsrc_value = $Panel/Control/HSlider.value * max_slider_value
	var MM_dict = {}
	if resource_selected == "stone":
		var sum = Helper.get_sum_of_dict(game.stone)
		for atom in atom_costs:
			if game.stone.has(atom):
				atom_costs[atom] = rsrc_value * ratios[atom] * game.stone[atom] / sum if sum != 0 else 0
	else:
		for atom in atom_costs:
			atom_costs[atom] = rsrc_value * ratios[atom]
	MM_dict[resource_selected] = rsrc_value
	rsrc_nodes_from = Helper.put_rsrc($Panel/Control2/ScrollContainer/From, 40, atom_costs, true, atom_to_rsrc)
	rsrc_nodes_to = Helper.put_rsrc($Panel/Control2/To, 40, MM_dict, true, not atom_to_rsrc)
	$Panel/Control/EnergyCostText.text = Helper.format_num(round(reactions[resource_selected].energy_cost * rsrc_value / au_mult / path_2_value)) + "  [img]Graphics/Icons/help.png[/img]"
	if au_mult > 1:
		$Panel/Control/EnergyCostText.help_text = ("[aurora au_int=%s]" % (au_mult - 1.0)) + tr("MORE_ENERGY_EFFICIENT") % Helper.clever_round(au_mult)
	else:
		$Panel/Control/EnergyCostText.help_text = tr("AMN_TIP")
	$Panel/ReactionInProgress.visible = obj.bldg.has("qty") and resource_selected == obj.bldg.reaction
	$Panel/Control.visible = not $Panel/ReactionInProgress.visible and resource_selected != ""
	$Panel/Transform.visible = $Panel/ReactionInProgress.visible or $Panel/Control.visible
	$Panel/Control/TimeCostText.text = Helper.time_to_str(difficulty * rsrc_value / obj.bldg.path_1_value / tile_num / Helper.get_IR_mult(Building.ATOM_MANIPULATOR) / game.u_i.time_speed / obj.get("time_speed_bonus", 1.0))
	$Panel/Control/HSlider.visible = not is_equal_approx(max_slider_value, 0.0)
	if $Panel/ReactionInProgress.visible:
		set_text_to_white()
		$Panel/Transform.visible = true
		$Panel/Transform.text = "%s (G)" % tr("STOP")
	else:
		$Panel/Transform.visible = $Panel/Control/HSlider.max_value != 0 and not obj.bldg.has("qty")
		$Panel/Transform.text = "%s (G)" % tr("TRANSFORM")

func get_max_slider_value():
	var max_value:float = 0.0
	if atom_to_rsrc:
		for atom in ratios:
			if ratios[atom] == 0 or not game.atoms.has(atom):
				continue
			var max_value2 = game.atoms[atom] / ratios[atom]
			if max_value2 < max_value or max_value == 0.0:
				max_value = max_value2
	else:
		if resource_selected == "stone":
			max_value = Helper.get_sum_of_dict(game.stone)
		else:
			max_value = game[rsrc_type][resource_selected]
	return min(game.energy * 0.999 * au_mult / reactions[resource_selected].energy_cost * path_2_value, max_value * 0.999)
	
func reset_poses(_name:String):
	resource_selected = _name
	if _name != "stone":
		rsrc_type = reactions[_name].type
	atom_to_rsrc = true
	$Panel/Control2.visible = true
	$Panel/Control2/ScrollContainer.position = Vector2(92.0, 128.0)
	$Panel/Control2/To.position = Vector2(376.0, 132.0)
	if not obj.is_empty():
		$Panel/ReactionInProgress.visible = obj.bldg.has("qty") and obj.bldg.reaction == resource_selected
		if $Panel/ReactionInProgress.visible and not obj.bldg.atom_to_rsrc and resource_selected != "stone":
			_on_Switch_pressed(false)
	$Panel/Control.visible = not $Panel/ReactionInProgress.visible

func _on_Switch_pressed(refresh:bool = true):
	var pos = $Panel/Control2/To.position
	$Panel/Control2/To.position = $Panel/Control2/ScrollContainer.position
	$Panel/Control2/ScrollContainer.position = pos
	atom_to_rsrc = not atom_to_rsrc
	if refresh:
		_on_HSlider_value_changed($Panel/Control/HSlider.value)

func _on_HSlider_value_changed(value): # value is always between 0.0 and 1.0
	refresh()

func _on_Transform_pressed():
	if obj.bldg.has("qty"):
		var reaction_info = get_reaction_info(obj)
		var MM_value = reaction_info.MM_value
		var progress = reaction_info.progress
		var rsrc_to_add:Dictionary = atom_costs.duplicate(true)
		if obj.bldg.atom_to_rsrc:
			for atom in rsrc_to_add:
				rsrc_to_add[atom] = max(0, obj.bldg.qty - MM_value) * ratios[atom]
			rsrc_to_add[resource_selected] = MM_value
		else:
			var sum = Helper.get_sum_of_dict(obj.bldg.AMN_stone)
			if sum != 0:
				for atom in rsrc_to_add:
					if obj.bldg.AMN_stone.has(atom):
						rsrc_to_add[atom] = MM_value * ratios[atom] * obj.bldg.AMN_stone[atom] / sum
			if resource_selected == "stone":
				rsrc_to_add[resource_selected] = {}
				for atom in rsrc_to_add:
					if atom == "stone":
						continue
					if obj.bldg.AMN_stone.has(atom) and sum != 0:
						rsrc_to_add[resource_selected][atom] = max(0, obj.bldg.qty - MM_value) * obj.bldg.AMN_stone[atom] / sum
			else:
				rsrc_to_add[resource_selected] = max(0, obj.bldg.qty - MM_value)
		rsrc_to_add.energy = round((1 - progress) * reactions[resource_selected].energy_cost / au_mult * obj.bldg.qty / path_2_value)
		game.add_resources(rsrc_to_add)
		obj.bldg.erase("qty")
		obj.bldg.erase("start_date")
		obj.bldg.erase("reaction")
		obj.bldg.erase("AMN_stone")
		$Panel/Control.visible = true
		$Panel/ReactionInProgress.visible = false
		$Panel/Transform.text = "%s (G)" % tr("TRANSFORM")
		refresh_time_icon()
		_on_HSlider_value_changed($Panel/Control/HSlider.value)
	else:
		var rsrc = $Panel/Control/HSlider.value
		if rsrc == 0:
			return
		rsrc *= get_max_slider_value()
		var rsrc_to_deduct = {}
		if atom_to_rsrc:
			rsrc_to_deduct = atom_costs.duplicate(true)
		else:
			rsrc_to_deduct[resource_selected] = rsrc
		rsrc_to_deduct.energy = round(reactions[resource_selected].energy_cost * rsrc / au_mult / path_2_value)
		if not game.check_enough(rsrc_to_deduct):
			game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)
			return
		obj.bldg.qty = rsrc
		obj.bldg.AMN_stone = game.stone.duplicate(true)
		obj.bldg.start_date = Time.get_unix_time_from_system()
		obj.bldg.reaction = resource_selected
		obj.bldg.atom_to_rsrc = atom_to_rsrc
		game.deduct_resources(rsrc_to_deduct)
		set_text_to_white()
		$Panel/Control.visible = false
		$Panel/ReactionInProgress.visible = true
		$Panel/Transform.text = "%s (G)" % tr("STOP")
		refresh_time_icon()
	game.HUD.refresh()

func set_text_to_white():
	for hbox in rsrc_nodes_from:
		hbox.rsrc.get_node("Text")["theme_override_colors/font_color"] = Color.WHITE
	for hbox in rsrc_nodes_to:
		hbox.rsrc.get_node("Text")["theme_override_colors/font_color"] = Color.WHITE

func refresh_time_icon():
	for r in $ScrollContainer/GridContainer.get_children():
		if obj.bldg.has("reaction") and r.name == obj.bldg.reaction:
			r.get_node("Time").show()
		else:
			r.get_node("Time").hide()

func _process(delta):
	if not visible:
		set_process(false)
		return
	if obj == null or obj.is_empty():
		_on_close_button_pressed()
		return
	for btn in $ScrollContainer/GridContainer.get_children():
		if btn.name == "stone":
			btn.get_node("Label").text = Helper.format_num(Helper.get_sum_of_dict(game.stone), true)
		else:
			btn.get_node("Label").text = Helper.format_num(game[reactions[btn.name].type][btn.name], true)
	if not obj.bldg.has("start_date") or not visible or obj.bldg.reaction != resource_selected:
		return
	var reaction_info = get_reaction_info(obj)
	#MM produced or MM used
	var MM_value = reaction_info.MM_value
	$Panel/ReactionInProgress/TextureProgressBar.value = reaction_info.progress
	var MM_dict = {}
	var atom_dict:Dictionary = atom_costs.duplicate(true)
	if obj.bldg.atom_to_rsrc:
		MM_dict[resource_selected] = MM_value
		for atom in atom_dict:
			atom_dict[atom] = Helper.clever_round(max(0, obj.bldg.qty - MM_value) * ratios[atom])
	else:
		MM_dict[resource_selected] = max(0, obj.bldg.qty - MM_value)
		if resource_selected == "stone":
			var sum = Helper.get_sum_of_dict(obj.bldg.AMN_stone)
			for atom in atom_costs:
				if obj.bldg.AMN_stone.has(atom) and sum != 0:
					atom_dict[atom] = Helper.clever_round(MM_value * ratios[atom] * obj.bldg.AMN_stone[atom] / sum)
		else:
			for atom in atom_dict:
				atom_dict[atom] = Helper.clever_round(MM_value * ratios[atom])
	for hbox in rsrc_nodes_from:
		hbox.rsrc.show_available = false
		hbox.rsrc.rsrcs_required = atom_dict[hbox.name]
	for hbox in rsrc_nodes_to:
		hbox.rsrc.show_available = false
		hbox.rsrc.rsrcs_required = MM_dict[hbox.name]
	$Panel/ReactionInProgress/TimeRemainingText.text = Helper.time_to_str(max(0, difficulty * (obj.bldg.qty - MM_value) / obj.bldg.path_1_value / tile_num / Helper.get_IR_mult(Building.ATOM_MANIPULATOR) / game.u_i.time_speed / obj.get("time_speed_bonus", 1.0)))

func get_reaction_info(obj):
	var MM_value:float = clamp((Time.get_unix_time_from_system() - obj.bldg.start_date) / difficulty * obj.bldg.path_1_value * tile_num * Helper.get_IR_mult(Building.ATOM_MANIPULATOR) * game.u_i.time_speed * obj.get("time_speed_bonus", 1.0), 0, obj.bldg.qty)
	return {"MM_value":MM_value, "progress":MM_value / obj.bldg.qty}

func _on_EnergyCostText_mouse_entered():
	if au_mult > 1:
		game.show_tooltip(("[aurora au_int=%s]" % (au_mult - 1.0)) + tr("MORE_ENERGY_EFFICIENT") % Helper.clever_round(au_mult))


func _on_EnergyCostText_mouse_exited():
	if au_mult > 1:
		game.hide_tooltip()
