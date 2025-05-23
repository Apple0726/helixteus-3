extends Node2D

@onready var game = get_node("/root/Game")
@onready var stars_info = game.system_data[game.c_s].stars
@onready var view = get_parent()

#Used to prevent view from moving outside viewport
var dimensions:float

const PLANET_SCALE_DIV = 1200000.0
var scale_mult = 1.0
var glows = []
var planet_plant_bars = []
var star_rsrcs = []
var planet_rsrcs = []
var planet_hovered:int = -1
var tile_datas:Array = []
var build_all_MS_stages:bool = false
var CBS_range:float = 0.0
var broken_CBS_range:float = 0.0
var bldg_costs:Dictionary
var rsrc_salvaged:Dictionary

func _ready():
	refresh_stars()

func refresh_planets():
	scale_mult = 70.0 / game.system_data[game.c_s].closest_planet_distance
	CBS_range = 0.0
	broken_CBS_range = 0.0
	var curr_time = Time.get_unix_time_from_system()
	for planet_thing in get_tree().get_nodes_in_group("planet_stuff"):
		planet_thing.queue_free()
	for orbit in get_tree().get_nodes_in_group("orbits"):
		orbit.queue_free()
	for info_node in get_tree().get_nodes_in_group("info_nodes"):
		info_node.queue_free()
	for rsrc in planet_rsrcs:
		rsrc.node.queue_free()
	glows.clear()
	planet_rsrcs.clear()
	tile_datas.clear()
	var planets_affected_by_CBS:int = 0
	var planets_affected_by_broken_CBS:int = 0
	var p_num:int = len(game.planet_data)
	for i in len(stars_info):
		var star_info:Dictionary = stars_info[i]
		if star_info.has("MS") and star_info.MS == "CBS":
			if star_info.MS_lv == 0:
				if star_info.has("repair_cost"):
					planets_affected_by_broken_CBS = max(planets_affected_by_broken_CBS, ceil(p_num * 0.1))
				else:
					planets_affected_by_CBS = max(planets_affected_by_CBS, ceil(p_num * 0.1))
			else:
				if star_info.has("repair_cost"):
					planets_affected_by_broken_CBS = max(planets_affected_by_broken_CBS, ceil(p_num * star_info.MS_lv * 0.333))
				else:
					planets_affected_by_CBS = max(planets_affected_by_CBS, ceil(p_num * star_info.MS_lv * 0.333))
	for i in p_num:
		var p_i:Dictionary = game.planet_data[i]
		if p_i.is_empty():
			tile_datas.append([])
			continue
		var sc:float = p_i["distance"] / 2400.0 * scale_mult
		var tile_data_to_append:Array = game.open_obj("Planets", p_i.id)
		tile_datas.append(tile_data_to_append)
		
		var v:Vector2 = Vector2.from_angle(p_i.angle) * p_i.distance * scale_mult
		var orbit = preload("res://Scenes/Orbit.tscn").instantiate()
		add_child(orbit)
		orbit.radius = p_i.distance * scale_mult
		orbit.add_to_group("orbits")
		var planet = preload("res://Scenes/PlanetButton.tscn").instantiate()
		var planet_btn = planet.get_node("Button")
		var planet_glow = planet.get_node("Glow")
		planet_btn.texture_normal = game.planet_textures[p_i.type - 3]
		add_child(planet)
		planet_btn.connect("mouse_entered",Callable(self,"on_planet_over").bind(p_i.id, p_i.l_id))
		planet_glow.connect("mouse_entered",Callable(self,"on_glow_planet_over").bind(p_i.id, p_i.l_id, planet_glow))
		planet_btn.connect("mouse_exited",Callable(self,"on_btn_out"))
		planet_glow.connect("mouse_exited",Callable(self,"on_btn_out"))
		planet_btn.connect("pressed",Callable(self,"on_planet_click").bind(p_i["id"], p_i.l_id))
		planet_glow.connect("pressed",Callable(self,"on_planet_click").bind(p_i["id"], p_i.l_id))
		planet_btn.scale.x = p_i["size"] / PLANET_SCALE_DIV * scale_mult
		planet_btn.scale.y = p_i["size"] / PLANET_SCALE_DIV * scale_mult
		planet_glow.scale *= sc
		if game.system_data[game.c_s].has("conquered"):
			p_i.conquered = true
		if p_i.has("conquered"):
			if p_i.has("bldg"):
				planet_glow.modulate = Color(0.2, 0.2, 1, 1)
			elif p_i.has("wormhole"):
				planet_glow.modulate = Color(0.74, 0.6, 0.78, 1)
			elif p_i.type in [11, 12]:
				planet_glow.modulate = Color.BURLYWOOD
			else:
				if p_i.has("discovered"):
					planet_glow.modulate = Color(0, 1, 0, 1)
				else:
					planet_glow.modulate = Color(0.8, 1, 0, 1)
			if game.element_overlay_enabled:
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
				if not bldgs.is_empty():
					var grid:GridContainer = GridContainer.new()
					grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
					grid.columns = 3
					grid.scale *= sc * 2.5
					for bldg in bldgs:
						var bldg_count = preload("res://Scenes/EntityCount.tscn").instantiate()
						bldg_count.get_node("Texture2D").connect("mouse_entered",Callable(self,"on_entity_icon_over").bind(tr("%s_NAME" % Building.names[bldg].to_upper())))
						bldg_count.get_node("Texture2D").connect("mouse_exited",Callable(self,"on_entity_icon_out"))
						grid.add_child(bldg_count)
						bldg_count.get_node("Texture2D").texture = game.bldg_textures[bldg]
						bldg_count.get_node("Label").text = "x %s" % Helper.format_num(bldgs[bldg])
					add_child(grid)
					grid.add_to_group("info_nodes")
					grid.position.x = v.x - grid.size.x / 2.0 * sc * 2.5
					grid.position.y = v.y - (grid.size.y + 50) * sc * 2.5
		else:
			if game.element_overlay_enabled:
				add_elements(p_i, v, sc)
			else:
				var HX_count = preload("res://Scenes/EntityCount.tscn").instantiate()
				HX_count.get_node("Texture2D").connect("mouse_entered",Callable(self,"on_entity_icon_over").bind(tr("ENEMIES")))
				HX_count.get_node("Texture2D").connect("mouse_exited",Callable(self,"on_entity_icon_out"))
				HX_count.scale *= sc * 3.0
				HX_count.get_node("Label").text = "x %s" % len(p_i.HX_data)
				add_child(HX_count)
				HX_count.add_to_group("info_nodes")
				HX_count.position.x = v.x - HX_count.size.x / 2.0 * sc * 3.0
				HX_count.position.y = v.y - (HX_count.size.y + 40) * sc * 3.0
			if p_i.type in [11, 12]:
				planet_glow.modulate = Color.BURLYWOOD
			else:
				planet_glow.modulate = Color.RED
		dimensions = v.length()
		if p_i.has("MS"):
			planet_glow.modulate = Color(0.6, 0.6, 0.6, 1)
			var MS = Sprite2D.new()
			MS.texture = load("res://Graphics/Megastructures/%s_%s.png" % [p_i.MS, p_i.MS_lv])
			MS.scale *= 0.2
			if p_i.MS == "SE":
				MS.position.x = -50 * cos(p_i.angle) * scale_mult
				MS.position.y = -50 * sin(p_i.angle) * scale_mult
				MS.rotation = p_i.angle + PI / 2
			elif p_i.MS == "MME":
				MS.scale *= 0.25
				add_rsrc(v, Color(0, 0.5, 0.9, 1), Data.minerals_icon, p_i.l_id, false, sc)
			MS.scale *= scale_mult
			planet.add_child(MS)
		if p_i.has("tile_num") and p_i.bldg.has("name"):
			planet.add_child(Helper.add_lv_boxes(p_i, Vector2.ZERO, sc))
			match p_i.bldg.name:
				Building.MINERAL_EXTRACTOR:
					add_rsrc(v, Color(0, 0.5, 0.9, 1), Data.rsrc_icons[p_i.bldg.name], p_i.l_id, false, sc)
				Building.POWER_PLANT:
					add_rsrc(v, Color(0, 0.8, 0, 1), Data.rsrc_icons[p_i.bldg.name], p_i.l_id, false, sc)
				Building.RESEARCH_LAB:
					add_rsrc(v, Color(0, 0.8, 0, 1), Data.rsrc_icons[p_i.bldg.name], p_i.l_id, false, sc)
				Building.ATMOSPHERE_EXTRACTOR:
					add_rsrc(v, Color(0.89, 0.55, 1.0, 1), Data.rsrc_icons[p_i.bldg.name], p_i.l_id, false, sc)
				Building.BORING_MACHINE:
					add_rsrc(v, Color(0.6, 0.6, 0.6, 1), Data.rsrc_icons[p_i.bldg.name], p_i.l_id, false, sc, true)
		planet.position = v
		planet.add_to_group("planet_stuff")
		glows.append(planet_glow)
		if planets_affected_by_CBS > 0 and i == planets_affected_by_CBS - 1:
			CBS_range = v.length() * 1.1
		if planets_affected_by_broken_CBS > planets_affected_by_CBS and i == planets_affected_by_broken_CBS - 1:
			broken_CBS_range = v.length() * 1.1

func _draw():
	draw_arc(Vector2.ZERO, CBS_range, 0, 2*PI, 100, Color(0.4, 0.4, 1.0, 0.8), -1)
	draw_circle(Vector2.ZERO, CBS_range, Color(0.4, 0.4, 1.0, 0.15))
	draw_arc(Vector2.ZERO, broken_CBS_range, 0, 2*PI, 100, Color(0.5, 0.5, 0.5, 0.8), -1)
	draw_circle(Vector2.ZERO, broken_CBS_range, Color(0.5, 0.5, 0.5, 0.15))

func add_elements(p_i:Dictionary, v:Vector2, sc:float):
	var grid:GridContainer = GridContainer.new()
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.columns = 3
	grid.scale *= sc * 4.0
	if game.element_overlay_type == 0:#Planet interior
		var R = p_i.size * 1000.0 / 2#in meters
		var surface_volume = Helper.get_sph_V(R, R - p_i.crust_start_depth)#in m^3
		var crust_volume = Helper.get_sph_V(R - p_i.crust_start_depth, R - p_i.mantle_start_depth)
		var mantle_volume = Helper.get_sph_V(R - p_i.mantle_start_depth, R - p_i.core_start_depth)
		var core_volume = Helper.get_sph_V(R - p_i.core_start_depth)
		var crust_stone_amount = (surface_volume + crust_volume) * ((5600 + p_i.mantle_start_depth * 0.01) / 2.0)
		var mantle_stone_amount = mantle_volume * ((5690 + (p_i.mantle_start_depth + p_i.core_start_depth) * 0.01) / 2.0)
		var core_stone_amount = core_volume * ((5700 + (p_i.core_start_depth + R) * 0.01) / 2.0)
		for atom in game.show_atoms:
			var atom_count = preload("res://Scenes/EntityCount.tscn").instantiate()
			atom_count.get_node("Texture2D").connect("mouse_entered",Callable(self,"on_entity_icon_over").bind(tr("%s_NAME" % atom.to_upper())))
			atom_count.get_node("Texture2D").connect("mouse_exited",Callable(self,"on_entity_icon_out"))
			grid.add_child(atom_count)
			atom_count.get_node("Texture2D").texture = load("res://Graphics/Atoms/%s.png" % atom)
			var num:float = ((p_i.crust[atom] if p_i.crust.has(atom) else 0.0) * crust_stone_amount + (p_i.mantle[atom] if p_i.mantle.has(atom) else 0.0) * mantle_stone_amount + (p_i.core[atom] if p_i.core.has(atom) else 0.0) * core_stone_amount)# / Data.molar_mass[atom] / 1000.0
			atom_count.get_node("Label").text = "%s mol" % Helper.format_num(num, true)
	elif game.element_overlay_type == 1:
		for atom in game.show_atoms:
			var atom_count = preload("res://Scenes/EntityCount.tscn").instantiate()
			atom_count.get_node("Texture2D").connect("mouse_entered",Callable(self,"on_entity_icon_over").bind(tr("%s_NAME" % atom.to_upper())))
			atom_count.get_node("Texture2D").connect("mouse_exited",Callable(self,"on_entity_icon_out"))
			grid.add_child(atom_count)
			atom_count.get_node("Texture2D").texture = load("res://Graphics/Atoms/%s.png" % atom)
			var percentage:float = p_i.atmosphere[atom] * 100.0 if p_i.atmosphere.has(atom) else 0.0
			atom_count.get_node("Label").text = "%s%%" % Helper.clever_round(percentage)
	add_child(grid)
	grid.add_to_group("info_nodes")
	grid.position.x = v.x - grid.size.x / 2.0 * sc * 4.0
	grid.position.y = v.y - (grid.size.y + 50) * sc * 4.0

func on_entity_icon_over(txt:String):
	game.show_tooltip(txt)

func on_entity_icon_out():
	game.hide_tooltip()

func refresh_stars():
	scale_mult = 70.0 / game.system_data[game.c_s].closest_planet_distance
	for star in get_tree().get_nodes_in_group("stars_system"):
		star.queue_free()
	for rsrc in star_rsrcs:
		rsrc.node.queue_free()
	star_rsrcs.clear()
	var star_tween
	if Settings.enable_shaders:
		star_tween = create_tween()
		star_tween.set_parallel(true)
	for i in len(stars_info):
		var star_info:Dictionary = stars_info[i]
		var star = TextureButton.new()
		star.texture_normal = load("res://Graphics/Effects/spotlight_%s.png" % [int(star_info.temperature) % 3 + 4])
		self.add_child(star)
		star.scale.x = max(5.0 * star_info.size / game.STAR_SCALE_DIV, 0.008) * scale_mult
		star.scale.y = max(5.0 * star_info.size / game.STAR_SCALE_DIV, 0.008) * scale_mult
		star.texture_click_mask = preload("res://Graphics/Misc/StarCM.png")
		star.position = star_info.pos * scale_mult - Vector2(512, 512) * star.scale.x
		star.connect("mouse_entered",Callable(self,"on_star_over").bind(i))
		star.connect("mouse_exited",Callable(self,"on_btn_out"))
		star.connect("pressed",Callable(self,"on_star_pressed").bind(i))
		star.material = ShaderMaterial.new()
		star.material.shader = preload("res://Shaders/Star.gdshader")
		star.material.set_shader_parameter("time_offset", 10.0 * randf())
		star.material.set_shader_parameter("color", Helper.get_star_modulate(star_info["class"]))
		star.material.set_shader_parameter("alpha", 0.0)
		star_tween.tween_property(star.material, "shader_parameter/alpha", 1.0, 0.3)
		star.modulate = Helper.get_star_modulate(star_info["class"])
		if not game.achievement_data.exploration.has("B_star") and star_info["class"][0] == "B":
			game.earn_achievement("exploration", "B_star")
		if not game.achievement_data.exploration.has("O_star") and star_info["class"][0] == "O":
			game.earn_achievement("exploration", "O_star")
		if not game.achievement_data.exploration.has("Q_star") and star_info["class"][0] == "Q":
			game.earn_achievement("exploration", "Q_star")
		if not game.achievement_data.exploration.has("R_star") and star_info["class"][0] == "R":
			game.earn_achievement("exploration", "R_star")
		if not game.achievement_data.exploration.has("Z_star") and star_info["class"][0] == "Z":
			game.earn_achievement("exploration", "Z_star")
		if not game.achievement_data.exploration.has("HG_star") and star_info.type >= StarType.HYPERGIANT + 1:
			game.earn_achievement("exploration", "HG_star")
		if not game.achievement_data.exploration.has("HG_V_star") and star_info.type >= StarType.HYPERGIANT + 5:
			game.earn_achievement("exploration", "HG_V_star")
		if not game.achievement_data.exploration.has("HG_X_star") and star_info.type >= StarType.HYPERGIANT + 10:
			game.earn_achievement("exploration", "HG_X_star")
		if not game.achievement_data.exploration.has("HG_XX_star") and star_info.type >= StarType.HYPERGIANT + 20:
			game.earn_achievement("exploration", "HG_XX_star")
		if not game.achievement_data.exploration.has("HG_L_star") and star_info.type >= StarType.HYPERGIANT + 50:
			game.earn_achievement("exploration", "HG_L_star")
		star.add_to_group("stars_system")
		if star_info.has("MS"):
			var MS = Sprite2D.new()
			if star_info.MS == "MB":
				MS.texture = preload("res://Graphics/Megastructures/MB_0.png")
			else:
				MS.texture = load("res://Graphics/Megastructures/%s_%s.png" % [star_info.MS, star_info.MS_lv])
			MS.position = Vector2(512, 512)
			if star_info.MS == "DS":
				MS.scale *= 0.7
			star.add_child(MS)
			if star_info.MS == "DS":
				add_rsrc(star_info.pos * scale_mult, Color(0, 0.8, 0, 1), Data.energy_icon, i, true, max(star_info.size / 6.0, 0.5) * scale_mult)
			elif star_info.MS == "MB":
				add_rsrc(star_info.pos * scale_mult, Color(0, 0.8, 0, 1), Data.SP_icon, i, true, max(star_info.size / 6.0, 0.5) * scale_mult)

var glow_over

func on_planet_over (id:int, l_id:int):
	show_planet_info(id, l_id)

func on_glow_planet_over (id:int, l_id:int, glow):
	glow_over = glow
	show_planet_info(id, l_id)

func add_constr_costs(vbox:VBoxContainer, data):
	if data.has("cost_div"):
		Helper.add_label("%s (%s)" % [tr("CONSTRUCTION_COSTS"), tr("DIV_BY") % Helper.clever_round(data.cost_div)], 0)
	else:
		Helper.add_label(tr("CONSTRUCTION_COSTS"), 0)
	game.get_node("UI/Panel").visible = true
	game.get_node("UI/Panel/AnimationPlayer").play("Fade")
	
func show_DS_costs(star:Dictionary, base:bool = false):
	var vbox = game.get_node("UI/Panel/VBox")
	bldg_costs = Data.MS_costs["DS_%s" % ((star.MS_lv + 1) if not base else 0)].duplicate(true)
	if base and build_all_MS_stages:
		Helper.add_dict_to_dict(bldg_costs, Data.MS_costs.DS_1)
		Helper.add_dict_to_dict(bldg_costs, Data.MS_costs.DS_2)
		Helper.add_dict_to_dict(bldg_costs, Data.MS_costs.DS_3)
		Helper.add_dict_to_dict(bldg_costs, Data.MS_costs.DS_4)
	for cost in bldg_costs:
		bldg_costs[cost] = round(bldg_costs[cost] * pow(star.size, 2) * game.engineering_bonus.BCM / star.get("cost_div", 1.0))
	Helper.put_rsrc(vbox, 32, bldg_costs, true, true)
	add_constr_costs(vbox, star)
	Helper.add_label(tr("PRODUCTION_PER_SECOND"))
	if base and build_all_MS_stages:
		Helper.put_rsrc(vbox, 32, {"energy":Helper.get_DS_output(star, Data.MS_num_stages.DS + 1) * Helper.get_IR_mult(Building.POWER_PLANT) * game.u_i.time_speed}, false)
	else:
		Helper.put_rsrc(vbox, 32, {"energy":Helper.get_DS_output(star, 1) * Helper.get_IR_mult(Building.POWER_PLANT) * game.u_i.time_speed}, false)
	Helper.add_label(tr("CAPACITY_INCREASE"))
	await get_tree().process_frame
	if base and build_all_MS_stages:
		Helper.put_rsrc(vbox, 32, {"energy":Helper.get_DS_capacity(star, Data.MS_num_stages.DS + 1) * Helper.get_IR_mult(Building.BATTERY)}, false)
	else:
		Helper.put_rsrc(vbox, 32, {"energy":Helper.get_DS_capacity(star, 1) * Helper.get_IR_mult(Building.BATTERY)}, false)

func show_CBS_costs(star:Dictionary, base:bool = false):
	var vbox = game.get_node("UI/Panel/VBox")
	var stage:int = (star.MS_lv + 1) if not base else 0
	bldg_costs = Data.MS_costs["CBS_%s" % stage].duplicate(true)
	if base and build_all_MS_stages:
		Helper.add_dict_to_dict(bldg_costs, Data.MS_costs.CBS_1)
		Helper.add_dict_to_dict(bldg_costs, Data.MS_costs.CBS_2)
		Helper.add_dict_to_dict(bldg_costs, Data.MS_costs.CBS_3)
	for cost in bldg_costs:
		bldg_costs[cost] = round(bldg_costs[cost] * game.planet_data[-1].distance / 1000.0 * game.engineering_bonus.BCM / (star.cost_div if star.has("cost_div") else 1.0))
	Helper.put_rsrc(vbox, 32, bldg_costs, true, true)
	add_constr_costs(vbox, star)
	Helper.add_label(tr("CBD_PATH_1") % Helper.clever_round(1 + log(star.luminosity + 1)))
	var p_num:int = len(game.planet_data)
	await get_tree().process_frame
	if base and build_all_MS_stages:
		Helper.add_label(tr("CBS_PATH_3") % [p_num, 100])
	elif base:
		Helper.add_label(tr("CBS_PATH_3") % [ceil(p_num * 0.1), 10])
	else:
		Helper.add_label(tr("CBS_PATH_3") % [ceil(p_num * stage * 0.333), round(stage * 33.3)])

func show_PK_costs(star:Dictionary, base:bool = false):
	var vbox = game.get_node("UI/Panel/VBox")
	bldg_costs = Data.MS_costs["PK_%s" % ((star.MS_lv + 1) if not base else 0)].duplicate(true)
	if base and build_all_MS_stages:
		Helper.add_dict_to_dict(bldg_costs, Data.MS_costs.PK_1)
		Helper.add_dict_to_dict(bldg_costs, Data.MS_costs.PK_2)
	for cost in bldg_costs:
		bldg_costs[cost] = round(bldg_costs[cost] * game.engineering_bonus.BCM / (star.cost_div if star.has("cost_div") else 1.0))
	Helper.put_rsrc(vbox, 32, bldg_costs, true, true)
	add_constr_costs(vbox, star)
	var max_diameter = 4000
	await get_tree().process_frame
	if not star.has("MS"):
		if build_all_MS_stages:
			Helper.add_label(tr("PK2_POWER"), -1, true, true)
		else:
			Helper.add_label(tr("PK0_POWER") % int(4000 * sqrt(game.u_i.gravitational)), -1, true, true)
	elif star.MS_lv == 0:
		Helper.add_label(tr("PK1_POWER") % int(40000 * sqrt(game.u_i.gravitational)), -1, true, true)
	elif star.MS_lv == 1:
		Helper.add_label(tr("PK2_POWER"), -1, true, true)
	
func show_SE_costs(p_i:Dictionary, base:bool = false):
	var vbox = game.get_node("UI/Panel/VBox")
	bldg_costs = Data.MS_costs["SE_%s" % ((p_i.MS_lv + 1) if not base else 0)].duplicate(true)
	if base and build_all_MS_stages:
		Helper.add_dict_to_dict(bldg_costs, Data.MS_costs.SE_1)
	for cost in bldg_costs:
		if cost != "energy":
			bldg_costs[cost] = round(bldg_costs[cost] * p_i.size / 12000.0 * game.engineering_bonus.BCM / (p_i.cost_div if p_i.has("cost_div") else 1.0))
		else:
			bldg_costs.energy = round(bldg_costs.energy * p_i.size / 48000.0 * pow(max(0.25, p_i.pressure), 1.1)) * game.engineering_bonus.BCM / (p_i.cost_div if p_i.has("cost_div") else 1.0)
	Helper.put_rsrc(vbox, 32, bldg_costs, true, true)
	add_constr_costs(vbox, p_i)

func show_MME_costs(p_i:Dictionary, base:bool = false):
	var vbox = game.get_node("UI/Panel/VBox")
	bldg_costs = Data.MS_costs["MME_%s" % ((p_i.MS_lv + 1) if not base else 0)].duplicate(true)
	if base and build_all_MS_stages:
		Helper.add_dict_to_dict(bldg_costs, Data.MS_costs.MME_1)
		Helper.add_dict_to_dict(bldg_costs, Data.MS_costs.MME_2)
		Helper.add_dict_to_dict(bldg_costs, Data.MS_costs.MME_3)
	for cost in bldg_costs:
		bldg_costs[cost] = round(bldg_costs[cost] * pow(p_i.size / 13000.0, 2) * game.engineering_bonus.BCM / (p_i.cost_div if p_i.has("cost_div") else 1.0))
	Helper.put_rsrc(vbox, 32, bldg_costs, true, true)
	add_constr_costs(vbox, p_i)
	Helper.add_label(tr("PRODUCTION_PER_SECOND"), -1, false)
	await get_tree().process_frame
	if build_all_MS_stages:
		Helper.put_rsrc(vbox, 32, {"minerals":Helper.get_MME_output(p_i, Data.MS_num_stages.MME + 1) * Helper.get_IR_mult(Building.MINERAL_EXTRACTOR) * game.u_i.time_speed}, false)
	else:
		Helper.put_rsrc(vbox, 32, {"minerals":Helper.get_MME_output(p_i, 1) * Helper.get_IR_mult(Building.MINERAL_EXTRACTOR) * game.u_i.time_speed}, false)
	Helper.add_label(tr("CAPACITY_INCREASE"), -1, false)
	if build_all_MS_stages:
		Helper.put_rsrc(vbox, 32, {"minerals":Helper.get_MME_capacity(p_i, Data.MS_num_stages.MME + 1) * Helper.get_IR_mult(Building.MINERAL_SILO)}, false)
	else:
		Helper.put_rsrc(vbox, 32, {"minerals":Helper.get_MME_capacity(p_i, 1) * Helper.get_IR_mult(Building.MINERAL_SILO)}, false)

func show_planet_info(id:int, l_id:int):
	planet_hovered = l_id
	var p_i = game.planet_data[l_id]
	var wid:int = Helper.get_wid(p_i.size)
	var building:bool = game.bottom_info_action in ["building-SE", "building-MME"]
	var has_MS:bool = p_i.has("MS")
	var vbox = game.get_node("UI/Panel/VBox")
	if building:
		var MS:String = game.bottom_info_action.split("-")[1]
		if not has_MS:
			call("show_%s_costs" % MS, p_i, true)
	elif has_MS:
		game.get_node("UI/Panel").visible = true
		game.get_node("UI/Panel/AnimationPlayer").play("Fade")
		Helper.put_rsrc(vbox, 32, {})
		var stage:String
		if p_i.has("repair_cost"):
			stage = tr("BROKEN_X").format({"building_name":tr("M_%s_NAME" % p_i.MS)})
		else:
			stage = tr("M_%s_NAME" % p_i.MS)
		if Data.MS_num_stages[p_i.MS] > 0:
			stage += " (%s)" % [tr("STAGE_X_X") % [p_i.MS_lv, Data.MS_num_stages[p_i.MS]]]
		Helper.add_label(stage, -1, true, true)
		MS_constr_data.obj = p_i
		if p_i.has("repair_cost"):
			if p_i.has("conquered"):
				Helper.add_label(tr("REPAIR_COST") + ":", -1, false)
				Helper.put_rsrc(vbox, 32, {"money":p_i.repair_cost}, false)
				MS_constr_data.confirm_repair = true
				bldg_costs = {"money":p_i.repair_cost}
				Helper.add_label(tr("PRESS_F_TO_REPAIR"))
		else:
			if p_i.MS == "SE":
				Helper.add_label(tr("M_SE_%s_BENEFITS" % p_i.MS_lv), -1, false)
			elif p_i.MS == "MME":
				Helper.add_label(tr("PRODUCTION_PER_SECOND"), -1, false)
				Helper.put_rsrc(vbox, 32, {"minerals":Helper.get_MME_output(p_i) * Helper.get_IR_mult(Building.MINERAL_EXTRACTOR) * game.u_i.time_speed}, false)
				Helper.add_label(tr("CAPACITY_INCREASE"), -1, false)
				Helper.put_rsrc(vbox, 32, {"minerals":Helper.get_MME_capacity(p_i) * Helper.get_IR_mult(Building.MINERAL_SILO)}, false)
			if p_i.MS_lv < Data.MS_num_stages[p_i.MS] and game.science_unlocked.has("%s%s" % [p_i.MS, (p_i.MS_lv + 1)]):
				MS_constr_data.obj = p_i
				MS_constr_data.confirm_upgrade = false
				Helper.add_label(tr("PRESS_F_TO_CONTINUE_CONSTR"))
		Helper.add_label(tr("PRESS_X_TO_DESTROY"))
		MS_constr_data.destroyable = true
	if Helper.ships_on_planet(l_id) and not p_i.has("conquered"):
		game.show_tooltip(tr("CLICK_TO_BATTLE"))
	else:
		var tooltip:String = ""
		var icons:Array = Data.desc_icons[p_i.bldg.name] if p_i.has("tile_num") and Data.desc_icons.has(p_i.bldg.name) else []
		var additional_tooltip = ""
		if p_i.has("tile_num"):
			if p_i.bldg.name in [Building.BORING_MACHINE, Building.GREENHOUSE, Building.ATOM_MANIPULATOR, Building.SUBATOMIC_PARTICLE_REACTOR]:
				tooltip += "%s (%s %s)\n%s" %  [p_i.name, Helper.format_num(p_i.tile_num), tr("%s_NAME_S" % Building.names[p_i.bldg.name].to_upper()).to_lower(), Helper.get_bldg_tooltip(p_i, p_i, 1)]
				if p_i.bldg.name == Building.BORING_MACHINE:
					tooltip += "\n%s: %s m" % [tr("HOLE_DEPTH"), Helper.format_num(p_i.depth)]
			else:
				tooltip += "%s (%s %s)\n%s" %  [p_i.name, Helper.format_num(p_i.tile_num), tr("%s_NAME_S" % Building.names[p_i.bldg.name].to_upper()).to_lower(), Helper.get_bldg_tooltip(p_i, p_i, p_i.tile_num)]
		else:
			var T_gradient:Gradient = preload("res://Resources/TemperatureGradient.tres")
			var temp_color:String = T_gradient.sample(inverse_lerp(0, 500, p_i.temperature)).to_html(false)
			var P_gradient:Gradient = preload("res://Resources/IntensityGradient.tres")
			var pressure_color:String = P_gradient.sample(inverse_lerp(1, 150, p_i.pressure)).to_html(false)
			tooltip = "%s\n%s: %s km (%sx%s)\n%s: %s AU\n%s: [color=#%s]%s °C (%s K)[/color]\n%s: [color=#%s]%s bar[/color]" % [p_i.name, tr("DIAMETER"), Helper.format_num(round(p_i.size), false, 9), wid, wid, tr("DISTANCE_FROM_STAR"), Helper.format_num(p_i.distance / 569.25, true), tr("SURFACE_TEMPERATURE"), temp_color, Helper.clever_round(p_i.temperature - 273, 4), Helper.clever_round(p_i.temperature, 4), tr("ATMOSPHERE_PRESSURE"), pressure_color, Helper.clever_round(p_i.pressure, 4)]
			additional_tooltip = tr("CLICK_TO_SEND_SHIPS")
			if p_i.has("conquered"):
				additional_tooltip = tr("CTRL_CLICK_TO_SEND_SHIPS")
				if p_i.has("tile_num"):
					additional_tooltip += tr("PRESS_F_TO_UPGRADE")
			if game.help.has("planet_details"):
				additional_tooltip += "\n%s" % [tr("MORE_DETAILS")]
		game.show_tooltip(tooltip, {"additional_text":additional_tooltip, "additional_text_delay":1.5, "imgs": Helper.flatten(icons)})

var MS_constr_data:Dictionary = {}
var current_MS_action = ""

func _input(event):
	if Input.is_action_just_released("F"):
		if not MS_constr_data.is_empty():
			if MS_constr_data.has("confirm_repair"):
				build_MS(MS_constr_data.obj, MS_constr_data.obj.MS)
				current_MS_action = ""
				MS_constr_data.erase("confirm_repair")
			elif MS_constr_data.has("confirm_upgrade") and not MS_constr_data.confirm_upgrade:
				current_MS_action = "upgrading"
				var MS:String = MS_constr_data.obj.MS
				call("show_%s_costs" % MS, MS_constr_data.obj)
				MS_constr_data.confirm_upgrade = true
				await get_tree().process_frame
				Helper.add_label(tr("X_TO_CONFIRM") % "F")
			elif current_MS_action == "upgrading":
				build_MS(MS_constr_data.obj, MS_constr_data.obj.MS)
				current_MS_action = ""
		elif planet_hovered != -1 and game.planet_data[planet_hovered].has("bldg") and game.planet_data[planet_hovered].bldg.has("name"):
			game.upgrade_panel.ids = []
			game.upgrade_panel.planet = game.planet_data[planet_hovered]
			game.toggle_panel(game.upgrade_panel)
	elif Input.is_action_just_released("X") and MS_constr_data.has("destroyable"):
		if not MS_constr_data.has("confirm_destroy"):
			MS_constr_data.confirm_destroy = true
			current_MS_action = "destroying"
			var vbox = game.get_node("UI/Panel/VBox")
			if MS_constr_data.obj.MS == "MB":
				rsrc_salvaged = Data.MS_costs["MB"].duplicate(true)
			else:
				rsrc_salvaged = Data.MS_costs["%s_%s" % [MS_constr_data.obj.MS, MS_constr_data.obj.MS_lv]].duplicate(true)
			rsrc_salvaged.erase("money")
			rsrc_salvaged.erase("energy")
			var MS_repair_cost_money = 0.0
			var MS_repair_cost_energy = 0.0
			for rsrc in rsrc_salvaged.keys():
				if MS_constr_data.obj.MS in ["DS", "MB"]:
					rsrc_salvaged[rsrc] *= pow(MS_constr_data.obj.size, 2)
				elif MS_constr_data.obj.MS == "CBS":
					rsrc_salvaged[rsrc] *= game.planet_data[-1].distance / 1000.0
				elif MS_constr_data.obj.MS == "SE":
					rsrc_salvaged[rsrc] *= MS_constr_data.obj.size / 12000.0
				elif MS_constr_data.obj.MS == "MME":
					rsrc_salvaged[rsrc] *= pow(MS_constr_data.obj.size / 13000.0, 2)
				rsrc_salvaged[rsrc] = round(rsrc_salvaged[rsrc] * game.engineering_bonus.BCM * (0.25 if MS_constr_data.obj.has("repair_cost") else 0.5))
				if rsrc == "stone":
					MS_repair_cost_money += rsrc_salvaged[rsrc] * 2.0
					MS_repair_cost_energy += rsrc_salvaged[rsrc]
				else:
					MS_repair_cost_money += rsrc_salvaged[rsrc] * 250.0
					MS_repair_cost_energy += rsrc_salvaged[rsrc] * 50
			rsrc_salvaged.erase("stone")
			bldg_costs = {"money":MS_repair_cost_money, "energy":MS_repair_cost_energy}
			Helper.put_rsrc(vbox, 32, bldg_costs, true, true)
			Helper.put_rsrc(vbox, 32, rsrc_salvaged, false)
			Helper.add_label(tr("DISMANTLING_COSTS"), 0)
			Helper.add_label(tr("YOU_WILL_SALVAGE"), 3)
			Helper.add_label(tr("X_TO_CONFIRM") % "X")
		elif current_MS_action == "destroying":
			if game.check_enough(bldg_costs):
				game.deduct_resources(bldg_costs)
				game.add_resources(rsrc_salvaged)
				if not MS_constr_data.obj.has("repair_cost"):
					if MS_constr_data.obj.MS == "DS":
						game.autocollect.MS.energy -= Helper.get_DS_output(MS_constr_data.obj)
						game.energy_capacity -= Helper.get_DS_capacity(MS_constr_data.obj)
					elif MS_constr_data.obj.MS == "MB":
						game.autocollect.MS.SP -= Helper.get_MB_output(MS_constr_data.obj)
						game.energy_capacity -= Helper.get_DS_capacity(MS_constr_data.obj)
					elif MS_constr_data.obj.MS == "CBS":
						var p_num_total:int = len(game.planet_data)
						var p_num:int = ceil(p_num_total * MS_constr_data.obj.MS_lv * 0.333)
						if MS_constr_data.obj.MS_lv == 0:
							p_num = ceil(p_num_total * 0.1)
						for i in range(0, p_num):
							game.planet_data[i].cost_div_dict.erase(star_over_id)
							if game.planet_data[i].cost_div_dict.is_empty():
								game.planet_data[i].erase("cost_div")
								game.planet_data[i].erase("cost_div_dict")
							else:
								var div:float = 1.0
								for st in game.planet_data[i].cost_div_dict.keys():
									div = max(div, game.planet_data[i].cost_div_dict[st])
								game.planet_data[i].cost_div = div
						for i in len(stars_info):
							if stars_info[i].hash() != MS_constr_data.obj.hash():
								stars_info[i].cost_div_dict.erase(star_over_id)
								if stars_info[i].cost_div_dict.is_empty():
									stars_info[i].erase("cost_div")
									stars_info[i].erase("cost_div_dict")
								else:
									var div:float = 1.0
									for st in stars_info[i].cost_div_dict.keys():
										div = max(div, stars_info[i].cost_div_dict[st])
									stars_info[i].cost_div = div
						queue_redraw()
					elif MS_constr_data.obj.MS == "M_MMB":
						game.autocollect.MS.minerals -= Helper.get_MME_output(MS_constr_data.obj)
						game.mineral_capacity -= MS_constr_data.obj.min_cap_to_add
				MS_constr_data.obj.erase("repair_cost")
				MS_constr_data.obj.erase("MS")
				MS_constr_data.obj.erase("MS_lv")
				game.popup(tr("MS_REKT"), 2.0)
				game.get_node("UI/Panel/AnimationPlayer").play("FadeOut")
				MS_constr_data.clear()
				refresh_planets()
				refresh_stars()
			else:
				game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)

func build_MS(obj:Dictionary, MS_to_build:String):
	if bldg_costs.is_empty():
		return
	if obj.has("tile_num"):
		game.popup(tr("MS_ON_TF_PLANET"), 2.0)
		return
	if obj.has("repair_cost"):
		var error = false
		if obj.MS == "MB":
			if not game.science_unlocked.has("MB"):
				error = true
		elif obj.MS_lv == 0:
			if not game.science_unlocked.has("MAE"):
				error = true
		else:
			if not game.science_unlocked.has(obj.MS + str(obj.MS_lv)):
				error = true
		if error:
			game.popup(tr("NO_SCIENCE_TO_REPAIR_MS"), 2.0)
			return 
	var curr_time = Time.get_unix_time_from_system()
	if game.check_enough(bldg_costs):
		game.deduct_resources(bldg_costs)
		if not game.achievement_data.progression.has("build_MS"):
			game.earn_achievement("progression", "build_MS")
		if obj.has("MS"):
			if not obj.has("repair_cost"):
				obj.MS_lv += 1
				if obj.MS == "DS":
					if MS_to_build == "MB":
						game.autocollect.MS.energy -= Helper.get_DS_output(obj, -1)
					else:
						game.energy_capacity += Helper.get_DS_capacity(obj) - Helper.get_DS_capacity(obj, -1)
				elif obj.MS == "MME":
					game.mineral_capacity += Helper.get_MME_capacity(obj) - Helper.get_MME_capacity(obj, -1)
			else:
				obj.erase("repair_cost")
				if obj.MS in ["DS", "MB"]:
					game.energy_capacity += Helper.get_DS_capacity(obj)
				elif obj.MS == "MME":
					game.mineral_capacity += Helper.get_MME_capacity(obj)
		else:
			if build_all_MS_stages:
				obj.MS_lv = Data.MS_num_stages[MS_to_build]
			else:
				obj.MS_lv = 0
			if MS_to_build == "DS":
				game.energy_capacity += Helper.get_DS_capacity(obj)
			elif MS_to_build == "MME":
				game.mineral_capacity += Helper.get_MME_capacity(obj)
			game.stats_univ.MS_constructed += 1
			game.stats_dim.MS_constructed += 1
			game.stats_global.MS_constructed += 1
		obj.MS = MS_to_build
		game.system_data[game.c_s].has_MS = true
		obj.bldg = {}
		game.universe_data[game.c_u].xp += round(bldg_costs.money / 100.0)
		if obj.MS == "DS":
			game.autocollect.MS.energy += Helper.get_DS_output(obj)
		elif obj.MS == "MB":
			game.autocollect.MS.SP += Helper.get_MB_output(obj)
		elif obj.MS == "MME":
			game.autocollect.MS.minerals += Helper.get_MME_output(obj)
		elif obj.MS == "CBS":
			var p_num_total:int = len(game.planet_data)
			var p_num:int = ceil(p_num_total * obj.MS_lv * 0.333)
			if obj.MS_lv == 0:
				p_num = ceil(p_num_total * 0.1)
			var cost_div = 1 + log(obj.luminosity + 1)
			for i in range(0, p_num):
				var p_i:Dictionary = game.planet_data[i]
				if p_i.is_empty():
					continue
				p_i.cost_div = max(p_i.get("cost_div", 1.0), cost_div)
				if p_i.has("cost_div_dict"):
					p_i.cost_div_dict[star_over_id] = cost_div
				else:
					p_i.cost_div_dict = {star_over_id:cost_div}
			for i in len(stars_info):
				if i != star_over_id:
					var _star:Dictionary = stars_info[i]
					_star.cost_div = max(_star.get("cost_div", 1.0), cost_div)
					if _star.has("cost_div_dict"):
						_star.cost_div_dict[star_over_id] = cost_div
					else:
						_star.cost_div_dict = {star_over_id:cost_div}
			queue_redraw()
		game.HUD.refresh()
		game.get_node("UI/Panel/AnimationPlayer").play("FadeOut")
		MS_constr_data.clear()
		game.space_HUD.get_node("StarPanel").refresh()
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
	var p_i = game.planet_data[l_id]
	if not view.dragged:
		if Input.is_action_pressed("shift"):
			game.c_p = l_id
			game.c_p_g = id
			game.switch_view("planet_details")
			return
		var building:bool = game.bottom_info_action in ["building-SE", "building-MME"]
		if building:
			if p_i.has("conquered"):
				if not p_i.has("MS"):
					var MS:String = game.bottom_info_action.split("-")[1]
					if MS == "MME" and not p_i.type in [11, 12]:
						game.popup(tr("ONLY_GAS_GIANT"), 2.0)
					else:
						call("build_MS", p_i, MS)
				else:
					game.popup(tr("MS_ALREADY_PRESENT_PLANET"), 2.0)
			else:
				game.popup(tr("PLANET_MS_ERROR"), 2.5)
			return
		elif p_i.has("tile_num"):
			if p_i.bldg.name == Building.GREENHOUSE:
				toggle_GH(p_i, false)
			elif p_i.bldg.name == Building.ATOM_MANIPULATOR:
				game.AMN_panel.tf = true
				game.AMN_panel.obj = p_i
				game.AMN_panel.tile_num = p_i.tile_num
				game.toggle_panel(game.AMN_panel)
			elif p_i.bldg.name == Building.SUBATOMIC_PARTICLE_REACTOR:
				game.SPR_panel.tf = true
				game.SPR_panel.obj = p_i
				game.SPR_panel.tile_num = p_i.tile_num
				game.toggle_panel(game.SPR_panel)
		if p_i.has("conquered") and not Input.is_action_pressed("ctrl"):
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
						if not is_instance_valid(game.send_ships_panel) or not game.send_ships_panel.visible:
							game.fade_in_panel("send_ships_panel", {"dest_p_id": l_id})
				else:
					game.popup_window(tr("NO_SHIPS_DESC"), tr("NO_SHIPS"))
	if game.is_ancestor_of(game.HUD):
		game.HUD.refresh()

var star_over_id:int

func on_star_over (id:int):
	var star = stars_info[id]
	var star_type:int = star.type
	var star_type_str:String = ""
	var star_tier:String = ""
	match star_type:
		StarType.MAIN_SEQUENCE:
			star_type_str = tr("MAIN_SEQUENCE")
		StarType.WHITE_DWARF:
			star_type_str = tr("WHITE_DWARF")
		StarType.BROWN_DWARF:
			star_type_str = tr("BROWN_DWARF")
		StarType.GIANT:
			star_type_str = tr("GIANT")
		StarType.SUPERGIANT:
			star_type_str = tr("SUPERGIANT")
	if star_type >= StarType.HYPERGIANT + 1:
		star_type_str = tr("HYPERGIANT")
		star_tier = " " + Helper.get_roman_num(star_type - StarType.HYPERGIANT)
	var tooltip = tr("STAR_TITLE").format({"type":"%s%s" % [star_type_str, star_tier.to_upper()], "class":star["class"]})
	tooltip += "\n%s\n%s %s\n%s\n%s" % [
		tr("STAR_TEMPERATURE") % [Helper.format_num(star.temperature, false, 9)], 
		tr("STAR_SIZE") % [(Helper.clever_round(star.size, 3, true) if star.size < 1000 else Helper.format_num(star.size))], tr("SOLAR_RADII"),
		tr("STAR_MASS") % (Helper.clever_round(star.mass, 3, true) if star.mass < 1000 else Helper.format_num(star.mass)),
		tr("STAR_LUMINOSITY") % (Helper.clever_round(star.luminosity, 3, true) if star.luminosity < 1000 else Helper.format_num(star.luminosity))
	]
	show_MS_construct_info(star)
	game.show_tooltip(tooltip)

func show_MS_construct_info(star:Dictionary):
	var has_MS:bool = star.has("MS")
	var vbox = game.get_node("UI/Panel/VBox")
	if game.bottom_info_action == "building_DS":
		if not has_MS:
			show_DS_costs(star, true)
	elif game.bottom_info_action == "building_CBS":
		if not has_MS:
			show_CBS_costs(star, true)
	elif game.bottom_info_action == "building_MB":
		if not has_MS or not star.MS == "MB":
			game.get_node("UI/Panel").visible = true
			game.get_node("UI/Panel/AnimationPlayer").play("Fade")
			bldg_costs = Data.MS_costs.MB.duplicate(true)
			for cost in bldg_costs:
				bldg_costs[cost] = round(bldg_costs[cost] * pow(star.size, 2) / star.get("cost_div", 1.0))
			Helper.put_rsrc(vbox, 32, bldg_costs, true, true)
			add_constr_costs(vbox, star)
			Helper.add_label(tr("PRODUCTION_PER_SECOND"))
			Helper.put_rsrc(vbox, 32, {"SP":Helper.get_MB_output(star) * Helper.get_IR_mult(Building.RESEARCH_LAB)}, false)
			Helper.add_label(tr("CAPACITY_INCREASE"), -1, false)
			Helper.put_rsrc(vbox, 32, {"energy":Data.MS_output["DS_4"] * pow(star.size, 2) * game.u_i.planck * game.u_i.time_speed * 5000.0 * Helper.get_IR_mult(Building.POWER_PLANT)}, false)
	elif game.bottom_info_action == "building_PK":
		if not has_MS:
			show_PK_costs(star, true)
	elif has_MS:
		game.get_node("UI/Panel").visible = true
		game.get_node("UI/Panel/AnimationPlayer").play("Fade")
		Helper.put_rsrc(vbox, 32, {})
		var stage:String
		if star.has("repair_cost"):
			stage = tr("BROKEN_X").format({"building_name":tr("M_%s_NAME" % star.MS)})
		else:
			stage = tr("M_%s_NAME" % star.MS)
		if Data.MS_num_stages[star.MS] > 0:
			stage += " (%s)" % [tr("STAGE_X_X") % [star.MS_lv, Data.MS_num_stages[star.MS]]]
		Helper.add_label(stage)
		MS_constr_data.obj = star
		if star.has("repair_cost"):
			if game.system_data[game.c_s].has("conquered"):
				Helper.add_label(tr("REPAIR_COST"), -1, false)
				Helper.put_rsrc(vbox, 32, {"money":star.repair_cost}, false)
				MS_constr_data.confirm_repair = true
				bldg_costs = {"money":star.repair_cost}
				Helper.add_label(tr("PRESS_F_TO_REPAIR"))
		else:
			if star.MS == "DS":
				Helper.add_label(tr("PRODUCTION_PER_SECOND"), -1, false)
				Helper.put_rsrc(vbox, 32, {"energy":Helper.get_DS_output(star) * Helper.get_IR_mult(Building.POWER_PLANT) * game.u_i.time_speed}, false)
				Helper.add_label(tr("CAPACITY_INCREASE"), -1, false)
				Helper.put_rsrc(vbox, 32, {"energy":Helper.get_DS_capacity(star) * Helper.get_IR_mult(Building.BATTERY)}, false)
			elif star.MS == "MB":
				Helper.add_label(tr("PRODUCTION_PER_SECOND"), -1, false)
				Helper.put_rsrc(vbox, 32, {"SP":Helper.get_MB_output(star) * Helper.get_IR_mult(Building.RESEARCH_LAB) * game.u_i.time_speed}, false)
				Helper.add_label(tr("CAPACITY_INCREASE"), -1, false)
				Helper.put_rsrc(vbox, 32, {"energy":Helper.get_DS_capacity(star) * Helper.get_IR_mult(Building.BATTERY)}, false)
			elif star.MS == "PK":
				if star.MS_lv == 0:
					Helper.add_label(tr("PK0_POWER") % int(4000 * sqrt(game.u_i.gravitational)), -1, true, true)
				elif star.MS_lv == 1:
					Helper.add_label(tr("PK1_POWER") % int(40000 * sqrt(game.u_i.gravitational)), -1, true, true)
				elif star.MS_lv == 2:
					Helper.add_label(tr("PK2_POWER"), -1, true, true)
			elif star.MS == "CBS":
				var p_num:int = len(game.planet_data)
				Helper.add_label(tr("CBD_PATH_1") % Helper.clever_round(1 + log(star.luminosity + 1)))
				if star.MS_lv == 0:
					Helper.add_label(tr("CBS_PATH_3") % [ceil(p_num * 0.1), 10])
				else:
					Helper.add_label(tr("CBS_PATH_3") % [ceil(p_num * star.MS_lv * 0.333), round(star.MS_lv * 33.3)])
			if star.MS_lv < Data.MS_num_stages[star.MS]:
				if star.MS == "DS" and game.science_unlocked.has("DS%s" % (star.MS_lv + 1)):
					continue_upg(star)
				elif star.MS == "PK" and game.science_unlocked.has("PK%s" % (star.MS_lv + 1)):
					continue_upg(star)
				elif star.MS == "CBS" and game.science_unlocked.has("CBS%s" % (star.MS_lv + 1)):
					continue_upg(star)
		if game.system_data[game.c_s].has("conquered"):
			Helper.add_label(tr("PRESS_X_TO_DESTROY"))
			MS_constr_data.destroyable = true

func continue_upg(obj:Dictionary):
	MS_constr_data.obj = obj
	MS_constr_data.confirm_upgrade = false
	Helper.add_label(tr("PRESS_F_TO_CONTINUE_CONSTR"))

func on_star_pressed (id:int):
	star_over_id = id
	var curr_time = Time.get_unix_time_from_system()
	var star = stars_info[id]
	if game.bottom_info_action in ["building_DS", "building_PK", "building_CBS"]:
		if game.system_data[game.c_s].has("conquered"):
			if not star.has("MS"):
				if game.bottom_info_action == "building_DS":
					build_MS(star, "DS")
				elif game.bottom_info_action == "building_PK":
					build_MS(star, "PK")
				elif game.bottom_info_action == "building_CBS":
					build_MS(star, "CBS")
			else:
				game.popup(tr("MS_ALREADY_PRESENT"), 2.0)
		else:
			game.popup(tr("STAR_MS_ERROR"), 3.0)
	elif game.bottom_info_action == "building_MB":
		if game.system_data[game.c_s].has("conquered"):
			if not star.has("MS") or star.MS != "DS":
				game.popup(tr("MB_ERROR_1"), 3.0)
			else:
				if star.MS_lv == 4:
					build_MS(star, "MB")
				else:
					game.popup(tr("MB_ERROR_2"), 3.0)
		else:
			game.popup(tr("STAR_MS_ERROR"), 3.0)
	elif star.has("MS"):
		var t:String = game.item_to_use.type
		if t == "":
			if star.MS == "PK" and not star.has("repair_cost"):
				game.planetkiller_panel.star = star
				game.toggle_panel(game.planetkiller_panel)

func on_btn_out ():
	planet_hovered = -1
	glow_over = null
	game.get_node("UI/Panel/AnimationPlayer").play("FadeOut")
	game.hide_tooltip()
	MS_constr_data.clear()

func _process(_delta):
	for glow in glows:
		glow.modulate.a = clamp(0.6 / (view.scale.x * glow.scale.x) - 0.1, 0, 1)
		if glow.modulate.a == 0 and glow.visible:
			if glow == glow_over:
				game.hide_tooltip()
			glow.visible = false
		if glow.modulate.a != 0:
			glow.visible = true
	for orbit in get_tree().get_nodes_in_group("orbits"):
		orbit.alpha = clamp(view.scale.x * orbit.radius / 300.0, 0.05, 0.6)
		orbit.queue_redraw()
	var curr_time = Time.get_unix_time_from_system()
	for rsrc_obj in star_rsrcs:
		var star = stars_info[rsrc_obj.id]
		if star.has("repair_cost"):
			continue
		var rsrc:ResourceStored = rsrc_obj.node
		var prod:float
		if star.MS == "DS":
			prod = Helper.get_DS_output(star) * Helper.get_IR_mult(Building.POWER_PLANT) * game.u_i.time_speed
		elif star.MS == "MB":
			prod = Helper.get_MB_output(star) * Helper.get_IR_mult(Building.RESEARCH_LAB) * game.u_i.time_speed
		rsrc.set_text("%s/%s" % [Helper.format_num(prod), tr("S_SECOND")])
	for rsrc_obj in planet_rsrcs:
		var planet = game.planet_data[rsrc_obj.id]
		var rsrc:ResourceStored = rsrc_obj.node
		if planet.has("tile_num"):
			Helper.update_rsrc(planet, planet, rsrc)
		elif planet.has("MS") and not planet.has("repair_cost"):
			var prod:float
			if planet.MS == "MME":
				prod = round(Helper.get_MME_output(planet) * Helper.get_IR_mult(Building.MINERAL_EXTRACTOR) * game.u_i.time_speed)
			rsrc.set_text("%s/%s" % [Helper.format_num(prod), tr("S_SECOND")])

func _on_System_tree_exited():
	queue_free()

func finish_construct():
	pass

func add_rsrc(v:Vector2, mod:Color, icon, id:int, is_star:bool, sc:float = 1, current_bar_visible = false):
	var rsrc:ResourceStored = preload("res://Scenes/ResourceStored.tscn").instantiate()
	add_child(rsrc)
	rsrc.set_icon_texture(icon)
	rsrc.scale *= sc
	rsrc.position = v + Vector2(0, 70 * sc)
	rsrc.set_panel_modulate(mod)
	rsrc.set_current_bar_visibility(current_bar_visible)
	if is_star:
		star_rsrcs.append({"node":rsrc, "id":id})
	else:
		planet_rsrcs.append({"node":rsrc, "id":id})

func _on_System_draw():
	refresh_planets()
