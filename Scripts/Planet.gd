extends Node2D

@onready var game = get_node("/root/Game")
@onready var view = game.view
@onready var p_id = game.c_p
@onready var p_i = game.planet_data[p_id]

#Used to prevent view from moving outside viewport
var dimensions:float

#For exploring a cave
var rover_selected:int = -1
#The building you selected in construct panel
var bldg_to_construct:int = -1
#The cost of the above building
var constr_costs:Dictionary = {}
var constr_costs_total:Dictionary = {}
#The transparent sprite
var shadow:Sprite2D
var shadows:Array = []
#Local id of the tile hovered
var tile_over:int = -1
var hboxes:Array
var time_bars = []
var rsrcs:Array
var bldgs:Array#Tiles with a bldg
var plant_sprites = {}
var tiles_selected = []
var items_collected = {}

var icons_hidden:bool = false#To save performance

@onready var wid:int = round(Helper.get_wid(p_i.size))
#A rectangle enclosing all tiles
@onready var planet_bounds:PackedVector2Array = [Vector2.ONE, Vector2(1, wid * 200), Vector2(wid * 200, wid * 200), Vector2(wid * 200, 1)]

var mass_build_rect:NinePatchRect
var mass_build_rect_size:Vector2
var shadow_num:int = 0
var wormhole
var timer:Timer
var interval:float = 0.1
var star_mod:Color
var caves_data:Dictionary = {}

func _ready():
	shadows.resize(wid * wid)
	var tile_brightness:float = game.tile_brightness[p_i.type - 3]
	#$TileMap.material.shader = preload("res://Shaders/BCS.gdshader")
	var lum:float = 0.0
	for star in game.system_data[game.c_s].stars:
		var sc:float = 0.5 * star.size / (p_i.distance / 500)
		if star.luminosity > lum:
			star_mod = Helper.get_star_modulate(star["class"])
			var mod_lum = star_mod.get_luminance()
			if mod_lum < 0.2:
				star_mod = star_mod.lightened(0.2 - mod_lum)
			$TileMap.modulate = star_mod
			var strength_mult = 1.0
			if p_i.temperature >= 1500:
				strength_mult = min(remap(p_i.temperature, 1000, 3000, 1.2, 1.5), 1.5)
			else:
				strength_mult = min(remap(p_i.temperature, -273, 1000, 0.3, 1.2), 1.2)
			#var brightness:float = remap(tile_brightness, 40000, 90000, 2.5, 1.1) * strength_mult
			#var contrast:float = sqrt(brightness)
			#$TileMap.material.set_shader_parameter("brightness", min(brightness, 2.0))
			#$TileMap.material.set_shader_parameter("contrast", clamp(strength_mult, 1.0, 2.0))
			#$TileMap.material.set_shader_parameter("saturation", clamp(strength_mult, 1.0, 2.0))
			lum = star.luminosity
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = interval
	timer.start()
	timer.connect("timeout",Callable(self,"on_timeout"))
	mass_build_rect = game.mass_build_rect.instantiate()
	mass_build_rect.visible = false
	add_child(mass_build_rect)
	bldgs = []
	bldgs.resize(wid * wid)
	hboxes = []
	hboxes.resize(wid * wid)
	rsrcs = []
	rsrcs.resize(wid * wid)
	dimensions = wid * 200
	$TileMap.tile_set = game.planet_TS
	$Obstacles.tile_set = game.obstacles_TS
	$Obstacles.modulate = star_mod
	var nuclear_fusion_reactor_main_tiles = []
	if p_i.unique_bldgs.has(UniqueBuilding.NUCLEAR_FUSION_REACTOR):
		for i in len(p_i.unique_bldgs[UniqueBuilding.NUCLEAR_FUSION_REACTOR]):
			nuclear_fusion_reactor_main_tiles.append(p_i.unique_bldgs[UniqueBuilding.NUCLEAR_FUSION_REACTOR][i].tile)
	var lake_tiles:Array = [[], []]
	var ash_tiles:Array = []
	var soil_tiles:Array = []
	var aurora_tiles:Array = []
	for i in wid:
		for j in wid:
			var id2 = i % wid + j * wid
			var tile = game.tile_data[id2]
			$TileMap.set_cell(0, Vector2i(i, j), p_i.type - 3, Vector2(0, 0))
			if tile == null:
				continue
			if tile.has("crater"):
				var metal = Sprite2D.new()
				metal.texture = game.metal_textures[tile.crater.metal]
				metal.scale *= 0.4
				add_child(metal)
				metal.position = Vector2(i, j) * 200 + Vector2(100, 70)
				var crater = Sprite2D.new()
				if tile.crater.variant == 3:
					tile.crater.variant = 2
				if tile.crater.variant == 1:
					crater.texture = preload("res://Graphics/Tiles/Crater/1.png")
				else:
					crater.texture = preload("res://Graphics/Tiles/Crater/2.png")
				crater.scale *= clamp(remap(tile.crater.init_depth, 10, 1000, 0.4, 1.0), 0.4, 1.0)
				add_child(crater)
				crater.position = Vector2(i, j) * 200 + Vector2(100, 100)
			if tile.has("depth") and not tile.has("bridge") and not tile.has("crater"):
				$Obstacles.set_cell(0, Vector2i(i, j), 2, Vector2(0, 0))
			if tile.has("aurora"):
				aurora_tiles.append(id2)
			if tile.has("unique_bldg"):
				if tile.unique_bldg.name != UniqueBuilding.NUCLEAR_FUSION_REACTOR or id2 in nuclear_fusion_reactor_main_tiles:
					add_unique_building_sprite(tile, id2, Vector2(i, j) * 200)
			elif tile.has("cave"):
				if tile.cave.has("id"):
					var cave_file_path:String = "user://%s/Univ%s/Caves/%s.hx3" % [game.c_sv, game.c_u, tile.cave.id]
					var cave_data_file = FileAccess.open(cave_file_path, FileAccess.READ)
					var cave_data = cave_data_file.get_var()
					cave_data_file.close()
					caves_data[id2] = len(cave_data.seeds)
				$Obstacles.set_cell(0, Vector2i(i, j), 0, Vector2(0, 0))
			elif tile.has("volcano"):
				$Obstacles.set_cell(0, Vector2i(i, j), 4, Vector2(0, 0))
			elif tile.has("ship"):
				if len(game.ship_data) == 0:
					$Obstacles.set_cell(0, Vector2i(i, j), 1, Vector2(0, 0))
			elif tile.has("wormhole"):
				wormhole = game.wormhole_scene.instantiate()
				wormhole.get_node("Active").visible = tile.wormhole.active
				wormhole.get_node("Inactive").visible = not tile.wormhole.active
				wormhole.position = Vector2(i, j) * 200 + Vector2(100, 100)
				add_child(wormhole)
				if tile.wormhole.has("investigation_length"):
					add_time_bar(id2, "wormhole")
				p_i.wormhole = true
			elif tile.has("lake"):
				lake_tiles[tile.lake-1].append(Vector2i(i, j))
			if tile.has("ash"):
				ash_tiles.append(Vector2i(i, j))
	if len(aurora_tiles) > 400:
		for id in aurora_tiles:
			var tile = game.tile_data[id]
			var i:int = id % wid
			var j:int = id / wid
			var aurora_image = Sprite2D.new()
			aurora_image.texture = preload("res://Graphics/Tiles/Auroras.png")
			aurora_image.position = Vector2(i, j) * 200 + Vector2(100, 100)
			var hue:float = 0.4 + log(tile.aurora + 1.0) / 10.0
			var sat:float = 1.0 - floor(hue - 0.4) / 5.0
			aurora_image.modulate = Color.from_hsv(fmod(hue, 1.0), sat, 1.0) * max(log(tile.aurora) / 10.0, 1.0)
			$Auroras.add_child(aurora_image)
	else:
		for id in aurora_tiles:
			var tile = game.tile_data[id]
			var i:int = id % wid
			var j:int = id / wid
			var aurora = game.aurora_scene.instantiate()
			aurora.position = Vector2(i, j) * 200 + Vector2(100, 100)
			aurora.amount = min(5 + int(tile.aurora * 10), 50)
			aurora.lifetime = 3.0 / game.u_i.time_speed / tile.get("time_speed_bonus", 1.0)
			#aurora.process_material["shader_parameter/strength"] = 1.0 if randf() < 0.5 else 0.0
			#var hue:float = 0.4 + max(0, pow(tile.aurora.au_int, 0.35) - pow(4, 0.25)) / 10
			var hue:float = 0.4 + log(tile.aurora + 1.0) / 10.0
			var sat:float = 1.0 - floor(hue - 0.4) / 5.0
			aurora.modulate = Color.from_hsv(fmod(hue, 1.0), sat, 1.0) * max(log(tile.aurora) / 10.0, 1.0)
			$Auroras.add_child(aurora)
	$Shadow.size = Vector2.ONE * 200 * wid
	$Shadow["theme_override_styles/panel"].shadow_color = game.tile_avg_mod[p_i.type - 3] * $TileMap.modulate
	var lake_state_id = {
		"s":0,
		"l":1,
		"sc":2
	}
	$TileFeatures.set_cells_terrain_connect(2, soil_tiles, 0, 3)
	$TileFeatures.set_cells_terrain_connect(3, ash_tiles, 0, 4)
	if p_i.has("lake_1"):
		$TileFeatures.set_layer_modulate(0, Data.lake_colors[p_i.lake_1.element][p_i.lake_1.state])
		$TileFeatures.set_cells_terrain_connect(0, lake_tiles[0], 0, lake_state_id[p_i.lake_1.state])
	if p_i.has("lake_2"):
		$TileFeatures.set_layer_modulate(1, Data.lake_colors[p_i.lake_2.element][p_i.lake_2.state])
		$TileFeatures.set_cells_terrain_connect(1, lake_tiles[1], 0, lake_state_id[p_i.lake_2.state])
	$BadApple.wid_p = wid
	$BadApple.pixel_color = Color.BLACK if star_mod.get_luminance() > 0.3 else Color(0.5, 0.5, 0.5, 1.0)
	var await_counter:int = 0
	for id2 in len(game.tile_data):
		if not is_inside_tree():
			return
		var i:int = id2 % wid
		var j:int = id2 / wid
		var tile = game.tile_data[id2]
		if tile and tile.has("bldg"):
			add_bldg(id2, tile.bldg.name)
			bldgs[id2].modulate.a = 0
			var tween = create_tween()
			tween.tween_property(bldgs[id2], "modulate:a", 1.0, 0.15)
			if tile.bldg.name == Building.GREENHOUSE:
				soil_tiles.append(Vector2i(i, j))
			await_counter += 1
			if await_counter % int(1000.0 / Engine.get_frames_per_second()) == 0:
				await get_tree().process_frame

func add_unique_building_sprite(tile:Dictionary, tile_id:int, v:Vector2, building_animation:bool = false):
	var mod:Color = Color.WHITE
	if tile.unique_bldg.has("repair_cost"):
		mod = Color(0.3, 0.3, 0.3)
	var unique_building_name = tile.unique_bldg.name
	if tile.unique_bldg.name == UniqueBuilding.NUCLEAR_FUSION_REACTOR:
		bldgs[tile_id] = add_bldg_sprite(v, unique_building_name, game.unique_bldg_textures[unique_building_name], building_animation, mod, 0.8, Vector2(200, 200))
		add_rsrc(v + Vector2(200, 200), Color(0, 0.8, 0, 1), Data.energy_icon, tile_id)
	else:
		bldgs[tile_id] = add_bldg_sprite(v, unique_building_name, game.unique_bldg_textures[unique_building_name], building_animation, mod)
		if unique_building_name == UniqueBuilding.CELLULOSE_SYNTHESIZER:
			add_rsrc(v + Vector2(100, 100), Color.BROWN, Data.cellulose_icon, tile_id)
		elif unique_building_name == UniqueBuilding.SUBSTATION:
			add_rsrc(v + Vector2(100, 100), Color(0, 0.8, 0, 1), Data.energy_icon, tile_id)
	if tile.unique_bldg.tier > 1 and bldgs[tile_id]:
		var particle_props = [	{"c":Color(1.2, 2.4, 1.2), "amount":50, "lifetime":2.4},
								{"c":Color(1.2, 1.2, 2.4), "amount":60, "lifetime":2.8},
								{"c":Color(2.4, 1.2, 2.4), "amount":70, "lifetime":3.2},
								{"c":Color(2.4, 1.8, 1.2), "amount":80, "lifetime":3.6},
								{"c":Color(2.4, 2.4, 1.8), "amount":90, "lifetime":4.0},
								{"c":Color(2.4, 1.2, 1.2), "amount":100, "lifetime":4.4}]
		var particles = preload("res://Scenes/UniqueBuildingParticles.tscn").instantiate()
		particles.modulate = particle_props[tile.unique_bldg.tier - 2].c
		particles.amount = particle_props[tile.unique_bldg.tier - 2].amount
		particles.lifetime = particle_props[tile.unique_bldg.tier - 2].lifetime
		particles.speed_scale = game.u_i.time_speed * tile.get("time_speed_bonus", 1.0)
		bldgs[tile_id].add_child(particles)

func add_particles(pos:Vector2):
	var particle:GPUParticles2D = game.particles_scene.instantiate()
	particle.position = pos + Vector2(30, 30)
	particle.lifetime = 2.0 / game.u_i.time_speed
	add_child(particle)

func show_tooltip(tile, tile_id:int):
	if tile == null:
		return
	var tooltip:String = ""
	var icons = []
	var fiery_tooltip:int = -1
	var fire_strength:float = 0.0
	if tile.has("bldg"):
		tooltip = tr(Building.names[tile.bldg.name].to_upper() + "_NAME") + "\n"
		tooltip += Helper.get_bldg_tooltip(p_i, tile, 1)
		icons.append_array(Helper.flatten(Data.desc_icons[tile.bldg.name]) if Data.desc_icons.has(tile.bldg.name) else [])
		if bldg_to_construct == -1:
			if not game.get_node("UI").has_node("BuildingShortcuts") and $BuildingShortcutTimer.is_stopped():
				if game.dim_num == 1 and game.c_u == 0:
					$BuildingShortcutTimer.start(remap(game.u_i.lv, 1, 18, 0.5, 6.0))
				else:
					$BuildingShortcutTimer.start(6.0)
		if tile.has("overclock_bonus") and overclockable(tile.bldg.name):
			tooltip += "\n[color=#EEEE00]" + tr("BENEFITS_FROM_OVERCLOCK") % tile.overclock_bonus + "[/color]"
		if tile.bldg.name == Building.BORING_MACHINE:
			tooltip += "\n%s: %s m" % [tr("HOLE_DEPTH"), tile.depth]
		elif tile.bldg.name in [Building.GLASS_FACTORY, Building.STEAM_ENGINE, Building.STONE_CRUSHER]:
			tooltip += "\n[color=#88CCFF]%s\nG: %s[/color]" % [tr("CLICK_TO_CONFIGURE"), tr("LOAD_UNLOAD")]
	elif tile.has("unique_bldg"):
		tooltip += "[color=#%s]" % Data.tier_colors[tile.unique_bldg.tier - 1].to_html(false)
		var unique_building_name = UniqueBuilding.names[tile.unique_bldg.name]
		if tile.unique_bldg.has("repair_cost"):
			tooltip += tr("BROKEN_X").format({"building_name":tr(unique_building_name.to_upper())})
		else:
			tooltip += tr(unique_building_name.to_upper())
		if tile.unique_bldg.tier > 1:
			tooltip += " " + Helper.get_roman_num(tile.unique_bldg.tier)
		tooltip += "[/color]"
		tooltip += "\n"
		if game.help.has("%s_desc" % unique_building_name):
			tooltip += "[color=#BBFFFF]"
			tooltip += tr("%s_DESC1" % unique_building_name.to_upper())
			if game.help_str == "":
				game.help_str = "%s_desc" % unique_building_name
			tooltip += "\n[/color][color=#77BBBB]" + tr("HIDE_HELP") + "\n[/color]"
		var desc = tr("%s_DESC2" % unique_building_name.to_upper())
		match tile.unique_bldg.name:
			UniqueBuilding.SPACEPORT:
				desc = desc % [	Helper.get_spaceport_exit_cost_reduction(tile.unique_bldg.tier) * 100,
								Helper.get_spaceport_travel_cost_reduction(tile.unique_bldg.tier) * 100]
			UniqueBuilding.MINERAL_REPLICATOR, UniqueBuilding.MINING_OUTPOST, UniqueBuilding.OBSERVATORY:
				desc = desc.format({"n":Helper.get_unique_bldg_area(tile.unique_bldg.tier)}) % Helper.get_MR_Obs_Outpost_prod_mult(tile.unique_bldg.tier)
			UniqueBuilding.SUBSTATION:
				desc = desc.format({"n":Helper.get_unique_bldg_area(tile.unique_bldg.tier), "time":Helper.time_to_str(Helper.get_substation_capacity_bonus(tile.unique_bldg.tier))}) % Helper.get_substation_prod_mult(tile.unique_bldg.tier)
#			"AURORA_GENERATOR":
#				desc = desc.format({"intensity":Helper.get_AG_au_int_mult(tile.unique_bldg.tier), "n":Helper.get_AG_num_auroras(tile.unique_bldg.tier)})
			UniqueBuilding.NUCLEAR_FUSION_REACTOR:
				desc = desc % Helper.format_num(Helper.get_NFR_prod_mult(tile.unique_bldg.tier))
			UniqueBuilding.CELLULOSE_SYNTHESIZER:
				desc = desc % Helper.format_num(Helper.get_CS_prod_mult(tile.unique_bldg.tier))
		tooltip += desc
		icons.append_array(Data.unique_bldg_icons[tile.unique_bldg.name])
		if tile.unique_bldg.has("repair_cost"):
			tooltip += "\n" + tr("BROKEN_BLDG_DESC1") + "\n"
			icons.append(Data.money_icon)
			tooltip += tr("BROKEN_BLDG_DESC2") % Helper.format_num(tile.unique_bldg.repair_cost, true)
			icons.append(Data.money_icon)
	elif tile.has("volcano"):
		if game.help_str == "":
			game.help_str = "volcano_desc"
		if not game.help.has("volcano_desc"):
			tooltip = "%s\n[color=#BBFFFF]%s\n[/color][color=#77BBBB]%s[/color]\n%s: %s" % [tr("VOLCANO"), tr("VOLCANO_DESC"), tr("HIDE_HELP"), tr("LARGEST_VEI") % ("(" + tr("VEI") + ") "), Helper.clever_round(tile.volcano.VEI)]
		else:
			tooltip = "%s\n%s: %s" % [tr("VOLCANO"), tr("LARGEST_VEI") % "", Helper.clever_round(tile.volcano.VEI)]
	elif tile.has("crater") and tile.crater.has("init_depth"):
		if tile.has("aurora"):
			tooltip = "[aurora au_int=%s]" % tile.aurora
		if game.help_str == "":
			game.help_str = "crater_desc"
		if game.help.has("crater_desc"):
			tooltip += tr("METAL_CRATER").format({"metal":tr(tile.crater.metal.to_upper()), "crater":tr("CRATER")}) + "[color=#BBFFFF]\n%s\n[/color][color=#77BBBB]%s[/color]\n%s" % [tr("CRATER_DESC"), tr("HIDE_HELP"), tr("HOLE_DEPTH") + ": %s m"  % [tile.depth]]
		else:
			tooltip += tr("METAL_CRATER").format({"metal":tr(tile.crater.metal.to_upper()), "crater":tr("CRATER")}) + "\n%s" % [tr("HOLE_DEPTH") + ": %s m"  % [tile.depth]]
	elif tile.has("cave"):
		var au_str:String = ""
		if tile.has("aurora"):
			au_str = "[aurora au_int=%s]" % tile.aurora
			tooltip = au_str
		if tile.has("ash"):
			fiery_tooltip = tile_over
			fire_strength = tile.ash.richness
		tooltip += tr("CAVE")
		var floor_size:String = tr("FLOOR_SIZE").format({"size":tile.cave.floor_size})
		if not game.science_unlocked.has("RC"):
			tooltip += "\n%s\n%s\n%s" % [tr("CAVE_DESC"), tr("NUM_FLOORS") % tile.cave.num_floors, floor_size]
		else:
			tooltip += "\n%s" % tr("NUM_FLOORS") % tile.cave.num_floors
			if caves_data.has(tile_id):
				if caves_data[tile_id] == tile.cave.num_floors:
					tooltip += " [color=#00FF00](%s)[/color]" % (tr("EXPLORED_X") % caves_data[tile_id])
				else:
					tooltip += " [color=#FFFF00](%s)[/color]" % (tr("EXPLORED_X") % caves_data[tile_id])
			tooltip += "\n%s" % floor_size
			if game.help.has("cave_controls"):
				tooltip += "\n[color=#88CCFF]%s[/color]" % [tr("CLICK_CAVE_TO_EXPLORE")]
		if tile.cave.has("modifiers"):
			tooltip += Helper.get_modifier_string(tile.cave.modifiers, au_str, icons)
		if Settings.cave_gen_info:
			tooltip += "\n%s: %s\n%s: %.2f" % [tr("PERIOD"), tile.cave.get("period", 0), tr("AMOUNT_OF_DEBRIS"), tile.cave.get("debris", 0)]
	elif tile.has("ash"):
			tooltip = "%s\n%s: %s" % [tr("VOLCANIC_ASH"), tr("MINERAL_RICHNESS"), Helper.clever_round(tile.ash.richness)]
	elif tile.has("lake"):
		var lake_info = p_i["lake_%s" % tile.lake]
		if lake_info.state == "s" and lake_info.element == "H2O":
			tooltip = tr("ICE")
		elif lake_info.state == "l" and lake_info.element == "H2O":
			tooltip = tr("H2O_NAME")
		else:
			match lake_info.state:
				"l":
					tooltip = tr("LAKE_CONTENTS").format({"state":tr("LIQUID"), "contents":tr("%s_NAME" % lake_info.element.to_upper())})
				"s":
					tooltip = tr("LAKE_CONTENTS").format({"state":tr("SOLID"), "contents":tr("%s_NAME" % lake_info.element.to_upper())})
				"sc":
					tooltip = tr("LAKE_CONTENTS").format({"state":tr("SUPERCRITICAL"), "contents":tr("%s_NAME" % lake_info.element.to_upper())})
		tooltip += "\n" + tr("EFFECT_ON_PLANTS") + "\n[color=#00FF00]"
		if Data.lake_bonus_values[lake_info.element].operator == "x":
			tooltip += tr("%s_LAKE_BONUS" % lake_info.element.to_upper()) % Helper.clever_round(Data.lake_bonus_values[lake_info.element][lake_info.state] * game.biology_bonus[lake_info.element])
		elif Data.lake_bonus_values[lake_info.element].operator == "÷":
			tooltip += tr("%s_LAKE_BONUS" % lake_info.element.to_upper()) % Helper.clever_round(Data.lake_bonus_values[lake_info.element][lake_info.state] / game.biology_bonus[lake_info.element])
		elif Data.lake_bonus_values[lake_info.element].operator == "+":
			tooltip += tr("%s_LAKE_BONUS" % lake_info.element.to_upper()) % (Data.lake_bonus_values[lake_info.element][lake_info.state] + game.biology_bonus[lake_info.element])
		tooltip += "[/color]"
	elif tile.has("ship"):
		tooltip = tr("SPACESHIP") + "\n"
		if game.science_unlocked.has("SCT"):
			tooltip += tr("CLICK_TO_CONTROL_SHIP")
		else:
			if game.help_str == "":
				game.help_str = "abandoned_ship"
			if game.help.has("abandoned_ship"):
				tooltip += "[color=#BBFFFF]" + tr("ABANDONED_SHIP") + "\n[/color][color=#77BBBB]" + tr("HIDE_HELP") + "[/color]"
	elif tile.has("wormhole"):
		if tile.wormhole.active:
			if game.help_str == "":
				game.help_str = "active_wormhole"
			if game.help.has("active_wormhole"):
				tooltip = "%s[color=#BBFFFF]\n%s[/color][color=#77BBBB]\n%s[/color]" % [tr("ACTIVE_WORMHOLE"), tr("ACTIVE_WORMHOLE_DESC"), tr("HIDE_HELP")]
			else:
				tooltip = tr("ACTIVE_WORMHOLE")
		else:
			if game.help_str == "":
				game.help_str = "inactive_wormhole"
			if game.help.has("inactive_wormhole"):
				tooltip = "%s[color=#BBFFFF]\n%s[/color][color=#77BBBB]\n%s[/color]" % [tr("INACTIVE_WORMHOLE"), tr("INACTIVE_WORMHOLE_DESC"), tr("HIDE_HELP")]
			else:
				tooltip = tr("INACTIVE_WORMHOLE")
			var wh_costs:Dictionary = get_wh_costs()
			if not tile.wormhole.has("investigation_length"):
				tooltip += "\n%s: @i %s  @i %s" % [tr("INVESTIGATION_COSTS"), Helper.format_num(wh_costs.SP), Helper.time_to_str(wh_costs.time)]
				icons = [Data.SP_icon, Data.time_icon]
	if tile.has("depth") and not tile.has("bldg") and not tile.has("crater") and not tile.has("bridge"):
		tooltip += "%s: %s m\n%s" % [tr("HOLE_DEPTH"), tile.depth, tr("SHIFT_CLICK_TO_BRIDGE_HOLE")]
	elif bldg_to_construct in [Building.MINERAL_EXTRACTOR, Building.RESEARCH_LAB, Building.SOLAR_PANEL] and tile.has("resource_production_bonus") and not tile.resource_production_bonus.is_empty() and (game.u_i.lv < 18 or view.scale.x < 0.25):
		tooltip = tr("BUILD_HERE_FOR_X_BONUS")
		if bldg_to_construct == Building.MINERAL_EXTRACTOR and tile.resource_production_bonus.has("minerals"):
			if view.scale.x < 0.25:
				tooltip += " (x %s)" % Helper.clever_round(tile.resource_production_bonus.minerals)
			icons = [Data.minerals_icon]
		elif bldg_to_construct == Building.RESEARCH_LAB and tile.resource_production_bonus.has("SP"):
			if view.scale.x < 0.25:
				tooltip += " (x %s)" % Helper.clever_round(tile.resource_production_bonus.SP)
			icons = [Data.SP_icon]
		elif bldg_to_construct == Building.SOLAR_PANEL and tile.resource_production_bonus.has("energy"):
			if view.scale.x < 0.25:
				tooltip += " (x %s)" % Helper.clever_round(tile.resource_production_bonus.energy)
			icons = [Data.energy_icon]
		else:
			tooltip = ""
	elif tile.has("aurora") and tooltip == "":
		if game.help_str == "":
			game.help_str = "aurora_desc"
		if game.help.has("aurora_desc"):
			tooltip = "%s\n[color=#BBFFFF]%s\n[/color][color=#77BBBB]%s[/color]\n%s" % [tr("AURORA"), tr("AURORA_DESC"), tr("HIDE_HELP"), tr("AURORA_INTENSITY") + ": %s" % [tile.aurora]]
		else:
			tooltip = tr("AURORA_INTENSITY") + ": %s" % [tile.aurora]
	if tile.has("time_speed_bonus"):
		var real_time_speed_bonus = tile.time_speed_bonus
		if tile.has("cave") and game.subject_levels.dimensional_power >= 4:
			real_time_speed_bonus = Helper.clever_round(log(game.u_i.time_speed * tile.time_speed_bonus - 1.0 + exp(1.0)) / log(game.u_i.time_speed - 1.0 + exp(1.0)))
		tooltip += ("\n" if tooltip != "" else "") + "[color=#FFBBBB]" + tr("TIME_FLOWS_X_FASTER_HERE") % real_time_speed_bonus + "[/color]"
	if tooltip != "":
		game.show_adv_tooltip(tooltip, icons)
	if fiery_tooltip != -1 and is_instance_valid(game.tooltip):
		game.tooltip.get_node("ColorRect").visible = true
		game.tooltip.get_node("ColorRect").material.set_shader_parameter("seed", fiery_tooltip)
		game.tooltip.get_node("ColorRect").material.set_shader_parameter("color", Color(1, 0.51, 0, 1) * clamp(remap(fire_strength, 6.0, 12.0, 0.5, 2.0), 0.5, 2.0))
		#game.tooltip.get_node("ColorRect").material.set_shader_parameter("color", Color(1, 0.51, 0, 1) * 2.0)
		game.tooltip.get_node("ColorRect").material.set_shader_parameter("fog_mvt_spd", clamp(remap(fire_strength, 6.0, 12.0, 0.5, 1.5), 0.5, 1.5))
		#game.tooltip.get_node("ColorRect").material.set_shader_parameter("fog_mvt_spd", 1.5)

func get_wh_costs():
	return {"SP":round(10000 * pow(game.stats_univ.wormholes_activated + 1, 0.8)), "time":900 / game.u_i.time_speed if game.subject_levels.dimensional_power == 0 else 0.2}

func flash_construction_button():
	game.planet_HUD.get_node("VBoxContainer/Construct").material.set_shader_parameter("color", Color.WHITE)
	game.planet_HUD.get_node("VBoxContainer/Construct/AnimationPlayer").play("FlashOnce")

func construct_unique_building(tile_id:int, unique_building:int):
	if unique_building == -1:
		return
	if game.check_enough(constr_costs_total):
		game.deduct_resources(constr_costs_total)
		var obj = {"tile":tile_id, "tier":constructing_unique_building_tier}
		if p_i.unique_bldgs.has(unique_building):
			p_i.unique_bldgs[unique_building].append(obj)
		else:
			p_i.unique_bldgs[unique_building] = [obj]
		for j in ([tile_id, tile_id+1, tile_id+wid, tile_id+1+wid] if unique_building == UniqueBuilding.NUCLEAR_FUSION_REACTOR else [tile_id]):
			if game.tile_data[j] == null:
				game.tile_data[j] = {}
			game.tile_data[j].unique_bldg = {"name":unique_building, "tier":constructing_unique_building_tier, "id":tile_id}
		game.unique_building_counters[unique_building][constructing_unique_building_tier] = game.unique_building_counters[unique_building].get(constructing_unique_building_tier, 0) + 1
		game.u_i.xp += constr_costs_total.money / 100.0
		constr_costs_total = Data.unique_building_costs[unique_building].duplicate(true)
		var n = game.unique_building_counters[unique_building][constructing_unique_building_tier] + 1
		for cost in constr_costs_total.keys():
			constr_costs_total[cost] *= pow(constructing_unique_building_tier, 20) * pow(10, -game.engineering_bonus.unique_building_a_value) * pow(n, constructing_unique_building_tier * game.engineering_bonus.unique_building_b_value)
		add_unique_building_sprite(game.tile_data[tile_id], tile_id, Vector2(tile_id % wid, tile_id / wid) * 200)
		Helper.set_unique_bldg_bonuses(p_i, game.tile_data[tile_id].unique_bldg, tile_id, wid)
		game.HUD.refresh()
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.2)

func constr_bldg(tile_id:int, curr_time:int, _bldg_to_construct:int, mass_build:bool = false):
	if _bldg_to_construct == -1:
		return
	var tile = game.tile_data[tile_id]
	if _bldg_to_construct == Building.GREENHOUSE:
		if tile == null or not tile.has("lake_elements"):
			if not mass_build:
				game.popup(tr("NOT_ADJACENT_TO_LAKE"), 1.5)
			return
	var constr_costs2:Dictionary = constr_costs_total.duplicate()
	if game.subject_levels.dimensional_power >= 1:
		constr_costs2.time = 0.2
	else:
		constr_costs2.time /= game.u_i.time_speed
	if game.check_enough(constr_costs2):
		game.deduct_resources(constr_costs2)
		game.stats_univ.bldgs_built += 1
		game.stats_dim.bldgs_built += 1
		game.stats_global.bldgs_built += 1
		if game.stats_univ.bldgs_built >= 1 and not game.new_bldgs.has(Building.POWER_PLANT):
			game.new_bldgs[Building.POWER_PLANT] = true
			flash_construction_button()
		if game.stats_univ.bldgs_built >= 5 and not game.new_bldgs.has(Building.MINERAL_SILO):
			game.new_bldgs[Building.BATTERY] = true
			game.new_bldgs[Building.MINERAL_SILO] = true
			flash_construction_button()
		if game.stats_univ.bldgs_built >= 10 and not game.new_bldgs.has(Building.RESEARCH_LAB):
			game.new_bldgs[Building.RESEARCH_LAB] = true
			flash_construction_button()
		if game.stats_univ.bldgs_built >= 18 and not game.new_bldgs.has(Building.CENTRAL_BUSINESS_DISTRICT):
			game.new_bldgs[Building.CENTRAL_BUSINESS_DISTRICT] = true
			flash_construction_button()
		if tile == null:
			tile = {}
		if not tile.has("resource_production_bonus"):
			tile.resource_production_bonus = {}
		tile.bldg = {}
		tile.bldg.name = _bldg_to_construct
		if not game.show.has("minerals") and _bldg_to_construct == Building.MINERAL_EXTRACTOR:
			game.show.minerals = true
			game.show.shop = true
			game.HUD.minerals.visible = true
			game.HUD.shop.visible = true
			game.HUD.MU.visible = true
			game.HUD.get_node("Bottom/Panel").visible = true
		tile.bldg.is_constructing = true
		tile.bldg.construction_date = curr_time
		tile.bldg.construction_length = constr_costs2.time
		tile.bldg.XP = constr_costs2.money / 100.0
		var path_1_value
		if _bldg_to_construct != Building.PROBE_CONSTRUCTION_CENTER:
			path_1_value = Data.path_1[_bldg_to_construct].value
			tile.bldg.path_1 = 1
			tile.bldg.path_1_value = path_1_value
		if _bldg_to_construct in [Building.STONE_CRUSHER, Building.GLASS_FACTORY, Building.STEAM_ENGINE, Building.GREENHOUSE, Building.CENTRAL_BUSINESS_DISTRICT, Building.ATOM_MANIPULATOR, Building.SUBATOMIC_PARTICLE_REACTOR]:
			tile.bldg.path_2 = 1
			tile.bldg.path_2_value = Data.path_2[_bldg_to_construct].value
		if _bldg_to_construct in [Building.STONE_CRUSHER, Building.GLASS_FACTORY, Building.STEAM_ENGINE]:
			tile.bldg.collect_date = tile.bldg.construction_date + tile.bldg.construction_length
			tile.bldg.stored = 0
		if _bldg_to_construct in [Building.STONE_CRUSHER, Building.GLASS_FACTORY, Building.STEAM_ENGINE, Building.CENTRAL_BUSINESS_DISTRICT]:
			tile.bldg.path_3 = 1
			tile.bldg.path_3_value = Data.path_3[_bldg_to_construct].value
		if _bldg_to_construct == Building.RESEARCH_LAB:
			game.show.SP = true
			game.HUD.SP.visible = true
			game.HUD.sc_tree.visible = true
		elif _bldg_to_construct == Building.MINERAL_SILO:
			tile.bldg.cap_upgrade = path_1_value # The amount of cap to add once construction is done
		elif _bldg_to_construct == Building.POWER_PLANT:
			if tile.has("substation_bonus"):
				tile.bldg.cap_upgrade = path_1_value * tile.substation_bonus * Helper.get_substation_capacity_bonus(game.tile_data[tile.substation_tile].unique_bldg.tier)
			else:
				tile.bldg.cap_upgrade = 0
		elif _bldg_to_construct == Building.SOLAR_PANEL:
			if tile.has("substation_bonus"):
				tile.bldg.cap_upgrade = Helper.get_SP_production(p_i.temperature, path_1_value * (tile.get("aurora", 0.0) + 1.0) * tile.substation_bonus) * Helper.get_substation_capacity_bonus(game.tile_data[tile.substation_tile].unique_bldg.tier)
			else:
				tile.bldg.cap_upgrade = 0
		elif _bldg_to_construct == Building.BATTERY:
			tile.bldg.cap_upgrade = path_1_value * game.u_i.charge#The amount of cap to add once construction is done
		elif _bldg_to_construct == Building.CENTRAL_BUSINESS_DISTRICT:
			tile.bldg.x_pos = tile_id % wid
			tile.bldg.y_pos = tile_id / wid
			tile.bldg.wid = wid
		if _bldg_to_construct == Building.GREENHOUSE:
			var soil_tiles = $TileFeatures.get_used_cells_by_id(2, 3, Vector2i.ZERO)
			soil_tiles.append(Vector2i(tile_id % wid, int(tile_id / wid)))
			$TileFeatures.set_cells_terrain_connect(2, soil_tiles, 0, 3)
		tile.bldg.c_p_g = game.c_p_g
		if _bldg_to_construct == Building.BORING_MACHINE:
			if not tile.has("depth"):
				tile.depth = 0
			if not game.boring_machine_data.has(game.c_p_g):
				game.boring_machine_data[game.c_p_g] = {"tiles":[tile_id], "c_s_g":game.c_s_g, "c_p":game.c_p}
			else:
				game.boring_machine_data[game.c_p_g].tiles.append(tile_id)
			tile.bldg.collect_date = tile.bldg.construction_date + tile.bldg.construction_length
		game.tile_data[tile_id] = tile
		add_bldg(tile_id, _bldg_to_construct, true)
	elif not mass_build:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.2)

func speedup_bldg(tile, tile_id:int, curr_time):
	if tile.bldg.has("is_constructing"):
		var speedup_time = game.speedups_info[game.item_to_use.name].time
		#Time remaining to finish construction
		var time_remaining = tile.bldg.construction_date + tile.bldg.construction_length - curr_time
		var num_needed = min(game.item_to_use.num, ceil((time_remaining) / float(speedup_time)))
		if not tiles_selected.is_empty():
			min(game.item_to_use.num / len(tiles_selected), ceil((time_remaining) / float(speedup_time)))
		tile.bldg.construction_date -= speedup_time * num_needed
		var time_sped_up = min(speedup_time * num_needed, time_remaining)
		if tile.bldg.has("overclock_date"):
			tile.bldg.overclock_date -= time_sped_up
		if tile.bldg.has("collect_date"):
			tile.bldg.collect_date -= time_sped_up
		if tile.bldg.has("start_date"):
			tile.bldg.start_date -= time_sped_up
		game.item_to_use.num -= num_needed

func overclock_bldg(tile, tile_id:int, curr_time):
	var mult:float = game.overclocks_info[game.item_to_use.name].mult * tile.get("overclock_bonus", 1.0)
	if overclockable(tile.bldg.name) and not tile.bldg.has("is_constructing") and (not tile.bldg.has("overclock_mult") or tile.bldg.overclock_mult < mult):
		var mult_diff:float
		if not tile.bldg.has("overclock_mult"):
			add_time_bar(tile_id, "overclock")
			mult_diff = mult - 1
		else:
			mult_diff = mult - tile.bldg.overclock_mult
		tile.bldg.overclock_date = curr_time
		tile.bldg.overclock_length = game.overclocks_info[game.item_to_use.name].duration / game.u_i.time_speed / tile.get("time_speed_bonus", 1.0)
		tile.bldg.overclock_mult = mult
		if tile.bldg.name == Building.RESEARCH_LAB:
			game.autocollect.rsrc.SP += tile.bldg.path_1_value * mult_diff * tile.resource_production_bonus.get("SP", 1.0) * tile.get("time_speed_bonus", 1.0)
		elif tile.bldg.name == Building.MINERAL_EXTRACTOR:
			game.autocollect.rsrc.minerals += tile.bldg.path_1_value * mult_diff * tile.resource_production_bonus.get("minerals", 1.0) * tile.get("time_speed_bonus", 1.0)
		elif tile.bldg.name == Building.POWER_PLANT:
			game.autocollect.rsrc.energy += tile.bldg.path_1_value * mult_diff * tile.resource_production_bonus.get("energy", 1.0) * tile.get("time_speed_bonus", 1.0)
		elif tile.bldg.name == Building.SOLAR_PANEL:
			var SP_prod = Helper.get_SP_production(p_i.temperature, tile.bldg.path_1_value * mult_diff * (tile.get("aurora", 0.0) + 1.0) * tile.resource_production_bonus.get("energy", 1.0) * tile.get("time_speed_bonus", 1.0))
			game.autocollect.rsrc.energy += SP_prod
		elif tile.bldg.name == Building.ATMOSPHERE_EXTRACTOR:
			var base = tile.bldg.path_1_value * mult_diff * p_i.pressure * tile.get("time_speed_bonus", 1.0)
			for el in p_i.atmosphere:
				var base_prod:float = base * p_i.atmosphere[el]
				Helper.add_atom_production(el, base_prod)
			Helper.add_energy_from_NFR(p_i, base)
			Helper.add_energy_from_CS(p_i, base)
		elif tile.bldg.name == Building.BORING_MACHINE:
			var tiles_mined = (curr_time - tile.bldg.collect_date) * tile.bldg.path_1_value * Helper.get_prod_mult(tile) * tile.get("mining_outpost_bonus", 1.0)
			if tiles_mined >= 1:
				game.add_resources(Helper.mass_generate_rock(tile, p_i, int(tiles_mined)))
				tile.bldg.collect_date = curr_time
				tile.depth += int(tiles_mined)
		game.item_to_use.num -= 1

func click_tile(tile, tile_id:int):
	if not tile.has("bldg") or is_instance_valid(game.active_panel):
		return
	var bldg:int = tile.bldg.name
	if not tile.bldg.has("is_constructing"):
		game.c_t = tile_id
		match bldg:
			Building.GREENHOUSE:
				game.greenhouse_panel.c_v = "planet"
				if tiles_selected.is_empty():
					game.greenhouse_panel.tiles_selected = [tile_id]
					game.greenhouse_panel.tile_num = 1
				else:
					game.greenhouse_panel.tiles_selected = tiles_selected.duplicate(true)
					game.greenhouse_panel.tile_num = len(tiles_selected)
				game.greenhouse_panel.p_i = p_i
				game.toggle_panel(game.greenhouse_panel)
			Building.ROVER_CONSTRUCTION_CENTER:
				game.toggle_panel(game.RC_panel)
			Building.SHIPYARD:
				game.toggle_panel(game.shipyard_panel)
			Building.PROBE_CONSTRUCTION_CENTER:
				game.PC_panel.probe_tier = 0
				game.toggle_panel(game.PC_panel)
			Building.STONE_CRUSHER:
				game.SC_panel.c_t = tile_id
				game.toggle_panel(game.SC_panel)
				game.SC_panel.hslider.value = game.SC_panel.hslider.max_value
			Building.GLASS_FACTORY:
				game.toggle_panel(game.production_panel)
				game.production_panel.refresh2(bldg, "sand", "glass", "mats", "mats")
			Building.STEAM_ENGINE:
				game.toggle_panel(game.production_panel)
				game.production_panel.refresh2(bldg, "coal", "energy", "mats", "")
			Building.ATOM_MANIPULATOR:
				game.AMN_panel.tf = false
				game.toggle_panel(game.AMN_panel)
			Building.SUBATOMIC_PARTICLE_REACTOR:
				game.SPR_panel.tf = false
				game.toggle_panel(game.SPR_panel)
				if tile.bldg.has("reaction"):
					game.SPR_panel._on_Atom_pressed(tile.bldg.reaction)
		hide_tooltip()

func destroy_bldg(id2:int, mass:bool = false):
	var tile = game.tile_data[id2]
	var bldg:int = tile.bldg.name
	items_collected.clear()
	Helper.update_rsrc(p_i, tile)
	bldgs[id2].queue_free()
	hboxes[id2].queue_free()
	if is_instance_valid(rsrcs[id2]):
		rsrcs[id2].queue_free()
	var overclock_mult:float = tile.bldg.get("overclock_mult", 1.0)
	if bldg == Building.MINERAL_SILO:
		if tile.bldg.has("is_constructing"):
			game.mineral_capacity -= tile.bldg.path_1_value - tile.bldg.cap_upgrade
		else:
			game.mineral_capacity -= tile.bldg.path_1_value
		if game.mineral_capacity < 200:
			game.mineral_capacity = 200
	elif bldg == Building.BATTERY:
		if tile.bldg.has("is_constructing"):
			game.energy_capacity -= (tile.bldg.path_1_value - tile.bldg.cap_upgrade) * game.u_i.charge
		else:
			game.energy_capacity -= tile.bldg.path_1_value * game.u_i.charge
		if game.energy_capacity < 7500:
			game.energy_capacity = 7500
	elif bldg == Building.MINERAL_EXTRACTOR:
		if not tile.bldg.has("is_constructing"):
			game.autocollect.rsrc.minerals -= tile.bldg.path_1_value * overclock_mult * tile.resource_production_bonus.get("minerals", 1.0)
	elif bldg == Building.POWER_PLANT:
		if not tile.bldg.has("is_constructing"):
			game.autocollect.rsrc.energy -= tile.bldg.path_1_value * overclock_mult * tile.resource_production_bonus.get("energy", 1.0)
		if tile.has("substation_tile"):
			var cap_to_remove = tile.bldg.path_1_value * tile.substation_bonus * Helper.get_substation_capacity_bonus(game.tile_data[tile.substation_tile].unique_bldg.tier)
			game.tile_data[tile.substation_tile].unique_bldg.capacity_bonus -= cap_to_remove
			game.capacity_bonus_from_substation -= cap_to_remove
	elif bldg == Building.SOLAR_PANEL:
		if not tile.bldg.has("is_constructing"):
			var SP_prod = Helper.get_SP_production(p_i.temperature, tile.bldg.path_1_value * overclock_mult * (tile.get("aurora", 0.0) + 1.0))
			game.autocollect.rsrc.energy -= SP_prod
		if tile.has("substation_tile"):
			var cap_to_remove = Helper.get_SP_production(p_i.temperature, tile.bldg.path_1_value * (tile.get("aurora", 0.0) + 1.0)) * Helper.get_substation_capacity_bonus(game.tile_data[tile.substation_tile].unique_bldg.tier)
			game.tile_data[tile.substation_tile].unique_bldg.capacity_bonus -= cap_to_remove
			game.capacity_bonus_from_substation -= cap_to_remove
	elif bldg == Building.RESEARCH_LAB:
		if not tile.bldg.has("is_constructing"):
			game.autocollect.rsrc.SP -= tile.bldg.path_1_value * overclock_mult * tile.resource_production_bonus.get("SP", 1.0)
	elif bldg == Building.ATMOSPHERE_EXTRACTOR:
		if not tile.bldg.has("is_constructing"):
			var base = -tile.bldg.path_1_value * overclock_mult * p_i.pressure
			for el in p_i.atmosphere:
				var base_prod:float = base * p_i.atmosphere[el]
				Helper.add_atom_production(el, base_prod)
			Helper.add_energy_from_NFR(p_i, base)
			Helper.add_energy_from_CS(p_i, base)
	elif bldg == Building.CENTRAL_BUSINESS_DISTRICT:
		var n:int = tile.bldg.path_3_value
		var wid:int = tile.bldg.wid
		var second_path_str = "overclock"
		if game.subject_levels.dimensional_power >= 7:
			second_path_str = "time_speed"
		for i in n:
			var x:int = tile.bldg.x_pos + i - n / 2
			if x < 0 or x >= wid:
				continue
			for j in n:
				var y:int = tile.bldg.y_pos + j - n / 2
				if y < 0 or y >= tile.bldg.wid or x == tile.bldg.x_pos and y == tile.bldg.y_pos:
					continue
				var id:int = x % wid + y * wid
				var _tile = game.tile_data[id]
				_tile.cost_div_dict.erase(id2)
				if _tile.cost_div_dict.is_empty():
					_tile.erase("cost_div_dict")
					_tile.erase("cost_div")
				else:
					var div:float = 1.0
					for st in _tile.cost_div_dict.keys():
						div = max(div, _tile.cost_div_dict[st])
					_tile.cost_div = div
				_tile["%s_dict" % second_path_str].erase(id2)
				if _tile["%s_dict" % second_path_str].is_empty():
					if second_path_str == "time_speed" and _tile.has("bldg"):
						Helper.add_autocollect(p_i, _tile, -_tile.time_speed_bonus + 1.0)
					_tile.erase("%s_dict" % second_path_str)
					_tile.erase("%s_bonus" % second_path_str)
				else:
					var bonus:float = 1.0
					for st in _tile["%s_dict" % second_path_str].keys():
						bonus = max(bonus, _tile["%s_dict" % second_path_str][st])
					if second_path_str == "time_speed" and _tile.has("bldg"):
						var diff:float = bonus - _tile.time_speed_bonus
						Helper.add_autocollect(p_i, _tile, diff)
					_tile["%s_bonus" % second_path_str] = bonus
	elif bldg == Building.GREENHOUSE:
		$Soil.set_cell(id2 % wid, int(id2 / wid), -1)
		$Soil.update_bitmask_region()
	elif bldg == Building.BORING_MACHINE:
		game.boring_machine_data[game.c_p_g].tiles.erase(id2)
		if game.boring_machine_data[game.c_p_g].tiles.is_empty():
			game.boring_machine_data.erase(game.c_p_g)
	if tile.has("auto_GH"):
		Helper.remove_GH_produce_from_autocollect(tile.auto_GH.produce, tile.get("aurora", 0.0))
		game.autocollect.mats.cellulose += tile.auto_GH.cellulose_drain
		if tile.auto_GH.has("soil_drain"):
			game.autocollect.mats.soil += tile.auto_GH.soil_drain
		tile.erase("auto_GH")
	tile.erase("bldg")
	if tile.is_empty():
		game.tile_data[id2] = null
	if not mass:
		game.show_collect_info(items_collected)

func add_shadows():
	var poly:Rect2 = Rect2(mass_build_rect.position, Vector2.ZERO)
	poly.end = mouse_pos
	poly = poly.abs()
	constr_costs_total = constr_costs.duplicate()
	for cost in constr_costs.keys():
		constr_costs_total[cost] = 0
	for i in wid:
		for j in wid:
			var shadow_pos:Vector2 = Vector2(i * 200, j * 200) + Vector2(100, 100)
			var tile_rekt:Rect2 = Rect2(Vector2(i * 200, j * 200), Vector2.ONE * 200)
			var id2:int = i % wid + j * wid
			var tile = game.tile_data[id2]
			if is_instance_valid(shadows[id2]) and is_ancestor_of(shadows[id2]):
				if not poly.intersects(tile_rekt):
					shadows[id2].free()
					shadow_num -= 1
			else:
				if poly.intersects(tile_rekt) and available_to_build(tile):
					shadows[id2] = put_shadow(Sprite2D.new(), game.bldg_textures[bldg_to_construct], shadow_pos)
					shadow_num += 1
			if is_instance_valid(shadows[id2]):
				for cost in constr_costs.keys():
					constr_costs_total[cost] += constr_costs[cost] / (tile.cost_div if tile and tile.has("cost_div") else 1.0)
			

func remove_selected_tiles():
	tiles_selected.clear()
	for white_rect in get_tree().get_nodes_in_group("white_rects"):
		white_rect.queue_free()
		white_rect.remove_from_group("white_rects")

var prev_tile_over = -1
var mouse_pos = Vector2.ZERO

func check_tile_change(event, fn:String, fn_args:Array = []):
	var delta:Vector2 = event.relative / view.scale if event is InputEventMouseMotion else Vector2.ZERO
	var new_x = snapped(round(mouse_pos.x - 100), 200)
	var new_y = snapped(mouse_pos.y - 100, 200)
	var old_x = snapped(round(mouse_pos.x - delta.x - 100), 200)
	var old_y = snapped(mouse_pos.y - delta.y - 100, 200)
	if new_x > old_x:
		callv(fn, fn_args)
	elif new_x < old_x:
		callv(fn, fn_args)
	if new_y > old_y:
		callv(fn, fn_args)
	elif new_y < old_y:
		callv(fn, fn_args)

func collect_prod_bldgs(tile_id:int):
	var _tile = game.tile_data[tile_id]
	if _tile.bldg.has("is_constructing"):
		return
	var curr_time = Time.get_unix_time_from_system()
	if _tile.bldg.name in [Building.GLASS_FACTORY, Building.STEAM_ENGINE]:
		if _tile.bldg.has("qty1"):
			var prod_i = Helper.get_prod_info(_tile)
			if _tile.bldg.name == Building.GLASS_FACTORY:
				Helper.add_item_to_coll(items_collected, "sand", prod_i.qty_left)
				Helper.add_item_to_coll(items_collected, "glass", prod_i.qty_made)
			elif _tile.bldg.name == Building.STEAM_ENGINE:
				Helper.add_item_to_coll(items_collected, "coal", prod_i.qty_left)
				Helper.add_item_to_coll(items_collected, "energy", prod_i.qty_made)
			_tile.bldg.erase("qty1")
			_tile.bldg.erase("start_date")
			_tile.bldg.erase("ratio")
			_tile.bldg.erase("qty2")
		else:
			var rsrc_to_deduct = {}
			if _tile.bldg.name == Building.GLASS_FACTORY:
				rsrc_to_deduct = {"sand":_tile.bldg.path_2_value}
			elif _tile.bldg.name == Building.STEAM_ENGINE:
				rsrc_to_deduct = {"coal":_tile.bldg.path_2_value}
			if game.check_enough(rsrc_to_deduct):
				game.deduct_resources(rsrc_to_deduct)
				_tile.bldg.qty1 = _tile.bldg.path_2_value
				_tile.bldg.start_date = curr_time
				var ratio:float = _tile.bldg.path_3_value
				if _tile.bldg.name == Building.GLASS_FACTORY:
					ratio /= 15.0
				elif _tile.bldg.name == Building.STEAM_ENGINE:
					ratio *= 40.0
				_tile.bldg.ratio = ratio
				_tile.bldg.qty2 = _tile.bldg.path_2_value * ratio
	elif _tile.bldg.name == Building.STONE_CRUSHER:
		if not _tile.bldg.has("stone"):
			var stone_max_qty = _tile.bldg.path_2_value
			var stone_total = Helper.get_sum_of_dict(game.stone)
			if stone_total > 0:
				var stone_to_crush:Dictionary = {}
				var qty_to_crush = min(stone_max_qty, stone_total)
				for el in game.stone:
					stone_to_crush[el] = qty_to_crush / stone_total * game.stone[el]
					game.stone[el] *= (1.0 - qty_to_crush / stone_total)
				_tile.bldg.stone = stone_to_crush
				_tile.bldg.stone_qty = qty_to_crush
				_tile.bldg.start_date = curr_time
				var expected_rsrc:Dictionary = {}
				Helper.get_SC_output(expected_rsrc, qty_to_crush, _tile.bldg.path_3_value, stone_total)
				_tile.bldg.expected_rsrc = expected_rsrc
		else:
			var crush_spd = _tile.bldg.path_1_value * game.u_i.time_speed * _tile.get("time_speed_bonus", 1.0)
			var qty_left = max(0, round(_tile.bldg.stone_qty - (curr_time - _tile.bldg.start_date) * crush_spd))
			if qty_left > 0:
				var progress = (curr_time - _tile.bldg.start_date) * crush_spd / _tile.bldg.stone_qty
				for el in _tile.bldg.stone:
					game.stone[el] += qty_left / _tile.bldg.stone_qty * _tile.bldg.stone[el]
				var rsrc_collected = _tile.bldg.expected_rsrc.duplicate(true)
				for rsrc in rsrc_collected:
					rsrc_collected[rsrc] = round(rsrc_collected[rsrc] * progress * 1000) / 1000
					Helper.add_item_to_coll(items_collected, rsrc, rsrc_collected[rsrc])
				game.add_resources(rsrc_collected)
			else:
				for rsrc in _tile.bldg.expected_rsrc:
					Helper.add_item_to_coll(items_collected, rsrc, _tile.bldg.expected_rsrc[rsrc])
				game.add_resources(_tile.bldg.expected_rsrc)
			_tile.bldg.erase("stone")
			_tile.bldg.erase("stone_qty")
			_tile.bldg.erase("start_date")
			_tile.bldg.erase("expected_rsrc")


func _unhandled_input(event):
	var about_to_mine = game.bottom_info_action == "about_to_mine"
	var mass_build:bool = Input.is_action_pressed("left_click") and Input.is_action_pressed("shift") and game.bottom_info_action == "building" and constructing_unique_building_tier == -1
	view.move_view = not mass_build
	view.scroll_view = not mass_build
	if tile_over != -1 and game.bottom_info_action != "building" and tile_over < len(game.tile_data):
		var tile = game.tile_data[tile_over]
		if tile:
			if tile.has("unique_bldg") and tile.unique_bldg.name != UniqueBuilding.SPACEPORT and tile.unique_bldg.name in game.unique_bldgs_discovered.keys() and int(tile.unique_bldg.tier) in game.unique_bldgs_discovered[tile.unique_bldg.name].keys():
				if Input.is_action_just_released("Q"):
					var tier:int = tile.unique_bldg.tier
					game.put_bottom_info(tr("CLICK_TILE_TO_CONSTRUCT"), "building", "cancel_building")
					var base_cost = Data.unique_building_costs[tile.unique_bldg.name].duplicate(true)
					var n = game.unique_building_counters[tile.unique_bldg.name].get(tier, 0) + 1
					for cost in base_cost:
						base_cost[cost] *= pow(tier, 20) * pow(10, -game.engineering_bonus.unique_building_a_value) * pow(n, tier * game.engineering_bonus.unique_building_b_value)
					constructing_unique_building_tier = tier
					initiate_unique_building_construction(tile.unique_bldg.name, base_cost)
			if tile.has("bldg"):
				if Input.is_action_just_released("Q"):
					game.put_bottom_info(tr("CLICK_TILE_TO_CONSTRUCT"), "building", "cancel_building")
					var base_cost = Data.costs[tile.bldg.name].duplicate(true)
					for cost in base_cost:
						base_cost[cost] *= game.engineering_bonus.BCM
					if tile.bldg.name == Building.GREENHOUSE:
						base_cost.energy = round(base_cost.energy * (1 + abs(p_i.temperature - 273) / 10.0))
					construct(tile.bldg.name, base_cost)
					shadow.modulate.a = 0.5
					shadow.position = floor(mouse_pos / 200) * 200 + Vector2.ONE * 100
				elif Input.is_action_just_released("F"):
					if game.get_node("UI").has_node("BuildingShortcuts"):
						game.get_node("UI").get_node("BuildingShortcuts").close()
					else:
						$BuildingShortcutTimer.stop()
					game.upgrade_panel.planet.clear()
					if tiles_selected.is_empty():
						game.upgrade_panel.ids = [tile_over]
					else:
						game.upgrade_panel.ids = tiles_selected.duplicate(true)
					game.toggle_panel(game.upgrade_panel)
				elif Input.is_action_just_released("X") and not game.active_panel:
					hide_tooltip()
					if tiles_selected.is_empty():
						var bldg:int = tile.bldg.name
						var money_cost = 0.0
						if Data.path_1.has(bldg):
							money_cost += Data.costs[bldg].money * pow(Data.path_1[bldg].get("cost_pw", 1.3), tile.bldg.path_1)
						if Data.path_2.has(bldg):
							money_cost += Data.costs[bldg].money * pow(Data.path_2[bldg].get("cost_pw", 1.3), tile.bldg.path_2)
						if Data.path_3.has(bldg):
							money_cost += Data.costs[bldg].money * pow(Data.path_3[bldg].get("cost_pw", 1.3), tile.bldg.path_3)
						if tile.has("cost_div"):
							money_cost /= tile.cost_div
						var total_XP = 10 * (1 - pow(game.maths_bonus.ULUGF, game.u_i.lv - 1)) / (1 - game.maths_bonus.ULUGF) + game.u_i.xp
						if money_cost >= total_XP + game.money / 100.0:
							game.show_YN_panel("destroy_building", tr("DESTROY_BLDG_CONFIRM"), [tile_over])
						else:
							destroy_bldg(tile_over)
							game.HUD.refresh()
					else:
						game.show_YN_panel("destroy_buildings", tr("DESTROY_X_BUILDINGS") % [len(tiles_selected)], [tiles_selected.duplicate(true)])
				elif Input.is_action_just_released("G") and not is_instance_valid(game.active_panel):
					items_collected.clear()
					if not tiles_selected.is_empty():
						for tile_id in tiles_selected:
							collect_prod_bldgs(tile_id)
					else:
						collect_prod_bldgs(tile_over)
					game.show_collect_info(items_collected)
					game.HUD.refresh()
		if not is_instance_valid(game.active_panel) and Input.is_action_just_pressed("shift") and tile:
			tiles_selected.clear()
			if game.get_node("UI").has_node("BuildingShortcuts"):
#				game.get_node("UI").get_node("BuildingShortcuts").close()
#				var shortcuts = preload("res://Scenes/KeyboardShortcuts.tscn").instantiate()
				var shortcuts = game.get_node("UI").get_node("BuildingShortcuts")
				shortcuts.keys.clear()
				shortcuts.add_key("F", "UPGRADE_ALL")
				shortcuts.add_key("Q", "DUPLICATE")
				shortcuts.add_key("X", "DESTROY_ALL")
				shortcuts.add_key("Shift", "SELECT_ALL")
#				shortcuts.center_position.x = 1048
#				shortcuts.center_position.y = 360
#				shortcuts.name = "BuildingShortcuts"
#				game.get_node("UI").add_child(shortcuts)
				shortcuts.refresh()
			var path_1_value_sum:float = 0
			var path_2_value_sum:float = 0
			var path_3_value_sum:float = 0
			for i in len(game.tile_data):
				var select:bool = false
				var tile2 = game.tile_data[i]
				if tile2 == null or not tile2.has("bldg"):
					continue
				if tile.has("bldg"):
					if tile2.has("bldg") and tile2.bldg.name == tile.bldg.name:
						if not Input.is_action_pressed("alt") or tile2.has("cost_div"):
							select = true
				if select:
					if tile.has("bldg"):
						if tile.bldg.name in [Building.STONE_CRUSHER, Building.STEAM_ENGINE, Building.GLASS_FACTORY]:
							path_1_value_sum += Helper.get_final_value(p_i, tile2, 1)
							path_2_value_sum += Helper.get_final_value(p_i, tile2, 2)
						elif tile.bldg.name in [Building.MINERAL_EXTRACTOR, Building.POWER_PLANT, Building.SOLAR_PANEL, Building.ATMOSPHERE_EXTRACTOR, Building.BORING_MACHINE, Building.BATTERY, Building.RESEARCH_LAB, Building.MINERAL_SILO, "PC", "NC", "EC", "NSF", "ESF"]:
							path_1_value_sum += Helper.get_final_value(p_i, tile2, 1)
						else:
							path_1_value_sum = Helper.get_final_value(p_i, tile2, 1) if tile2.bldg.has("path_1_value") else 0
							path_2_value_sum = Helper.get_final_value(p_i, tile2, 2) if tile2.bldg.has("path_2_value") else 0
						path_3_value_sum = Helper.get_final_value(p_i, tile2, 3) if tile2.bldg.has("path_3_value") else 0
					tiles_selected.append(i)
					var white_rect = game.white_rect_scene.instantiate()
					white_rect.position.x = (i % wid) * 200
					white_rect.position.y = (i / wid) * 200
					white_rect.modulate.a = 0.0
					var tween = create_tween()
					tween.tween_property(white_rect, "modulate:a", 1.0, 0.1)
					add_child(white_rect)
					white_rect.add_to_group("white_rects")
			if game.shop_panel.tab in ["Speedups", "Overclocks"]:
				game.shop_panel.get_node("VBox/HBox/ItemInfo/VBox/HBox/BuyAmount").value = len(tiles_selected)
				game.shop_panel.num = len(tiles_selected)
			if tile.has("bldg") and not game.item_cursor.visible:
				if Data.desc_icons.has(tile.bldg.name):
					var tooltip:String = ""
					var N:int = len(tiles_selected)
					if N > 1:
						tooltip = str(N) + " " + tr(Building.names[tile.bldg.name].to_upper() + "_NAME_S") + "\n"
					else:
						tooltip = str(N) + " " + tr(Building.names[tile.bldg.name].to_upper() + "_NAME") + "\n"
					tooltip += Helper.get_bldg_tooltip2(tile.bldg.name, path_1_value_sum, path_2_value_sum, path_3_value_sum)
					if tile.bldg.name in [Building.GLASS_FACTORY, Building.STEAM_ENGINE, Building.STONE_CRUSHER]:
						tooltip += "\n[color=#88CCFF]G: %s[/color]" % tr("LOAD_UNLOAD_ALL")
					game.show_adv_tooltip(tooltip, Helper.flatten(Data.desc_icons[tile.bldg.name]))
				else:
					game.show_adv_tooltip(Helper.get_bldg_tooltip2(tile.bldg.name, path_1_value_sum, path_2_value_sum, path_3_value_sum) + "\n" + tr("SELECTED_X_BLDGS") % len(tiles_selected))
	if Input.is_action_just_released("shift"):
		remove_selected_tiles()
		if game.get_node("UI").has_node("BuildingShortcuts"):
			var shortcuts = game.get_node("UI").get_node("BuildingShortcuts")
			shortcuts.keys.clear()
			shortcuts.add_key("F", "UPGRADE")
			shortcuts.add_key("Q", "DUPLICATE")
			shortcuts.add_key("X", "DESTROY")
			shortcuts.add_key("Shift", "SELECT_ALL")
			shortcuts.refresh()
		view.move_view = true
		view.scroll_view = true
		if tile_over != -1 and not game.upgrade_panel.visible:
			if game.tile_data[tile_over] and not is_instance_valid(game.active_panel) and not game.item_cursor.visible and not game.planet_HUD.get_node("ConstructPanel").visible:
				show_tooltip(game.tile_data[tile_over], tile_over)
	if not is_instance_valid(game.planet_HUD) or not is_instance_valid(game.HUD):
		return
	var not_on_button:bool = not game.planet_HUD.on_button and not game.HUD.on_button and not game.close_button_over
	if event is InputEventMouse or event is InputEventScreenDrag:
		mouse_pos = to_local(event.position)
		var mouse_on_tiles = Geometry2D.is_point_in_polygon(mouse_pos, planet_bounds)
		var N:int = mass_build_rect_size.x
		var M:int = mass_build_rect_size.y
		if mass_build:
			mass_build_rect.size.x = abs(mouse_pos.x - mass_build_rect.position.x)
			mass_build_rect.size.y = abs(mouse_pos.y - mass_build_rect.position.y)
			if mouse_pos.x - mass_build_rect.position.x < 0:
				mass_build_rect.scale.x = -1
			else:
				mass_build_rect.scale.x = 1
			if mouse_pos.y - mass_build_rect.position.y < 0:
				mass_build_rect.scale.y = -1
			else:
				mass_build_rect.scale.y = 1
			check_tile_change(event, "add_shadows")
		else:
			if constructing_unique_building_tier == -1:
				for cost in constr_costs.keys():
					constr_costs_total[cost] = constr_costs[cost] / (game.tile_data[tile_over].cost_div if game.tile_data[tile_over] and game.tile_data[tile_over].has("cost_div") else 1.0)
		var black_bg = game.get_node("UI/PopupBackground").visible
		$WhiteRect.visible = mouse_on_tiles and not black_bg
		$WhiteRect.position.x = floor(mouse_pos.x / 200) * 200
		$WhiteRect.position.y = floor(mouse_pos.y / 200) * 200
		if mouse_on_tiles:
			var x_over:int = int(mouse_pos.x / 200)
			var y_over:int = int(mouse_pos.y / 200)
			tile_over = x_over % wid + y_over * wid
			if tile_over != prev_tile_over and not_on_button and not game.item_cursor.visible and not black_bg and not game.active_panel and not game.planet_HUD.get_node("ConstructPanel").visible:
				hide_tooltip()
				if not tiles_selected.is_empty() and not tile_over in tiles_selected:
					remove_selected_tiles()
				if tile_over >= len(game.tile_data):
					return
				var tile = game.tile_data[tile_over]
				show_tooltip(tile, tile_over)
				for white_rect in get_tree().get_nodes_in_group("CBD_white_rects"):
					white_rect.queue_free()
					white_rect.remove_from_group("CBD_white_rects")
				if tile and (tile.has("bldg") and tile.bldg.name == Building.CENTRAL_BUSINESS_DISTRICT or tile.has("unique_bldg") and tile.unique_bldg.name in [UniqueBuilding.MINERAL_REPLICATOR, UniqueBuilding.OBSERVATORY, UniqueBuilding.SUBSTATION, UniqueBuilding.MINING_OUTPOST]):
					var n:int = tile.bldg.path_3_value if tile.has("bldg") else Helper.get_unique_bldg_area(tile.unique_bldg.tier)
					for i in n:
						var x:int = x_over + i - n / 2
						if x < 0 or x >= wid:
							continue
						for j in n:
							var y:int = y_over + j - n / 2
							if y < 0 or y >= wid or x == x_over and y == y_over:
								continue
							var white_rect = game.white_rect_scene.instantiate()
							white_rect.position.x = x * 200
							white_rect.position.y = y * 200
							white_rect.modulate.a = 0.0
							var tween = create_tween()
							tween.tween_property(white_rect, "modulate:a", 1.0, 0.1)
							add_child(white_rect)
							white_rect.add_to_group("CBD_white_rects")
			prev_tile_over = tile_over
		else:
			if tile_over != -1 and not_on_button:
				tile_over = -1
				prev_tile_over = -1
			hide_tooltip()
		if is_instance_valid(shadow):
			shadow.visible = mouse_on_tiles and not mass_build
			shadow.modulate.a = 0.5
			if constructing_unique_building_tier != -1 and bldg_to_construct == UniqueBuilding.NUCLEAR_FUSION_REACTOR:
				shadow.position = floor(mouse_pos / 200) * 200 + Vector2.ONE * 200
			else:
				shadow.position = floor(mouse_pos / 200) * 200 + Vector2.ONE * 100
	#finish mass build
	if Input.is_action_just_released("left_click") and mass_build_rect.visible:
		mass_build_rect.visible = false
		var curr_time = Time.get_unix_time_from_system()
		for i in len(shadows):
			if is_instance_valid(shadows[i]):
				constr_bldg(get_tile_id_from_pos(shadows[i].position), curr_time, bldg_to_construct, true)
				shadows[i].queue_free()
		shadow_num = 0
		game.HUD.refresh()
		return
	#initiate mass build
	if Input.is_action_just_pressed("left_click") and not mass_build_rect.visible and Input.is_action_pressed("shift") and game.bottom_info_action == "building" and constructing_unique_building_tier == -1:
		mass_build_rect.position = mouse_pos
		mass_build_rect.size = Vector2.ZERO
		mass_build_rect.visible = true
		mass_build_rect_size = Vector2.ONE
		if available_to_build(game.tile_data[tile_over]):
			shadows[tile_over] = put_shadow(Sprite2D.new(), game.bldg_textures[bldg_to_construct], mouse_pos)
			shadow_num = 1
		else:
			shadow_num = 0
		shadow.visible = false
	if mass_build:
		return
	if (not Input.is_action_pressed("shift") and Input.is_action_just_released("left_click") or Input.is_action_pressed("shift") and Input.is_action_just_pressed("left_click") or event is InputEventScreenTouch) and not view.dragged and not_on_button and Geometry2D.is_point_in_polygon(mouse_pos, planet_bounds):
		var x_pos = int(mouse_pos.x / 200)
		var y_pos = int(mouse_pos.y / 200)
		var tile_id = get_tile_id_from_pos(mouse_pos)
		var tile = game.tile_data[tile_id]
	if (Input.is_action_just_released("left_click") or event is InputEventScreenTouch) and not view.dragged and not_on_button and Geometry2D.is_point_in_polygon(mouse_pos, planet_bounds):
		var curr_time = Time.get_unix_time_from_system()
		var x_pos = int(mouse_pos.x / 200)
		var y_pos = int(mouse_pos.y / 200)
		var tile_id = get_tile_id_from_pos(mouse_pos)
		var tile = game.tile_data[tile_id]
		if bldg_to_construct != -1:
			if constructing_unique_building_tier == -1:
				if available_to_build(tile):
					constr_bldg(tile_id, curr_time, bldg_to_construct)
			else:
				if bldg_to_construct == UniqueBuilding.NUCLEAR_FUSION_REACTOR:
					if x_pos < wid-1 and y_pos < wid-1:
						for _tile_id in [tile_id, tile_id+1, tile_id+wid, tile_id+1+wid]:
							if is_obstacle(game.tile_data[_tile_id]):
								return
						construct_unique_building(tile_id, bldg_to_construct)
				else:
					if bldg_to_construct == UniqueBuilding.SPACEPORT and p_i.unique_bldgs.has(UniqueBuilding.SPACEPORT) and not p_i.unique_bldgs[UniqueBuilding.SPACEPORT].is_empty():
						game.popup(tr("SPACEPORT_ERROR"), 2.0)
						return
					if not is_obstacle(tile):
						construct_unique_building(tile_id, bldg_to_construct)
		if about_to_mine and available_for_mining(tile):
			game.mine_tile(tile_id)
			return
		if tile and tile.has("depth") and not tile.has("bldg") and bldg_to_construct == -1 and not tile.has("bridge"):
			if Input.is_action_pressed("shift"):
				game.tile_data[tile_id].bridge = true
				$Obstacles.set_cell(0, Vector2i(x_pos, y_pos))
			else:
				game.mine_tile(tile_id)
		if tile and bldg_to_construct == -1:
			items_collected.clear()
			var t:String = game.item_to_use.type
			if tile.has("bldg"):
				if t in ["speedup", "overclock"]:
					var orig_num:int = game.item_to_use.num
					if tiles_selected.is_empty():
						call("%s_bldg" % [t], tile, tile_id, curr_time)
					else:
						for _tile in tiles_selected:
							call("%s_bldg" % [t], game.tile_data[_tile], _tile, curr_time)
							if game.item_to_use.num <= 0:
								break
					game.remove_items(game.item_to_use.name, orig_num - game.item_to_use.num)
					game.update_item_cursor()
				else:
					click_tile(tile, tile_id)
					mouse_pos = Vector2.ZERO
			elif tile.has("unique_bldg"):
				if tile.unique_bldg.has("repair_cost"):
					if game.money >= tile.unique_bldg.repair_cost:
						game.money -= tile.unique_bldg.repair_cost
						p_i.unique_bldgs[tile.unique_bldg.name][tile.unique_bldg.id].erase("repair_cost")
						if tile.unique_bldg.name == UniqueBuilding.NUCLEAR_FUSION_REACTOR:
							var tile_id2 = p_i.unique_bldgs[tile.unique_bldg.name][tile.unique_bldg.id].tile
							for j in [tile_id2, tile_id2+1, tile_id2+wid, tile_id2+wid+1]:
								game.tile_data[j].unique_bldg.erase("repair_cost")
							bldgs[tile_id2].self_modulate = Color.WHITE
							Helper.set_unique_bldg_bonuses(p_i, tile.unique_bldg, tile_id2, wid)
						else:
							tile.unique_bldg.erase("repair_cost")
							bldgs[tile_id].self_modulate = Color.WHITE
							Helper.set_unique_bldg_bonuses(p_i, tile.unique_bldg, tile_id, wid)
						game.popup(tr("BUILDING_REPAIRED"), 1.5)
						game.hide_adv_tooltip()
					else:
						game.popup(tr("NOT_ENOUGH_MONEY"), 1.5)
			elif tile.has("cave"):
				if game.bottom_info_action == "enter_cave":
					game.c_t = tile_id
					game.rover_id = rover_selected
					if game.rover_data[rover_selected].MK == 3:
						game.popup_window("", "", [tr("GO_TO_FLOOR_X") % 16, tr("GO_TO_FLOOR_X") % 8, tr("START_AT_FLOOR_1")], [Callable(game, "switch_view").bind("cave", {"start_floor":16}), Callable(game, "switch_view").bind("cave", {"start_floor":8}), Callable(game, "switch_view").bind("cave")], tr("CANCEL"))
					elif game.rover_data[rover_selected].MK == 2:
						game.popup_window("", "", [tr("GO_TO_FLOOR_X") % 8, tr("START_AT_FLOOR_1")], [Callable(game, "switch_view").bind("cave", {"start_floor":8}), Callable(game, "switch_view").bind("cave")], tr("CANCEL"))
					else:
						game.switch_view("cave")
				else:
					if (game.show.has("vehicles_button") or len(game.rover_data) > 0) and not game.vehicle_panel.visible:
						game.toggle_panel(game.vehicle_panel)
						game.vehicle_panel.tile_id = tile_id
			elif tile.has("ship"):
				if game.science_unlocked.has("SCT"):
					if len(game.ship_data) == 0:
						game.tile_data[tile_id].erase("ship")
						$Obstacles.set_cell(0, Vector2i(x_pos, y_pos))
						game.popup(tr("SHIP_CONTROL_SUCCESS"), 1.5)
						game.HUD.ships.visible = true
						game.ship_data.append({"name":tr("SHIP"), "lv":1, "HP":25, "total_HP":25, "atk":10, "def":5, "acc":10, "eva":10, "points":2, "max_points":2, "HP_mult":1.0, "atk_mult":1.0, "def_mult":1.0, "acc_mult":1.0, "eva_mult":1.0, "ability":"none", "superweapon":"none", "XP":0, "XP_to_lv":20, "bullet":{"lv":1, "XP":0, "XP_to_lv":10}, "laser":{"lv":1, "XP":0, "XP_to_lv":10}, "bomb":{"lv":1, "XP":0, "XP_to_lv":10}, "light":{"lv":1, "XP":0, "XP_to_lv":20}})
				else:
					if game.show.has("SP"):
						game.popup(tr("SHIP_CONTROL_FAIL"), 1.5)
					elif not game.get_node("UI/PopupBackground").visible:
						game.popup_window("%s %s" % [tr("SHIP_CONTROL_FAIL"), tr("SHIP_CONTROL_HELP")], tr("RESEARCH_NEEDED"))
			elif tile.has("wormhole"):
				on_wormhole_click(tile, tile_id)
			game.show_collect_info(items_collected)
		if game.planet_HUD:
			game.planet_HUD.refresh()

func on_wormhole_click(tile:Dictionary, tile_id:int):
	if tile.wormhole.active:
		if game.universe_data[game.c_u].lv < 18:
			game.popup_window(tr("LV_18_NEEDED_DESC"), tr("LV_18_NEEDED"))
			return
		Helper.update_ship_travel()
		if game.ships_travel_data.travel_view != "-":
			game.popup(tr("SHIPS_ALREADY_TRAVELLING"), 1.5)
			return
		if Helper.ships_on_planet(p_id):
			if game.view_tween.is_running():
				return
			game.view_tween = create_tween()
			game.view_tween.tween_property(game.view, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.1)
			await game.view_tween.finished
			rsrcs.clear()
			if tile.wormhole.new:#generate galaxy -> remove tiles -> generate system -> open/close tile_data to update wormhole info -> open destination tile_data to place destination wormhole
				visible = false
				if game.galaxy_data[game.c_g].has("wormholes"):
					game.galaxy_data[game.c_g].wormholes.append({"from":game.c_s, "to":tile.wormhole.l_dest_s_id})
				else:
					game.galaxy_data[game.c_g].wormholes = [{"from":game.c_s, "to":tile.wormhole.l_dest_s_id}]
				if not game.galaxy_data[game.c_g].has("discovered"):#if galaxy generated systems
					await game.start_system_generation()
				else:
					Helper.save_obj("Clusters", game.c_c, game.galaxy_data)
				var wh_system:Dictionary = game.system_data[tile.wormhole.l_dest_s_id]
				var orig_s_l:int = game.c_s
				var orig_s_g:int = game.c_s_g
				var orig_p_l:int = game.c_p
				var orig_p_g:int = game.c_p_g
				view.save_zooms("planet")
				Helper.save_obj("Systems", game.c_s_g, game.planet_data)
				game.c_s = tile.wormhole.l_dest_s_id
				game.c_s_g = tile.wormhole.g_dest_s_id
				if wh_system.has("discovered"):#if system generated planets
					game.planet_data = game.open_obj("Systems", tile.wormhole.g_dest_s_id)
				else:
					game.planet_data.clear()
					game.generate_planets(tile.wormhole.l_dest_s_id)
				var wh_planet = game.planet_data[randi() % wh_system.planet_num]
				while wh_planet.type in [11, 12]:
					wh_planet = game.planet_data[randi() % wh_system.planet_num]
				game.planet_data[wh_planet.l_id].conquered = true
				game.erase_tile(tile_id)
				game.tile_data[tile_id].wormhole = {}
				game.tile_data[tile_id].wormhole.l_dest_p_id = wh_planet.l_id
				game.tile_data[tile_id].wormhole.g_dest_p_id = wh_planet.id
				game.tile_data[tile_id].wormhole.new = false
				game.tile_data[tile_id].wormhole.active = true
				var _wid:int = sqrt(len(game.tile_data))
				var tile_x:int = tile_id % _wid
				var tile_y:int = tile_id / _wid
				for k in range(max(0, tile_x - 2), min(tile_x + 2 + 1, _wid)):
					for l in range(max(0, tile_y - 2), min(tile_y + 2 + 1, _wid)):
						var id2 = k % _wid + l * _wid
						var _tile = game.tile_data[id2]
						if Vector2(k, l) == Vector2(tile_x, tile_y) or _tile.has("cave") or _tile.has("volcano") or _tile.has("lake") or _tile.has("wormhole"):
							continue
						_tile.resource_production_bonus.SP = _tile.resource_production_bonus.get("SP", 1.0) + 7.0
				Helper.save_obj("Planets", game.c_p_g, game.tile_data)#update current tile info (original wormhole)
				game.c_p = wh_planet.l_id
				game.c_p_g = wh_planet.id
				if not wh_planet.has("discovered"):
					game.generate_tiles(wh_planet.l_id)
				game.tile_data = game.open_obj("Planets", wh_planet.id)
				var wh_tile:int = randi() % len(game.tile_data)
				while game.tile_data[wh_tile] and game.tile_data[wh_tile].has("cave"):
					wh_tile = randi() % len(game.tile_data)
				game.erase_tile(wh_tile)
				game.tile_data[wh_tile].wormhole = {"active":true, "new":false, "l_dest_s_id":orig_s_l, "g_dest_s_id":orig_s_g, "l_dest_p_id":orig_p_l, "g_dest_p_id":orig_p_g}
				Helper.save_obj("Planets", wh_planet.id, game.tile_data)#update new tile info (destination wormhole)
			else:
				game.remove_planet()
				game.c_v = ""
				game.c_p = tile.wormhole.l_dest_p_id
				game.c_p_g = tile.wormhole.g_dest_p_id
				game.c_s = tile.wormhole.l_dest_s_id
				game.c_s_g = tile.wormhole.g_dest_s_id
				game.tile_data = game.open_obj("Planets", game.c_p_g)
				game.planet_data = game.open_obj("Systems", game.c_s_g)
			game.ships_travel_data.c_coords.p = game.c_p
			game.ships_travel_data.dest_coords.p = game.c_p
			game.ships_travel_data.c_coords.s = game.c_s
			game.ships_travel_data.dest_coords.s = game.c_s
			game.ships_travel_data.c_g_coords.s = game.c_s_g
			game.ships_travel_data.dest_g_coords.s = game.c_s_g
			game.switch_view("planet", {"dont_save_zooms":true})
		else:
			game.send_ships_panel.dest_p_id = p_id
			game.toggle_panel(game.send_ships_panel)
	else:
		if not tile.wormhole.has("investigation_length"):
			var costs:Dictionary = get_wh_costs()
			if game.SP >= costs.SP:
				if not game.objective.is_empty() and game.objective.type == game.ObjectiveType.WORMHOLE:
					game.objective.current += 1
				game.SP -= costs.SP
				game.stats_univ.wormholes_activated += 1
				game.stats_dim.wormholes_activated += 1
				game.stats_global.wormholes_activated += 1
				tile.wormhole.investigation_length = costs.time
				tile.wormhole.investigation_date = Time.get_unix_time_from_system()
				game.popup(tr("INVESTIGATION_STARTED"), 2.0)
				add_time_bar(tile_id, "wormhole")
			else:
				game.popup(tr("NOT_ENOUGH_SP"), 1.5)

func hide_tooltip():
	if game.get_node("UI").has_node("BuildingShortcuts"):
		game.get_node("UI").get_node("BuildingShortcuts").close()
	else:
		$BuildingShortcutTimer.stop()
	game.hide_tooltip()
	game.hide_adv_tooltip()
	if game.help_str != "mass_build":
		game.help_str = ""

func is_obstacle(tile, bldg_is_obstacle:bool = true):
	if tile == null:
		return false
	return tile.has("rock") or (tile.has("bldg") if bldg_is_obstacle else true) or tile.has("unique_bldg") or tile.has("ship") or tile.has("wormhole") or tile.has("lake") or tile.has("cave") or tile.has("volcano") or ((tile.has("depth") or tile.has("crater")) and not tile.has("bridge"))

func available_for_mining(tile):
	return tile == null or not tile.has("bldg") and not tile.has("unique_bldg") and not tile.has("rock") and not tile.has("ship") and not tile.has("wormhole") and not tile.has("lake") and not tile.has("cave") and not tile.has("volcano")

func available_to_build(tile):
	if bldg_to_construct == Building.BORING_MACHINE:
		return available_for_mining(tile)
	if tile == null:
		return true
	if bldg_to_construct == Building.GREENHOUSE:
		return not is_obstacle(tile)
	if bldg_to_construct == Building.MINERAL_EXTRACTOR:
		if tile.has("ash"):
			return not is_obstacle(tile)
	return not is_obstacle(tile)

func add_time_bar(id2:int, type:String):
	var local_id = id2
	var v = Vector2.ZERO
	v.x = (local_id % wid) * 200
	v.y = floor(local_id / wid) * 200
	v += Vector2(100, 15)
	var time_bar = game.time_scene.instantiate()
	time_bar.visible = get_parent().scale.x >= 0.25
	time_bar.position = v
	add_child(time_bar)
	match type:
		"bldg":
			time_bar.modulate = Color(0, 0.74, 0, 1)
		"overclock":
			time_bar.modulate = Color(0, 0, 1, 1)
		"wormhole":
			time_bar.modulate = Color(105/255.0, 0, 1, 1)
	time_bars.append({"node":time_bar, "id":id2, "type":type})

func add_bldg_sprite(pos:Vector2, _name:int, texture, building_animation:bool = false, mod:Color = Color.WHITE, sc:float = 0.4, offset:Vector2 = Vector2(100, 100)):
	var bldg = Sprite2D.new()
	bldg.texture = texture
	bldg.scale *= sc
	bldg.position = pos + offset
	bldg.self_modulate = mod
	if building_animation:
		bldg.material = ShaderMaterial.new()
		bldg.material.shader = preload("res://Shaders/BuildingConstruction.gdshader")
		bldg.material.set_shader_parameter("alpha", 0.0)
		bldg.material.set_shader_parameter("progress", 0.0)
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(bldg.material, "shader_parameter/alpha", 1.0, 0.5)
		tween.tween_property(bldg.material, "shader_parameter/progress", 1.0, 0.8).set_delay(0.3)
	$Buildings.add_child(bldg)
	return bldg
	
func add_bldg(id2:int, type:int, building_animation:bool = false):
	var v = Vector2.ZERO
	v.x = (id2 % wid) * 200
	v.y = floor(id2 / wid) * 200
	bldgs[id2] = add_bldg_sprite(v, type, game.bldg_textures[type], building_animation)
	v += Vector2(100, 100)
	var tile = game.tile_data[id2]
	match type:
		Building.MINERAL_EXTRACTOR:
			add_rsrc(v, Color(0, 0.5, 0.9, 1), Data.rsrc_icons[Building.MINERAL_EXTRACTOR], id2)
		Building.POWER_PLANT:
			add_rsrc(v, Color(0, 0.8, 0, 1), Data.rsrc_icons[Building.POWER_PLANT], id2)
		Building.SOLAR_PANEL:
			add_rsrc(v, Color(0, 0.8, 0, 1), Data.rsrc_icons[Building.SOLAR_PANEL], id2)
		Building.ATMOSPHERE_EXTRACTOR:
			add_rsrc(v, Color(0.89, 0.55, 1.0, 1), Data.rsrc_icons[Building.ATMOSPHERE_EXTRACTOR], id2)
		Building.RESEARCH_LAB:
			add_rsrc(v, Color(0.3, 1.0, 0.3, 1), Data.rsrc_icons[Building.RESEARCH_LAB], id2)
		Building.BORING_MACHINE:
			add_rsrc(v, Color(0.6, 0.6, 0.6, 1), Data.rsrc_icons[Building.BORING_MACHINE], id2, true)
		Building.STONE_CRUSHER:
			add_rsrc(v, Color(0.6, 0.6, 0.6, 1), Data.rsrc_icons[Building.STONE_CRUSHER], id2)
		Building.GLASS_FACTORY:
			add_rsrc(v, Color(0.8, 0.9, 0.85, 1), Data.rsrc_icons[Building.GLASS_FACTORY], id2)
		Building.STEAM_ENGINE:
			add_rsrc(v, Color(0, 0.8, 0, 1), Data.rsrc_icons[Building.STEAM_ENGINE], id2)
		Building.ATOM_MANIPULATOR:
			add_rsrc(v, Color(0.89, 0.55, 1.0, 1), Data.rsrc_icons[Building.ATOM_MANIPULATOR], id2)
		Building.GREENHOUSE:
			if tile.has("auto_GH"):
				if tile.auto_GH.has("soil_drain"):
					var fert = Sprite2D.new()
					fert.texture = preload("res://Graphics/Agriculture/fertilizer.png")
					bldgs[id2].add_child(fert)
					fert.name = "Fertilizer"
				add_rsrc(v, Color(0.41, 0.25, 0.16, 1), load("res://Graphics/Metals/%s.png" % tile.auto_GH.seed.split("_")[0]), id2)
			else:
				add_rsrc(v, Color(0.41, 0.25, 0.16, 1), null, id2)
		Building.SUBATOMIC_PARTICLE_REACTOR:
			if tile.bldg.has("reaction"):
				add_rsrc(v, Color.WHITE, load("res://Graphics/Atoms/%s.png" % tile.bldg.reaction), id2)
			else:
				add_rsrc(v, Color.WHITE, Data.rsrc_icons[Building.SUBATOMIC_PARTICLE_REACTOR], id2)
		_:
			if Mods.added_buildings.has(type):
				add_rsrc(v, Mods.added_buildings[type].icon_color, Data.rsrc_icons[type], id2)
	var hbox = Helper.add_lv_boxes(tile, v)
	add_child(hbox)
	hboxes[id2] = hbox
	if tile.bldg.has("overclock_mult"):
		add_time_bar(id2, "overclock")
	if tile.bldg.has("is_constructing"):
		add_time_bar(id2, "bldg")
	else:
		Helper.update_rsrc(p_i, tile)

func overclockable(bldg:int):
	return bldg in [Building.MINERAL_EXTRACTOR, Building.POWER_PLANT, Building.RESEARCH_LAB, Building.BORING_MACHINE, Building.SOLAR_PANEL, Building.ATMOSPHERE_EXTRACTOR]

func add_rsrc(v:Vector2, mod:Color, icon, id2:int, current_bar_visible = false):
	var rsrc:ResourceStored = game.rsrc_stored_scene.instantiate()
	rsrc.visible = get_parent().scale.x >= 0.25
	add_child(rsrc)
	rsrc.set_icon_texture(icon)
	rsrc.position = v + Vector2(0, 70)
	rsrc.set_panel_modulate(mod)
	rsrc.set_current_bar_visibility(current_bar_visible)
	rsrcs[id2] = rsrc

func on_timeout():
	if game.c_v != "planet":
		return
	var curr_time = Time.get_unix_time_from_system()
	var update_XP:bool = false
	for time_bar_obj in time_bars:
		var time_bar = time_bar_obj.node
		var id2 = time_bar_obj.id
		var type = time_bar_obj.type
		var tile = game.tile_data[id2]
		var start_date:int
		var length:float
		var progress:float
		if type == "bldg":
			if tile == null or not tile.has("bldg") or not tile.bldg.has("is_constructing"):
				time_bar.queue_free()
				time_bars.erase(time_bar_obj)
				continue
			start_date = tile.bldg.construction_date
			length = tile.bldg.construction_length
			progress = (curr_time - start_date) / float(length)
			if Helper.update_bldg_constr(tile, p_i):
				if tile.bldg.has("path_1"):
					hboxes[id2].get_node("Path1").text = str(tile.bldg.path_1)
				if tile.bldg.has("path_2"):
					hboxes[id2].get_node("Path2").text = str(tile.bldg.path_2)
				if tile.bldg.has("path_3"):
					hboxes[id2].get_node("Path3").text = str(tile.bldg.path_3)
				update_XP = true
		elif type == "overclock":
			if tile == null or not tile.has("bldg") or not tile.bldg.has("overclock_date"):
				time_bar.queue_free()
				time_bars.erase(time_bar_obj)
				continue
			start_date = tile.bldg.overclock_date
			length = tile.bldg.overclock_length
			progress = 1 - (curr_time - start_date) / float(length)
			if progress < 0:
				var mult:float = tile.bldg.overclock_mult
				if tile.bldg.name == Building.POWER_PLANT:
					game.autocollect.rsrc.energy -= tile.bldg.path_1_value * (mult - 1) * tile.resource_production_bonus.get("energy", 1.0)
				elif tile.bldg.name == Building.MINERAL_EXTRACTOR:
					game.autocollect.rsrc.minerals -= tile.bldg.path_1_value * (mult - 1) * tile.resource_production_bonus.get("minerals", 1.0)
				elif tile.bldg.name == Building.RESEARCH_LAB:
					game.autocollect.rsrc.SP -= tile.bldg.path_1_value * (mult - 1) * tile.resource_production_bonus.get("SP", 1.0)
				elif tile.bldg.name == Building.SOLAR_PANEL:
					var SP_prod = Helper.get_SP_production(p_i.temperature, tile.bldg.path_1_value * (mult - 1) * (tile.get("aurora", 0.0) + 1.0) * tile.resource_production_bonus.get("energy", 1.0))
					game.autocollect.rsrc.energy -= SP_prod
				elif tile.bldg.name == Building.ATMOSPHERE_EXTRACTOR:
					var base = -tile.bldg.path_1_value * (mult - 1) * p_i.pressure
					for el in p_i.atmosphere:
						var base_prod:float = base * p_i.atmosphere[el]
						Helper.add_atom_production(el, base_prod)
					Helper.add_energy_from_NFR(p_i, base)
					Helper.add_energy_from_CS(p_i, base)
				tile.bldg.erase("overclock_date")
				tile.bldg.erase("overclock_length")
				tile.bldg.erase("overclock_mult")
		elif type == "wormhole":
			if tile.wormhole.active:
				wormhole.get_node("Active").visible = true
				wormhole.get_node("Inactive").visible = false
				time_bar.queue_free()
				time_bars.erase(time_bar_obj)
				continue
			start_date = tile.wormhole.investigation_date
			length = tile.wormhole.investigation_length
			progress = (curr_time - start_date) / float(length)
			if progress > 1:
				tile.wormhole.active = true
		time_bar.get_node("TimeString").text = Helper.time_to_str(length - curr_time + start_date)
		time_bar.get_node("Bar").value = progress
	if icons_hidden:
		return
	for i in len(rsrcs):
		var tile = game.tile_data[i]
		if tile == null or not tile.has("bldg") and not tile.has("unique_bldg") or tile.has("bldg") and tile.bldg.has("is_constructing"):
			continue
		Helper.update_rsrc(p_i, tile, rsrcs[i])
	game.HUD.update_money_energy_SP()
	game.HUD.update_minerals()
	if update_XP:
		game.HUD.update_XP()

var constructing_unique_building_tier:int = -1

func initiate_unique_building_construction(type:int, costs:Dictionary):
	finish_construct()
	if game.get_node("UI").has_node("BuildingShortcuts"):
		game.get_node("UI").get_node("BuildingShortcuts").close()
	else:
		$BuildingShortcutTimer.stop()
	var tween = create_tween()
	tween.tween_property(game.HUD.get_node("Top/TextureRect"), "modulate", Color(1.5, 1.5, 1.0, 1.0), 0.2)
	bldg_to_construct = type
	constr_costs = costs
	constr_costs_total = costs.duplicate()
	shadow = Sprite2D.new()
	if type == UniqueBuilding.NUCLEAR_FUSION_REACTOR:
		put_shadow(shadow, game.unique_bldg_textures[bldg_to_construct], mouse_pos, 0.8, Vector2.ONE * 200)
	else:
		put_shadow(shadow, game.unique_bldg_textures[bldg_to_construct], mouse_pos)
	game.HUD.get_node("Top/Resources/Stone").visible = false
	game.HUD.get_node("Top/Resources/Minerals").visible = false
	game.HUD.get_node("Top/Resources/Cellulose").visible = false
	var grayed_out_tile_positions:PackedVector2Array
	for i in wid:
		for j in wid:
			var id2 = i % wid + j * wid
			var tile = game.tile_data[id2]
			if tile and is_obstacle(tile) or type == UniqueBuilding.NUCLEAR_FUSION_REACTOR and (i == wid-1 or j == wid-1):
				grayed_out_tile_positions.append(Vector2(i, j))
				var gray_tile = preload("res://Scenes/GrayscaleTile.tscn").instantiate()
				gray_tile.position = Vector2(i, j) * 200.0
				add_child(gray_tile)
				gray_tile.add_to_group("gray_tiles")
	if len(grayed_out_tile_positions) > 0:
		var gray_tile = get_tree().get_first_node_in_group("gray_tiles")
		var tween2 = create_tween()
		var v = gray_tile.position / 200.0
		tween2.tween_property(gray_tile.material, "shader_parameter/amount", 1.0, 0.2)
	game.HUD.refresh()
	
func construct(type:int, costs:Dictionary):
	constructing_unique_building_tier = -1
	finish_construct()
	if game.get_node("UI").has_node("BuildingShortcuts"):
		game.get_node("UI").get_node("BuildingShortcuts").close()
	else:
		$BuildingShortcutTimer.stop()
	var tween = create_tween()
	tween.tween_property(game.HUD.get_node("Top/TextureRect"), "modulate", Color(1.5, 1.5, 1.0, 1.0), 0.2)
	game.planet_HUD.get_node("MassBuild").visible = game.stats_univ.bldgs_built >= 10
	bldg_to_construct = type
	constr_costs = costs
	constr_costs_total = costs.duplicate()
	shadow = Sprite2D.new()
	put_shadow(shadow, game.bldg_textures[bldg_to_construct])
	game.HUD.get_node("Top/Resources/Stone").visible = false
	game.HUD.get_node("Top/Resources/SP").visible = false
	game.HUD.get_node("Top/Resources/Minerals").visible = false
	game.HUD.get_node("Top/Resources/Cellulose").visible = false
	if type == Building.GREENHOUSE:
		game.HUD.get_node("Top/Resources/Glass").visible = true
		game.HUD.get_node("Top/Resources/Soil").visible = true
	var rsrc = ""
	if type == Building.MINERAL_EXTRACTOR:
		rsrc = "minerals"
	elif type == Building.RESEARCH_LAB:
		rsrc = "SP"
	elif type == Building.SOLAR_PANEL:
		rsrc = "energy"
	var grayed_out_tile_positions:PackedVector2Array
	for i in wid:
		for j in wid:
			var id2 = i % wid + j * wid
			var tile = game.tile_data[id2]
			if (type == Building.GREENHOUSE and (not tile or not tile.has("lake_elements"))) or tile and not available_to_build(tile):
				grayed_out_tile_positions.append(Vector2(i, j))
				var gray_tile = preload("res://Scenes/GrayscaleTile.tscn").instantiate()
				gray_tile.position = Vector2(i, j) * 200.0
				add_child(gray_tile)
				gray_tile.add_to_group("gray_tiles")
	if len(grayed_out_tile_positions) > 0:
		var gray_tile = get_tree().get_first_node_in_group("gray_tiles")
		var tween2 = create_tween()
		var v = gray_tile.position / 200.0
		tween2.tween_property(gray_tile.material, "shader_parameter/amount", 1.0, 0.2)
	game.HUD.refresh()
	var bonus_rsrc_icon
	if rsrc != "":
		bonus_rsrc_icon = Data["%s_icon" % rsrc]
	var await_counter:int = 0
	for i in wid:
		for j in wid:
			var id2 = i % wid + j * wid
			if not is_inside_tree():
				return
			var tile = game.tile_data[id2]
			if tile and tile.has("resource_production_bonus") and tile.resource_production_bonus.has(rsrc):
				if bldg_to_construct == -1:
					return
				var tile_bonus_node = preload("res://Scenes/TileBonus.tscn").instantiate()
				tile_bonus_node.position = Vector2(i, j) * 200
				add_child(tile_bonus_node)
				tile_bonus_node.set_icon(bonus_rsrc_icon)
				tile_bonus_node.set_multiplier(tile.resource_production_bonus[rsrc])
				tile_bonus_node.modulate.a = 0
				var tween2 = create_tween()
				tween2.tween_property(tile_bonus_node, "modulate:a", 0.8, 0.2)
				tile_bonus_node.add_to_group("tile_bonus_nodes")
				if view.scale.x < 0.25:
					tile_bonus_node.color.a = 0.6
					tile_bonus_node.get_node("TileBonus").modulate.a = 0.0
				if await_counter % int(1000.0 / Engine.get_frames_per_second()) == 0:
					await get_tree().process_frame
				await_counter += 1

func place_gray_tiles_mining():
	var grayed_out_tile_positions:PackedVector2Array
	for i in wid:
		for j in wid:
			var id2 = i % wid + j * wid
			var tile = game.tile_data[id2]
			if not available_for_mining(tile):
				var gray_tile = preload("res://Scenes/GrayscaleTile.tscn").instantiate()
				gray_tile.position = Vector2(i, j) * 200.0
				add_child(gray_tile)
				gray_tile.add_to_group("gray_tiles")
	if len(get_tree().get_nodes_in_group("gray_tiles")) > 0:
		var gray_tile = get_tree().get_first_node_in_group("gray_tiles")
		var tween2 = create_tween()
		var v = gray_tile.position / 200.0
		tween2.tween_property(gray_tile.material, "shader_parameter/amount", 1.0, 0.2).set_delay((v.x + v.y) / 7.5 / wid)
	
func put_shadow(spr:Sprite2D, texture, pos:Vector2 = Vector2.ZERO, sc:float = 0.4, offset:Vector2 = Vector2.ONE * 100):
	spr.texture = texture
	spr.scale *= sc
	spr.modulate.a = 0.5
	spr.position = (floor(pos / 200) * 200).clamp(Vector2.ZERO, Vector2.ONE * wid * 200) + offset
	add_child(spr)
	return spr
	
func finish_construct():
	if is_instance_valid(shadow):
		bldg_to_construct = -1
		shadow.free()
	if not get_tree().get_nodes_in_group("tile_bonus_nodes").is_empty():
		var tween = create_tween()
		tween.set_parallel(true)
		for tile_bonus_node in get_tree().get_nodes_in_group("tile_bonus_nodes"):
			tween.tween_property(tile_bonus_node, "modulate:a", 0.0, 0.2)
			tween.tween_callback(tile_bonus_node.queue_free).set_delay(0.2)
			tile_bonus_node.remove_from_group("tile_bonus_nodes")
	if mass_build_rect.visible:
		mass_build_rect.visible = false
		for i in len(shadows):
			if is_instance_valid(shadows[i]):
				shadows[i].queue_free()
		shadow_num = 0
	constr_costs.clear()
	constr_costs_total.clear()
	var tween2 = create_tween()
	tween2.tween_property(game.HUD.get_node("Top/TextureRect"), "modulate", Color.WHITE, 0.2)
	game.planet_HUD.get_node("MassBuild").visible = false

func _on_Planet_tree_exited():
	queue_free()

func get_tile_id_from_pos(pos:Vector2):
	var x_pos = int(pos.x / 200)
	var y_pos = int(pos.y / 200)
	return x_pos % wid + y_pos * wid

func play_bad_apple(LOD):
	$BadApple.load_data(LOD)


func _on_building_shortcut_timer_timeout():
	if is_instance_valid(game.active_panel):
		return
	var shortcuts = preload("res://Scenes/KeyboardShortcuts.tscn").instantiate()
	shortcuts.keys.clear()
	shortcuts.add_key("F", "UPGRADE")
	shortcuts.add_key("Q", "DUPLICATE")
	shortcuts.add_key("X", "DESTROY")
	shortcuts.add_key("Shift", "SELECT_ALL")
	shortcuts.center_position.x = 1048
	shortcuts.center_position.y = 360
	shortcuts.name = "BuildingShortcuts"
	game.get_node("UI").add_child(shortcuts)
