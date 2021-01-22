extends Node2D

onready var game = get_node("/root/Game")
onready var stars_info = game.system_data[game.c_s]["stars"]
onready var star_graphic = preload("res://Graphics/Stars/Star.png")
onready var view = get_parent()

const PLANET_SCALE_DIV = 6400000.0 / 2.0
const STAR_SCALE_DIV = 300.0/2.63
var glows = []
var star_time_bars = []
var planet_time_bars = []
var star_rsrcs = []
var planet_rsrcs = []

func _ready():
	refresh_planets()
	refresh_stars()

func refresh_planets():
	for planet_thing in get_tree().get_nodes_in_group("planet_stuff"):
		planet_thing.remove_from_group("planet_stuff")
		remove_child(planet_thing)
	for p_i in game.planet_data:
		var orbit = game.orbit_scene.instance()
		orbit.radius = p_i["distance"]
		self.add_child(orbit)
		orbit.add_to_group("planet_stuff")
		var planet_btn = TextureButton.new()
		var planet_glow = TextureButton.new()
		var planet = Sprite.new()
		var planet_texture = load("res://Graphics/Planets/" + String(p_i["type"]) + ".png")
		var planet_glow_texture = preload("res://Graphics/Misc/Glow.png")
		planet_btn.texture_normal = planet_texture
		planet_glow.texture_normal = planet_glow_texture
		self.add_child(planet)
		planet.add_child(planet_glow)
		planet.add_child(planet_btn)
		planet_btn.connect("mouse_entered", self, "on_planet_over", [p_i.id, p_i.l_id])
		planet_glow.connect("mouse_entered", self, "on_glow_planet_over", [p_i.id, p_i.l_id, planet_glow])
		planet_btn.connect("mouse_exited", self, "on_btn_out")
		planet_glow.connect("mouse_exited", self, "on_btn_out")
		planet_btn.connect("pressed", self, "on_planet_click", [p_i["id"], p_i.l_id])
		planet_glow.connect("pressed", self, "on_planet_click", [p_i["id"], p_i.l_id])
		planet_btn.rect_position = Vector2(-320, -320)
		planet_btn.rect_pivot_offset = Vector2(320, 320)
		planet_btn.rect_scale.x = p_i["size"] / PLANET_SCALE_DIV
		planet_btn.rect_scale.y = p_i["size"] / PLANET_SCALE_DIV
		planet_glow.rect_pivot_offset = Vector2(100, 100)
		planet_glow.rect_position = Vector2(-100, -100)
		planet_glow.rect_scale *= p_i["distance"] / 1200.0
		if p_i.conquered:
			planet_glow.modulate = Color(0, 1, 0, 1)
		else:
			planet_glow.modulate = Color(1, 0, 0, 1)
		if p_i.has("MS"):
			var MS = Sprite.new()
			MS.texture = load("res://Graphics/Megastructures/M_SE_%s.png" % p_i.MS_lv)
			MS.scale *= 0.2
			MS.position.x = -50 * cos(p_i.angle)
			MS.position.y = -50 * sin(p_i.angle)
			MS.rotation = p_i.angle + PI / 2
			planet.add_child(MS)
			if p_i.is_constructing:
				var time_bar = game.time_scene.instance()
				time_bar.rect_position = Vector2(0, -80)
				planet.add_child(time_bar)
				time_bar.modulate = Color(0, 0.74, 0, 1)
				planet_time_bars.append({"node":time_bar, "p_i":p_i, "parent":planet})
		planet.position.x = cos(p_i["angle"]) * p_i["distance"]
		planet.position.y = sin(p_i["angle"]) * p_i["distance"]
		planet.add_to_group("planet_stuff")
		glows.append(planet_glow)
	
func refresh_stars():
	for star in get_tree().get_nodes_in_group("stars"):
		star.remove_from_group("stars")
		remove_child(star)
	for time_bar in star_time_bars:
		remove_child(time_bar)
	for rsrc in star_rsrcs:
		remove_child(rsrc)
	star_time_bars.clear()
	star_rsrcs.clear()
	#var combined_star_size = 0
	for i in range(0, stars_info.size()):
		var star_info = stars_info[i]
		var star = TextureButton.new()
		star.texture_normal = star_graphic
		self.add_child(star)
		star.rect_pivot_offset = Vector2(300, 300)
		#combined_star_size += star_info["size"]
		star.rect_scale.x = max(0.04, star_info["size"] / STAR_SCALE_DIV)
		star.rect_scale.y = max(0.04, star_info["size"] / STAR_SCALE_DIV)
		star.rect_position = star_info["pos"] - Vector2(300, 300)
		star.connect("mouse_entered", self, "on_star_over", [i])
		star.connect("mouse_exited", self, "on_btn_out")
		star.connect("pressed", self, "on_star_pressed", [i])
		star.modulate = game.get_star_modulate(star_info["class"])
		star.add_to_group("stars")
		if star_info.has("MS"):
			var MS = Sprite.new()
			MS.texture = load("res://Graphics/Megastructures/%s_%s.png" % [star_info.MS, star_info.MS_lv])
			MS.position = Vector2(300, 300)
			star.add_child(MS)
			add_rsrc(star_info.pos, Color(0, 0.8, 0, 1), Data.icons.PP, i, true)
			if star_info.is_constructing:
				var time_bar = game.time_scene.instance()
				time_bar.rect_position = star_info["pos"] - Vector2(0, 80)
				add_child(time_bar)
				time_bar.modulate = Color(0, 0.74, 0, 1)
				star_time_bars.append({"node":time_bar, "id":i})

var glow_over

func on_planet_over (id:int, l_id:int):
	show_planet_info(id, l_id)

func on_glow_planet_over (id:int, l_id:int, glow):
	glow_over = glow
	show_planet_info(id, l_id)

func show_SE_costs(p_i:Dictionary):
	var vbox = game.get_node("UI/Panel/VBox")
	game.get_node("UI/Panel").visible = true
	bldg_costs = Data.MS_costs["M_SE_%s" % ((p_i.MS_lv + 1) if p_i.has("MS") else 0)].duplicate(true)
	for cost in bldg_costs:
		if cost != "energy":
			bldg_costs[cost] = round(bldg_costs[cost] * p_i.size / 12000.0)
		else:
			bldg_costs.energy = round(bldg_costs.energy * p_i.size / 12000.0 * pow(max(0.25, p_i.pressure), 1.2))
	Helper.put_rsrc(vbox, 32, bldg_costs, true, true)
	Helper.add_label(tr("CONSTRUCTION_COSTS"), 0)
	
func show_planet_info(id:int, l_id:int):
	var p_i = game.planet_data[l_id]
	var wid:int = Helper.get_wid(p_i.size)
	var building:bool = game.bottom_info_action == "building_SE"
	var has_MS:bool = p_i.has("MS")
	var vbox = game.get_node("UI/Panel/VBox")
	if building:
		show_SE_costs(p_i)
	elif has_MS:
		game.get_node("UI/Panel").visible = true
		Helper.put_rsrc(vbox, 32, {})
		Helper.add_label(tr("%s_STAGE_X" % p_i.MS) % p_i.MS_lv)
		Helper.add_label(tr("SE_%s_BENEFITS" % p_i.MS_lv), -1, false)
		if not p_i.is_constructing:
			if p_i.MS == "M_SE" and p_i.MS_lv < 3 and game.science_unlocked["SE%s" % (p_i.MS_lv + 1)]:
				MS_constr_data.obj = p_i
				MS_constr_data.confirm = false
				Helper.add_label(tr("PRESS_F_TO_CONTINUE_CONSTR"))
	if game.c_sc == game.ships_c_coords.sc and game.c_c == game.ships_c_coords.c and game.c_g == game.ships_c_coords.g and game.c_s == game.ships_c_coords.s and l_id == game.ships_c_coords.p and not p_i.conquered:
		game.show_tooltip(tr("CLICK_TO_BATTLE"))
	else:
		game.show_tooltip("%s\n%s: %s km (%sx%s)\n%s: %s AU\n%s: %s °C\n%s: %s bar\n%s" % [p_i.name, tr("DIAMETER"), round(p_i.size), wid, wid, tr("DISTANCE_FROM_STAR"), game.clever_round(p_i.distance / 569.25, 3), tr("SURFACE_TEMPERATURE"), game.clever_round(p_i.temperature - 273), tr("ATMOSPHERE_PRESSURE"), game.clever_round(p_i.pressure), tr("MORE_DETAILS")])

var MS_constr_data:Dictionary = {}

func _input(event):
	if Input.is_action_just_released("F") and not MS_constr_data.empty():
		if not MS_constr_data.confirm:
			if MS_constr_data.obj.MS == "M_SE":
				show_SE_costs(MS_constr_data.obj)
				MS_constr_data.confirm = true
				Helper.add_label(tr("F_TO_CONFIRM"))
		else:
			build_SE(MS_constr_data.obj)

func build_SE(p_i:Dictionary):
	var curr_time = OS.get_system_time_msecs()
	if game.check_enough(bldg_costs):
		game.deduct_resources(bldg_costs)
		if p_i.has("MS"):
			p_i.MS_lv += 1
		else:
			p_i.MS = "M_SE"
			p_i.MS_lv = 0
		p_i.is_constructing = true
		p_i.construction_date = curr_time
		p_i.construction_length = bldg_costs.time * 1000
		p_i.XP = round(bldg_costs.money / 100.0)
		refresh_planets()
		game.get_node("UI/Panel").visible = false
		MS_constr_data.clear()
		Helper.save_obj("Systems", game.c_s_g, game.planet_data)
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)

func on_planet_click (id:int, l_id:int):
	var p_i = game.planet_data[l_id]
	if not view.dragged:
		game.get_node("UI/Panel").visible = false
		var building:bool = game.bottom_info_action == "building_SE"
		var vbox = game.get_node("UI/Panel/VBox")
		if building:
			if p_i.conquered:
				build_SE(p_i)
			else:
				game.popup(tr("PLANET_MS_ERROR"), 2.5)
		else:
			if Input.is_action_pressed("shift"):
				game.c_p = l_id
				game.c_p_g = id
				game.switch_view("planet_details")
			elif Input.is_action_pressed("Q") or p_i.conquered:
				game.c_p = l_id
				game.c_p_g = id
				game.switch_view("planet")
				game.planet_data[l_id].conquered = true
				var all_conquered = true
				for planet in game.planet_data:
					if not planet.conquered:
						all_conquered = false
				game.system_data[game.c_s].conquered = all_conquered
				Helper.save_obj("Systems", game.c_s_g, game.planet_data)
				Helper.save_obj("Galaxies", game.c_g_g, game.system_data)
			else:
				if game.c_sc == game.ships_c_coords.sc and game.c_c == game.ships_c_coords.c and game.c_g == game.ships_c_coords.g and game.c_s == game.ships_c_coords.s and l_id == game.ships_c_coords.p and not p_i.conquered:
					game.c_p = l_id
					game.c_p_g = id
					game.switch_view("battle")
				else:
					if len(game.ship_data) > 0:
						game.send_ships_panel.dest_p_id = l_id
						game.toggle_panel(game.send_ships_panel)
					else:
						game.long_popup(tr("NO_SHIPS_DESC"), tr("NO_SHIPS"))

var bldg_costs:Dictionary

func on_star_over (id:int):
	var star = stars_info[id]
	var star_type:String = star.type
	var star_tier:String = ""
	if star_type.substr(0, 11) == "hypergiant ":
		star_type = star_type.split(" ")[0]
		star_tier = " %s" % star.type.split(" ")[1]
	var tooltip = tr("STAR_TITLE").format({"type":"%s%s" % [tr(star_type.to_upper()), star_tier.to_upper()], "class":star.class})
	tooltip += "\n%s\n%s\n%s\n%s" % [	tr("STAR_TEMPERATURE") % [star.temperature], 
										tr("STAR_SIZE") % [star.size],
										tr("STAR_MASS") % [star.mass],
										tr("STAR_LUMINOSITY") % [Helper.e_notation(star.luminosity) if star.luminosity < 0.0001 else star.luminosity]]
	var building:bool = game.bottom_info_action == "building_DS"
	var has_MS:bool = star.has("MS")
	var vbox = game.get_node("UI/Panel/VBox")
	if building:
		game.get_node("UI/Panel").visible = true
		bldg_costs = Data.MS_costs.M_DS_0.duplicate(true)
		for cost in bldg_costs:
			bldg_costs[cost] = round(bldg_costs[cost] * pow(star.size, 2))
		Helper.put_rsrc(vbox, 32, bldg_costs, true, true)
		Helper.add_label(tr("CONSTRUCTION_COSTS"), 0)
		Helper.add_label(tr("PRODUCTION_PER_SECOND"))
		Helper.put_rsrc(vbox, 32, {"energy":Data.MS_output.M_DS_0 * star.luminosity}, false)
	elif has_MS:
		game.get_node("UI/Panel").visible = true
		Helper.put_rsrc(vbox, 32, {})
		Helper.add_label(tr("%s_STAGE_X" % star.MS) % star.MS_lv)
		Helper.add_label(tr("PRODUCTION_PER_SECOND"), -1, false)
		Helper.put_rsrc(vbox, 32, {"energy":Data.MS_output.M_DS_0 * star.luminosity}, false)
		if not star.is_constructing:
			if star.MS == "M_DS" and star.MS_lv < 4 and game.science_unlocked["DS%s" % (star.MS_lv + 1)]:
				Helper.add_label(tr("PRESS_F_TO_CONTINUE_CONSTR"))
	game.show_tooltip(tooltip)

func on_star_pressed (id:int):
	var curr_time = OS.get_system_time_msecs()
	var star = stars_info[id]
	if game.bottom_info_action == "building_DS":
		if game.system_data[game.c_s].conquered:
			if not star.has("MS"):
				if game.check_enough(bldg_costs):
					game.deduct_resources(bldg_costs)
					star.MS = "M_DS"
					star.MS_lv = 0
					star.stored = 0
					star.is_constructing = true
					star.construction_date = curr_time
					star.construction_length = bldg_costs.time * 1000
					star.collect_date = star.construction_date + star.construction_length
					star.XP = round(bldg_costs.money / 100.0)
					refresh_stars()
				else:
					game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)
			else:
				game.popup(tr("MS_ALREADY_PRESENT"), 2.0)
		else:
			game.popup(tr("STAR_MS_ERROR"), 3.0)
	elif star.has("MS"):
		if star.MS == "M_DS":
			game.energy += star.stored
			star.stored = 0

func on_btn_out ():
	glow_over = null
	game.get_node("UI/Panel").visible = false
	game.hide_tooltip()
	MS_constr_data.clear()

func _process(_delta):
	for glow in glows:
		glow.modulate.a = clamp(0.6 / (view.scale.x * glow.rect_scale.x) - 0.1, 0, 1)
		if glow.modulate.a == 0 and glow.visible:
			if glow == glow_over:
				game.hide_tooltip()
			glow.visible = false
		if glow.modulate.a != 0:
			glow.visible = true
	var curr_time = OS.get_system_time_msecs()
	for time_bar_obj in star_time_bars:
		var time_bar = time_bar_obj.node
		var id = time_bar_obj.id
		var star = stars_info[id]
		var progress = (curr_time - star.construction_date) / float(star.construction_length)
		time_bar.get_node("TimeString").text = Helper.time_to_str(star.construction_length - curr_time + star.construction_date)
		time_bar.get_node("Bar").value = progress
		if progress > 1:
			if star.is_constructing:
				star.is_constructing = false
				game.xp += star.XP
				game.HUD.refresh()
			remove_child(time_bar)
			star_time_bars.erase(time_bar_obj)
	for time_bar_obj in planet_time_bars:
		var time_bar = time_bar_obj.node
		var p_i = time_bar_obj.p_i
		var progress = (curr_time - p_i.construction_date) / float(p_i.construction_length)
		time_bar.get_node("TimeString").text = Helper.time_to_str(p_i.construction_length - curr_time + p_i.construction_date)
		time_bar.get_node("Bar").value = progress
		if progress > 1:
			if p_i.is_constructing:
				p_i.is_constructing = false
				game.xp += p_i.XP
				game.HUD.refresh()
			time_bar_obj.parent.remove_child(time_bar)
			planet_time_bars.erase(time_bar_obj)
			Helper.save_obj("Systems", game.c_s_g, game.planet_data)
	for rsrc_obj in star_rsrcs:
		var star = stars_info[rsrc_obj.id]
		if star.is_constructing:
			continue
		var rsrc = rsrc_obj.node
		var prod = 1000.0 / Data.MS_output["M_DS_%s" % [star.MS_lv]]
		var stored = star.stored
		var c_d = star.collect_date
		var c_t = curr_time
		var current_bar = rsrc.get_node("Control/CurrentBar")
		current_bar.value = min((c_t - c_d) / prod, 1)
		if c_t - c_d > prod:
			var rsrc_num = floor((c_t - c_d) / prod)
			star.stored += rsrc_num
			star.collect_date += prod * rsrc_num
		rsrc.get_node("Control/Label").text = Helper.format_num(stored, 4)

func _on_System_tree_exited():
	queue_free()

func construct(_name:String):
	pass

func finish_construct():
	pass

func add_rsrc(v:Vector2, mod:Color, icon, id:int, is_star:bool):
	var rsrc = game.rsrc_stocked_scene.instance()
	add_child(rsrc)
	rsrc.get_node("TextureRect").texture = icon
	rsrc.rect_position = v + Vector2(0, 70)
	rsrc.get_node("Control").modulate = mod
	if is_star:
		star_rsrcs.append({"node":rsrc, "id":id})
	else:
		planet_rsrcs.append({"node":rsrc, "id":id})
