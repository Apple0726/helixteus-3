extends "Panel.gd"

var obj:Dictionary
var tile_num
var tf:bool = false
var atom_to_p:bool = true#MM: material or metal
var difficulty:float#Amount of time per unit of atom/metal
var energy_cost:float
var reaction:String = ""
var au_mult:float
var Z:int
var atom_costs:Dictionary = {}
var reactions:Dictionary = {	"H":{"Z":1, "energy_cost":2, "difficulty":0.001},
								"He":{"Z":2, "energy_cost":4, "difficulty":0.0015},
								"O":{"Z":8, "energy_cost":10, "difficulty":0.002},
								"Ne":{"Z":10, "energy_cost":500, "difficulty":2},
								"Si":{"Z":14, "energy_cost":300, "difficulty":0.005},
								"Fe":{"Z":26, "energy_cost":200, "difficulty":0.01},
								"Xe":{"Z":54, "energy_cost":300000, "difficulty":40},
								"Pu":{"Z":94, "energy_cost":14000000000, "difficulty":8000},
}

func _ready():
	set_process(false)
	set_polygon(rect_size)
	$Title.text = tr("SPR_NAME")
	$Desc.text = tr("REACTIONS_PANEL_DESC")
	for _name in reactions:
		var btn = Button.new()
		btn.name = _name
		btn.rect_min_size.y = 30
		btn.expand_icon = true
		btn.text = tr("%s_NAME" % _name.to_upper())
		btn.connect("pressed", self, "_on_Atom_pressed", [_name])
		$ScrollContainer/VBoxContainer.add_child(btn)
	$Control/Max.visible = false

func _on_Atom_pressed(_name:String):
	reset_poses(_name, reactions[_name].Z)
	energy_cost = reactions[_name].energy_cost
	difficulty = reactions[_name].difficulty
	refresh()

func refresh():
	if tf:
		var max_star_temp = game.get_max_star_prop(game.c_s, "temperature")
		au_mult = 1 + pow(12000.0 * game.galaxy_data[game.c_g].B_strength * max_star_temp, Helper.get_AIE())
	else:
		tile_num = 1
		obj = game.tile_data[game.c_t]
		au_mult = Helper.get_au_mult(obj)
	if au_mult > 1:
		$Control/EnergyCostText["custom_colors/font_color"] = Color.yellow
	else:
		$Control/EnergyCostText["custom_colors/font_color"] = Color.white
	$Control/EnergyCostText.text = Helper.format_num(round(energy_cost * tile_num * $Control/HSlider.value / au_mult / game.u_i.charge))
	$Control/TimeCostText.text = Helper.time_to_str(difficulty * $Control/HSlider.value * 1000 / obj.bldg.path_1_value / Helper.get_IR_mult("SPR") / tile_num / game.u_i.time_speed)
	$Control3.visible = obj.bldg.has("qty") and reaction == obj.bldg.reaction
	$Control.visible = not $Control3.visible and reaction != ""
	for reaction_name in reactions:
		var disabled:bool = false
		if game.particles.proton == 0 or game.particles.neutron == 0 or game.particles.electron == 0:
			disabled = true
		disabled = disabled and game.atoms[reaction_name] == 0 and (not obj.bldg.has("qty") or not obj.bldg.reaction == reaction_name)
		$ScrollContainer/VBoxContainer.get_node(reaction_name).disabled = disabled
	refresh_icon()
	if reaction == "":
		return
	set_process($Control3.visible)
	var max_value:float = 0.0
	$Control/Max.visible = atom_to_p
	if atom_to_p:
		max_value = game.atoms[reaction]
	else:
		for particle in game.particles:
			var max_value2 = game.particles[particle] / Z
			if max_value2 < max_value or max_value == 0.0:
				max_value = max_value2
	$Control/HSlider.max_value = max_value
	#$Control/HSlider.step = int(max_value / 100.0)
	$Control/HSlider.visible = $Control/HSlider.max_value != 0
	if $Control3.visible:
		$Transform.visible = true
		$Transform.text = "%s (G)" % tr("STOP")
	else:
		$Transform.visible = $Control/HSlider.max_value != 0 and not obj.bldg.has("qty")
		$Transform.text = "%s (G)" % tr("TRANSFORM")
	var value = $Control/HSlider.value
	var atom_dict = {}
	var p_costs = {"proton":value, "neutron":value, "electron":value}
	for particle in p_costs:
		p_costs[particle] *= Z
	atom_dict[reaction] = value
	Helper.put_rsrc($Control2/ScrollContainer/From, 32, atom_dict, true, atom_to_p)
	Helper.put_rsrc($Control2/To, 32, p_costs, true, not atom_to_p)

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
	#atom_to_p = true
	$Control2.visible = true
	#$Control2/From.rect_position = Vector2(480, 240)
	#$Control2/To.rect_position = Vector2(772, 240)
	$Control3.visible = obj.bldg.has("qty") and obj.bldg.reaction == reaction
	$Control.visible = not $Control3.visible
	if $Control3.visible and not obj.bldg.atom_to_p:
		_on_Switch_pressed(false)
	#_on_HSlider_value_changed(0)

func _on_Switch_pressed(refresh:bool = true):
	var pos = $Control2/To.rect_position
	$Control2/To.rect_position = $Control2/ScrollContainer.rect_position
	$Control2/ScrollContainer.rect_position = pos
	atom_to_p = not atom_to_p
	if refresh:
		#_on_HSlider_value_changed($Control/HSlider.value)
		refresh()

func _on_HSlider_value_changed(value):
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
		rsrc_to_add.energy = round((1 - progress) * energy_cost * tile_num / au_mult / game.u_i.charge * obj.bldg.qty)
		game.add_resources(rsrc_to_add)
		obj.bldg.erase("qty")
		obj.bldg.erase("start_date")
		obj.bldg.erase("reaction")
		obj.bldg.erase("difficulty")
		$Control.visible = true
		$Control3.visible = false
		refresh_icon()
#		$Transform.text = "%s (G)" % tr("TRANSFORM")
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
		rsrc_to_deduct.energy = round(energy_cost * tile_num * rsrc / au_mult / game.u_i.charge)
		if not game.check_enough(rsrc_to_deduct):
			game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)
			return
		game.deduct_resources(rsrc_to_deduct)
		obj.bldg.qty = rsrc
		obj.bldg.start_date = OS.get_system_time_msecs()
		obj.bldg.reaction = reaction
		obj.bldg.difficulty = difficulty
		obj.bldg.atom_to_p = atom_to_p
		if not tf:
			for i in len(game.view.obj.rsrcs):
				if i == game.c_t:
					game.view.obj.rsrcs[i].get_node("TextureRect").texture = load("res://Graphics/Atoms/%s.png" % reaction)
					break
		set_process(true)
		$Control.visible = false
		$Control3.visible = true
		refresh_icon()
#		$Transform.text = "%s (G)" % tr("STOP")
	refresh()
	game.HUD.refresh()

func _process(delta):
	if not obj or obj.empty():
		_on_close_button_pressed()
		set_process(false)
		return
	if not obj.bldg.has("start_date") or not visible:
		set_process(false)
		return
	var reaction_info = get_reaction_info(obj)
	#MM produced or MM used
	var MM_value = reaction_info.MM_value
	$Control3/TextureProgress.value = reaction_info.progress
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
	Helper.put_rsrc($Control2/ScrollContainer/From, 32, atom_dict)
	Helper.put_rsrc($Control2/To, 32, MM_dict)
	$Control3/TimeRemainingText.text = Helper.time_to_str(max(0, difficulty * (obj.bldg.qty - MM_value) * 1000 / obj.bldg.path_1_value / Helper.get_IR_mult("SPR") / tile_num / game.u_i.time_speed))

func refresh_icon():
	for r in $ScrollContainer/VBoxContainer.get_children():
		r.icon = Data.time_icon if obj.bldg.has("reaction") and r.name == obj.bldg.reaction else null

func _on_Max_pressed():
	if atom_to_p:
		$Control/HSlider.value = min(game.energy * au_mult * game.u_i.charge / energy_cost / tile_num, game.atoms[reaction])

func _on_EnergyCostText_mouse_entered():
	if au_mult > 1:
		game.show_tooltip(tr("MORE_ENERGY_EFFICIENT") % Helper.clever_round(au_mult))

func get_reaction_info(obj):
	var MM_value:float = clamp((OS.get_system_time_msecs() - obj.bldg.start_date) / (1000 * difficulty) * obj.bldg.path_1_value * tile_num * Helper.get_IR_mult("SPR") * game.u_i.time_speed, 0, obj.bldg.qty)
	return {"MM_value":MM_value, "progress":MM_value / obj.bldg.qty}

func _on_EnergyCostText_mouse_exited():
	if au_mult > 1:
		game.hide_tooltip()
