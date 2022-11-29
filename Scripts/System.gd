extends Node2D

onready var game = get_node("/root/Game")
onready var stars_info = game.system_data[game.c_s]["stars"]
onready var view = get_parent()
var star_shader = preload("res://Shaders/Star.shader")

#Used to prevent view from moving outside viewport
var dimensions:float

const PLANET_SCALE_DIV = 1200000.0
var glows = []
var star_time_bars = []
var planet_time_bars = []
var planet_plant_bars = []
var star_rsrcs = []
var planet_rsrcs = []
var planet_hovered:int = -1
var tile_datas:Array = []
var num_stages:Dictionary = {"M_DS":4, "M_MME":3, "M_CBS":3, "M_PK":2, "M_SE":1, "M_MPCC":0, "M_MB":0}
var build_all_MS_stages:bool = false
var CBS_range:float = 0.0

func _ready():
	refresh_stars()
	if game.tutorial:
		if game.tutorial.tut_num == 27:
			game.tutorial.begin()
		elif game.tutorial.tut_num == 30 and len(game.ship_data) > 0:
			game.tutorial.begin()

func refresh_planets():
	var curr_time = OS.get_system_time_msecs()
	for planet_thing in get_tree().get_nodes_in_group("planet_stuff"):
		planet_thing.remove_from_group("planet_stuff")
		planet_thing.queue_free()
	for info_node in get_tree().get_nodes_in_group("info_nodes"):
		info_node.remove_from_group("info_nodes")
		info_node.queue_free()
	for rsrc in planet_rsrcs:
		rsrc.node.queue_free()
	glows.clear()
	planet_rsrcs.clear()
	tile_datas.clear()
	var planets_affected_by_CBS:int = 0
	var p_num:int = len(game.planet_data)
	for i in len(stars_info):
		var star_info:Dictionary = stars_info[i]
		if star_info.has("MS") and star_info.MS == "M_CBS":
			if star_info.MS_lv == 0:
				planets_affected_by_CBS = max(planets_affected_by_CBS, ceil(p_num * 0.1))
			else:
				planets_affected_by_CBS = max(planets_affected_by_CBS, ceil(p_num * star_info.MS_lv * 0.333))
	for i in p_num:
		var p_i:Dictionary = game.planet_data[i]
		if p_i.empty():
			tile_datas.append([])
			continue
		var tile_data_to_append:Array = game.open_obj("Planets", p_i.id)
		tile_datas.append(tile_data_to_append)
		
		var v:Vector2 = polar2cartesian(p_i.distance, p_i.angle)
		var orbit = game.orbit_scene.instance()
		orbit.radius = v.length()
		self.add_child(orbit)
		orbit.add_to_group("planet_stuff")
		var planet = preload("res://Scenes/PlanetButton.tscn").instance()
		var planet_btn = planet.get_node("Button")
		var planet_glow = planet.get_node("Glow")
		planet_btn.texture_normal = game.planet_textures[p_i.type - 3]
		add_child(planet)
		planet_btn.connect("mouse_entered", self, "on_planet_over", [p_i.id, p_i.l_id])
		planet_glow.connect("mouse_entered", self, "on_glow_planet_over", [p_i.id, p_i.l_id, planet_glow])
		planet_btn.connect("mouse_exited", self, "on_btn_out")
		planet_glow.connect("mouse_exited", self, "on_btn_out")
		planet_btn.connect("pressed", self, "on_planet_click", [p_i["id"], p_i.l_id])
		planet_glow.connect("pressed", self, "on_planet_click", [p_i["id"], p_i.l_id])
		planet_btn.rect_scale.x = p_i["size"] / PLANET_SCALE_DIV
		planet_btn.rect_scale.y = p_i["size"] / PLANET_SCALE_DIV
		var sc:float = p_i["distance"] / 2400.0
		planet_glow.rect_scale *= sc
		if game.system_data[game.c_s].has("conquered"):
			p_i.conquered = true
		if not is_instance_valid(game.element_overlay):
			yield(get_tree(), "idle_frame")
		if p_i.has("conquered"):
			if p_i.has("bldg"):
				planet_glow.modulate = Color(0.2, 0.2, 1, 1)
			elif p_i.has("wormhole"):
				planet_glow.modulate = Color(0.74, 0.6, 0.78, 1)
			elif p_i.type in [11, 12]:
				planet_glow.modulate = Color.burlywood
			else:
				if p_i.has("discovered"):
					planet_glow.modulate = Color(0, 1, 0, 1)
				else:
					planet_glow.modulate = Color(0.8, 1, 0, 1)
			if game.element_overlay.toggle_btn.pressed:
				add_elements(p_i, v, sc)
			else:
				var tile_data:Array = tile_datas[p_i.l_id]
				var bldgs:Dictionary = {}
				if p_i.has("tile_num") and p_i.bldg.has("name"):
					Helper.add_to_dict(bldgs, p_i.bldg.name, p_i.tile_num)
				else:
					for tile in tile_data:
						if tile and tile.has("bldg") and tile.bldg.has("name"):
							Helper.add_to_dict(bldgs, tile.bldg.name, 1)
				if not bldgs.empty():
					var grid:GridContainer = GridContainer.new()
					grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
					grid.columns = 3
					grid.rect_scale *= sc * 2.5
					for bldg in bldgs:
						var bldg_count = preload("res://Scenes/EntityCount.tscn").instance()
						bldg_count.get_node("Texture").connect("mouse_entered", self, "on_entity_icon_over", [tr("%s_NAME" % bldg)])
						bldg_count.get_node("Texture").connect("mouse_exited", self, "on_entity_icon_out")
						grid.add_child(bldg_count)
						bldg_count.get_node("Texture").texture = game.bldg_textures[bldg]
						bldg_count.get_node("Label").text = "x %s" % Helper.format_num(bldgs[bldg])
					add_child(grid)
					grid.add_to_group("info_nodes")
					grid.rect_position.x = v.x - grid.rect_size.x / 2.0 * sc * 2.5
					grid.rect_position.y = v.y - (grid.rect_size.y + 50) * sc * 2.5
		else:
			if game.element_overlay.toggle_btn.pressed:
				add_elements(p_i, v, sc)
			else:
				var HX_count = preload("res://Scenes/EntityCount.tscn").instance()
				HX_count.get_node("Texture").connect("mouse_entered", self, "on_entity_icon_over", [tr("ENEMIES")])
				HX_count.get_node("Texture").connect("mouse_exited", self, "on_entity_icon_out")
				HX_count.rect_scale *= sc * 3.0
				#HX_count.rect_position = v - Vector2(0, 80) * sc * 3.0
				HX_count.get_node("Label").text = "x %s" % len(p_i.HX_data)
				add_child(HX_count)
				HX_count.add_to_group("info_nodes")
				HX_count.rect_position.x = v.x - HX_count.rect_size.x / 2.0 * sc * 3.0
				HX_count.rect_position.y = v.y - (HX_count.rect_size.y + 40) * sc * 3.0
			if p_i.type in [11, 12]:
				planet_glow.modulate = Color.burlywood
			else:
				planet_glow.modulate = Color.red
		dimensions = v.length()
		if p_i.has("MS"):
			planet_glow.modulate = Color(0.6, 0.6, 0.6, 1)
			var MS = Sprite.new()
			MS.texture = load("res://Graphics/Megastructures/%s_%s.png" % [p_i.MS, p_i.MS_lv])
			MS.scale *= 0.2
			if p_i.MS == "M_SE":
				MS.position.x = -50 * cos(p_i.angle)
				MS.position.y = -50 * sin(p_i.angle)
				MS.rotation = p_i.angle + PI / 2
			elif p_i.MS == "M_MME":
				MS.scale *= 0.25
				add_rsrc(v, Color(0, 0.5, 0.9, 1), Data.minerals_icon, p_i.l_id, false, sc)
			planet.add_child(MS)
			if p_i.bldg.has("is_constructing"):
				var time_bar = game.time_scene.instance()
				time_bar.rect_position = Vector2(0, -80 * sc)
				time_bar.rect_scale *= sc
				planet.add_child(time_bar)
				time_bar.modulate = Color(0, 0.74, 0, 1)
				planet_time_bars.append({"node":time_bar, "p_i":p_i, "parent":planet})
		if p_i.has("tile_num") and p_i.bldg.has("name"):
			planet.add_child(Helper.add_lv_boxes(p_i, Vector2.ZERO, sc))
			match p_i.bldg.name:
				"ME":
					add_rsrc(v, Color(0, 0.5, 0.9, 1), Data.rsrc_icons.ME, p_i.l_id, false, sc)
				"PP":
					add_rsrc(v, Color(0, 0.8, 0, 1), Data.rsrc_icons.PP, p_i.l_id, false, sc)
				"RL":
					add_rsrc(v, Color(0, 0.8, 0, 1), Data.rsrc_icons.RL, p_i.l_id, false, sc)
				"ME":
					add_rsrc(v, Color(0.89, 0.55, 1.0, 1), Data.rsrc_icons.ME, p_i.l_id, false, sc)
				"AE":
					add_rsrc(v, Color(0.89, 0.55, 1.0, 1), Data.rsrc_icons.AE, p_i.l_id, false, sc)
				"MM":
					add_rsrc(v, Color(0.6, 0.6, 0.6, 1), Data.rsrc_icons.MM, p_i.l_id, false, sc, true)
		planet.rect_position = v
		planet.add_to_group("planet_stuff")
		glows.append(planet_glow)
		if planets_affected_by_CBS > 0 and i == planets_affected_by_CBS - 1:
			CBS_range = v.length() * 1.1

func _draw():
	draw_arc(Vector2.ZERO, CBS_range, 0, 2*PI, 100, Color(0.4, 0.4, 1.0, 0.8), 1)
	draw_circle(Vector2.ZERO, CBS_range, Color(0.4, 0.4, 1.0, 0.15))

func add_elements(p_i:Dictionary, v:Vector2, sc:float):
	var grid:GridContainer = GridContainer.new()
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.columns = 3
	grid.rect_scale *= sc * 4.0
	if game.element_overlay.option_btn.get_selected_id() == 0:#Planet interior
		var R = p_i.size * 1000.0 / 2#in meters
		var surface_volume = get_sph_V(R, R - p_i.crust_start_depth)#in m^3
		var crust_volume = get_sph_V(R - p_i.crust_start_depth, R - p_i.mantle_start_depth)
		var mantle_volume = get_sph_V(R - p_i.mantle_start_depth, R - p_i.core_start_depth)
		var core_volume = get_sph_V(R - p_i.core_start_depth)
		var crust_stone_amount = (surface_volume + crust_volume) * ((5600 + p_i.mantle_start_depth * 0.01) / 2.0)
		var mantle_stone_amount = mantle_volume * ((5690 + (p_i.mantle_start_depth + p_i.core_start_depth) * 0.01) / 2.0)
		var core_stone_amount = core_volume * ((5700 + (p_i.core_start_depth + R) * 0.01) / 2.0)
		for atom in game.show_atoms:
			var atom_count = preload("res://Scenes/EntityCount.tscn").instance()
			atom_count.get_node("Texture").connect("mouse_entered", self, "on_entity_icon_over", [tr("%s_NAME" % atom.to_upper())])
			atom_count.get_node("Texture").connect("mouse_exited", self, "on_entity_icon_out")
			grid.add_child(atom_count)
			atom_count.get_node("Texture").texture = load("res://Graphics/Atoms/%s.png" % atom)
			var num:float = ((p_i.crust[atom] if p_i.crust.has(atom) else 0.0) * crust_stone_amount + (p_i.mantle[atom] if p_i.mantle.has(atom) else 0.0) * mantle_stone_amount + (p_i.core[atom] if p_i.core.has(atom) else 0.0) * core_stone_amount)# / Data.molar_mass[atom] / 1000.0
			atom_count.get_node("Label").text = "%s mol" % Helper.format_num(num, true)
	elif game.element_overlay.option_btn.get_selected_id() == 1:
		for atom in game.show_atoms:
			var atom_count = preload("res://Scenes/EntityCount.tscn").instance()
			atom_count.get_node("Texture").connect("mouse_entered", self, "on_entity_icon_over", [tr("%s_NAME" % atom.to_upper())])
			atom_count.get_node("Texture").connect("mouse_exited", self, "on_entity_icon_out")
			grid.add_child(atom_count)
			atom_count.get_node("Texture").texture = load("res://Graphics/Atoms/%s.png" % atom)
			var percentage:float = p_i.atmosphere[atom] * 100.0 if p_i.atmosphere.has(atom) else 0.0
			atom_count.get_node("Label").text = "%s%%" % Helper.clever_round(percentage)
	add_child(grid)
	grid.add_to_group("info_nodes")
	grid.rect_position.x = v.x - grid.rect_size.x / 2.0 * sc * 4.0
	grid.rect_position.y = v.y - (grid.rect_size.y + 50) * sc * 4.0

#get_sphere_volume
func get_sph_V(outer:float, inner:float = 0):
	outer /= 150.0#I have to reduce the size of planets otherwise it's too OP
	inner /= 150.0
	return 4/3.0 * PI * (pow(outer, 3) - pow(inner, 3))

func on_entity_icon_over(txt:String):
	game.show_tooltip(txt)

func on_entity_icon_out():
	game.hide_tooltip()

func refresh_stars():
	for star in get_tree().get_nodes_in_group("stars"):
		star.remove_from_group("stars")
		star.queue_free()
	for time_bar in star_time_bars:
		time_bar.node.queue_free()
	for rsrc in star_rsrcs:
		rsrc.node.queue_free()
	star_time_bars.clear()
	star_rsrcs.clear()
	#var combined_star_size = 0
	for i in len(stars_info):
		var star_info:Dictionary = stars_info[i]
		var star = TextureButton.new()
		star.texture_normal = load("res://Graphics/Effects/spotlight_%s.png" % [int(star_info.temperature) % 3 + 4])
		star.texture_click_mask = preload("res://Graphics/Misc/StarCM.png")
		self.add_child(star)
		star.rect_pivot_offset = Vector2(512, 512)
		#combined_star_size += star_info["size"]
		star.rect_scale.x = max(5.0 * star_info["size"] / game.STAR_SCALE_DIV, 0.008)
		star.rect_scale.y = max(5.0 * star_info["size"] / game.STAR_SCALE_DIV, 0.008)
		star.rect_position = star_info["pos"] - Vector2(512, 512)
		star.connect("mouse_entered", self, "on_star_over", [i])
		star.connect("mouse_exited", self, "on_btn_out")
		star.connect("pressed", self, "on_star_pressed", [i])
		star.modulate = Helper.get_star_modulate(star_info["class"])
		if star_info.type.substr(0, 10) == "hypergiant" and not star_info.has("hypergiant"):
			star_info.hypergiant = 1
		if not game.achievement_data.exploration.has("B_star") and star_info.class[0] == "B":
			game.earn_achievement("exploration", "B_star")
		if not game.achievement_data.exploration.has("O_star") and star_info.class[0] == "O":
			game.earn_achievement("exploration", "O_star")
		if not game.achievement_data.exploration.has("Q_star") and star_info.class[0] == "Q":
			game.earn_achievement("exploration", "Q_star")
		if not game.achievement_data.exploration.has("R_star") and star_info.class[0] == "R":
			game.earn_achievement("exploration", "Rstar")
		if not game.achievement_data.exploration.has("Z_star") and star_info.class[0] == "Z":
			game.earn_achievement("exploration", "Z_star")
		if not game.achievement_data.exploration.has("HG_star") and star_info.has("hypergiant"):
			game.earn_achievement("exploration", "HG_star")
		if not game.achievement_data.exploration.has("HG_V_star") and star_info.has("hypergiant") and star_info.hypergiant >= 5:
			game.earn_achievement("exploration", "HG_V_star")
		if not game.achievement_data.exploration.has("HG_X_star") and star_info.has("hypergiant") and star_info.hypergiant >= 10:
			game.earn_achievement("exploration", "HG_X_star")
		if not game.achievement_data.exploration.has("HG_XX_star") and star_info.has("hypergiant") and star_info.hypergiant >= 20:
			game.earn_achievement("exploration", "HG_XX_star")
		if not game.achievement_data.exploration.has("HG_L_star") and star_info.has("hypergiant") and star_info.hypergiant >= 50:
			game.earn_achievement("exploration", "HG_L_star")
		star.add_to_group("stars")
		if game.enable_shaders:
			star.material = ShaderMaterial.new()
			star.material.shader = star_shader
			star.material.set_shader_param("time_offset", 10.0 * randf())
			star.material.set_shader_param("brightness_offset", 2.0)
			star.material.set_shader_param("twinkle_speed", 0.8)
			star.material.set_shader_param("amplitude", 0.3)
		if star_info.has("MS"):
			var MS = Sprite.new()
			if star_info.MS == "M_MB":
				MS.texture = preload("res://Graphics/Megastructures/M_MB_0.png")
			else:
				MS.texture = load("res://Graphics/Megastructures/%s_%s.png" % [star_info.MS, star_info.MS_lv])
			MS.position = Vector2(512, 512)
			if star_info.MS == "M_DS":
				MS.scale *= 0.7
			star.add_child(MS)
			if star_info.MS in ["M_DS", "M_MB"]:
				if star_info.MS == "M_DS":
					add_rsrc(star_info.pos, Color(0, 0.8, 0, 1), Data.energy_icon, i, true, max(star_info.size / 6.0, 0.5))
				elif star_info.MS == "M_MB":
					add_rsrc(star_info.pos, Color(0, 0.8, 0, 1), Data.SP_icon, i, true, max(star_info.size / 6.0, 0.5))
			if star_info.bldg.has("is_constructing"):
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

func auto_speedup(bldg_costs:Dictionary):
	bldg_costs.time /= game.u_i.time_speed
	if game.universe_data[game.c_u].lv >= 55:
		bldg_costs.money += bldg_costs.time * 200
		bldg_costs.time = 0.2

func add_constr_costs(vbox:VBoxContainer, dict:Dictionary):
	if dict.has("cost_div"):
		Helper.add_label("%s (%s)" % [tr("CONSTRUCTION_COSTS"), tr("DIV_BY") % Helper.clever_round(dict.cost_div)], 0)
	else:
		Helper.add_label(tr("CONSTRUCTION_COSTS"), 0)
	
func show_M_DS_costs(star:Dictionary, base:bool = false):
	var vbox = game.get_node("UI/Panel/VBox")
	game.get_node("UI/Panel").visible = true
	bldg_costs = Data.MS_costs["M_DS_%s" % ((star.MS_lv + 1) if not base else 0)].duplicate(true)
	if base and build_all_MS_stages:
		Helper.add_dict_to_dict(bldg_costs, Data.MS_costs.M_DS_1)
		Helper.add_dict_to_dict(bldg_costs, Data.MS_costs.M_DS_2)
		Helper.add_dict_to_dict(bldg_costs, Data.MS_costs.M_DS_3)
		Helper.add_dict_to_dict(bldg_costs, Data.MS_costs.M_DS_4)
	for cost in bldg_costs:
		bldg_costs[cost] = round(bldg_costs[cost] * pow(star.size, 2) * game.engineering_bonus.BCM / (star.cost_div if star.has("cost_div") else 1.0))
	auto_speedup(bldg_costs)
	Helper.put_rsrc(vbox, 32, bldg_costs, true, true)
	add_constr_costs(vbox, star)
	Helper.add_label(tr("PRODUCTION_PER_SECOND"))
	if base and build_all_MS_stages:
		Helper.put_rsrc(vbox, 32, {"energy":Helper.get_DS_output(star, num_stages.M_DS + 1)}, false)
	else:
		Helper.put_rsrc(vbox, 32, {"energy":Helper.get_DS_output(star, 1)}, false)
	Helper.add_label(tr("CAPACITY_INCREASE"))
	if base and build_all_MS_stages:
		Helper.put_rsrc(vbox, 32, {"energy":Helper.get_DS_capacity(star, num_stages.M_DS + 1) * Helper.get_IR_mult("M_DS")}, false)
	else:
		Helper.put_rsrc(vbox, 32, {"energy":Helper.get_DS_capacity(star, 1) * Helper.get_IR_mult("M_DS")}, false)

func show_M_CBS_costs(star:Dictionary, base:bool = false):
	var vbox = game.get_node("UI/Panel/VBox")
	game.get_node("UI/Panel").visible = true
	var stage:int = (star.MS_lv + 1) if not base else 0
	bldg_costs = Data.MS_costs["M_CBS_%s" % stage].duplicate(true)
	if base and build_all_MS_stages:
		Helper.add_dict_to_dict(bldg_costs, Data.MS_costs.M_CBS_1)
		Helper.add_dict_to_dict(bldg_costs, Data.MS_costs.M_CBS_2)
		Helper.add_dict_to_dict(bldg_costs, Data.MS_costs.M_CBS_3)
	for cost in bldg_costs:
		bldg_costs[cost] = round(bldg_costs[cost] * game.planet_data[-1].distance / 1000.0 * game.engineering_bonus.BCM / (star.cost_div if star.has("cost_div") else 1.0))
	auto_speedup(bldg_costs)
	Helper.put_rsrc(vbox, 32, bldg_costs, true, true)
	add_constr_costs(vbox, star)
	Helper.add_label(tr("CBD_PATH_1") % Helper.clever_round(1 + log(star.luminosity + 1)))
	var p_num:int = len(game.planet_data)
	if base and build_all_MS_stages:
		Helper.add_label(tr("CBS_PATH_3") % [p_num, 100])
	elif base:
		Helper.add_label(tr("CBS_PATH_3") % [ceil(p_num * 0.1), 10])
	else:
		Helper.add_label(tr("CBS_PATH_3") % [ceil(p_num * stage * 0.333), round(stage * 33.3)])

func show_M_PK_costs(star:Dictionary, base:bool = false):
	var vbox = game.get_node("UI/Panel/VBox")
	game.get_node("UI/Panel").visible = true
	bldg_costs = Data.MS_costs["M_PK_%s" % ((star.MS_lv + 1) if not base else 0)].duplicate(true)
	if base and build_all_MS_stages:
		Helper.add_dict_to_dict(bldg_costs, Data.MS_costs.M_PK_1)
		Helper.add_dict_to_dict(bldg_costs, Data.MS_costs.M_PK_2)
	for cost in bldg_costs:
		bldg_costs[cost] = round(bldg_costs[cost] * game.engineering_bonus.BCM / (star.cost_div if star.has("cost_div") else 1.0))
	auto_speedup(bldg_costs)
	Helper.put_rsrc(vbox, 32, bldg_costs, true, true)
	add_constr_costs(vbox, star)
	var max_diameter = 4000
	if not star.has("MS"):
		if build_all_MS_stages:
			Helper.add_label(tr("PK2_POWER"), -1, true, true)
		else:
			Helper.add_label(tr("PK0_POWER") % int(4000 * sqrt(game.u_i.gravitational)), -1, true, true)
	elif star.MS_lv == 0:
		Helper.add_label(tr("PK1_POWER") % int(40000 * sqrt(game.u_i.gravitational)), -1, true, true)
	elif star.MS_lv == 1:
		Helper.add_label(tr("PK2_POWER"), -1, true, true)
	
func show_M_SE_costs(p_i:Dictionary, base:bool = false):
	var vbox = game.get_node("UI/Panel/VBox")
	game.get_node("UI/Panel").visible = true
	bldg_costs = Data.MS_costs["M_SE_%s" % ((p_i.MS_lv + 1) if not base else 0)].duplicate(true)
	if base and build_all_MS_stages:
		Helper.add_dict_to_dict(bldg_costs, Data.MS_costs.M_SE_1)
	for cost in bldg_costs:
		if cost != "energy":
			bldg_costs[cost] = round(bldg_costs[cost] * p_i.size / 12000.0 * game.engineering_bonus.BCM / (p_i.cost_div if p_i.has("cost_div") else 1.0))
		else:
			bldg_costs.energy = round(bldg_costs.energy * p_i.size / 48000.0 * pow(max(0.25, p_i.pressure), 1.1)) * game.engineering_bonus.BCM / (p_i.cost_div if p_i.has("cost_div") else 1.0)
	auto_speedup(bldg_costs)
	Helper.put_rsrc(vbox, 32, bldg_costs, true, true)
	add_constr_costs(vbox, p_i)

func show_M_MME_costs(p_i:Dictionary, base:bool = false):
	var vbox = game.get_node("UI/Panel/VBox")
	game.get_node("UI/Panel").visible = true
	bldg_costs = Data.MS_costs["M_MME_%s" % ((p_i.MS_lv + 1) if not base else 0)].duplicate(true)
	if base and build_all_MS_stages:
		Helper.add_dict_to_dict(bldg_costs, Data.MS_costs.M_MME_1)
		Helper.add_dict_to_dict(bldg_costs, Data.MS_costs.M_MME_2)
		Helper.add_dict_to_dict(bldg_costs, Data.MS_costs.M_MME_3)
	for cost in bldg_costs:
		bldg_costs[cost] = round(bldg_costs[cost] * pow(p_i.size / 13000.0, 2) * game.engineering_bonus.BCM / (p_i.cost_div if p_i.has("cost_div") else 1.0))
	auto_speedup(bldg_costs)
	Helper.put_rsrc(vbox, 32, bldg_costs, true, true)
	add_constr_costs(vbox, p_i)
	Helper.add_label(tr("PRODUCTION_PER_SECOND"), -1, false)
	if build_all_MS_stages:
		Helper.put_rsrc(vbox, 32, {"minerals":Helper.get_MME_output(p_i, num_stages.M_MME + 1)}, false)
	else:
		Helper.put_rsrc(vbox, 32, {"minerals":Helper.get_MME_output(p_i, 1)}, false)
	Helper.add_label(tr("CAPACITY_INCREASE"), -1, false)
	if build_all_MS_stages:
		Helper.put_rsrc(vbox, 32, {"minerals":Helper.get_MME_capacity(p_i, num_stages.M_MME + 1) * Helper.get_IR_mult("M_MME")}, false)
	else:
		Helper.put_rsrc(vbox, 32, {"minerals":Helper.get_MME_capacity(p_i, 1) * Helper.get_IR_mult("M_MME")}, false)

func show_M_MPCC_costs(p_i:Dictionary, base:bool = false):
	var vbox = game.get_node("UI/Panel/VBox")
	game.get_node("UI/Panel").visible = true
	bldg_costs = Data.MS_costs.M_MPCC_0.duplicate(true)
	for cost in bldg_costs:
		bldg_costs[cost] = round(bldg_costs[cost] * game.engineering_bonus.BCM / (p_i.cost_div if p_i.has("cost_div") else 1.0))
	auto_speedup(bldg_costs)
	Helper.put_rsrc(vbox, 32, bldg_costs, true, true)
	add_constr_costs(vbox, p_i)

func show_planet_info(id:int, l_id:int):
	planet_hovered = l_id
	var p_i = game.planet_data[l_id]
	var wid:int = Helper.get_wid(p_i.size)
	var building:bool = game.bottom_info_action in ["building-M_SE", "building-M_MME", "building-M_MPCC"]
	var has_MS:bool = p_i.has("MS")
	var vbox = game.get_node("UI/Panel/VBox")
	if building:
		var MS:String = game.bottom_info_action.split("-")[1]
		if not has_MS:
			call("show_%s_costs" % MS, p_i, true)
	elif has_MS:
		game.get_node("UI/Panel").visible = true
		Helper.put_rsrc(vbox, 32, {})
		var stage:String = tr("%s_NAME" % p_i.MS)
		if num_stages[p_i.MS] > 0:
			stage += " (%s)" % [tr("STAGE_X_X") % [p_i.MS_lv, num_stages[p_i.MS]]]
		Helper.add_label(stage)
		if p_i.MS == "M_SE":
			Helper.add_label(tr("M_SE_%s_BENEFITS" % p_i.MS_lv), -1, false)
		elif p_i.MS == "M_MME":
			Helper.add_label(tr("PRODUCTION_PER_SECOND"), -1, false)
			Helper.put_rsrc(vbox, 32, {"minerals":Helper.get_MME_output(p_i)}, false)
			Helper.add_label(tr("CAPACITY_INCREASE"), -1, false)
			Helper.put_rsrc(vbox, 32, {"minerals":Helper.get_MME_capacity(p_i) * Helper.get_IR_mult("M_MME")}, false)
		if not p_i.bldg.has("is_constructing"):
			if p_i.MS_lv < num_stages[p_i.MS] and game.science_unlocked.has("%s%s" % [p_i.MS.split("_")[1], (p_i.MS_lv + 1)]):
				MS_constr_data.obj = p_i
				MS_constr_data.confirm = false
				Helper.add_label(tr("PRESS_F_TO_CONTINUE_CONSTR"))
	if Helper.ships_on_planet(l_id) and not p_i.has("conquered"):
		game.show_tooltip(tr("CLICK_TO_BATTLE"))
	else:
		var tooltip:String = ""
		var icons:Array = Data.desc_icons[p_i.bldg.name] if p_i.has("tile_num") and Data.desc_icons.has(p_i.bldg.name) else []
		if p_i.has("tile_num"):
			if p_i.bldg.name in ["MM", "GH", "AMN", "SPR"]:
				tooltip += "%s (%s %s)\n%s" %  [p_i.name, Helper.format_num(p_i.tile_num), tr("%s_NAME_S" % p_i.bldg.name).to_lower(), Helper.get_bldg_tooltip(p_i, p_i, 1)]
				if p_i.bldg.name == "MM":
					tooltip += "\n%s: %s m" % [tr("HOLE_DEPTH"), p_i.depth]
			else:
				tooltip += "%s (%s %s)\n%s" %  [p_i.name, Helper.format_num(p_i.tile_num), tr("%s_NAME_S" % p_i.bldg.name).to_lower(), Helper.get_bldg_tooltip(p_i, p_i, p_i.tile_num)]
		else:
			game.help_str = "planet_details"
			var T_gradient:Gradient = preload("res://Resources/TemperatureGradient.tres")
			var temp_color:String = T_gradient.interpolate(inverse_lerp(0, 500, p_i.temperature)).to_html(false)
			var P_gradient:Gradient = preload("res://Resources/IntensityGradient.tres")
			var pressure_color:String = P_gradient.interpolate(inverse_lerp(1, 150, p_i.pressure)).to_html(false)
			tooltip = "%s\n%s: %s km (%sx%s)\n%s: %s AU\n%s: [color=#%s]%s °C[/color]\n%s: [color=#%s]%s bar[/color]" % [p_i.name, tr("DIAMETER"), Helper.format_num(round(p_i.size), false, 9), wid, wid, tr("DISTANCE_FROM_STAR"), Helper.format_num(p_i.distance / 569.25, true), tr("SURFACE_TEMPERATURE"), temp_color, Helper.clever_round(p_i.temperature - 273, 4), tr("ATMOSPHERE_PRESSURE"), pressure_color, Helper.clever_round(p_i.pressure, 4)]
			if p_i.has("conquered"):
				tooltip += "\n%s" % tr("CTRL_CLICK_TO_SEND_SHIPS")
				if p_i.has("tile_num"):
					tooltip += "\n%s" % tr("PRESS_F_TO_UPGRADE")
			if game.help.has("planet_details"):
				tooltip += "\n%s\n%s" % [tr("MORE_DETAILS"), tr("HIDE_SHORTCUTS")]
		game.show_adv_tooltip(tooltip, Helper.flatten(icons))

var MS_constr_data:Dictionary = {}

func _input(event):
	if Input.is_action_just_released("F"):
		if not MS_constr_data.empty():
			if not MS_constr_data.confirm:
				var MS:String = MS_constr_data.obj.MS
				call("show_%s_costs" % MS, MS_constr_data.obj)
				MS_constr_data.confirm = true
				Helper.add_label(tr("F_TO_CONFIRM"))
			else:
				build_MS(MS_constr_data.obj, MS_constr_data.obj.MS)
		elif planet_hovered != -1 and game.planet_data[planet_hovered].has("bldg") and game.planet_data[planet_hovered].bldg.has("name"):
			game.upgrade_panel.ids = []
			game.upgrade_panel.planet = game.planet_data[planet_hovered]
			game.toggle_panel(game.upgrade_panel)

func build_MS(obj:Dictionary, MS:String):
	if bldg_costs.empty():
		return
	if obj.has("tile_num"):
		game.popup(tr("MS_ON_TF_PLANET"), 2.0)
		return
	var curr_time = OS.get_system_time_msecs()
	if game.check_enough(bldg_costs):
		game.deduct_resources(bldg_costs)
		if not game.achievement_data.progression.has("build_MS"):
			game.earn_achievement("progression", "build_MS")
		if obj.has("MS"):
			if obj.MS == "M_DS":
				game.autocollect.MS.energy -= Helper.get_DS_output(obj)
			elif obj.MS == "M_MME":
				game.autocollect.MS.minerals -= Helper.get_MME_output(obj)
			obj.MS_lv += 1
		else:
			if build_all_MS_stages:
				obj.MS_lv = num_stages[MS]
			else:
				obj.MS_lv = 0
			game.stats_univ.MS_constructed += 1
			game.stats_dim.MS_constructed += 1
			game.stats_global.MS_constructed += 1
		obj.MS = MS
		game.system_data[game.c_s].has_MS = true
		obj.bldg = {}
		obj.bldg.is_constructing = true
		obj.bldg.construction_date = curr_time
		obj.bldg.construction_length = bldg_costs.time * 1000
		obj.bldg.XP = round(bldg_costs.money / 100.0)
		game.get_node("UI/Panel").visible = false
		MS_constr_data.clear()
		Helper.save_obj("Systems", game.c_s_g, game.planet_data)
		refresh_planets()
		refresh_stars()
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)

func toggle_GH(p_i:Dictionary, fertilizer:bool):
	game.greenhouse_panel.tile_num = p_i.tile_num
	game.greenhouse_panel.p_i = p_i
	game.greenhouse_panel.fertilizer = fertilizer
	game.greenhouse_panel.c_v = "system"
	game.toggle_panel(game.greenhouse_panel)

func on_planet_click (id:int, l_id:int):
	if game.tutorial and game.tutorial.visible:
		return
	var p_i = game.planet_data[l_id]
	if not view.dragged:
		if Input.is_action_pressed("shift"):
			game.c_p = l_id
			game.c_p_g = id
			game.switch_view("planet_details")
			return
		var building:bool = game.bottom_info_action in ["building-M_SE", "building-M_MME", "building-M_MPCC"]
		if building:
			if p_i.has("conquered"):
				if not p_i.has("MS"):
					var MS:String = game.bottom_info_action.split("-")[1]
					if MS == "M_MME" and not p_i.type in [11, 12]:
						game.popup(tr("ONLY_GAS_GIANT"), 2.0)
					else:
						call("build_MS", p_i, MS)
				else:
					game.popup(tr("MS_ALREADY_PRESENT_PLANET"), 2.0)
			else:
				game.popup(tr("PLANET_MS_ERROR"), 2.5)
			return
		elif p_i.has("MS"):
			var t:String = game.item_to_use.type
			if t == "":
				if p_i.MS == "M_MME":
					return
				if p_i.MS == "M_MPCC":
					game.PC_panel.id = id
					game.PC_panel.l_id = l_id
					game.PC_panel.probe_tier = 1
					game.toggle_panel(game.PC_panel)
					game.get_node("UI/Panel").visible = false
					game.hide_tooltip()
					return
			elif p_i.bldg.has("is_constructing"):
				var curr_time = OS.get_system_time_msecs()
				var orig_num:int = game.item_to_use.num
				var speedup_time = game.speedups_info[game.item_to_use.name].time / 20.0
				var time_remaining = p_i.bldg.construction_date + p_i.bldg.construction_length - curr_time
				var num_needed = min(game.item_to_use.num, ceil((time_remaining) / float(speedup_time)))
				p_i.bldg.construction_date -= speedup_time * num_needed
				var time_sped_up = min(speedup_time * num_needed, time_remaining)
				if p_i.bldg.has("collect_date"):
					p_i.bldg.collect_date -= time_sped_up
				game.item_to_use.num -= num_needed
				game.remove_items(game.item_to_use.name, num_needed)
				game.update_item_cursor()
				return
		elif p_i.has("tile_num"):
			if p_i.bldg.name == "GH":
				toggle_GH(p_i, false)
			elif p_i.bldg.name == "AMN":
				game.AMN_panel.tf = true
				game.AMN_panel.obj = p_i
				game.AMN_panel.tile_num = p_i.tile_num
				game.toggle_panel(game.AMN_panel)
			elif p_i.bldg.name == "SPR":
				game.SPR_panel.tf = true
				game.SPR_panel.obj = p_i
				game.SPR_panel.tile_num = p_i.tile_num
				game.toggle_panel(game.SPR_panel)
		if (Input.is_action_pressed("Q") or p_i.has("conquered")) and not Input.is_action_pressed("ctrl"):
			if not p_i.has("conquered"):
				game.stats_univ.planets_conquered += 1
				game.stats_dim.planets_conquered += 1
				game.stats_global.planets_conquered += 1
				game.planet_data[l_id].conquered = true
				var all_conquered = true
				for planet in game.planet_data:
					if not planet.has("conquered"):
						all_conquered = false
				if game.system_data[game.c_s].has("conquered") != all_conquered:
					game.system_data[game.c_s].conquered = all_conquered
					Helper.save_obj("Galaxies", game.c_g_g, game.system_data)
			if not p_i.type in [11, 12]:
				if not p_i.has("bldg") or not p_i.bldg.has("name"):
					game.switch_view("planet", {"fn":"set_custom_coords", "fn_args":[["c_p", "c_p_g"], [l_id, id]]})
					Helper.save_obj("Systems", game.c_s_g, game.planet_data)
			else:
				game.popup(tr("NO_ACTIVITY_ON_GAS_GIANT"), 2.0)
		else:
			if Helper.ships_on_planet(l_id) and not p_i.has("conquered"):
				game.c_p = l_id
				game.c_p_g = id
				game.is_conquering_all = false
				game.switch_view("battle")
			else:
				if len(game.ship_data) > 0:
					if not p_i.has("conquered") or Input.is_action_pressed("ctrl"):
						game.send_ships_panel.dest_p_id = l_id
						game.toggle_panel(game.send_ships_panel)
				else:
					game.long_popup(tr("NO_SHIPS_DESC"), tr("NO_SHIPS"))
	if game.is_a_parent_of(game.HUD):
		game.HUD.refresh()

var bldg_costs:Dictionary

func on_star_over (id:int):
	var star = stars_info[id]
	var star_type:String = star.type
	var star_tier:String = ""
	if star_type.substr(0, 11) == "hypergiant ":
		star_type = star_type.split(" ")[0]
		star_tier = " %s" % star.type.split(" ")[1]
	var tooltip = tr("STAR_TITLE").format({"type":"%s%s" % [tr(star_type.to_upper()), star_tier.to_upper()], "class":star.class})
	tooltip += "\n%s\n%s %s\n%s\n%s" % [
		tr("STAR_TEMPERATURE") % [star.temperature], 
		tr("STAR_SIZE") % [star.size], tr("SOLAR_RADII"),
		tr("STAR_MASS") % [star.mass],
		tr("STAR_LUMINOSITY") % Helper.format_num(star.luminosity)
	]
	var has_MS:bool = star.has("MS")
	var vbox = game.get_node("UI/Panel/VBox")
	if game.bottom_info_action == "building_DS":
		if not has_MS:
			show_M_DS_costs(star, true)
	elif game.bottom_info_action == "building_CBS":
		if not has_MS:
			show_M_CBS_costs(star, true)
	elif game.bottom_info_action == "building_MB":
		if not has_MS or not star.MS == "M_MB":
			game.get_node("UI/Panel").visible = true
			bldg_costs = Data.MS_costs.M_MB.duplicate(true)
			for cost in bldg_costs:
				bldg_costs[cost] = round(bldg_costs[cost] * pow(star.size, 2))
			bldg_costs.time /= game.u_i.time_speed
			if game.universe_data[game.c_u].lv >= 60:
				bldg_costs.money += bldg_costs.time * 200
				bldg_costs.time = 0.2
			Helper.put_rsrc(vbox, 32, bldg_costs, true, true)
			Helper.add_label(tr("CONSTRUCTION_COSTS"), 0)
			Helper.add_label(tr("PRODUCTION_PER_SECOND"))
			Helper.put_rsrc(vbox, 32, {"SP":Helper.get_MB_output(star)}, false)
			Helper.add_label(tr("CAPACITY_INCREASE"), -1, false)
			Helper.put_rsrc(vbox, 32, {"energy":Helper.get_DS_capacity(star) * Helper.get_IR_mult("M_DS")}, false)
	elif game.bottom_info_action == "building_PK":
		if not has_MS:
			show_M_PK_costs(star, true)
	elif has_MS:
		game.get_node("UI/Panel").visible = true
		Helper.put_rsrc(vbox, 32, {})
		var stage:String = tr("%s_NAME" % star.MS)
		if num_stages[star.MS] > 0:
			stage += " (%s)" % [tr("STAGE_X_X") % [star.MS_lv, num_stages[star.MS]]]
		Helper.add_label(stage)
		if star.MS == "M_DS":
			Helper.add_label(tr("PRODUCTION_PER_SECOND"), -1, false)
			Helper.put_rsrc(vbox, 32, {"energy":Helper.get_DS_output(star)}, false)
			Helper.add_label(tr("CAPACITY_INCREASE"), -1, false)
			Helper.put_rsrc(vbox, 32, {"energy":Helper.get_DS_capacity(star) * Helper.get_IR_mult("M_DS")}, false)
		elif star.MS == "M_MB":
			Helper.add_label(tr("PRODUCTION_PER_SECOND"), -1, false)
			Helper.put_rsrc(vbox, 32, {"SP":Helper.get_MB_output(star)}, false)
			Helper.add_label(tr("CAPACITY_INCREASE"), -1, false)
			Helper.put_rsrc(vbox, 32, {"energy":Helper.get_DS_capacity(star) * Helper.get_IR_mult("M_DS")}, false)
		elif star.MS == "M_PK":
			if star.MS_lv == 0:
				Helper.add_label(tr("PK0_POWER") % int(4000 * sqrt(game.u_i.gravitational)), -1, true, true)
			elif star.MS_lv == 1:
				Helper.add_label(tr("PK1_POWER") % int(40000 * sqrt(game.u_i.gravitational)), -1, true, true)
			elif star.MS_lv == 2:
				Helper.add_label(tr("PK2_POWER"), -1, true, true)
		elif star.MS == "M_CBS":
			var p_num:int = len(game.planet_data)
			Helper.add_label(tr("CBD_PATH_1") % Helper.clever_round(1 + log(star.luminosity + 1)))
			if star.MS_lv == 0:
				Helper.add_label(tr("CBS_PATH_3") % [ceil(p_num * 0.1), 10])
			else:
				Helper.add_label(tr("CBS_PATH_3") % [ceil(p_num * star.MS_lv * 0.333), round(star.MS_lv * 33.3)])
		if not star.bldg.has("is_constructing") and star.MS_lv < num_stages[star.MS]:
			if star.MS == "M_DS" and game.science_unlocked.has("DS%s" % (star.MS_lv + 1)):
				continue_upg(star)
			elif star.MS == "M_PK" and game.science_unlocked.has("PK%s" % (star.MS_lv + 1)):
				continue_upg(star)
			elif star.MS == "M_CBS" and game.science_unlocked.has("CBS%s" % (star.MS_lv + 1)):
				continue_upg(star)
	game.show_tooltip(tooltip)

func continue_upg(obj:Dictionary):
	MS_constr_data.obj = obj
	MS_constr_data.confirm = false
	Helper.add_label(tr("PRESS_F_TO_CONTINUE_CONSTR"))

func on_star_pressed (id:int):
	var curr_time = OS.get_system_time_msecs()
	var star = stars_info[id]
	if game.bottom_info_action in ["building_DS", "building_PK", "building_CBS"]:
		if game.system_data[game.c_s].has("conquered"):
			if not star.has("MS"):
				if game.bottom_info_action == "building_DS":
					build_MS(star, "M_DS")
				elif game.bottom_info_action == "building_PK":
					build_MS(star, "M_PK")
				elif game.bottom_info_action == "building_CBS":
					build_MS(star, "M_CBS")
			else:
				game.popup(tr("MS_ALREADY_PRESENT"), 2.0)
		else:
			game.popup(tr("STAR_MS_ERROR"), 3.0)
	elif game.bottom_info_action == "building_MB":
		if game.system_data[game.c_s].has("conquered"):
			if not star.has("MS") or star.MS != "M_DS":
				game.popup(tr("MB_ERROR_1"), 3.0)
			else:
				if star.MS_lv == 4:
					build_MS(star, "M_MB")
				else:
					game.popup(tr("MB_ERROR_2"), 3.0)
		else:
			game.popup(tr("STAR_MS_ERROR"), 3.0)
	elif star.has("MS"):
		var t:String = game.item_to_use.type
		if t == "":
			if star.MS == "M_PK" and not star.bldg.has("is_constructing"):
				game.planetkiller_panel.star = star
				game.toggle_panel(game.planetkiller_panel)
		elif star.bldg.has("is_constructing"):
			var orig_num:int = game.item_to_use.num
			var speedup_time = game.speedups_info[game.item_to_use.name].time / 20.0
			var time_remaining = star.bldg.construction_date + star.bldg.construction_length - curr_time
			var num_needed = min(game.item_to_use.num, ceil((time_remaining) / float(speedup_time)))
			star.bldg.construction_date -= speedup_time * num_needed
			var time_sped_up = min(speedup_time * num_needed, time_remaining)
			if star.bldg.has("collect_date"):
				star.bldg.collect_date -= time_sped_up
			game.item_to_use.num -= num_needed
			game.remove_items(game.item_to_use.name, num_needed)
			game.update_item_cursor()
			return

func on_btn_out ():
	planet_hovered = -1
	glow_over = null
	game.get_node("UI/Panel").visible = false
	game.hide_tooltip()
	game.hide_adv_tooltip()
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
		var progress = (curr_time - star.bldg.construction_date) / float(star.bldg.construction_length)
		time_bar.get_node("TimeString").text = Helper.time_to_str(star.bldg.construction_length - curr_time + star.bldg.construction_date)
		time_bar.get_node("Bar").value = progress
		if progress > 1:
			if star.bldg.has("is_constructing"):
				star.bldg.erase("is_constructing")
				game.universe_data[game.c_u].xp += star.bldg.XP
				if star.MS == "M_DS":
					game.autocollect.MS.energy += Helper.get_DS_output(star)
					game.energy_capacity += Helper.get_DS_capacity(star) - Helper.get_DS_capacity(star, -1)
				elif star.MS == "M_MB":
					game.autocollect.MS.SP += Helper.get_MB_output(star)
				elif star.MS == "M_CBS":
					var p_num_total:int = len(game.planet_data)
					var p_num:int = ceil(p_num_total * star.MS_lv * 0.333)
					if star.MS_lv == 0:
						p_num = ceil(p_num_total * 0.1)
					for i in range(0, p_num):
						var p_i:Dictionary = game.planet_data[i]
						if p_i.empty():
							continue
						if p_i.has("cost_div"):
							p_i.cost_div = max(p_i.cost_div, 1 + log(star.luminosity + 1))
						else:
							p_i.cost_div = 1 + log(star.luminosity + 1)
					for i in len(stars_info):
						if i != id:
							var _star:Dictionary = stars_info[i]
							if _star.has("cost_div"):
								_star.cost_div = max(_star.cost_div, 1 + log(star.luminosity + 1))
							else:
								_star.cost_div = 1 + log(star.luminosity + 1)
					update()
				game.HUD.refresh()
			time_bar.queue_free()
			star_time_bars.erase(time_bar_obj)
	for time_bar_obj in planet_time_bars:
		var time_bar = time_bar_obj.node
		if not is_instance_valid(time_bar):
			continue
		var p_i = time_bar_obj.p_i
		var progress = (curr_time - p_i.bldg.construction_date) / float(p_i.bldg.construction_length)
		time_bar.get_node("TimeString").text = Helper.time_to_str(p_i.bldg.construction_length - curr_time + p_i.bldg.construction_date)
		time_bar.get_node("Bar").value = progress
		if progress > 1:
			if p_i.bldg.has("is_constructing"):
				p_i.bldg.erase("is_constructing")
				game.universe_data[game.c_u].xp += p_i.bldg.XP
				if p_i.has("MS"):
					if p_i.MS == "M_MME":
						game.autocollect.MS.minerals += Helper.get_MME_output(p_i)
						game.mineral_capacity += Helper.get_MME_capacity(p_i) - Helper.get_MME_capacity(p_i, -1)
				game.HUD.refresh()
			time_bar_obj.parent.remove_child(time_bar)
			time_bar.queue_free()
			planet_time_bars.erase(time_bar_obj)
			Helper.save_obj("Systems", game.c_s_g, game.planet_data)
#	for time_bar_obj in planet_plant_bars:
#		var time_bar = time_bar_obj.node
#		if not is_instance_valid(time_bar):
#			continue
#		var p_i = time_bar_obj.p_i
#		if not p_i.plant.has("grow_time"):
#			continue
#		var progress = (curr_time - p_i.plant.plant_date) / float(p_i.plant.grow_time)
#		time_bar.get_node("TimeString").text = Helper.time_to_str(p_i.plant.grow_time - curr_time + p_i.plant.plant_date)
#		time_bar.get_node("Bar").value = progress
#		if progress > 1:
#			if p_i.plant.is_growing:
#				p_i.plant.is_growing = false
#			time_bar_obj.parent.remove_child(time_bar)
#			time_bar.queue_free()
#			planet_plant_bars.erase(time_bar_obj)
	for rsrc_obj in star_rsrcs:
		var star = stars_info[rsrc_obj.id]
		if star.bldg.has("is_constructing"):
			continue
		#var value = Helper.update_MS_rsrc(star)
		var rsrc:ResourceStored = rsrc_obj.node
		#rsrc.set_current_bar_value(value)
		var prod:float
		if star.MS == "M_DS":
			prod = Helper.get_DS_output(star)
		elif star.MS == "M_MB":
			prod = Helper.get_MB_output(star)
		rsrc.set_text("%s/%s" % [Helper.format_num(prod), tr("S_SECOND")])
	for rsrc_obj in planet_rsrcs:
		var planet = game.planet_data[rsrc_obj.id]
		if planet.has("bldg") and planet.bldg.has("is_constructing"):
			if not planet.bldg.is_constructing:
				planet.bldg.erase("is_constructing")
			continue
		var rsrc:ResourceStored = rsrc_obj.node
		if planet.has("tile_num"):
			Helper.update_rsrc(planet, planet, rsrc)
#			if planet.bldg.name in ["PP", "RL"]:
#				var prod:float = Helper.clever_round(planet.bldg.path_1_value * Helper.get_IR_mult(planet.bldg.name) * planet.tile_num * game.u_i.time_speed)
#				rsrc.set_text("%s/%s" % [Helper.format_num(prod), tr("S_SECOND")])
#			elif planet.bldg.name == "ME":
#				var prod:float = Helper.clever_round(planet.bldg.path_1_value * Helper.get_IR_mult("ME") * (planet.ash_richness if planet.has("ash_richness") else 1.0) * planet.tile_num * game.u_i.time_speed)
#				rsrc.set_text("%s/%s" % [Helper.format_num(prod), tr("S_SECOND")])
#			elif planet.bldg.name == "MM":
#				rsrc.set_text("%s m" % planet.depth)
#			elif planet.bldg.name == "AE":
#				var prod:float = Helper.clever_round(planet.bldg.path_1_value * planet.tile_num * game.u_i.time_speed * planet.pressure)
#				rsrc.set_text("%s mol/%s" % [Helper.format_num(prod), tr("S_SECOND")])
		elif planet.has("MS"):
			var prod:float
			if planet.MS == "M_MME":
				prod = round(Helper.get_MME_output(planet))
			rsrc.set_text("%s/%s" % [Helper.format_num(prod), tr("S_SECOND")])

func _on_System_tree_exited():
	queue_free()

func finish_construct():
	pass

func add_rsrc(v:Vector2, mod:Color, icon, id:int, is_star:bool, sc:float = 1, current_bar_visible = false):
	var rsrc:ResourceStored = game.rsrc_stored_scene.instance()
	add_child(rsrc)
	rsrc.set_icon_texture(icon)
	rsrc.rect_scale *= sc
	rsrc.rect_position = v + Vector2(0, 70 * sc)
	rsrc.set_modulate(mod)
	rsrc.set_current_bar_visibility(current_bar_visible)
	if is_star:
		star_rsrcs.append({"node":rsrc, "id":id})
	else:
		planet_rsrcs.append({"node":rsrc, "id":id})

func _on_System_draw():
	refresh_planets()
