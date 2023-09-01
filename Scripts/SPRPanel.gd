extends "Panel.gd"

var obj:Dictionary
var tile_num
var tf:bool = false
var atom_to_p:bool = true#MM: material or metal
var difficulty:float#Amount of time per unit of atom/metal
var energy_cost:float
var reaction:String = ""
var au_mult:float
var au_int:float
var Z:int
var atom_costs:Dictionary = {}
var reactions:Dictionary = {	"H":{"Z":1, "energy_cost":2, "difficulty":0.00005},
								"He":{"Z":2, "energy_cost":4, "difficulty":0.001},
								"C":{"Z":6, "energy_cost":7, "difficulty":0.0015},
								"O":{"Z":8, "energy_cost":10, "difficulty":0.002},
								"Ne":{"Z":10, "energy_cost":90, "difficulty":0.1},
								"Na":{"Z":11, "energy_cost":12, "difficulty":0.002},
								"Si":{"Z":14, "energy_cost":30, "difficulty":0.005},
								"Ti":{"Z":22, "energy_cost":60, "difficulty":0.02},
								"Fe":{"Z":26, "energy_cost":40, "difficulty":0.01},
								"Xe":{"Z":54, "energy_cost":3000000, "difficulty":4000},
								"Ta":{"Z":73, "energy_cost":100000, "difficulty":5},
								"W":{"Z":74, "energy_cost":100000, "difficulty":5},
								"Os":{"Z":76, "energy_cost":120000, "difficulty":5},
								"Pt":{"Z":78, "energy_cost":180000, "difficulty":6},
								"Pu":{"Z":94, "energy_cost":1.4e16, "difficulty":8e6},
}
var rsrc_nodes_from:Array
var rsrc_nodes_to:Array
var path_2_value:float = 1.0

func _ready():
	set_process(false)
	set_polygon(size)
	$Title.text = tr("SPR_NAME")
	$Desc.text = tr("REACTIONS_PANEL_DESC")
	for _name in reactions:
		var btn = preload("res://Scenes/AdvButton.tscn").instantiate()
		if _name in ["Ta", "W", "Os"] and not game.science_unlocked.has("AMM"):
			btn.visible = false
		btn.name = _name
		btn.custom_minimum_size.y = 30
		btn.button_text = tr("%s_NAME" % _name.to_upper())
		btn.connect("pressed",Callable(self,"_on_Atom_pressed").bind(_name))
		btn.icon_texture = Data.time_icon
		$ScrollContainer/VBoxContainer.add_child(btn)

func _on_Atom_pressed(_name:String):
	reset_poses(_name, reactions[_name].Z)
	energy_cost = reactions[_name].energy_cost
	difficulty = reactions[_name].difficulty
	refresh()

func refresh():
	for btn in $ScrollContainer/VBoxContainer.get_children():
		btn.visible = not btn.name in ["Ta", "W", "Os"] or game.science_unlocked.has("AMM")
	if tf:
		$Title.text = "%s %s" % [Helper.format_num(tile_num), tr("SPR_NAME_S").to_lower(),]
		var max_star_temp = game.get_max_star_prop(game.c_s, "temperature")
		au_int = 12000.0 * game.galaxy_data[game.c_g].B_strength * max_star_temp
		au_mult = 1.0 + au_int
	else:
		$Title.text = tr("SPR_NAME")
		tile_num = 1
		obj = game.tile_data[game.c_t]
		au_int = obj.aurora.au_int if obj.has("aurora") else 0.0
		au_mult = Helper.get_au_mult(obj)
	path_2_value = obj.bldg.path_2_value * Helper.get_IR_mult("SPR")
	$Control/EnergyCostText.text = Helper.format_num(round(energy_cost * $Control/HSlider.value / au_mult / game.u_i.charge / path_2_value)) + "  [img]Graphics/Icons/help.png[/img]"
	if au_mult > 1:
		$Control/EnergyCostText.help_text = ("[aurora au_int=%s]" % au_int) + tr("MORE_ENERGY_EFFICIENT") % Helper.clever_round(au_mult)
	else:
		$Control/EnergyCostText.help_text = tr("AMN_TIP")
	$Control/TimeCostText.text = Helper.time_to_str(difficulty * $Control/HSlider.value / obj.bldg.path_1_value / Helper.get_IR_mult("SPR") / tile_num / game.u_i.time_speed / game.u_i.charge)
	$Control3.visible = obj.bldg.has("qty") and reaction == obj.bldg.reaction
	$Control.visible = not $Control3.visible and reaction != ""
	$Transform3D.visible = $Control3.visible or $Control.visible
	for reaction_name in reactions:
		var disabled:bool = false
		if game.particles.proton == 0 or game.particles.neutron == 0 or game.particles.electron == 0:
			disabled = true
		disabled = disabled and game.atoms[reaction_name] == 0 and (not obj.bldg.has("qty") or not obj.bldg.reaction == reaction_name)
		$ScrollContainer/VBoxContainer.get_node(reaction_name).disabled = disabled
	refresh_time_icon()
	if reaction == "":
		return
	set_process($Control3.visible)
	var max_value:float = 0.0
	if atom_to_p:
		max_value = game.atoms[reaction]
	else:
		for particle in game.particles:
			if not particle in ["proton", "electron", "neutron"]:
				continue
			var max_value2 = game.particles[particle] / Z
			if max_value2 < max_value or max_value == 0.0:
				max_value = max_value2
	$Control/HSlider.max_value = min(game.energy * au_mult * game.u_i.charge / energy_cost * path_2_value, max_value)
	$Control/HSlider.step = $Control/HSlider.max_value / 500.0
	$Control/HSlider.visible = $Control/HSlider.max_value != 0
	if $Control3.visible:
		set_text_to_white()
		$Transform3D.visible = true
		$Transform3D.text = "%s (G)" % tr("STOP")
	else:
		$Transform3D.visible = $Control/HSlider.max_value != 0 and not obj.bldg.has("qty")
		$Transform3D.text = "%s (G)" % tr("TRANSFORM")
	var value = $Control/HSlider.value
	var atom_dict = {}
	var p_costs = {"proton":value, "neutron":value, "electron":value}
	for particle in p_costs:
		p_costs[particle] *= Z
	atom_dict[reaction] = value
	rsrc_nodes_from = Helper.put_rsrc($Control2/ScrollContainer/From, 32, atom_dict, true, atom_to_p)
	rsrc_nodes_to = Helper.put_rsrc($Control2/To, 32, p_costs, true, not atom_to_p)

func reset_poses(_name:String, _Z:int):
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
	Z = _Z
	atom_to_p = true
	$Control2/ScrollContainer.position = Vector2(480, 240)
	$Control2/To.position = Vector2(772, 240)
	$Control2.visible = true
	$Control3.visible = obj.bldg.has("qty") and obj.bldg.reaction == reaction
	$Control.visible = not $Control3.visible
	if $Control3.visible and not obj.bldg.atom_to_p:
		_on_Switch_pressed(false)

func _on_Switch_pressed(refresh:bool = true):
	var pos = $Control2/To.position
	$Control2/To.position = $Control2/ScrollContainer.position
	$Control2/ScrollContainer.position = pos
	atom_to_p = not atom_to_p
	if refresh:
		_on_HSlider_value_changed($Control/HSlider.value)

func _on_HSlider_value_changed(value):
	#rsrc_nodes_from = Helper.put_rsrc($Control2/ScrollContainer/From, 32, atom_dict, true, atom_to_p)
	#rsrc_nodes_to = Helper.put_rsrc($Control2/To, 32, p_costs, true, not atom_to_p)
	refresh()

func _on_Transform_pressed():
	if obj.bldg.has("qty"):
		set_process(false)
		var reaction_info = get_reaction_info(obj)
		var MM_value = reaction_info.MM_value
		var progress = reaction_info.progress
		var rsrc_to_add:Dictionary
		var num
		if obj.bldg.atom_to_p:
			rsrc_to_add[reaction] = max(0, obj.bldg.qty - MM_value)
			num = MM_value * Z
		else:
			rsrc_to_add[reaction] = MM_value
			num = max(0, obj.bldg.qty - MM_value) * Z
		rsrc_to_add.proton = num
		rsrc_to_add.neutron = num
		rsrc_to_add.electron = num
		rsrc_to_add.energy = round((1 - progress) * energy_cost / au_mult / game.u_i.charge * obj.bldg.qty / path_2_value)
		game.add_resources(rsrc_to_add)
		obj.bldg.erase("qty")
		obj.bldg.erase("start_date")
		obj.bldg.erase("reaction")
		obj.bldg.erase("difficulty")
		$Control.visible = true
		$Control3.visible = false
		refresh_time_icon()
#		$Transform3D.text = "%s (G)" % tr("TRANSFORM")
		#_on_HSlider_value_changed($Control/HSlider.value)
	else:
		var rsrc = $Control/HSlider.value
		if rsrc == 0:
			return
		var rsrc_to_deduct = {}
		if atom_to_p:
			rsrc_to_deduct[reaction] = rsrc
		else:
			rsrc_to_deduct = {"proton":rsrc * Z, "neutron":rsrc * Z, "electron":rsrc * Z}
		rsrc_to_deduct.energy = round(energy_cost * rsrc / au_mult / game.u_i.charge / path_2_value)
		if not game.check_enough(rsrc_to_deduct):
			game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)
			return
		game.deduct_resources(rsrc_to_deduct)
		obj.bldg.qty = rsrc
		obj.bldg.start_date = Time.get_unix_time_from_system()
		obj.bldg.reaction = reaction
		obj.bldg.difficulty = difficulty
		obj.bldg.atom_to_p = atom_to_p
		if not tf:
			for i in len(game.view.obj.rsrcs):
				if i == game.c_t:
					game.view.obj.rsrcs[i].set_icon_texture(load("res://Graphics/Atoms/%s.png" % reaction))
					break
		set_text_to_white()
		set_process(true)
		$Control.visible = false
		$Control3.visible = true
		refresh_time_icon()
#		$Transform3D.text = "%s (G)" % tr("STOP")
	refresh()
	game.HUD.refresh()

func _process(delta):
	if obj == null or obj.is_empty():
		_on_close_button_pressed()
		return
	if not obj.bldg.has("start_date") or not visible:
		set_process(false)
		return
	var reaction_info = get_reaction_info(obj)
	#MM produced or MM used
	var MM_value = reaction_info.MM_value
	$Control3/TextureProgressBar.value = reaction_info.progress
	var MM_dict = {}
	var atom_dict:Dictionary = {}
	var num
	if obj.bldg.atom_to_p:
		num = MM_value * Z
		atom_dict[reaction] = max(0, obj.bldg.qty - MM_value)
	else:
		num = max(0, obj.bldg.qty - MM_value) * Z
		atom_dict[reaction] = MM_value
	MM_dict = {"proton":num, "neutron":num, "electron":num}
	for hbox in rsrc_nodes_from:
		hbox.rsrc.get_node("Text").text = "%s mol" % [Helper.format_num(atom_dict[hbox.name], true)]
	for hbox in rsrc_nodes_to:
		hbox.rsrc.get_node("Text").text = "%s mol" % [Helper.format_num(MM_dict[hbox.name], true)]
	$Control3/TimeRemainingText.text = Helper.time_to_str(max(0, difficulty * (obj.bldg.qty - MM_value) / obj.bldg.path_1_value / Helper.get_IR_mult("SPR") / tile_num / game.u_i.time_speed / game.u_i.charge))

func refresh_time_icon():
	for r in $ScrollContainer/VBoxContainer.get_children():
		r.get_node("Icon").visible = obj.bldg.has("reaction") and r.name == obj.bldg.reaction

func _on_Max_pressed():
	if atom_to_p:
		$Control/HSlider.value = min(game.energy * au_mult * game.u_i.charge / energy_cost * path_2_value, game.atoms[reaction])

func _on_EnergyCostText_mouse_entered():
	if au_mult > 1:
		game.show_adv_tooltip(("[aurora au_int=%s]" % au_int) + tr("MORE_ENERGY_EFFICIENT") % Helper.clever_round(au_mult))

func get_reaction_info(obj):
	var MM_value:float = clamp((Time.get_unix_time_from_system() - obj.bldg.start_date) / difficulty * obj.bldg.path_1_value * tile_num * Helper.get_IR_mult("SPR") * game.u_i.time_speed * game.u_i.charge, 0, obj.bldg.qty)
	return {"MM_value":MM_value, "progress":MM_value / obj.bldg.qty}

func _on_EnergyCostText_mouse_exited():
	if au_mult > 1:
		game.hide_tooltip()

func set_text_to_white():
	for hbox in rsrc_nodes_from:
		hbox.rsrc.get_node("Text")["theme_override_colors/font_color"] = Color.WHITE
	for hbox in rsrc_nodes_to:
		hbox.rsrc.get_node("Text")["theme_override_colors/font_color"] = Color.WHITE
