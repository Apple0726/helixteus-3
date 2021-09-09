extends "Panel.gd"

var target:Dictionary = {}
var p_id:int
var star:Dictionary
var planet_btn_scene = preload("res://Scenes/PlanetData.tscn")
var additional_energy:float
var charging_time:float
var rekt_planet:bool = false
var rsrc:Dictionary
var c_s_g:int = -1

func _ready():
	set_process(false)
	set_polygon(rect_size)

func select_planet(p_i:Dictionary, id:int, btn):
	for child in $Scroll/Planets.get_children():
		if child != btn:
			child.pressed = false
	if star.has("charging_time"):
		return
	p_id = id
	target = p_i
	refresh_planet_info()

func refresh():
	if c_s_g != game.c_s_g:
		$Control.visible = false
		$StartCharging.visible = false
		c_s_g = game.c_s_g
	for child in $Scroll/Planets.get_children():
		$Scroll/Planets.remove_child(child)
		child.free()
	for i in len(game.planet_data):
		var p_i = game.planet_data[i]
		if p_i.empty():
			continue
		var btn = planet_btn_scene.instance()
		$Scroll/Planets.add_child(btn)
		btn.get_node("HBoxContainer/TextureRect").texture = game.planet_textures[p_i.type - 3]
		btn.get_node("HBoxContainer/Diameter").text = "%s km" % [p_i.size]
		btn.get_node("HBoxContainer/Distance").text = "%s AU" % [Helper.clever_round(p_i.distance / 569.25)]
		btn.get_node("TF").visible = p_i.has("tile_num")
		btn.get_node("MS").visible = p_i.has("MS")
		btn.connect("pressed", self, "select_planet", [p_i, i, btn])
		btn.get_node("TF").connect("mouse_entered", self, "on_TF_over")
		btn.get_node("TF").connect("mouse_exited", self, "on_mouse_exit")
		btn.get_node("MS").connect("mouse_entered", self, "on_MS_over")
		btn.get_node("MS").connect("mouse_exited", self, "on_mouse_exit")
	if star.has("charging_time"):
		target = game.planet_data[star.p_id]
		set_process(true)
		$Control.visible = false
		$Control2.visible = true
		$StartCharging.text = tr("CANCEL_CHARGING")
	else:
		set_process(false)
		rekt_planet = false
		$StartCharging.visible = false
		$Control2.visible = false
		$StartCharging.text = tr("START_CHARGING")

func on_TF_over():
	game.show_tooltip(tr("PLANET_TFED"))

func on_MS_over():
	game.show_tooltip(tr("PLANET_HAS_MS"))

func on_mouse_exit():
	game.hide_tooltip()

func refresh_planet_info():
	var value = $Control/HSlider.value
	var energy_cost = pow(target.size / 10000.0, 3) * 10000000000000000.0
	var time_base = energy_cost / star.luminosity / 1000000000.0
	charging_time = time_base * (1 - value)
	additional_energy = time_base * star.luminosity * value * 1000000000000.0
	$Control.visible = true
	$StartCharging.visible = true
	$Control/EnergyCost.text = Helper.format_num(additional_energy)
	if charging_time <= 1000:
		charging_time = 1000
	$Control/TimeCost.text = Helper.time_to_str(charging_time)
	var R = target.size * 1000.0 / 2#in meters
	var surface_volume = get_sph_V(R, R - target.crust_start_depth)#in m^3
	var crust_volume = get_sph_V(R - target.crust_start_depth, R - target.mantle_start_depth)
	var mantle_volume = get_sph_V(R - target.mantle_start_depth, R - target.core_start_depth)
	var core_volume = get_sph_V(R - target.core_start_depth)
	var stone = {}
	add_stone(stone, target.crust, (surface_volume + crust_volume) * ((5600 + target.mantle_start_depth * 0.01) / 2.0))
	add_stone(stone, target.mantle, mantle_volume * ((5690 + (target.mantle_start_depth + target.core_start_depth) * 0.01) / 2.0))
	add_stone(stone, target.core, core_volume * ((5700 + (target.core_start_depth + R) * 0.01) / 2.0))
	rsrc = {"stone":stone}
	var max_star_temp = game.get_max_star_prop(game.c_s, "temperature")
	var au_int = 12000.0 * game.galaxy_data[game.c_g].B_strength * max_star_temp
	var au_mult = 1 + pow(au_int, Helper.get_AIE())
	$Control/MMM.bbcode_text = "[aurora au_int=%s]%s: %s" % [au_int, tr("MAT_MET_MULT"), Helper.format_num(Helper.clever_round(au_mult, 4))]
	for mat in target.surface:
		rsrc[mat] = surface_volume * target.surface[mat].chance * target.surface[mat].amount * au_mult * game.u_i.planck
	for met in game.met_info:
		rsrc[met] = get_sph_V(R - game.met_info[met].min_depth, R - game.met_info[met].max_depth) / game.met_info[met].rarity * au_mult * game.u_i.planck
	Helper.put_rsrc($Control/ScrollContainer/GridContainer, 36, rsrc)

#get_sphere_volume
func get_sph_V(outer:float, inner:float = 0):
	outer /= 150.0#I have to reduce the size of planets otherwise it's too OP
	inner /= 150.0
	return 4/3.0 * PI * (pow(outer, 3) - pow(inner, 3))

func add_stone(stone:Dictionary, layer:Dictionary, amount:float):
	for comp in layer:
		if stone.has(comp):
			stone[comp] += layer[comp] * amount * game.u_i.planck
		else:
			stone[comp] = layer[comp] * amount * game.u_i.planck

func _on_HSlider_value_changed(value):
	refresh_planet_info()


func _on_StartCharging_pressed():
	if rekt_planet:
		if game.c_v != "system":
			return
		var p_i:Dictionary = game.planet_data[star.p_id]
		if not p_i.empty():
			game.popup(tr("PLANET_REKT") % target.name, 2.5)
			if p_i.has("bookmarked"):
				game.bookmarks.planet.erase(str(target.id))
				game.HUD.planet_grid_btns.remove_child(game.HUD.planet_grid_btns.get_node(str(target.id)))
				p_i.erase("bookmarked")
			if p_i.has("MS") and p_i.MS == "M_MME":
				game.autocollect.MS.minerals -= Helper.get_MME_output(p_i)
			if p_i.has("tile_num"):
				if p_i.bldg.name == "RL":
					game.autocollect.rsrc.SP -= p_i.bldg.path_1_value * p_i.tile_num
				elif p_i.bldg.name == "MS":
					game.mineral_capacity -= p_i.bldg.path_1_value * p_i.tile_num
			var dir = Directory.new()
			if dir.file_exists("user://Save%s/Univ%s/Planets/%s.hx3" % [game.c_sv, game.c_u, target.id]):
				dir.remove("user://Save%s/Univ%s/Planets/%s.hx3" % [game.c_sv, game.c_u, target.id])
			target.clear()
			game.view.obj.refresh_planets()
			game.add_resources(star.rsrc)
		star.erase("charging_time")
		star.erase("charge_start_date")
		star.erase("p_id")
		star.erase("rsrc")
		set_process(false)
		$StartCharging.visible = false
		rekt_planet = false
		game.HUD.refresh()
		refresh()
	elif star.has("charging_time"):
		star.erase("charging_time")
		star.erase("charge_start_date")
		star.erase("p_id")
		star.erase("rsrc")
		$Control.visible = true
		$Control2.visible = false
		set_process(false)
		$StartCharging.text = tr("START_CHARGING")
	elif star.MS_lv == 0 and target.size <= int(4000 * pow(game.u_i.gravitational, 0.5)) or star.MS_lv == 1 and target.size <= int(40000 * pow(game.u_i.gravitational, 0.5)) or star.MS_lv == 2:
		if c_s_g == game.ships_c_g_coords.s and p_id == game.ships_c_coords.p:
			game.popup(tr("PK_ERROR"), 2.0)
			return
		for fighter in game.fighter_data:
			if c_s_g == fighter.c_s_g and p_id == fighter.c_p:
				game.popup(tr("PK_ERROR"), 2.0)
				return
		if game.energy >= additional_energy:
			game.energy -= additional_energy
			star.charge_start_date = OS.get_system_time_msecs()
			star.charging_time = charging_time
			star.p_id = p_id
			star.rsrc = rsrc.duplicate(true)
			$Control.visible = false
			$Control2.visible = true
			$StartCharging.text = tr("CANCEL_CHARGING")
			set_process(true)
			game.HUD.refresh()
		else:
			game.popup(tr("NOT_ENOUGH_ENERGY"), 1.5)
	else:
		game.popup(tr("PLANET_TOO_OP"), 2.0)

func _process(delta):
	var curr_time = OS.get_system_time_msecs()
	var start_date = star.charge_start_date
	var length = star.charging_time
	var progress = (curr_time - start_date) / float(length)
	$Control2/TimeCost.text = Helper.time_to_str(length - (curr_time - start_date))
	$Control2/TextureProgress.value = progress
	if progress <= 0.5:
		$Control2/Charging.text = tr("PK_CHARGING_MESSAGE_1")
	elif progress <= 0.9:
		$Control2/Charging.text = tr("PK_CHARGING_MESSAGE_2")
	elif progress <= 1:
		$Control2/Charging.text = tr("PK_CHARGING_MESSAGE_3")
	elif progress >= 1:
		$Control2/TimeCost.text = ""
		$Control2/Charging.text = tr("PLANET_READY_TO_BE_REKT") % target.name
		set_process(false)
		$StartCharging.visible = true
		$StartCharging.text = tr("FIRE")
		rekt_planet = true


func _on_MMM_mouse_entered():
	game.show_tooltip(tr("MMM_DESC"))


func _on_MMM_mouse_exited():
	game.hide_tooltip()
