extends Node2D

onready var game = get_node("/root/Game")
onready var view = game.view
onready var p_id = game.c_p
onready var p_i = game.planet_data[p_id]

#Used to prevent view from moving outside viewport
var dimensions:float

#For exploring a cave
var rover_selected:int = -1
#The building you selected in construct panel
var bldg_to_construct:String = ""
#The cost of the above building
var constr_costs:Dictionary = {}
var constr_costs_total:Dictionary = {}
#The transparent sprite
var shadow:Sprite
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

onready var wid:int = round(Helper.get_wid(p_i.size))
#A rectangle enclosing all tiles
onready var planet_bounds:PoolVector2Array = [Vector2.ONE, Vector2(1, wid * 200), Vector2(wid * 200, wid * 200), Vector2(wid * 200, 1)]

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
	$TileMap.material.shader = preload("res://Shaders/BCS.shader")
	var lum:float = 0.0
	for star in game.system_data[game.c_s].stars:
		var sc:float = 0.5 * star.size / (p_i.distance / 500)
		if star.luminosity > lum:
			star_mod = Helper.get_star_modulate(star.class)
			if star_mod.get_luminance() < 0.2:
				star_mod = star_mod.lightened(0.2 - star_mod.get_luminance())
			$TileMap.modulate = star_mod
			var strength_mult = 1.0
			if p_i.temperature >= 1500:
				strength_mult = min(range_lerp(p_i.temperature, 1000, 3000, 1.2, 1.5), 1.5)
			else:
				strength_mult = min(range_lerp(p_i.temperature, -273, 1000, 0.3, 1.2), 1.2)
			var brightness:float = range_lerp(tile_brightness, 40000, 90000, 2.5, 1.1) * strength_mult
			var contrast:float = sqrt(brightness)
			#$TileMap.material.set_shader_param("brightness", min(brightness, 2.0))
			$TileMap.material.set_shader_param("contrast", clamp(strength_mult, 1.0, 2.0))
			$TileMap.material.set_shader_param("saturation", clamp(strength_mult, 1.0, 2.0))
			lum = star.luminosity
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = interval
	timer.start()
	timer.connect("timeout", self, "on_timeout")
	mass_build_rect = game.mass_build_rect.instance()
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
	if p_i.has("lake_1"):
		$Lakes1.tile_set = game.lake_TS
		$Lakes1.modulate = Data.lake_colors[p_i.lake_1.element][p_i.lake_1.state]
	if p_i.has("lake_2"):
		$Lakes2.tile_set = game.lake_TS
		$Lakes2.modulate = Data.lake_colors[p_i.lake_2.element][p_i.lake_2.state]
	var nuclear_fusion_reactor_main_tiles = []
	if not p_i.has("unique_bldgs"): # Save migration
		p_i.unique_bldgs = {}
	if p_i.unique_bldgs.has("nuclear_fusion_reactor"):
		for i in len(p_i.unique_bldgs.nuclear_fusion_reactor):
			nuclear_fusion_reactor_main_tiles.append(p_i.unique_bldgs.nuclear_fusion_reactor[i].tile)
	for i in wid:
		for j in wid:
			var id2 = i % wid + j * wid
			var tile = game.tile_data[id2]
			$TileMap.set_cell(i, j, p_i.type - 3)
			if not tile:
				continue
			if tile.has("crater"):
				var metal = Sprite.new()
				metal.texture = game.metal_textures[tile.crater.metal]
				metal.scale *= 0.4
				add_child(metal)
				metal.position = Vector2(i, j) * 200 + Vector2(100, 70)
				var crater = Sprite.new()
				if tile.crater.variant == 3:
					tile.crater.variant = 2
				if tile.crater.variant == 1:
					crater.texture = preload("res://Graphics/Tiles/Crater/1.png")
				else:
					crater.texture = preload("res://Graphics/Tiles/Crater/2.png")
				crater.scale *= clamp(range_lerp(tile.crater.init_depth, 10, 1000, 0.4, 1.0), 0.4, 1.0)
				add_child(crater)
				crater.position = Vector2(i, j) * 200 + Vector2(100, 100)
			if tile.has("depth") and not tile.has("bridge") and not tile.has("crater"):
				$Obstacles.set_cell(i, j, 6)
			if tile.has("bldg"):
				add_bldg(id2, tile.bldg.name)
				if tile.bldg.name == "GH":
					$Soil.set_cell(id2 % wid, int(id2 / wid), 0)
					$Soil.update_bitmask_region()
			elif tile.has("unique_bldg"):
				var mod:Color = Color.white
				if tile.unique_bldg.has("repair_cost"):
					mod = Color(0.3, 0.3, 0.3)
				var v = Vector2(i, j) * 200
				if tile.unique_bldg.name == "nuclear_fusion_reactor":
					if id2 in nuclear_fusion_reactor_main_tiles:
						bldgs[id2] = add_bldg_sprite(v, tile.unique_bldg.name, mod, 0.8, Vector2(200, 200))
						add_rsrc(v + Vector2(200, 200), Color(0, 0.8, 0, 1), Data.rsrc_icons.PP, id2)
				else:
					bldgs[id2] = add_bldg_sprite(v, tile.unique_bldg.name, mod)
					if tile.unique_bldg.tier > 1:
						var particle_props = [	{"c":Color(1.2, 2.4, 1.2), "amount":50, "lifetime":2.4},
												{"c":Color(1.2, 1.2, 2.4), "amount":60, "lifetime":2.8},
												{"c":Color(2.4, 1.2, 2.4), "amount":70, "lifetime":3.2},
												{"c":Color(2.4, 1.8, 1.2), "amount":80, "lifetime":3.6},
												{"c":Color(2.4, 2.4, 1.8), "amount":90, "lifetime":4.0},
												{"c":Color(2.4, 1.2, 1.2), "amount":100, "lifetime":4.4}]
						var particles = preload("res://Scenes/UniqueBuildingParticles.tscn").instance()
						particles.modulate = particle_props[tile.unique_bldg.tier - 2].c
						particles.amount = particle_props[tile.unique_bldg.tier - 2].amount
						particles.lifetime = particle_props[tile.unique_bldg.tier - 2].lifetime
						bldgs[id2].add_child(particles)
					if tile.unique_bldg.name == "cellulose_synthesizer":
						add_rsrc(v + Vector2(100, 100), Color.brown, Data.cellulose_icon, id2)
					elif tile.unique_bldg.name == "substation":
						add_rsrc(v + Vector2(100, 100), Color(0, 0.8, 0, 1), Data.energy_icon, id2)
			elif tile.has("cave"):
				var cave_data_file = File.new()
				if tile.cave.has("id"):
					var cave_file_path:String = "user://%s/Univ%s/Caves/%s.hx3" % [game.c_sv, game.c_u, tile.cave.id]
					cave_data_file.open(cave_file_path, File.READ)
					var cave_data = cave_data_file.get_var()
					cave_data_file.close()
					caves_data[id2] = len(cave_data.seeds)
				$Obstacles.set_cell(i, j, 1)
			elif tile.has("volcano"):
				var volcano = Sprite.new()
				volcano.texture = preload("res://Graphics/Tiles/Volcano.png")
				add_child(volcano)
				volcano.position = Vector2(i, j) * 200 + Vector2(100, 100)
			elif tile.has("ship"):
				if len(game.ship_data) == 0:
					$Obstacles.set_cell(i, j, 5)
			elif tile.has("wormhole"):
				wormhole = game.wormhole_scene.instance()
				wormhole.get_node("Active").visible = tile.wormhole.active
				wormhole.get_node("Inactive").visible = not tile.wormhole.active
				wormhole.position = Vector2(i, j) * 200 + Vector2(100, 100)
				add_child(wormhole)
				if tile.wormhole.has("investigation_length"):
					add_time_bar(id2, "wormhole")
				p_i.wormhole = true
			elif tile.has("lake"):
				var state = p_i["lake_%s" % tile.lake].state
				if state == "l":
					get_node("Lakes%s" % tile.lake).set_cell(i, j, 2)
					add_particles(Vector2(i*200, j*200))
				elif state == "s":
					get_node("Lakes%s" % tile.lake).set_cell(i, j, 0)
				elif state == "sc":
					get_node("Lakes%s" % tile.lake).set_cell(i, j, 1)
			if tile.has("ash"):
				$Ash.set_cell(i, j, 0)
			if tile.has("aurora"):
				var aurora = game.aurora_scene.instance()
				aurora.position = Vector2(i, j) * 200 + Vector2(100, 100)
				aurora.get_node("Particles2D").amount = min(5 + int(tile.aurora.au_int * 10), 50)
				aurora.get_node("Particles2D").lifetime = 3.0 / game.u_i.time_speed
				#aurora.get_node("Particles2D").process_material["shader_param/strength"] = 1.0 if randf() < 0.5 else 0.0
				#var hue:float = 0.4 + max(0, pow(tile.aurora.au_int, 0.35) - pow(4, 0.25)) / 10
				var hue:float = 0.4 + log(tile.aurora.au_int + 1.0) / 10.0
				var sat:float = 1.0 - floor(hue - 0.4) / 5.0
				aurora.modulate = Color.from_hsv(fmod(hue, 1.0), sat, 1.0) * max(log(tile.aurora.au_int) / 10.0, 1.0)
				add_child(aurora)
	if p_i.has("lake_1"):
		$Lakes1.update_bitmask_region()
	if p_i.has("lake_2"):
		$Lakes2.update_bitmask_region()
	$Soil.update_bitmask_region()
	$Ash.update_bitmask_region()

func add_particles(pos:Vector2):
	var particle:Particles2D = game.particles_scene.instance()
	particle.position = pos + Vector2(30, 30)
	particle.lifetime = 2.0 / game.u_i.time_speed
	add_child(particle)

func show_tooltip(tile, tile_id:int):
	if not tile:
		return
	var tooltip:String = ""
	var icons = []
	var fiery_tooltip:int = -1
	var fire_strength:float = 0.0
	if tile.has("bldg"):
		tooltip += Helper.get_bldg_tooltip(p_i, tile, 1)
		icons.append_array(Helper.flatten(Data.desc_icons[tile.bldg.name]) if Data.desc_icons.has(tile.bldg.name) else [])
		if game.help_str == "":
			game.help_str = "tile_shortcuts"
		if game.help.has("tile_shortcuts") and bldg_to_construct == "":
			if game.get_node("UI").has_node("BuildingShortcuts"):
				game.get_node("UI").get_node("BuildingShortcuts").close()
			var shortcuts = preload("res://Scenes/KeyboardShortcuts.tscn").instance()
			shortcuts.keys.clear()
			shortcuts.add_key("F", "UPGRADE")
			shortcuts.add_key("Q", "DUPLICATE")
			shortcuts.add_key("X", "DESTROY")
			shortcuts.add_key("Shift", "SELECT_ALL")
			shortcuts.add_key("J", "HIDE_THIS_PANEL")
			shortcuts.center_position.x = 1048
			shortcuts.center_position.y = 360
			shortcuts.name = "BuildingShortcuts"
			game.get_node("UI").add_child(shortcuts)
			#tooltip += "\n%s\n%s\n%s\n%s\n%s" % [tr("PRESS_F_TO_UPGRADE"), tr("PRESS_Q_TO_DUPLICATE"), tr("PRESS_X_TO_DESTROY"), tr("HOLD_SHIFT_TO_SELECT_SIMILAR"), tr("HIDE_SHORTCUTS")]
		if tile.has("overclock_bonus") and overclockable(tile.bldg.name):
			tooltip += "\n[color=#EEEE00]" + tr("BENEFITS_FROM_OVERCLOCK") % tile.overclock_bonus + "[/color]"
		if tile.bldg.name == "MM":
			tooltip += "\n%s: %s m" % [tr("HOLE_DEPTH"), tile.depth]
		elif tile.bldg.name in ["GF", "SE", "SC"]:
			tooltip += "\n[color=#88CCFF]%s\nG: %s[/color]" % [tr("CLICK_TO_CONFIGURE"), tr("LOAD_UNLOAD")]
	elif tile.has("unique_bldg"):
		var tier_colors = ["FFFFFF", "00EE00", "2222FF", "FF22FF", "FF8800", "FFFF22", "FF0000"]
		tooltip += "[color=#%s]" % tier_colors[tile.unique_bldg.tier - 1]
		if tile.unique_bldg.has("repair_cost"):
			tooltip += tr("BROKEN_X").format({"building_name":tr(tile.unique_bldg.name.to_upper())})
		else:
			tooltip += tr(tile.unique_bldg.name.to_upper())
		if tile.unique_bldg.tier > 1:
			tooltip += " " + Helper.get_roman_num(tile.unique_bldg.tier)
		tooltip += "[/color]\n"
		if game.help.has("%s_desc" % tile.unique_bldg.name):
			tooltip += tr("%s_DESC1" % tile.unique_bldg.name.to_upper())
			game.help_str = "%s_desc" % tile.unique_bldg.name
			tooltip += "\n" + tr("HIDE_HELP") + "\n"
		var desc = tr("%s_DESC2" % tile.unique_bldg.name.to_upper())
		match tile.unique_bldg.name:
			"spaceport":
				desc = desc % [	Helper.get_spaceport_exit_cost_reduction(tile.unique_bldg.tier) * 100,
								Helper.get_spaceport_travel_cost_reduction(tile.unique_bldg.tier) * 100]
			"mineral_replicator", "mining_outpost", "observatory":
				desc = desc.format({"n":Helper.get_unique_bldg_area(tile.unique_bldg.tier)}) % Helper.get_MR_Obs_Outpost_prod_mult(tile.unique_bldg.tier)
			"substation":
				desc = desc.format({"n":Helper.get_unique_bldg_area(tile.unique_bldg.tier), "time":Helper.time_to_str(1000 * Helper.get_substation_capacity_bonus(tile.unique_bldg.tier))}) % Helper.get_substation_prod_mult(tile.unique_bldg.tier)
			"aurora_generator":
				desc = desc.format({"intensity":Helper.get_AG_au_int_mult(tile.unique_bldg.tier), "n":Helper.get_AG_num_auroras(tile.unique_bldg.tier)})
			"nuclear_fusion_reactor":
				desc = desc % Helper.format_num(Helper.get_NFR_prod_mult(tile.unique_bldg.tier))
			"cellulose_synthesizer":
				desc = desc % Helper.format_num(Helper.get_CS_prod_mult(tile.unique_bldg.tier))
		tooltip += desc
		icons.append_array(Data.unique_bldg_icons[tile.unique_bldg.name])
		if tile.unique_bldg.has("repair_cost"):
			tooltip += "\n" + tr("BROKEN_BLDG_DESC1") + "\n"
			icons.append(Data.money_icon)
			tooltip += tr("BROKEN_BLDG_DESC2") % Helper.format_num(tile.unique_bldg.repair_cost, true)
			icons.append(Data.money_icon)
	elif tile.has("volcano"):
		game.help_str = "volcano_desc"
		if not game.help.has("volcano_desc"):
			tooltip = "%s\n%s\n%s\n%s: %s" % [tr("VOLCANO"), tr("VOLCANO_DESC"), tr("HIDE_HELP"), tr("LARGEST_VEI") % ("(" + tr("VEI") + ") "), Helper.clever_round(tile.volcano.VEI)]
		else:
			tooltip = "%s\n%s: %s" % [tr("VOLCANO"), tr("LARGEST_VEI") % "", Helper.clever_round(tile.volcano.VEI)]
	elif tile.has("crater") and tile.crater.has("init_depth"):
		if tile.has("aurora"):
			tooltip = "[aurora au_int=%s]" % tile.aurora.au_int
		game.help_str = "crater_desc"
		if game.help.has("crater_desc"):
			tooltip += tr("METAL_CRATER").format({"metal":tr(tile.crater.metal.to_upper()), "crater":tr("CRATER")}) + "\n%s\n%s\n%s" % [tr("CRATER_DESC"), tr("HIDE_HELP"), tr("HOLE_DEPTH") + ": %s m"  % [tile.depth]]
		else:
			tooltip += tr("METAL_CRATER").format({"metal":tr(tile.crater.metal.to_upper()), "crater":tr("CRATER")}) + "\n%s" % [tr("HOLE_DEPTH") + ": %s m"  % [tile.depth]]
	elif tile.has("cave"):
		var au_str:String = ""
		if tile.has("aurora"):
			au_str = "[aurora au_int=%s]" % tile.aurora.au_int
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
		if game.cave_gen_info:
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
		tooltip += "\n" + tr("EFFECT_ON_PLANTS") + "\n"
		if Data.lake_bonus_values[lake_info.element].operator == "x":
			tooltip += tr("%s_LAKE_BONUS" % lake_info.element.to_upper()) % Helper.clever_round(Data.lake_bonus_values[lake_info.element][lake_info.state] * game.biology_bonus[lake_info.element])
		elif Data.lake_bonus_values[lake_info.element].operator == "÷":
			tooltip += tr("%s_LAKE_BONUS" % lake_info.element.to_upper()) % Helper.clever_round(Data.lake_bonus_values[lake_info.element][lake_info.state] / game.biology_bonus[lake_info.element])
		elif Data.lake_bonus_values[lake_info.element].operator == "+":
			tooltip += tr("%s_LAKE_BONUS" % lake_info.element.to_upper()) % (Data.lake_bonus_values[lake_info.element][lake_info.state] + game.biology_bonus[lake_info.element])
	elif tile.has("ship"):
		if game.science_unlocked.has("SCT"):
			tooltip = tr("CLICK_TO_CONTROL_SHIP")
		else:
			game.help_str = "abandoned_ship"
			if game.help.has("abandoned_ship"):
				tooltip = tr("ABANDONED_SHIP") + "\n" + tr("HIDE_HELP")
	elif tile.has("wormhole"):
		if tile.wormhole.active:
			game.help_str = "active_wormhole"
			if game.help.has("active_wormhole"):
				tooltip = "%s\n%s\n%s" % [tr("ACTIVE_WORMHOLE"), tr("ACTIVE_WORMHOLE_DESC"), tr("HIDE_HELP")]
			else:
				tooltip = tr("ACTIVE_WORMHOLE")
		else:
			game.help_str = "inactive_wormhole"
			if game.help.has("inactive_wormhole"):
				tooltip = "%s\n%s\n%s" % [tr("INACTIVE_WORMHOLE"), tr("INACTIVE_WORMHOLE_DESC"), tr("HIDE_HELP")]
			else:
				tooltip = tr("INACTIVE_WORMHOLE")
			var wh_costs:Dictionary = get_wh_costs()
			if not tile.wormhole.has("investigation_length"):
				tooltip += "\n%s: @i %s  @i %s" % [tr("INVESTIGATION_COSTS"), Helper.format_num(wh_costs.SP), Helper.time_to_str(wh_costs.time * 1000)]
				icons = [Data.SP_icon, Data.time_icon]
	if tile.has("depth") and not tile.has("bldg") and not tile.has("crater") and not tile.has("bridge"):
		tooltip += "%s: %s m\n%s" % [tr("HOLE_DEPTH"), tile.depth, tr("SHIFT_CLICK_TO_BRIDGE_HOLE")]
	elif tile.has("aurora") and tooltip == "":
		game.help_str = "aurora_desc"
		if game.help.has("aurora_desc"):
			tooltip = "%s\n%s\n%s\n%s" % [tr("AURORA"), tr("AURORA_DESC"), tr("HIDE_HELP"), tr("AURORA_INTENSITY") + ": %s" % [tile.aurora.au_int]]
		else:
			tooltip = tr("AURORA_INTENSITY") + ": %s" % [tile.aurora.au_int]
	if tile.has("ruins"):
		tooltip = "%s\n%s" % [tr("ABANDONED_RUINS"), tr("AR_DESC")]
	if tooltip != "":
		game.show_adv_tooltip(tooltip, icons)
	if fiery_tooltip != -1 and is_instance_valid(game.tooltip):
		game.tooltip.get_node("ColorRect").visible = true
		game.tooltip.get_node("ColorRect").material.set_shader_param("seed", fiery_tooltip)
		game.tooltip.get_node("ColorRect").material.set_shader_param("color", Color(1, 0.51, 0, 1) * clamp(range_lerp(fire_strength, 6.0, 12.0, 0.5, 2.0), 0.5, 2.0))
		#game.tooltip.get_node("ColorRect").material.set_shader_param("color", Color(1, 0.51, 0, 1) * 2.0)
		game.tooltip.get_node("ColorRect").material.set_shader_param("fog_mvt_spd", clamp(range_lerp(fire_strength, 6.0, 12.0, 0.5, 1.5), 0.5, 1.5))
		#game.tooltip.get_node("ColorRect").material.set_shader_param("fog_mvt_spd", 1.5)

func get_wh_costs():
	return {"SP":round(10000 * pow(game.stats_univ.wormholes_activated + 1, 0.8)), "time":900 / game.u_i.time_speed if game.subjects.dimensional_power.lv == 0 else 0.2}

func constr_bldg(tile_id:int, curr_time:int, _bldg_to_construct:String, mass_build:bool = false):
	if _bldg_to_construct == "":
		return
	var tile = game.tile_data[tile_id]
	if _bldg_to_construct == "EC":
		if not tile:
			if not mass_build:
				game.popup(tr("EC_ERROR"), 1.5)
			return
		if not tile.has("aurora"):
			if not mass_build:
				game.popup(tr("EC_ERROR"), 1.5)
			return
	elif _bldg_to_construct == "GH":
		if not tile or not tile.has("lake_elements"):
			if not mass_build:
				game.popup(tr("NOT_ADJACENT_TO_LAKE"), 1.5)
			return
	var constr_costs2:Dictionary = constr_costs_total.duplicate()
	if game.subjects.dimensional_power.lv >= 1:
		constr_costs2.time = 0.2
	else:
		constr_costs2.time /= game.u_i.time_speed
	if game.check_enough(constr_costs2):
		game.deduct_resources(constr_costs2)
		game.stats_univ.bldgs_built += 1
		game.stats_dim.bldgs_built += 1
		game.stats_global.bldgs_built += 1
		if game.stats_univ.bldgs_built >= 1 and not game.new_bldgs.has("PP"):
			game.new_bldgs.PP = true
		if game.stats_univ.bldgs_built >= 5 and not game.new_bldgs.has("MS"):
			game.new_bldgs.B = true
			game.new_bldgs.MS = true
		if game.stats_univ.bldgs_built >= 18 and not game.new_bldgs.has("RL"):
			game.new_bldgs.RL = true
			game.new_bldgs.CBD = true
		if not tile:
			tile = {}
		if game.tutorial:
			if game.tutorial.tut_num in [9, 10, 11] and game.tutorial.visible:
				game.tutorial.fade(0.4, false)
			elif game.tutorial.tut_num == 18 and _bldg_to_construct == "RL":
				game.tutorial.begin()
		tile.bldg = {}
		tile.bldg.name = _bldg_to_construct
		if not game.show.has("minerals") and _bldg_to_construct == "ME":
			game.show.minerals = true
			game.show.shop = true
			game.HUD.minerals.visible = true
			game.HUD.shop.visible = true
			game.HUD.MU.visible = true
			game.HUD.get_node("Bottom/Panel").visible = true
		tile.bldg.is_constructing = true
		tile.bldg.construction_date = curr_time
		tile.bldg.construction_length = constr_costs2.time * 1000
		tile.bldg.XP = round(constr_costs2.money / 100.0)
		if _bldg_to_construct != "PCC":
			tile.bldg.path_1 = 1
			tile.bldg.path_1_value = Data.path_1[_bldg_to_construct].value
		if _bldg_to_construct in ["SC", "GF", "SE", "GH", "CBD", "AMN", "SPR"]:
			tile.bldg.path_2 = 1
			tile.bldg.path_2_value = Data.path_2[_bldg_to_construct].value
		if _bldg_to_construct in ["SC", "GF", "SE"]:
			tile.bldg.collect_date = tile.bldg.construction_date + tile.bldg.construction_length
			tile.bldg.stored = 0
		if _bldg_to_construct in ["SC", "GF", "SE", "CBD"]:
			tile.bldg.path_3 = 1
			tile.bldg.path_3_value = Data.path_3[_bldg_to_construct].value
		if _bldg_to_construct == "RL":
			game.show.SP = true
			game.HUD.SP.visible = true
			game.HUD.sc_tree.visible = true
		elif _bldg_to_construct == "MS":
			tile.bldg.cap_upgrade = Data.path_1.MS.value#The amount of cap to add once construction is done
		elif _bldg_to_construct == "PP":
			if tile.has("substation_bonus"):
				tile.bldg.cap_upgrade = Data.path_1.PP.value * tile.substation_bonus * Helper.get_substation_capacity_bonus(game.tile_data[tile.substation_tile].unique_bldg.tier)
			else:
				tile.bldg.cap_upgrade = 0
		elif _bldg_to_construct == "SP":
			if tile.has("substation_bonus"):
				tile.bldg.cap_upgrade = Helper.get_SP_production(p_i.temperature, Data.path_1.SP.value * Helper.get_au_mult(tile) * tile.substation_bonus) * Helper.get_substation_capacity_bonus(game.tile_data[tile.substation_tile].unique_bldg.tier)
			else:
				tile.bldg.cap_upgrade = 0
		elif _bldg_to_construct == "B":
			tile.bldg.cap_upgrade = Data.path_1.B.value#The amount of cap to add once construction is done
		elif _bldg_to_construct == "NSF":
			tile.bldg.cap_upgrade = Data.path_1.NSF.value
		elif _bldg_to_construct == "ESF":
			tile.bldg.cap_upgrade = Data.path_1.ESF.value
		elif _bldg_to_construct == "CBD":
			tile.bldg.x_pos = tile_id % wid
			tile.bldg.y_pos = tile_id / wid
			tile.bldg.wid = wid
		elif _bldg_to_construct in ["PC", "NC"]:
			tile.bldg.planet_pressure = p_i.pressure
		if _bldg_to_construct == "GH":
			$Soil.set_cell(tile_id % wid, int(tile_id / wid), 0)
			$Soil.update_bitmask_region()
		tile.bldg.c_p_g = game.c_p_g
		if _bldg_to_construct == "MM":
			if not tile.has("depth"):
				tile.depth = 0
			if not game.MM_data.has(game.c_p_g):
				game.MM_data[game.c_p_g] = {"tiles":[tile_id], "c_s_g":game.c_s_g, "c_p":game.c_p}
			else:
				game.MM_data[game.c_p_g].tiles.append(tile_id)
			tile.bldg.collect_date = tile.bldg.construction_date + tile.bldg.construction_length
		game.tile_data[tile_id] = tile
		add_bldg(tile_id, _bldg_to_construct)
	elif not mass_build:
		var tooltip = tr("NOT_ENOUGH_RESOURCES")
		if game.tutorial and game.tutorial.tut_num < 15 and game.tutorial.tut_num > 6:
			game.popup("%s %s" % [tooltip, tr("COLLECT_REMINDER")], 3)
		else:
			game.popup(tooltip, 1.2)

func speedup_bldg(tile, tile_id:int, curr_time):
	if tile.bldg.has("is_constructing"):
		var speedup_time = game.speedups_info[game.item_to_use.name].time
		#Time remaining to finish construction
		var time_remaining = tile.bldg.construction_date + tile.bldg.construction_length - curr_time
		var num_needed = min(game.item_to_use.num, ceil((time_remaining) / float(speedup_time)))
		if not tiles_selected.empty():
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
	var mult:float = game.overclocks_info[game.item_to_use.name].mult * (tile.overclock_bonus if tile.has("overclock_bonus") else 1.0)
	if overclockable(tile.bldg.name) and not tile.bldg.has("is_constructing") and (not tile.bldg.has("overclock_mult") or tile.bldg.overclock_mult < mult):
		var mult_diff:float
		if not tile.bldg.has("overclock_mult"):
			add_time_bar(tile_id, "overclock")
			mult_diff = mult - 1
		else:
			mult_diff = mult - tile.bldg.overclock_mult
		tile.bldg.overclock_date = curr_time
		tile.bldg.overclock_length = game.overclocks_info[game.item_to_use.name].duration / game.u_i.time_speed
		tile.bldg.overclock_mult = mult
		if tile.bldg.name == "RL":
			game.autocollect.rsrc.SP += tile.bldg.path_1_value * mult_diff * (tile.observatory_bonus if tile.has("observatory_bonus") else 1.0)
		elif tile.bldg.name == "ME":
			game.autocollect.rsrc.minerals += tile.bldg.path_1_value * mult_diff * (tile.ash.richness if tile.has("ash") else 1.0) * (tile.mineral_replicator_bonus if tile.has("mineral_replicator_bonus") else 1.0)
		elif tile.bldg.name == "PP":
			game.autocollect.rsrc.energy += tile.bldg.path_1_value * mult_diff * (tile.substation_bonus if tile.has("substation_bonus") else 1.0)
		elif tile.bldg.name == "SP":
			var SP_prod = Helper.get_SP_production(p_i.temperature, tile.bldg.path_1_value * mult_diff * Helper.get_au_mult(tile) * (tile.substation_bonus if tile.has("substation_bonus") else 1.0))
			game.autocollect.rsrc.energy += SP_prod
			if tile.has("aurora"):
				if game.aurora_prod.has(tile.aurora.au_int):
					game.aurora_prod[tile.aurora.au_int].energy = game.aurora_prod[tile.aurora.au_int].get("energy", 0) + SP_prod
				else:
					game.aurora_prod[tile.aurora.au_int] = {"energy":SP_prod}
		elif tile.bldg.name == "AE":
			var base = tile.bldg.path_1_value * mult_diff * p_i.pressure
			for el in p_i.atmosphere:
				var base_prod:float = base * p_i.atmosphere[el]
				Helper.add_atom_production(el, base_prod)
			Helper.add_energy_from_NFR(p_i, base)
			Helper.add_energy_from_CS(p_i, base)
		elif tile.bldg.name == "PC":
			game.autocollect.particles.proton += tile.bldg.path_1_value / tile.bldg.planet_pressure * mult_diff
		elif tile.bldg.name == "NC":
			game.autocollect.particles.neutron += tile.bldg.path_1_value / tile.bldg.planet_pressure * mult_diff
		elif tile.bldg.name == "EC":
			game.autocollect.particles.electron += tile.bldg.path_1_value * tile.aurora.au_int * mult_diff
		elif tile.bldg.name == "MM":
			var tiles_mined = (curr_time - tile.bldg.collect_date) / 1000.0 * tile.bldg.path_1_value * Helper.get_prod_mult(tile) * (tile.mining_outpost_bonus if tile.has("mining_outpost_bonus") else 1.0)
			if tiles_mined >= 1:
				game.add_resources(Helper.mass_generate_rock(tile, p_i, int(tiles_mined)))
				tile.bldg.collect_date = curr_time
				tile.depth += int(tiles_mined)
		game.item_to_use.num -= 1

func click_tile(tile, tile_id:int):
	if not tile.has("bldg") or is_instance_valid(game.active_panel):
		return
	var bldg:String = tile.bldg.name
	if not tile.bldg.has("is_constructing"):
		game.c_t = tile_id
		match bldg:
			"GH":
				game.greenhouse_panel.c_v = "planet"
				if tiles_selected.empty():
					game.greenhouse_panel.tiles_selected = [tile_id]
					game.greenhouse_panel.tile_num = 1
				else:
					game.greenhouse_panel.tiles_selected = tiles_selected.duplicate(true)
					game.greenhouse_panel.tile_num = len(tiles_selected)
				game.greenhouse_panel.p_i = p_i
				game.toggle_panel(game.greenhouse_panel)
			"RCC":
				game.toggle_panel(game.RC_panel)
			"SY":
				game.toggle_panel(game.shipyard_panel)
			"PCC":
				game.PC_panel.probe_tier = 0
				game.toggle_panel(game.PC_panel)
			"SC":
				game.SC_panel.c_t = tile_id
				game.toggle_panel(game.SC_panel)
				game.SC_panel.hslider.value = game.SC_panel.hslider.max_value
			"GF":
				game.toggle_panel(game.production_panel)
				game.production_panel.refresh2(bldg, "sand", "glass", "mats", "mats")
			"SE":
				game.toggle_panel(game.production_panel)
				game.production_panel.refresh2(bldg, "coal", "energy", "mats", "")
			"AMN":
				game.AMN_panel.tf = false
				game.toggle_panel(game.AMN_panel)
			"SPR":
				game.SPR_panel.tf = false
				game.toggle_panel(game.SPR_panel)
				if tile.bldg.has("reaction"):
					game.SPR_panel._on_Atom_pressed(tile.bldg.reaction)
		hide_tooltip()

func destroy_bldg(id2:int, mass:bool = false):
	var tile = game.tile_data[id2]
	var bldg:String = tile.bldg.name
	items_collected.clear()
	Helper.update_rsrc(p_i, tile)
	bldgs[id2].queue_free()
	hboxes[id2].queue_free()
	if is_instance_valid(rsrcs[id2]):
		rsrcs[id2].queue_free()
	var overclock_mult:float = tile.bldg.overclock_mult if tile.bldg.has("overclock_mult") else 1.0
	if bldg == "MS":
		if tile.bldg.has("is_constructing"):
			game.mineral_capacity -= tile.bldg.path_1_value - tile.bldg.cap_upgrade
		else:
			game.mineral_capacity -= tile.bldg.path_1_value
		if game.mineral_capacity < 200:
			game.mineral_capacity = 200
	elif bldg == "B":
		if tile.bldg.has("is_constructing"):
			game.energy_capacity -= tile.bldg.path_1_value - tile.bldg.cap_upgrade
		else:
			game.energy_capacity -= tile.bldg.path_1_value
		if game.energy_capacity < 7500:
			game.energy_capacity = 7500
	elif bldg == "NSF":
		if tile.bldg.has("is_constructing"):
			game.neutron_cap -= tile.bldg.path_1_value - tile.bldg.cap_upgrade
		else:
			game.neutron_cap -= tile.bldg.path_1_value
	elif bldg == "ESF":
		if tile.bldg.has("is_constructing"):
			game.electron_cap -= tile.bldg.path_1_value - tile.bldg.cap_upgrade
		else:
			game.electron_cap -= tile.bldg.path_1_value
	elif bldg == "ME":
		if not tile.bldg.has("is_constructing"):
			game.autocollect.rsrc.minerals -= tile.bldg.path_1_value * overclock_mult * (tile.ash.richness if tile.has("ash") else 1.0) * (tile.mineral_replicator_bonus if tile.has("mineral_replicator_bonus") else 1.0)
	elif bldg == "PP":
		if not tile.bldg.has("is_constructing"):
			game.autocollect.rsrc.energy -= tile.bldg.path_1_value * overclock_mult * (tile.substation_bonus if tile.has("substation_bonus") else 1.0)
		if tile.has("substation_tile"):
			var cap_to_remove = tile.bldg.path_1_value * tile.substation_bonus * Helper.get_substation_capacity_bonus(game.tile_data[tile.substation_tile].unique_bldg.tier)
			game.tile_data[tile.substation_tile].unique_bldg.capacity_bonus -= cap_to_remove
			game.capacity_bonus_from_substation -= cap_to_remove
	elif bldg == "SP":
		if not tile.bldg.has("is_constructing"):
			var SP_prod = Helper.get_SP_production(p_i.temperature, tile.bldg.path_1_value * overclock_mult * Helper.get_au_mult(tile))
			game.autocollect.rsrc.energy -= SP_prod
			if tile.has("aurora"):
				game.aurora_prod[tile.aurora.au_int].energy -= SP_prod
				if is_zero_approx(game.aurora_prod[tile.aurora.au_int].energy):
					game.aurora_prod[tile.aurora.au_int].erase("energy")
					if game.aurora_prod[tile.aurora.au_int].empty():
						game.aurora_prod.erase(tile.aurora.au_int)
		if tile.has("substation_tile"):
			var cap_to_remove = Helper.get_SP_production(p_i.temperature, tile.bldg.path_1_value * Helper.get_au_mult(tile)) * Helper.get_substation_capacity_bonus(game.tile_data[tile.substation_tile].unique_bldg.tier)
			game.tile_data[tile.substation_tile].unique_bldg.capacity_bonus -= cap_to_remove
			game.capacity_bonus_from_substation -= cap_to_remove
	elif bldg == "RL":
		if not tile.bldg.has("is_constructing"):
			game.autocollect.rsrc.SP -= tile.bldg.path_1_value * overclock_mult * (tile.observatory_bonus if tile.has("observatory_bonus") else 1.0)
	elif bldg == "AE":
		if not tile.bldg.has("is_constructing"):
			var base = -tile.bldg.path_1_value * overclock_mult * p_i.pressure
			for el in p_i.atmosphere:
				var base_prod:float = base * p_i.atmosphere[el]
				Helper.add_atom_production(el, base_prod)
			Helper.add_energy_from_NFR(p_i, base)
			Helper.add_energy_from_CS(p_i, base)
	elif bldg == "PC":
		if not tile.bldg.has("is_constructing"):
			game.autocollect.particles.proton -= tile.bldg.path_1_value / tile.bldg.planet_pressure * overclock_mult
	elif bldg == "NC":
		if not tile.bldg.has("is_constructing"):
			game.autocollect.particles.neutron -= tile.bldg.path_1_value / tile.bldg.planet_pressure * overclock_mult
	elif bldg == "EC":
		if not tile.bldg.has("is_constructing"):
			game.autocollect.particles.electron -= tile.bldg.path_1_value * tile.aurora.au_int * overclock_mult
	elif bldg == "CBD":
		var n:int = tile.bldg.path_3_value
		var wid:int = tile.bldg.wid
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
				if not _tile:
					continue
				if _tile.has("cost_div_dict"):
					_tile.cost_div_dict.erase(String(id2))
					if _tile.cost_div_dict.empty():
						_tile.erase("cost_div_dict")
						_tile.erase("cost_div")
					else:
						var div:float = 1.0
						for st in _tile.cost_div_dict:
							div = max(div, _tile.cost_div_dict[st])
						_tile.cost_div = div
				if _tile.has("overclock_dict"):
					_tile.overclock_dict.erase(String(id2))
					if _tile.overclock_dict.empty():
						_tile.erase("overclock_dict")
						_tile.erase("overclock_bonus")
					else:
						var bonus:float = 1.0
						for st in _tile.overclock_dict:
							bonus = max(bonus, _tile.overclock_dict[st])
						_tile.overclock_bonus = bonus
	elif bldg == "GH":
		$Soil.set_cell(id2 % wid, int(id2 / wid), -1)
		$Soil.update_bitmask_region()
	elif bldg == "MM":
		game.MM_data[game.c_p_g].tiles.erase(id2)
		if game.MM_data[game.c_p_g].tiles.empty():
			game.MM_data.erase(game.c_p_g)
	if tile.has("auto_GH"):
		Helper.remove_GH_produce_from_autocollect(tile.auto_GH.produce, tile.aurora.au_int if tile.has("aurora") else 0.0)
		game.autocollect.mats.cellulose += tile.auto_GH.cellulose_drain
		if tile.auto_GH.has("soil_drain"):
			game.autocollect.mats.soil += tile.auto_GH.soil_drain
		tile.erase("auto_GH")
	tile.erase("bldg")
	if tile.empty():
		game.tile_data[id2] = null
	if not mass:
		game.show_collect_info(items_collected)

func add_shadows():
	var poly:Rect2 = Rect2(mass_build_rect.rect_position, Vector2.ZERO)
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
			if is_instance_valid(shadows[id2]) and is_a_parent_of(shadows[id2]):
				if not poly.intersects(tile_rekt):
					shadows[id2].free()
					shadow_num -= 1
			else:
				if poly.intersects(tile_rekt) and available_to_build(tile):
					shadows[id2] = put_shadow(Sprite.new(), shadow_pos)
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
	var new_x = stepify(round(mouse_pos.x - 100), 200)
	var new_y = stepify(mouse_pos.y - 100, 200)
	var old_x = stepify(round(mouse_pos.x - delta.x - 100), 200)
	var old_y = stepify(mouse_pos.y - delta.y - 100, 200)
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
	if _tile.bldg.name in ["GF", "SE"]:
		if _tile.bldg.has("qty1"):
			var prod_i = Helper.get_prod_info(_tile)
			if _tile.bldg.name == "GF":
				Helper.add_item_to_coll(items_collected, "sand", prod_i.qty_left)
				Helper.add_item_to_coll(items_collected, "glass", prod_i.qty_made)
			elif _tile.bldg.name == "SE":
				Helper.add_item_to_coll(items_collected, "coal", prod_i.qty_left)
				Helper.add_item_to_coll(items_collected, "energy", prod_i.qty_made)
			_tile.bldg.erase("qty1")
			_tile.bldg.erase("start_date")
			_tile.bldg.erase("ratio")
			_tile.bldg.erase("qty2")
		else:
			var rsrc_to_deduct = {"sand":_tile.bldg.path_2_value}
			if game.check_enough(rsrc_to_deduct):
				game.deduct_resources(rsrc_to_deduct)
				_tile.bldg.qty1 = _tile.bldg.path_2_value
				_tile.bldg.start_date = OS.get_system_time_msecs()
				var ratio:float = _tile.bldg.path_3_value
				if _tile.bldg.name == "GF":
					ratio /= 15.0
				elif _tile.bldg.name == "SE":
					ratio *= 40.0
				_tile.bldg.ratio = ratio
				_tile.bldg.qty2 = _tile.bldg.path_2_value * ratio
	elif _tile.bldg.name == "SC":
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
				_tile.bldg.start_date = OS.get_system_time_msecs()
				var expected_rsrc:Dictionary = {}
				Helper.get_SC_output(expected_rsrc, qty_to_crush, _tile.bldg.path_3_value, stone_total)
				_tile.bldg.expected_rsrc = expected_rsrc
		else:
			var time = OS.get_system_time_msecs()
			var crush_spd = _tile.bldg.path_1_value * game.u_i.time_speed
			var qty_left = max(0, round(_tile.bldg.stone_qty - (time - _tile.bldg.start_date) / 1000.0 * crush_spd))
			if qty_left > 0:
				var progress = (time - _tile.bldg.start_date) / 1000.0 * crush_spd / _tile.bldg.stone_qty
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
	if game.tutorial and game.tutorial.BG_blocked:
		return
	var about_to_mine = game.bottom_info_action == "about_to_mine"
	var mass_build:bool = Input.is_action_pressed("left_click") and Input.is_action_pressed("shift") and game.bottom_info_action == "building"
	view.move_view = not mass_build
	view.scroll_view = not mass_build
	if tile_over != -1 and game.bottom_info_action != "building" and tile_over < len(game.tile_data):
		var tile = game.tile_data[tile_over]
		if tile and tile.has("bldg"):
			if Input.is_action_just_released("Q"):
				game.put_bottom_info(tr("CLICK_TILE_TO_CONSTRUCT"), "building", "cancel_building")
				var base_cost = Data.costs[tile.bldg.name].duplicate(true)
				for cost in base_cost:
					base_cost[cost] *= game.engineering_bonus.BCM
				if tile.bldg.name == "GH":
					base_cost.energy = round(base_cost.energy * (1 + abs(p_i.temperature - 273) / 10.0))
				construct(tile.bldg.name, base_cost)
			elif Input.is_action_just_released("F"):
				if game.get_node("UI").has_node("BuildingShortcuts"):
					game.get_node("UI").get_node("BuildingShortcuts").close()
				game.upgrade_panel.planet.clear()
				if tiles_selected.empty():
					game.upgrade_panel.ids = [tile_over]
				else:
					game.upgrade_panel.ids = tiles_selected.duplicate(true)
				game.toggle_panel(game.upgrade_panel)
			elif Input.is_action_just_released("X") and not game.active_panel:
				hide_tooltip()
				if tiles_selected.empty():
					var bldg:String = tile.bldg.name
					var money_cost = 0.0
					if Data.path_1.has(bldg):
						money_cost += Data.costs[bldg].money * pow(Data.path_1[bldg].cost_pw if Data.path_1[bldg].has("cost_pw") else 1.3, tile.bldg.path_1)
					if Data.path_2.has(bldg):
						money_cost += Data.costs[bldg].money * pow(Data.path_2[bldg].cost_pw if Data.path_2[bldg].has("cost_pw") else 1.3, tile.bldg.path_2)
					if Data.path_3.has(bldg):
						money_cost += Data.costs[bldg].money * pow(Data.path_3[bldg].cost_pw if Data.path_3[bldg].has("cost_pw") else 1.3, tile.bldg.path_3)
					if tile.has("cost_div"):
						money_cost /= tile.cost_div
					var total_XP = 10 * (1 - pow(1.6, game.u_i.lv - 1)) / (1 - 1.6) + game.u_i.xp
					if money_cost >= total_XP + game.money / 100.0:
						game.show_YN_panel("destroy_building", tr("DESTROY_BLDG_CONFIRM"), [tile_over])
					else:
						destroy_bldg(tile_over)
						game.HUD.refresh()
				else:
					game.show_YN_panel("destroy_buildings", tr("DESTROY_X_BUILDINGS") % [len(tiles_selected)], [tiles_selected.duplicate(true)])
			elif Input.is_action_just_released("G") and not is_instance_valid(game.active_panel):
				items_collected.clear()
				if not tiles_selected.empty():
					for tile_id in tiles_selected:
						collect_prod_bldgs(tile_id)
				else:
					collect_prod_bldgs(tile_over)
				game.show_collect_info(items_collected)
				game.HUD.refresh()
		if not is_instance_valid(game.active_panel) and Input.is_action_just_pressed("shift") and tile:
			tiles_selected.clear()
			if game.help.has("tile_shortcuts"):
				if game.get_node("UI").has_node("BuildingShortcuts"):
					game.get_node("UI").get_node("BuildingShortcuts").close()
				var shortcuts = preload("res://Scenes/KeyboardShortcuts.tscn").instance()
				shortcuts.keys.clear()
				shortcuts.add_key("F", "UPGRADE_ALL")
				shortcuts.add_key("Q", "DUPLICATE")
				shortcuts.add_key("X", "DESTROY_ALL")
				shortcuts.add_key("Shift", "SELECT_ALL")
				shortcuts.add_key("J", "HIDE_THIS_PANEL")
				shortcuts.center_position.x = 1048
				shortcuts.center_position.y = 360
				shortcuts.name = "BuildingShortcuts"
				game.get_node("UI").add_child(shortcuts)
			var path_1_value_sum:float = 0
			var path_2_value_sum:float = 0
			var path_3_value_sum:float = 0
			for i in len(game.tile_data):
				var select:bool = false
				var tile2 = game.tile_data[i]
				if not tile2 or not tile2.has("bldg"):
					continue
				if tile.has("bldg"):
					if tile2.has("bldg") and tile2.bldg.name == tile.bldg.name:
						if not Input.is_action_pressed("alt") or tile2.has("cost_div"):
							select = true
				if select:
					if tile.has("bldg"):
						if tile.bldg.name in ["SC", "SE", "GF"]:
							path_1_value_sum += Helper.get_final_value(p_i, tile2, 1)
							path_2_value_sum += Helper.get_final_value(p_i, tile2, 2)
						elif tile.bldg.name in ["ME", "PP", "SP", "AE", "MM", "B", "RL", "MS", "PC", "NC", "EC", "NSF", "ESF"]:
							path_1_value_sum += Helper.get_final_value(p_i, tile2, 1)
						else:
							path_1_value_sum = Helper.get_final_value(p_i, tile2, 1) if tile2.bldg.has("path_1_value") else 0
							path_2_value_sum = Helper.get_final_value(p_i, tile2, 2) if tile2.bldg.has("path_2_value") else 0
						path_3_value_sum = Helper.get_final_value(p_i, tile2, 3) if tile2.bldg.has("path_3_value") else 0
					tiles_selected.append(i)
					var white_rect = game.white_rect_scene.instance()
					white_rect.position.x = (i % wid) * 200
					white_rect.position.y = (i / wid) * 200
					add_child(white_rect)
					white_rect.add_to_group("white_rects")
			if game.shop_panel.tab in ["Speedups", "Overclocks"]:
				game.shop_panel.get_node("VBox/HBox/ItemInfo/VBox/HBox/BuyAmount").value = len(tiles_selected)
				game.shop_panel.num = len(tiles_selected)
			if tile.has("bldg") and not game.item_cursor.visible:
				if Data.desc_icons.has(tile.bldg.name):
					var tooltip:String = Helper.get_bldg_tooltip2(tile.bldg.name, path_1_value_sum, path_2_value_sum, path_3_value_sum)
					if tile.bldg.name in ["GF", "SE", "SC"]:
						tooltip += "\n[color=#88CCFF]G: %s[/color]" % tr("LOAD_UNLOAD_ALL")
					tooltip += "\n" + tr("SELECTED_X_BLDGS") % len(tiles_selected)
					game.show_adv_tooltip(tooltip, Helper.flatten(Data.desc_icons[tile.bldg.name]))
				else:
					game.show_adv_tooltip(Helper.get_bldg_tooltip2(tile.bldg.name, path_1_value_sum, path_2_value_sum, path_3_value_sum) + "\n" + tr("SELECTED_X_BLDGS") % len(tiles_selected))
	if Input.is_action_just_released("shift"):
		remove_selected_tiles()
		if game.get_node("UI").has_node("BuildingShortcuts"):
			var shortcuts = game.get_node("UI").get_node("BuildingShortcuts")
			shortcuts.keys.clear()
			shortcuts.add_key("F", "UPGRADE_ALL")
			shortcuts.add_key("Q", "DUPLICATE")
			shortcuts.add_key("X", "DESTROY_ALL")
			shortcuts.add_key("Shift", "SELECT_ALL")
			shortcuts.add_key("J", "HIDE_THIS_PANEL")
			shortcuts.refresh()
		view.move_view = true
		view.scroll_view = true
		if tile_over != -1 and not game.upgrade_panel.visible and not game.YN_panel.visible:
			if game.tile_data[tile_over] and not is_instance_valid(game.active_panel) and not game.item_cursor.visible:
				show_tooltip(game.tile_data[tile_over], tile_over)
	if not is_instance_valid(game.planet_HUD) or not is_instance_valid(game.HUD):
		return
	var not_on_button:bool = not game.planet_HUD.on_button and not game.HUD.on_button and not game.close_button_over
	if event is InputEventMouse or event is InputEventScreenDrag:
		mouse_pos = to_local(event.position)
		var mouse_on_tiles = Geometry.is_point_in_polygon(mouse_pos, planet_bounds)
		var N:int = mass_build_rect_size.x
		var M:int = mass_build_rect_size.y
		if mass_build:
			mass_build_rect.rect_size.x = abs(mouse_pos.x - mass_build_rect.rect_position.x)
			mass_build_rect.rect_size.y = abs(mouse_pos.y - mass_build_rect.rect_position.y)
			if mouse_pos.x - mass_build_rect.rect_position.x < 0:
				mass_build_rect.rect_scale.x = -1
			else:
				mass_build_rect.rect_scale.x = 1
			if mouse_pos.y - mass_build_rect.rect_position.y < 0:
				mass_build_rect.rect_scale.y = -1
			else:
				mass_build_rect.rect_scale.y = 1
			check_tile_change(event, "add_shadows")
		else:
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
			if tile_over != prev_tile_over and not_on_button and not game.item_cursor.visible and not black_bg and not game.active_panel:
				hide_tooltip()
				if not tiles_selected.empty() and not tile_over in tiles_selected:
					remove_selected_tiles()
				var tile = game.tile_data[tile_over]
				show_tooltip(tile, tile_over)
				for white_rect in get_tree().get_nodes_in_group("CBD_white_rects"):
					white_rect.queue_free()
					white_rect.remove_from_group("CBD_white_rects")
				if tile and (tile.has("bldg") and tile.bldg.name == "CBD" or tile.has("unique_bldg") and tile.unique_bldg.name in ["mineral_replicator", "observatory", "substation", "mining_outpost"]):
					var n:int = tile.bldg.path_3_value if tile.has("bldg") else Helper.get_unique_bldg_area(tile.unique_bldg.tier)
					for i in n:
						var x:int = x_over + i - n / 2
						if x < 0 or x >= wid:
							continue
						for j in n:
							var y:int = y_over + j - n / 2
							if y < 0 or y >= wid or x == x_over and y == y_over:
								continue
							var white_rect = game.white_rect_scene.instance()
							white_rect.position.x = x * 200
							white_rect.position.y = y * 200
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
			shadow.position.x = floor(mouse_pos.x / 200) * 200 + 100
			shadow.position.y = floor(mouse_pos.y / 200) * 200 + 100
	#finish mass build
	if Input.is_action_just_released("left_click") and mass_build_rect.visible:
		mass_build_rect.visible = false
		var curr_time = OS.get_system_time_msecs()
		for i in len(shadows):
			if is_instance_valid(shadows[i]):
				constr_bldg(get_tile_id_from_pos(shadows[i].position), curr_time, bldg_to_construct, true)
				shadows[i].queue_free()
		shadow_num = 0
		game.HUD.refresh()
		return
	#initiate mass build
	if Input.is_action_just_pressed("left_click") and not mass_build_rect.visible and Input.is_action_pressed("shift") and game.bottom_info_action == "building":
		mass_build_rect.rect_position = mouse_pos
		mass_build_rect.rect_size = Vector2.ZERO
		mass_build_rect.visible = true
		mass_build_rect_size = Vector2.ONE
		if available_to_build(game.tile_data[tile_over]):
			shadows[tile_over] = put_shadow(Sprite.new(), mouse_pos)
			shadow_num = 1
		else:
			shadow_num = 0
		shadow.visible = false
	if mass_build:
		return
	if (not Input.is_action_pressed("shift") and Input.is_action_just_released("left_click") or Input.is_action_pressed("shift") and Input.is_action_just_pressed("left_click") or event is InputEventScreenTouch) and not view.dragged and not_on_button and Geometry.is_point_in_polygon(mouse_pos, planet_bounds):
		var x_pos = int(mouse_pos.x / 200)
		var y_pos = int(mouse_pos.y / 200)
		var tile_id = get_tile_id_from_pos(mouse_pos)
		var tile = game.tile_data[tile_id]
	if (Input.is_action_just_released("left_click") or event is InputEventScreenTouch) and not view.dragged and not_on_button and Geometry.is_point_in_polygon(mouse_pos, planet_bounds):
		var curr_time = OS.get_system_time_msecs()
		var x_pos = int(mouse_pos.x / 200)
		var y_pos = int(mouse_pos.y / 200)
		var tile_id = get_tile_id_from_pos(mouse_pos)
		var tile = game.tile_data[tile_id]
		if bldg_to_construct != "":
			if available_to_build(tile):
				constr_bldg(tile_id, curr_time, bldg_to_construct)
		if about_to_mine and available_for_mining(tile):
			game.mine_tile(tile_id)
			return
		if tile and tile.has("depth") and not tile.has("bldg") and bldg_to_construct == "" and not tile.has("bridge"):
			if Input.is_action_pressed("shift"):
				game.tile_data[tile_id].bridge = true
				$Obstacles.set_cell(x_pos, y_pos, -1)
			else:
				game.mine_tile(tile_id)
		if tile and bldg_to_construct == "":
			items_collected.clear()
			var t:String = game.item_to_use.type
			if tile.has("bldg"):
				if t in ["speedup", "overclock"]:
					var orig_num:int = game.item_to_use.num
					if tiles_selected.empty():
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
						if tile.unique_bldg.name == "nuclear_fusion_reactor":
							var tile_id2 = p_i.unique_bldgs[tile.unique_bldg.name][tile.unique_bldg.id].tile
							for j in [tile_id2, tile_id2+1, tile_id2+wid, tile_id2+wid+1]:
								game.tile_data[j].unique_bldg.erase("repair_cost")
							bldgs[tile_id2].self_modulate = Color.white
							Helper.set_unique_bldg_bonuses(p_i, tile.unique_bldg, tile_id2, wid)
						else:
							tile.unique_bldg.erase("repair_cost")
							bldgs[tile_id].self_modulate = Color.white
							Helper.set_unique_bldg_bonuses(p_i, tile.unique_bldg, tile_id, wid)
						game.popup(tr("BUILDING_REPAIRED"), 1.5)
						game.hide_adv_tooltip()
					else:
						game.popup(tr("NOT_ENOUGH_MONEY"), 1.5)
			elif tile.has("cave"):
				if game.bottom_info_action == "enter_cave":
					game.c_t = tile_id
					game.rover_id = rover_selected
					game.switch_view("cave")
				else:
					if (game.show.has("vehicles_button") or len(game.rover_data) > 0) and not game.vehicle_panel.visible:
						game.toggle_panel(game.vehicle_panel)
						game.vehicle_panel.tile_id = tile_id
			elif tile.has("ship"):
				if game.science_unlocked.has("SCT"):
					if len(game.ship_data) == 0:
						game.tile_data[tile_id].erase("ship")
						$Obstacles.set_cell(x_pos, y_pos, -1)
						game.popup(tr("SHIP_CONTROL_SUCCESS"), 1.5)
						game.HUD.ships.visible = true
						game.ship_data.append({"name":tr("SHIP"), "lv":1, "HP":25, "total_HP":25, "atk":10, "def":5, "acc":10, "eva":10, "points":2, "max_points":2, "HP_mult":1.0, "atk_mult":1.0, "def_mult":1.0, "acc_mult":1.0, "eva_mult":1.0, "ability":"none", "superweapon":"none", "XP":0, "XP_to_lv":20, "bullet":{"lv":1, "XP":0, "XP_to_lv":10}, "laser":{"lv":1, "XP":0, "XP_to_lv":10}, "bomb":{"lv":1, "XP":0, "XP_to_lv":10}, "light":{"lv":1, "XP":0, "XP_to_lv":20}})
					elif len(game.ship_data) == 1:
						game.tile_data[tile_id].erase("ship")
						$Obstacles.set_cell(x_pos, y_pos, -1)
						game.popup(tr("SHIP_CONTROL_SUCCESS"), 1.5)
						if not game.objective.empty() and game.objective.type in [game.ObjectiveType.DAVID, game.ObjectiveType.SIGNAL]:
							game.objective = {"type":game.ObjectiveType.LEVEL, "id":-1, "current":game.universe_data[game.c_u].lv, "goal":35}
						game.get_2nd_ship()
					elif len(game.ship_data) == 2:
						if game.third_ship_hints.parts[0] and game.third_ship_hints.parts[1] and game.third_ship_hints.parts[2] and game.third_ship_hints.parts[3] and game.third_ship_hints.parts[4]:
							game.tile_data[tile_id].erase("ship")
							$Obstacles.set_cell(x_pos, y_pos, -1)
							game.popup(tr("SHIP_CONTROL_SUCCESS"), 1.5)
							game.objective = {"type":game.ObjectiveType.LEVEL, "id":-1, "current":game.universe_data[game.c_u].lv, "goal":50}
							game.get_3rd_ship()
						else:
							game.popup(tr("MISSING_PARTS"), 2.5)
				else:
					if game.show.has("SP"):
						game.popup(tr("SHIP_CONTROL_FAIL"), 1.5)
					elif not game.get_node("UI/PopupBackground").visible:
						game.long_popup("%s %s" % [tr("SHIP_CONTROL_FAIL"), tr("SHIP_CONTROL_HELP")], tr("RESEARCH_NEEDED"))
			elif tile.has("wormhole"):
				on_wormhole_click(tile, tile_id)
			game.show_collect_info(items_collected)
		if game.planet_HUD:
			game.planet_HUD.refresh()

func on_wormhole_click(tile:Dictionary, tile_id:int):
	if tile.wormhole.active:
		if game.universe_data[game.c_u].lv < 18:
			game.long_popup(tr("LV_18_NEEDED_DESC"), tr("LV_18_NEEDED"))
			return
		Helper.update_ship_travel()
		if game.ships_travel_view != "-":
			game.popup(tr("SHIPS_ALREADY_TRAVELLING"), 1.5)
			return
		if Helper.ships_on_planet(p_id):
			if game.view_tween.is_active():
				return
			game.view_tween.interpolate_property(game.view, "modulate", null, Color(1.0, 1.0, 1.0, 0.0), 0.1)
			game.view_tween.start()
			yield(game.view_tween, "tween_all_completed")
			rsrcs.clear()
			if tile.wormhole.new:#generate galaxy -> remove tiles -> generate system -> open/close tile_data to update wormhole info -> open destination tile_data to place destination wormhole
				visible = false
				if game.galaxy_data[game.c_g].has("wormholes"):
					game.galaxy_data[game.c_g].wormholes.append({"from":game.c_s, "to":tile.wormhole.l_dest_s_id})
				else:
					game.galaxy_data[game.c_g].wormholes = [{"from":game.c_s, "to":tile.wormhole.l_dest_s_id}]
				if not game.galaxy_data[game.c_g].has("discovered"):#if galaxy generated systems
					yield(game.start_system_generation(), "completed")
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
				game.tile_data[tile_id].wormhole.l_dest_p_id = wh_planet.l_id
				game.tile_data[tile_id].wormhole.g_dest_p_id = wh_planet.id
				game.tile_data[tile_id].wormhole.new = false
				Helper.save_obj("Planets", game.c_p_g, game.tile_data)#update current tile info (original wormhole)
				game.c_p = wh_planet.l_id
				game.c_p_g = wh_planet.id
				if not wh_planet.has("discovered"):
					game.generate_tiles(wh_planet.l_id)
				game.tile_data = game.open_obj("Planets", wh_planet.id)
				var wh_tile:int = randi() % len(game.tile_data)
				while game.tile_data[wh_tile] and (game.tile_data[wh_tile].has("ship_locator_depth") or game.tile_data[wh_tile].has("cave")):
					wh_tile = randi() % len(game.tile_data)
				game.erase_tile(wh_tile)
				game.tile_data[wh_tile].wormhole = {"active":true, "new":false, "l_dest_s_id":orig_s_l, "g_dest_s_id":orig_s_g, "l_dest_p_id":orig_p_l, "g_dest_p_id":orig_p_g}
				Helper.save_obj("Planets", wh_planet.id, game.tile_data)#update new tile info (destination wormhole)
			else:
				game.switch_view("", {"dont_fade_anim":true})
				game.c_p = tile.wormhole.l_dest_p_id
				game.c_p_g = tile.wormhole.g_dest_p_id
				game.c_s = tile.wormhole.l_dest_s_id
				game.c_s_g = tile.wormhole.g_dest_s_id
				game.tile_data = game.open_obj("Planets", game.c_p_g)
				game.planet_data = game.open_obj("Systems", game.c_s_g)
			game.ships_c_coords.p = game.c_p
			game.ships_dest_coords.p = game.c_p
			game.ships_c_coords.s = game.c_s
			game.ships_dest_coords.s = game.c_s
			game.ships_c_g_coords.s = game.c_s_g
			game.ships_dest_g_coords.s = game.c_s_g
			game.switch_view("planet", {"dont_save_zooms":true, "dont_fade_anim":true})
			game.view_tween.interpolate_property(game.view, "modulate", null, Color(1.0, 1.0, 1.0, 1.0), 0.2)
			game.view_tween.start()
		else:
			game.send_ships_panel.dest_p_id = p_id
			game.toggle_panel(game.send_ships_panel)
	else:
		if not tile.wormhole.has("investigation_length"):
			var costs:Dictionary = get_wh_costs()
			if game.SP >= costs.SP:
				if not game.objective.empty() and game.objective.type == game.ObjectiveType.WORMHOLE:
					game.objective.current += 1
				game.SP -= costs.SP
				game.stats_univ.wormholes_activated += 1
				game.stats_dim.wormholes_activated += 1
				game.stats_global.wormholes_activated += 1
				tile.wormhole.investigation_length = costs.time * 1000
				tile.wormhole.investigation_date = OS.get_system_time_msecs()
				game.popup(tr("INVESTIGATION_STARTED"), 2.0)
				add_time_bar(tile_id, "wormhole")
			else:
				game.popup(tr("NOT_ENOUGH_SP"), 1.5)

func hide_tooltip():
	if game.get_node("UI").has_node("BuildingShortcuts"):
		game.get_node("UI").get_node("BuildingShortcuts").close()
	game.hide_tooltip()
	game.hide_adv_tooltip()

func is_obstacle(tile, bldg_is_obstacle:bool = true):
	if not tile:
		return false
	return tile.has("rock") or (tile.has("bldg") if bldg_is_obstacle else true) or tile.has("unique_bldg") or tile.has("ship") or tile.has("wormhole") or tile.has("lake") or tile.has("cave") or tile.has("volcano") or ((tile.has("depth") or tile.has("crater")) and not tile.has("bridge"))

func available_for_mining(tile):
	return not tile or not tile.has("bldg") and not tile.has("unique_bldg") and not tile.has("rock") and not tile.has("ship") and not tile.has("wormhole") and not tile.has("lake") and not tile.has("cave") and not tile.has("volcano")

func available_to_build(tile):
	if bldg_to_construct == "MM":
		return available_for_mining(tile)
	if not tile:
		return true
	if bldg_to_construct == "GH":
		return not is_obstacle(tile)
	if bldg_to_construct == "ME":
		if tile.has("ash"):
			return not is_obstacle(tile)
	return not is_obstacle(tile)

func add_time_bar(id2:int, type:String):
	var local_id = id2
	var v = Vector2.ZERO
	v.x = (local_id % wid) * 200
	v.y = floor(local_id / wid) * 200
	v += Vector2(100, 15)
	var time_bar = game.time_scene.instance()
	time_bar.visible = get_parent().scale.x >= 0.25
	time_bar.rect_position = v
	add_child(time_bar)
	match type:
		"bldg":
			time_bar.modulate = Color(0, 0.74, 0, 1)
		"overclock":
			time_bar.modulate = Color(0, 0, 1, 1)
		"wormhole":
			time_bar.modulate = Color(105/255.0, 0, 1, 1)
	time_bars.append({"node":time_bar, "id":id2, "type":type})

func add_bldg_sprite(pos:Vector2, st:String, mod:Color = Color.white, sc:float = 0.4, offset:Vector2 = Vector2(100, 100)):
	var bldg = Sprite.new()
	bldg.texture = game.bldg_textures[st]
	bldg.scale *= sc
	bldg.position = pos + offset
	bldg.self_modulate = mod
	add_child(bldg)
	return bldg
	
func add_bldg(id2:int, st:String):
	var v = Vector2.ZERO
	v.x = (id2 % wid) * 200
	v.y = floor(id2 / wid) * 200
	bldgs[id2] = add_bldg_sprite(v, st)
	v += Vector2(100, 100)
	var tile = game.tile_data[id2]
	match st:
		"ME":
			add_rsrc(v, Color(0, 0.5, 0.9, 1), Data.rsrc_icons.ME, id2)
		"PP":
			add_rsrc(v, Color(0, 0.8, 0, 1), Data.rsrc_icons.PP, id2)
		"SP":
			add_rsrc(v, Color(0, 0.8, 0, 1), Data.rsrc_icons.SP, id2)
		"AE":
			add_rsrc(v, Color(0.89, 0.55, 1.0, 1), Data.rsrc_icons.AE, id2)
		"RL":
			add_rsrc(v, Color(0.3, 1.0, 0.3, 1), Data.rsrc_icons.RL, id2)
		"PC":
			add_rsrc(v, Color.white, Data.proton_icon, id2)
		"NC":
			add_rsrc(v, Color.white, Data.neutron_icon, id2)
		"EC":
			add_rsrc(v, Color.white, Data.electron_icon, id2)
		"MM":
			add_rsrc(v, Color(0.6, 0.6, 0.6, 1), Data.rsrc_icons.MM, id2, true)
		"SC":
			add_rsrc(v, Color(0.6, 0.6, 0.6, 1), Data.rsrc_icons.SC, id2)
		"GF":
			add_rsrc(v, Color(0.8, 0.9, 0.85, 1), Data.rsrc_icons.GF, id2)
		"SE":
			add_rsrc(v, Color(0, 0.8, 0, 1), Data.rsrc_icons.SE, id2)
		"AMN":
			add_rsrc(v, Color(0.89, 0.55, 1.0, 1), Data.rsrc_icons.AMN, id2)
		"GH":
			if tile.has("auto_GH"):
				if tile.auto_GH.has("soil_drain"):
					var fert = Sprite.new()
					fert.texture = preload("res://Graphics/Agriculture/fertilizer.png")
					bldgs[id2].add_child(fert)
					fert.name = "Fertilizer"
				add_rsrc(v, Color(0.41, 0.25, 0.16, 1), load("res://Graphics/Metals/%s.png" % tile.auto_GH.seed.split("_")[0]), id2)
			else:
				add_rsrc(v, Color(0.41, 0.25, 0.16, 1), null, id2)
		"SPR":
			if tile.bldg.has("reaction"):
				add_rsrc(v, Color.white, load("res://Graphics/Atoms/%s.png" % tile.bldg.reaction), id2)
			else:
				add_rsrc(v, Color.white, Data.rsrc_icons.SPR, id2)
		_:
			if Mods.added_buildings.has(st):
				add_rsrc(v, Mods.added_buildings[st].icon_color, Data.rsrc_icons[st], id2)
	var curr_time = OS.get_system_time_msecs()
	var hbox = Helper.add_lv_boxes(tile, v)
	add_child(hbox)
	hboxes[id2] = hbox
	if tile.bldg.has("overclock_mult"):
		add_time_bar(id2, "overclock")
	if tile.bldg.has("is_constructing"):
		add_time_bar(id2, "bldg")
	else:
		Helper.update_rsrc(p_i, tile)

func overclockable(bldg:String):
	return bldg in ["ME", "PP", "RL", "PC", "NC", "EC", "MM", "SP", "AE"]

func add_rsrc(v:Vector2, mod:Color, icon, id2:int, current_bar_visible = false):
	var rsrc:ResourceStored = game.rsrc_stored_scene.instance()
	rsrc.visible = get_parent().scale.x >= 0.25
	add_child(rsrc)
	rsrc.set_icon_texture(icon)
	rsrc.rect_position = v + Vector2(0, 70)
	rsrc.set_modulate(mod)
	rsrc.set_current_bar_visibility(current_bar_visible)
	rsrcs[id2] = rsrc

func on_timeout():
	if game.c_v != "planet":
		return
	var curr_time = OS.get_system_time_msecs()
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
			if not tile or not tile.has("bldg") or not tile.bldg.has("is_constructing"):
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
			if not tile or not tile.has("bldg") or not tile.bldg.has("overclock_date"):
				time_bar.queue_free()
				time_bars.erase(time_bar_obj)
				continue
			start_date = tile.bldg.overclock_date
			length = tile.bldg.overclock_length
			progress = 1 - (curr_time - start_date) / float(length)
			if progress < 0:
				var mult:float = tile.bldg.overclock_mult
				if tile.bldg.name == "PP":
					game.autocollect.rsrc.energy -= tile.bldg.path_1_value * (mult - 1) * (tile.substation_bonus if tile.has("substation_bonus") else 1.0)
				elif tile.bldg.name == "ME":
					game.autocollect.rsrc.minerals -= tile.bldg.path_1_value * (mult - 1) * (tile.ash.richness if tile.has("ash") else 1.0) * (tile.mineral_replicator_bonus if tile.has("mineral_replicator_bonus") else 1.0)
				elif tile.bldg.name == "RL":
					game.autocollect.rsrc.SP -= tile.bldg.path_1_value * (mult - 1) * (tile.observatory_bonus if tile.has("observatory_bonus") else 1.0)
				elif tile.bldg.name == "SP":
					var SP_prod = Helper.get_SP_production(p_i.temperature, tile.bldg.path_1_value * (mult - 1) * Helper.get_au_mult(tile) * (tile.substation_bonus if tile.has("substation_bonus") else 1.0))
					game.autocollect.rsrc.energy -= SP_prod
					if tile.has("aurora"):
						game.aurora_prod[tile.aurora.au_int].energy -= SP_prod
				elif tile.bldg.name == "AE":
					var base = -tile.bldg.path_1_value * (mult - 1) * p_i.pressure
					for el in p_i.atmosphere:
						var base_prod:float = base * p_i.atmosphere[el]
						Helper.add_atom_production(el, base_prod)
					Helper.add_energy_from_NFR(p_i, base)
					Helper.add_energy_from_CS(p_i, base)
				elif tile.bldg.name == "PC":
					game.autocollect.particles.proton -= tile.bldg.path_1_value / tile.bldg.planet_pressure * (mult - 1)
				elif tile.bldg.name == "NC":
					game.autocollect.particles.neutron -= tile.bldg.path_1_value / tile.bldg.planet_pressure * (mult - 1)
				elif tile.bldg.name == "EC":
					game.autocollect.particles.electron -= tile.bldg.path_1_value * tile.aurora.au_int * (mult - 1)
				tile.bldg.erase("overclock_date")
				tile.bldg.erase("overclock_length")
				tile.bldg.erase("overclock_mult")
		elif type == "wormhole":
			if tile.wormhole.active:
				$Obstacles.set_cell(id2 % wid, int(id2 / wid), 8)
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
		if not tile or not tile.has("bldg") and not tile.has("unique_bldg") or tile.has("bldg") and tile.bldg.has("is_constructing"):
			continue
		Helper.update_rsrc(p_i, tile, rsrcs[i])
	game.HUD.update_money_energy_SP()
	game.HUD.update_minerals()
	if update_XP:
		game.HUD.update_XP()

func construct(st:String, costs:Dictionary):
	finish_construct()
	if game.get_node("UI").has_node("BuildingShortcuts"):
		game.get_node("UI").get_node("BuildingShortcuts").close()
	var tween = get_tree().create_tween()
	tween.tween_property(game.HUD.get_node("Top/TextureRect"), "modulate", Color(1.5, 1.5, 1.0, 1.0), 0.2)
	if game.help.has("mass_build") and game.stats_univ.bldgs_built >= 18 and (not game.tutorial or game.tutorial.tut_num >= 26):
		game.help_str = "mass_build"
		Helper.put_rsrc(game.get_node("UI/Panel/VBox"), 32, {})
		Helper.add_label(tr("HOLD_SHIFT_TO_MASS_BUILD"), -1, true, true)
		Helper.add_label(tr("HIDE_HELP"), -1, true, true)
		game.get_node("UI/Panel").visible = true
		game.get_node("UI/Panel/AnimationPlayer").play("Fade")
	bldg_to_construct = st
	constr_costs = costs
	constr_costs_total = costs.duplicate()
	shadow = Sprite.new()
	put_shadow(shadow)
	game.HUD.get_node("Top/Resources/Stone").visible = false
	game.HUD.get_node("Top/Resources/SP").visible = false
	game.HUD.get_node("Top/Resources/Minerals").visible = false
	game.HUD.get_node("Top/Resources/Cellulose").visible = false
	if st == "GH":
		game.HUD.get_node("Top/Resources/Glass").visible = true
		game.HUD.get_node("Top/Resources/Soil").visible = true
	game.HUD.refresh()

func put_shadow(spr:Sprite, pos:Vector2 = Vector2.ZERO):
	spr.texture = game.bldg_textures[bldg_to_construct]
	spr.scale *= 0.4
	spr.modulate.a = 0.5
	spr.position.x = floor(pos.x / 200) * 200 + 100
	spr.position.y = floor(pos.y / 200) * 200 + 100
	add_child(spr)
	return spr
	
func finish_construct():
	if is_instance_valid(shadow):
		bldg_to_construct = ""
		shadow.free()
	if mass_build_rect.visible:
		mass_build_rect.visible = false
		for i in len(shadows):
			if is_instance_valid(shadows[i]):
				shadows[i].queue_free()
		shadow_num = 0
	var tween = get_tree().create_tween()
	tween.tween_property(game.HUD.get_node("Top/TextureRect"), "modulate", Color.white, 0.2)
	game.get_node("UI/Panel/AnimationPlayer").play("FadeOut")

func _on_Planet_tree_exited():
	queue_free()

func get_tile_id_from_pos(pos:Vector2):
	var x_pos = int(pos.x / 200)
	var y_pos = int(pos.y / 200)
	return x_pos % wid + y_pos * wid
