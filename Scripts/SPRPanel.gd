extends "Panel.gd"

var obj:Dictionary
var tile_num
var tf:bool = false
var atom_to_p:bool = true#MM: material or metal
var difficulty:float#Amount of time per unit of atom/metal
var energy_cost:float
var resource_selected:String = ""
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
								"Al":{"Z":13, "energy_cost":55, "difficulty":0.01},
								"Si":{"Z":14, "energy_cost":30, "difficulty":0.005},
								"Ti":{"Z":22, "energy_cost":60, "difficulty":0.02},
								"Fe":{"Z":26, "energy_cost":40, "difficulty":0.006},
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
	set_polygon($GUI.size, $GUI.position)
	$Panel.hide()
	$Title.text = tr("SUBATOMIC_PARTICLE_REACTOR_NAME")
	$Desc.text = tr("REACTIONS_PANEL_DESC")
	for _name in reactions:
		var btn = preload("res://Scenes/ReactionButton.tscn").instantiate()
		btn.get_node("TextureRect").texture = load("res://Graphics/Atoms/%s.png" % _name)
		btn.name = _name
		btn.custom_minimum_size = Vector2.ONE * 75.0
		btn.mouse_entered.connect(show_recipe_tooltip.bind(_name))
		btn.mouse_exited.connect(game.hide_tooltip)
		btn.pressed.connect(_on_Atom_pressed.bind(_name))
		btn.get_node("Label").label_settings.font_size = 12
		$ScrollContainer/GridContainer.add_child(btn)

func show_recipe_tooltip(rsrc:String):
	if rsrc in ["Ta", "W", "Os"] and not game.science_unlocked.has("EMM"):
		game.show_tooltip(tr("LOCKED"))
	else:
		game.show_tooltip(tr("%s_NAME" % rsrc.to_upper()))

func _on_Atom_pressed(_name:String):
	reset_poses(_name, reactions[_name].Z)
	energy_cost = reactions[_name].energy_cost
	difficulty = reactions[_name].difficulty
	$Panel.show()
	refresh()

func refresh():
	set_process(true)
	for btn in $ScrollContainer/GridContainer.get_children():
		if btn.name in ["Ta", "W", "Os"] and not game.science_unlocked.has("EMM"):
			btn.modulate = Color(0.2, 0.2, 0.2)
			btn.disabled = true
		else:
			btn.modulate = Color.WHITE
			btn.disabled = false
	if tf:
		$Title.text = "%s %s" % [Helper.format_num(tile_num), tr("SUBATOMIC_PARTICLE_REACTOR_NAME_S").to_lower(),]
		var max_star_temp = game.get_max_star_prop(game.c_s, "temperature")
		au_int = 12000.0 * game.galaxy_data[game.c_g].B_strength * max_star_temp
		au_mult = 1.0 + au_int
	else:
		$Title.text = tr("SUBATOMIC_PARTICLE_REACTOR_NAME")
		tile_num = 1
		obj = game.tile_data[game.c_t]
		au_int = obj.get("aurora", 0.0)
		au_mult = au_int + 1.0
	refresh_time_icon()
	path_2_value = obj.bldg.path_2_value * Helper.get_IR_mult(Building.SUBATOMIC_PARTICLE_REACTOR)
	for reaction_name in reactions:
		if $ScrollContainer/GridContainer.get_node(reaction_name).disabled:
			continue
		var disabled:bool = false
		if is_zero_approx(game.particles.subatomic_particles):
			disabled = true
		disabled = disabled and is_zero_approx(game.atoms[reaction_name]) and (not obj.bldg.has("qty") or not obj.bldg.reaction == reaction_name)
		$ScrollContainer/GridContainer.get_node(reaction_name).disabled = disabled
		if disabled:
			$ScrollContainer/GridContainer.get_node(reaction_name).modulate = Color(0.4, 0.4, 0.4)
		else:
			$ScrollContainer/GridContainer.get_node(reaction_name).modulate = Color.WHITE
	if resource_selected == "":
		return
	var max_slider_value = get_max_slider_value()
	var rsrc_value = $Panel/Control/HSlider.value * max_slider_value
	$Panel/Control/EnergyCostText.text = Helper.format_num(round(energy_cost * rsrc_value / au_mult / game.u_i.charge / path_2_value)) + "  [img]Graphics/Icons/help.png[/img]"
	if au_mult > 1:
		$Panel/Control/EnergyCostText.help_text = ("[aurora au_int=%s]" % au_int) + tr("MORE_ENERGY_EFFICIENT") % Helper.clever_round(au_mult)
	else:
		$Panel/Control/EnergyCostText.help_text = tr("AMN_TIP")
	$Panel/Control/TimeCostText.text = Helper.time_to_str(difficulty * rsrc_value / obj.bldg.path_1_value / Helper.get_IR_mult(Building.SUBATOMIC_PARTICLE_REACTOR) / tile_num / game.u_i.time_speed / obj.get("time_speed_bonus", 1.0) / game.u_i.charge)
	$Panel/ReactionInProgress.visible = obj.bldg.has("qty") and resource_selected == obj.bldg.reaction
	$Panel/Control.visible = not $Panel/ReactionInProgress.visible and resource_selected != ""
	$Panel/Transform.visible = $Panel/ReactionInProgress.visible or $Panel/Control.visible
	$Panel/Control/HSlider.visible = max_slider_value != 0
	if $Panel/ReactionInProgress.visible:
		set_text_to_white()
		$Panel/Transform.visible = true
		$Panel/Transform.text = "%s (G)" % tr("STOP")
	else:
		$Panel/Transform.visible = max_slider_value != 0 and not obj.bldg.has("qty")
		$Panel/Transform.text = "%s (G)" % tr("TRANSFORM")
	var atom_dict = {}
	var p_costs = {"subatomic_particles":rsrc_value}
	for particle in p_costs:
		p_costs[particle] *= Z
	atom_dict[resource_selected] = rsrc_value
	rsrc_nodes_from = Helper.put_rsrc($Panel/Control2/ScrollContainer/From, 40, atom_dict, true, atom_to_p)
	rsrc_nodes_to = Helper.put_rsrc($Panel/Control2/To, 40, p_costs, true, not atom_to_p)

func get_max_slider_value():
	var max_value:float = 0.0
	if atom_to_p:
		max_value = game.atoms[resource_selected]
	else:
		var max_value2 = game.particles.subatomic_particles / Z
		if max_value2 < max_value or max_value == 0.0:
			max_value = max_value2
	return min(game.energy * au_mult * game.u_i.charge / energy_cost * path_2_value, max_value)

func reset_poses(_name:String, _Z:int):
	resource_selected = _name
	Z = _Z
	atom_to_p = true
	$Panel/Control2/ScrollContainer.position = Vector2(92.0, 128.0)
	$Panel/Control2/To.position = Vector2(376.0, 132.0)
	$Panel/Control2.visible = true
	$Panel/ReactionInProgress.visible = obj.bldg.has("qty") and obj.bldg.reaction == resource_selected
	$Panel/Control.visible = not $Panel/ReactionInProgress.visible
	if $Panel/ReactionInProgress.visible and not obj.bldg.atom_to_p:
		_on_Switch_pressed(false)

func _on_Switch_pressed(refresh:bool = true):
	var pos = $Panel/Control2/To.position
	$Panel/Control2/To.position = $Panel/Control2/ScrollContainer.position
	$Panel/Control2/ScrollContainer.position = pos
	atom_to_p = not atom_to_p
	if refresh:
		_on_HSlider_value_changed($Panel/Control/HSlider.value)

func _on_HSlider_value_changed(value):
	#rsrc_nodes_from = Helper.put_rsrc($Panel/Control2/ScrollContainer/From, 32, atom_dict, true, atom_to_p)
	#rsrc_nodes_to = Helper.put_rsrc($Panel/Control2/To, 32, p_costs, true, not atom_to_p)
	refresh()

func _on_Transform_pressed():
	if obj.bldg.has("qty"):
		var reaction_info = get_reaction_info(obj)
		var MM_value = reaction_info.MM_value
		var progress = reaction_info.progress
		var rsrc_to_add:Dictionary
		var num
		if obj.bldg.atom_to_p:
			rsrc_to_add[resource_selected] = max(0, obj.bldg.qty - MM_value)
			num = MM_value * Z
		else:
			rsrc_to_add[resource_selected] = MM_value
			num = max(0, obj.bldg.qty - MM_value) * Z
		rsrc_to_add.subatomic_particles = num
		rsrc_to_add.energy = round((1 - progress) * energy_cost / au_mult / game.u_i.charge * obj.bldg.qty / path_2_value)
		game.add_resources(rsrc_to_add)
		obj.bldg.erase("qty")
		obj.bldg.erase("start_date")
		obj.bldg.erase("reaction")
		obj.bldg.erase("difficulty")
		$Panel/Control.visible = true
		$Panel/ReactionInProgress.visible = false
		refresh_time_icon()
#		$Panel/Transform.text = "%s (G)" % tr("TRANSFORM")
		#_on_HSlider_value_changed($Panel/Control/HSlider.value)
	else:
		var rsrc_value = $Panel/Control/HSlider.value * get_max_slider_value()
		if rsrc_value == 0.0:
			return
		var rsrc_to_deduct = {}
		if atom_to_p:
			rsrc_to_deduct[resource_selected] = rsrc_value
		else:
			rsrc_to_deduct = {"subatomic_particles":rsrc_value * Z}
		rsrc_to_deduct.energy = round(energy_cost * rsrc_value / au_mult / game.u_i.charge / path_2_value)
		if not game.check_enough(rsrc_to_deduct):
			game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)
			return
		game.deduct_resources(rsrc_to_deduct)
		obj.bldg.qty = rsrc_value
		obj.bldg.start_date = Time.get_unix_time_from_system()
		obj.bldg.reaction = resource_selected
		obj.bldg.difficulty = difficulty
		obj.bldg.atom_to_p = atom_to_p
		if not tf:
			for i in len(game.view.obj.rsrcs):
				if i == game.c_t:
					game.view.obj.rsrcs[i].set_icon_texture(load("res://Graphics/Atoms/%s.png" % resource_selected))
					break
		$Panel/Control.visible = false
		$Panel/ReactionInProgress.visible = true
		refresh_time_icon()
#		$Panel/Transform.text = "%s (G)" % tr("STOP")
	refresh()
	game.HUD.refresh()

func _process(delta):
	if obj == null or obj.is_empty():
		_on_close_button_pressed()
		return
	for btn in $ScrollContainer/GridContainer.get_children():
		btn.get_node("Label").text = Helper.format_num(game.atoms[btn.name], true)
	$SubatomicParticles.text = Helper.format_num(game.particles.subatomic_particles, true) + " mol"
	if not obj.bldg.has("start_date") or not visible or obj.bldg.reaction != resource_selected:
		return
	var reaction_info = get_reaction_info(obj)
	#MM produced or MM used
	var MM_value = reaction_info.MM_value
	$Panel/ReactionInProgress/TextureProgressBar.value = reaction_info.progress
	var MM_dict = {}
	var atom_dict:Dictionary = {}
	var num
	if obj.bldg.atom_to_p:
		num = MM_value * Z
		atom_dict[resource_selected] = max(0, obj.bldg.qty - MM_value)
	else:
		num = max(0, obj.bldg.qty - MM_value) * Z
		atom_dict[resource_selected] = MM_value
	MM_dict = {"subatomic_particles":num}
	for hbox in rsrc_nodes_from:
		hbox.rsrc.show_available = false
		hbox.rsrc.rsrcs_required = atom_dict[hbox.name]
	for hbox in rsrc_nodes_to:
		hbox.rsrc.show_available = false
		hbox.rsrc.rsrcs_required = MM_dict[hbox.name]
	$Panel/ReactionInProgress/TimeRemainingText.text = Helper.time_to_str(max(0, difficulty * (obj.bldg.qty - MM_value) / obj.bldg.path_1_value / Helper.get_IR_mult(Building.SUBATOMIC_PARTICLE_REACTOR) / tile_num / game.u_i.time_speed / obj.get("time_speed_bonus", 1.0) / game.u_i.charge))

func refresh_time_icon():
	for r in $ScrollContainer/GridContainer.get_children():
		if obj.bldg.has("reaction") and r.name == obj.bldg.reaction:
			r.get_node("Time").show()
		else:
			r.get_node("Time").hide()

func _on_EnergyCostText_mouse_entered():
	if au_mult > 1:
		game.show_tooltip(("[aurora au_int=%s]" % au_int) + tr("MORE_ENERGY_EFFICIENT") % Helper.clever_round(au_mult))

func get_reaction_info(obj):
	var MM_value:float = clamp((Time.get_unix_time_from_system() - obj.bldg.start_date) / difficulty * obj.bldg.path_1_value * tile_num * Helper.get_IR_mult(Building.SUBATOMIC_PARTICLE_REACTOR) * game.u_i.time_speed * obj.get("time_speed_bonus", 1.0) * game.u_i.charge, 0, obj.bldg.qty)
	return {"MM_value":MM_value, "progress":MM_value / obj.bldg.qty}

func _on_EnergyCostText_mouse_exited():
	if au_mult > 1:
		game.hide_tooltip()

func set_text_to_white():
	for hbox in rsrc_nodes_from:
		hbox.rsrc.get_node("Text")["theme_override_colors/font_color"] = Color.WHITE
	for hbox in rsrc_nodes_to:
		hbox.rsrc.get_node("Text")["theme_override_colors/font_color"] = Color.WHITE
