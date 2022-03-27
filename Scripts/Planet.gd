extends Node2D

onready var game = get_node("/root/Game")
onready var view = game.view
onready var id = game.c_p
onready var p_i = game.planet_data[id]

#Used to prevent view from moving outside viewport
var dimensions:float

#For exploring a cave
var rover_selected:int = -1
#The building you selected in construct panel
var bldg_to_construct:String = ""
#The cost of the above building
var constr_costs:Dictionary = {}
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

func _ready():
	shadows.resize(wid * wid)
	var tile_brightness:float = game.tile_brightness[p_i.type - 3]
	$TileMap.material.shader = preload("res://Shaders/BCS.shader")
	var lum:float = 0.0
	for star in game.system_data[game.c_s].stars:
		var sc:float = 0.5 * star.size / (p_i.distance / 500)
		if star.luminosity > lum:
			star_mod = Helper.get_star_modulate(star.class)
			$TileMap.modulate = star_mod
			var strength_mult = 1.0
			if p_i.temperature >= 1500:
				strength_mult = min(range_lerp(p_i.temperature, 1000, 3000, 1.2, 1.5), 1.5)
			else:
				strength_mult = min(range_lerp(p_i.temperature, -273, 1000, 0.3, 1.2), 1.2)
			var brightness:float = range_lerp(tile_brightness, 40000, 90000, 2.5, 1.1) * strength_mult
			var contrast:float = sqrt(brightness)
			$TileMap.material.set_shader_param("brightness", min(brightness, 2.0))
			$TileMap.material.set_shader_param("contrast", 1.5)
			#$TileMap.material.set_shader_param("saturation", saturation)
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
	var lake_1_phase = "G"
	var lake_2_phase = "G"
	if p_i.has("lake_1"):
		$Lakes1.tile_set = game.lake_TS
		var phase_1_scene = load("res://Scenes/PhaseDiagrams/" + p_i.lake_1 + ".tscn")
		var phase_1 = phase_1_scene.instance()
		lake_1_phase = Helper.get_state(p_i.temperature, p_i.pressure, phase_1)
		if lake_1_phase != "G":
			$Lakes1.modulate = phase_1.colors[lake_1_phase]
		phase_1.free()
	if p_i.has("lake_2"):
		$Lakes2.tile_set = game.lake_TS
		var phase_2_scene = load("res://Scenes/PhaseDiagrams/" + p_i.lake_2 + ".tscn")
		var phase_2 = phase_2_scene.instance()
		lake_2_phase = Helper.get_state(p_i.temperature, p_i.pressure, phase_2)
		if lake_2_phase != "G":
			$Lakes2.modulate = phase_2.colors[lake_2_phase]
			#$Lakes2.modulate = Color(0.3, 0.3, 0.3, 1)
		phase_2.free()
	for i in wid:
		for j in wid:
			var id2 = i % wid + j * wid
			var tile = game.tile_data[id2]
			$TileMap.set_cell(i, j, p_i.type - 3)
			if not tile:
				continue
			if tile.has("bldg"):
				add_bldg(id2, tile.bldg.name)
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
				#aurora.modulate.a = min(1.0, 0.5 + floor(hue - 0.4) / 5.0)
				add_child(aurora)
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
			if tile.has("rock"):
				$Obstacles.set_cell(i, j, 0)
			if tile.has("cave"):
				$Obstacles.set_cell(i, j, 1)
			if tile.has("volcano"):
				var volcano = Sprite.new()
				volcano.texture = preload("res://Graphics/Tiles/Volcano.png")
				add_child(volcano)
				volcano.position = Vector2(i, j) * 200 + Vector2(100, 100)
			if tile.has("ship"):
				if len(game.ship_data) == 0:
					$Obstacles.set_cell(i, j, 5)
				elif len(game.ship_data) == 1:
					$Obstacles.set_cell(i, j, 7)
				elif len(game.ship_data) == 2:
					$Obstacles.set_cell(i, j, 10)
			if tile.has("wormhole"):
				wormhole = game.wormhole_scene.instance()
				wormhole.get_node("Active").visible = tile.wormhole.active
				wormhole.get_node("Inactive").visible = not tile.wormhole.active
				wormhole.position = Vector2(i, j) * 200 + Vector2(100, 100)
				add_child(wormhole)
				if tile.wormhole.has("investigation_length"):
					add_time_bar(id2, "wormhole")
				p_i.wormhole = true
			if (tile.has("ship_part") or tile.has("artifact")) and not tile.has("depth"):
				$Obstacles.set_cell(i, j, 11)
			if tile.has("ruins"):
				$Obstacles.set_cell(i, j, 12)
			if tile.has("diamond_tower"):
				var tower = Sprite.new()
				tower.texture = load("res://Graphics/Tiles/diamond_tower.png")
				tower.scale *= 0.4
				add_child(tower)
				tower.position = Vector2(i, j) * 200 + Vector2(100, 0)
			if tile.has("lake"):
				if tile.lake.state == "l":
					get_node("Lakes%s" % tile.lake.type).set_cell(i, j, 2)
					add_particles(Vector2(i*200, j*200))
				elif tile.lake.state == "s":
					get_node("Lakes%s" % tile.lake.type).set_cell(i, j, 0)
				elif tile.lake.state == "sc":
					get_node("Lakes%s" % tile.lake.type).set_cell(i, j, 1)
			if tile.has("plant"):
				var lake_data:Dictionary = Helper.check_lake_presence(Vector2(id2 % wid, int(id2 / wid)), wid)
				if lake_data.has_lake:
					game.tile_data[id2].adj_lake_state = lake_data.lake_state
				if tile.plant.has("ash"):
					$Ash.set_cell(i, j, 0)
				else:
					$Soil.set_cell(i, j, 0)
				if tile.plant.has("name"):
					add_plant(id2, tile.plant.name)
					if game.science_unlocked.has("GHA"):
						items_collected.clear()
						harvest_plant(tile, id2)
						tile.plant.clear()
						game.show_collect_info(items_collected)
	if p_i.has("lake_1"):
		$Lakes1.update_bitmask_region()
	if p_i.has("lake_2"):
		$Lakes2.update_bitmask_region()
	$Soil.update_bitmask_region()
	$Ash.update_bitmask_region()
	#game.HUD.refresh()

func add_particles(pos:Vector2):
	var particle:Particles2D = game.particles_scene.instance()
	particle.position = pos + Vector2(30, 30)
	particle.lifetime = 2.0 / game.u_i.time_speed
	add_child(particle)

func show_tooltip(tile):
	if not tile:
		return
	var tooltip:String = ""
	var icons = []
	var adv = false
	if tile.has("bldg"):
		tooltip += Helper.get_bldg_tooltip(p_i, tile, 1)
		icons.append_array(Helper.flatten(Data.desc_icons[tile.bldg.name]) if Data.desc_icons.has(tile.bldg.name) else [])
		adv = len(icons) > 0
		game.help_str = "tile_shortcuts"
		if game.help.has("tile_shortcuts") and (not game.tutorial or game.tutorial.tut_num >= 26):
			tooltip += "\n%s\n%s\n%s\n%s\n%s" % [tr("PRESS_F_TO_UPGRADE"), tr("PRESS_Q_TO_DUPLICATE"), tr("PRESS_X_TO_DESTROY"), tr("HOLD_SHIFT_TO_SELECT_SIMILAR"), tr("HIDE_SHORTCUTS")]
	elif tile.has("volcano"):
		game.help_str = "volcano_desc"
		if not game.help.has("volcano_desc"):
			tooltip = "%s\n%s\n%s\n%s: %s" % [tr("VOLCANO"), tr("VOLCANO_DESC"), tr("HIDE_HELP"), tr("LARGEST_VEI") % ("(" + tr("VEI") + ") "), Helper.clever_round(tile.volcano.VEI)]
		else:
			tooltip = "%s\n%s: %s" % [tr("VOLCANO"), tr("LARGEST_VEI") % "", Helper.clever_round(tile.volcano.VEI)]
	elif tile.has("crater") and tile.crater.has("init_depth"):
		adv = tile.has("aurora")
		if adv:
			tooltip = "[aurora au_int=%s]" % tile.aurora.au_int
		game.help_str = "crater_desc"
		if game.help.has("crater_desc"):
			tooltip += tr("METAL_CRATER").format({"metal":tr(tile.crater.metal.to_upper()), "crater":tr("CRATER")}) + "\n%s\n%s\n%s" % [tr("CRATER_DESC"), tr("HIDE_HELP"), tr("HOLE_DEPTH") + ": %s m"  % [tile.depth]]
		else:
			tooltip += tr("METAL_CRATER").format({"metal":tr(tile.crater.metal.to_upper()), "crater":tr("CRATER")}) + "\n%s" % [tr("HOLE_DEPTH") + ": %s m"  % [tile.depth]]
	elif tile.has("cave"):
		var au_str:String = ""
		adv = tile.has("aurora") or tile.cave.has("modifiers")
		if tile.has("aurora"):
			au_str = "[aurora au_int=%s]" % tile.aurora.au_int
			tooltip = au_str
		tooltip += tr("CAVE")
		var floor_size:String = tr("FLOOR_SIZE").format({"size":tile.cave.floor_size})
#		if tile.cave.has("special_cave") and tile.cave.special_cave == 1:
#			floor_size = tr("FLOOR_SIZE").format({"size":"?"})
		if not game.science_unlocked.has("RC"):
			tooltip += "\n%s\n%s\n%s" % [tr("CAVE_DESC"), tr("NUM_FLOORS") % tile.cave.num_floors, floor_size]
		else:
			if game.help.has("cave_controls"):
				tooltip += "\n%s\n%s\n%s" % [tr("NUM_FLOORS") % tile.cave.num_floors, floor_size, tr("CLICK_CAVE_TO_EXPLORE")]
			else:
				tooltip += "\n%s\n%s" % [tr("NUM_FLOORS") % tile.cave.num_floors, floor_size]
		if tile.cave.has("modifiers"):
			tooltip += Helper.get_modifier_string(tile.cave.modifiers, au_str, icons)
		if game.cave_gen_info:
			if tile.cave.has("period"):#Save migration
				tooltip += "\n%s: %s" % [tr("PERIOD"), tile.cave.period]
			else:
				tooltip += "\n%s: %s" % [tr("PERIOD"), 65]
	elif tile.has("plant"):
		if tile.plant.has("ash"):
			tooltip = "%s\n%s: %s" % [tr("VOLCANIC_ASH"), tr("MINERAL_RICHNESS"), Helper.clever_round(tile.plant.ash)]
		else:
			if not tile.plant.has("name"):
				game.help_str = "plant_something_here"
				if game.help.has("plant_something_here"):
					tooltip = tr("PLANT_STH") + "\n" + tr("HIDE_HELP")
			else:
				tooltip = Helper.get_plant_name(tile.plant.name)
				if OS.get_system_time_msecs() >= tile.plant.plant_date + tile.plant.grow_time:
					tooltip += "\n" + tr("CLICK_TO_HARVEST")
	elif tile.has("lake"):
		if tile.lake.state == "s" and tile.lake.element == "H2O":
			tooltip = tr("ICE")
		elif tile.lake.state == "l" and tile.lake.element == "H2O":
			tooltip = tr("H2O_NAME")
		else:
			match tile.lake.state:
				"l":
					tooltip = tr("LAKE_CONTENTS").format({"state":tr("LIQUID"), "contents":tr("%s_NAME" % tile.lake.element.to_upper())})
				"s":
					tooltip = tr("LAKE_CONTENTS").format({"state":tr("SOLID"), "contents":tr("%s_NAME" % tile.lake.element.to_upper())})
				"sc":
					tooltip = tr("LAKE_CONTENTS").format({"state":tr("SUPERCRITICAL"), "contents":tr("%s_NAME" % tile.lake.element.to_upper())})
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
				adv = true
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
	if adv:
		game.show_adv_tooltip(tooltip, icons)
	else:
		game.hide_adv_tooltip()
		if tooltip == "":
			game.hide_tooltip()
		else:
			game.show_tooltip(tooltip)

func get_wh_costs():
	return {"SP":round(10000 * pow(game.stats_univ.wormholes_activated + 1, 0.8)), "time":900 * pow(game.stats_univ.wormholes_activated + 1, 0.2) / game.u_i.time_speed}

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
	var constr_costs2:Dictionary = constr_costs.duplicate(true)
	if tile and tile.has("cost_div"):
		for cost in constr_costs2:
			constr_costs2[cost] /= tile.cost_div
	constr_costs2.time /= game.u_i.time_speed
	if game.check_enough(constr_costs2):
		game.deduct_resources(constr_costs2)
		game.stats_univ.bldgs_built += 1
		game.stats_dim.bldgs_built += 1
		game.stats_global.bldgs_built += 1
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
		tile.bldg.is_constructing = true
		tile.bldg.construction_date = curr_time
		tile.bldg.construction_length = constr_costs2.time * 1000
		tile.bldg.XP = round(constr_costs2.money / 100.0)
		if _bldg_to_construct != "PCC":
			tile.bldg.path_1 = 1
			tile.bldg.path_1_value = Data.path_1[_bldg_to_construct].value
		if _bldg_to_construct in ["ME", "PP", "MM", "SC", "GF", "SE", "GH", "SP", "AE", "CBD", "AMN", "SPR"]:
			tile.bldg.path_2 = 1
			tile.bldg.path_2_value = Data.path_2[_bldg_to_construct].value
		if _bldg_to_construct in ["ME", "PP", "MM", "SC", "GF", "SE", "SP", "AE"]:
			tile.bldg.collect_date = tile.bldg.construction_date + tile.bldg.construction_length
			tile.bldg.stored = 0
		if _bldg_to_construct in ["SC", "GF", "SE", "CBD"]:
			tile.bldg.path_3 = 1
			tile.bldg.path_3_value = Data.path_3[_bldg_to_construct].value
		if _bldg_to_construct == "RL":
			game.show.SP = true
			tile.bldg.collect_date = tile.bldg.construction_date + tile.bldg.construction_length
		elif _bldg_to_construct == "MS":
			tile.bldg.mineral_cap_upgrade = Data.path_1.MS.value#The amount of cap to add once construction is done
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
		tile.bldg.c_p_g = game.c_p_g
		if _bldg_to_construct == "MM" and not tile.has("depth"):
			tile.depth = 0
		if Helper.has_IR(_bldg_to_construct):
			tile.bldg.IR_mult = Helper.get_IR_mult(tile.bldg.name)
		else:
			tile.bldg.IR_mult = 1
		game.tile_data[tile_id] = tile
		add_bldg(tile_id, _bldg_to_construct)
	elif not mass_build:
		var tooltip = tr("NOT_ENOUGH_RESOURCES")
		if game.tutorial and game.tutorial.tut_num < 15 and game.tutorial.tut_num > 6:
			game.popup("%s %s" % [tooltip, tr("COLLECT_REMINDER")], 3)
		else:
			game.popup(tooltip, 1.2)

func seeds_plant(tile, tile_id:int, curr_time, mass_plant:bool = false):
	#Plants can't grow when not adjacent to lakes
	var check_lake = Helper.check_lake(Vector2(tile_id % wid, int(tile_id / wid)), wid, game.item_to_use.name)
	if check_lake[0]:
		tile.plant.name = game.item_to_use.name
		game.item_to_use.num -= 1
		tile.plant.plant_date = curr_time
		tile.plant.grow_time = game.craft_agriculture_info[game.item_to_use.name].grow_time
		tile.plant.grow_time /= Helper.get_au_mult(tile) * game.u_i.time_speed
		if tile.has("bldg") and tile.bldg.name == "GH":
			tile.plant.grow_time /= tile.bldg.path_1_value
		if check_lake[1] == "l":
			tile.plant.grow_time /= 2
		elif check_lake[1] == "sc":
			tile.plant.grow_time /= 4
		tile.plant.is_growing = true
		add_plant(tile_id, game.item_to_use.name)
		game.get_node("PlantingSounds/%s" % [Helper.rand_int(1,3)]).play()
		game.remove_items(game.item_to_use.name, 1)
	elif not mass_plant:
		game.popup(tr("NOT_ADJACENT_TO_LAKE") % [tr("%s_NAME" % game.craft_agriculture_info[game.item_to_use.name].lake.to_upper())], 2)

func fertilizer_plant(tile, tile_id:int):
	var curr_time = OS.get_system_time_msecs()
	tile.plant.plant_date -= game.craft_agriculture_info.fertilizer.speed_up_time
	game.item_to_use.num -= 1

func harvest_plant(tile, tile_id:int):
	if not tile.plant.has("name"):
		return
	var curr_time = OS.get_system_time_msecs()
	if curr_time >= tile.plant.grow_time + tile.plant.plant_date:
		var produce:Dictionary = game.craft_agriculture_info[tile.plant.name].produce.duplicate(true)
		for p in produce:
			produce[p] *= Helper.get_au_mult(tile)
			if tile.has("bldg") and tile.bldg.name == "GH":
				produce[p] *= tile.bldg.path_2_value
			if tile.plant.has("ash"):
				produce[p] *= tile.plant.ash
			game.show[p] = true
			Helper.add_item_to_coll(items_collected, p, produce[p])
		game.show.metals = true
		for plant_attr in tile.plant.keys():
			if plant_attr != "ash":
				tile.plant.erase(plant_attr)
		plant_sprites[String(tile_id)].queue_free()

func speedup_bldg(tile, tile_id:int, curr_time):
	if tile.bldg.is_constructing:
		var speedup_time = game.speedups_info[game.item_to_use.name].time
		#Time remaining to finish construction
		var time_remaining = tile.bldg.construction_date + tile.bldg.construction_length - curr_time
		var num_needed = min(game.item_to_use.num, ceil((time_remaining) / float(speedup_time)))
		if not tiles_selected.empty():
			min(game.item_to_use.num / len(tiles_selected), ceil((time_remaining) / float(speedup_time)))
		tile.bldg.construction_date -= speedup_time * num_needed
		var time_sped_up = min(speedup_time * num_needed, time_remaining)
		if tile.bldg.has("collect_date"):
			tile.bldg.collect_date -= time_sped_up
		if tile.bldg.has("overclock_date"):
			tile.bldg.overclock_date -= time_sped_up
		if tile.bldg.has("start_date"):
			tile.bldg.start_date -= time_sped_up
		game.item_to_use.num -= num_needed

func overclock_bldg(tile, tile_id:int, curr_time):
	var mult:float = game.overclocks_info[game.item_to_use.name].mult
	if overclockable(tile.bldg.name) and not tile.bldg.is_constructing and (not tile.bldg.has("overclock_mult") or tile.bldg.overclock_mult < mult):
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
			game.autocollect.rsrc.SP += tile.bldg.path_1_value * mult_diff
			game.autocollect.rsrc_list[String(tile.bldg.c_p_g)].SP += tile.bldg.path_1_value * mult_diff
		elif tile.bldg.name == "PC":
			game.autocollect.particles.proton += tile.bldg.path_1_value / tile.bldg.planet_pressure * mult_diff
		elif tile.bldg.name == "NC":
			game.autocollect.particles.neutron += tile.bldg.path_1_value / tile.bldg.planet_pressure * mult_diff
		elif tile.bldg.name == "EC":
			game.autocollect.particles.electron += tile.bldg.path_1_value * tile.aurora.au_int * mult_diff
		if tile.has("auto_collect"):
			if tile.bldg.name == "PP":
				game.autocollect.rsrc.energy += tile.bldg.path_1_value * mult_diff * tile.auto_collect / 100.0
				game.autocollect.rsrc_list[String(tile.bldg.c_p_g)].energy += tile.bldg.path_1_value * mult_diff * tile.auto_collect / 100.0
			elif tile.bldg.name == "SP":
				var prod:float = Helper.get_SP_production(p_i.temperature, tile.bldg.path_1_value * mult, 1.0 + (tile.aurora.au_int if tile.has("aurora") else 0.0))
				game.autocollect.rsrc.energy += prod * mult_diff  * tile.auto_collect / 100.0
				game.autocollect.rsrc_list[String(tile.bldg.c_p_g)].energy += prod * mult_diff * tile.auto_collect / 100.0
			elif tile.bldg.name == "ME":
				var prod:float = tile.bldg.path_1_value * (tile.plant.ash if tile.has("plant") and tile.plant.has("ash") else 1.0)
				game.autocollect.rsrc.minerals += prod * mult_diff * tile.auto_collect / 100.0
				game.autocollect.rsrc_list[String(tile.bldg.c_p_g)].minerals += prod * mult_diff * tile.auto_collect / 100.0
		var coll_date = tile.bldg.collect_date
		tile.bldg.collect_date = curr_time - (curr_time - coll_date) / tile.bldg.overclock_mult
		game.item_to_use.num -= 1

func click_tile(tile, tile_id:int):
	if not tile.has("bldg") or is_instance_valid(game.active_panel):
		return
	var bldg:String = tile.bldg.name
	if bldg in ["ME", "PP", "MM", "SP", "AE"]:
		Helper.update_rsrc(p_i, tile)
		if game.icon_animations:
			add_anim_icon(tile, tile_id)
		Helper.collect_rsrc(items_collected, p_i, tile, tile_id, false)
	else:
		if not tile.bldg.is_constructing:
			game.c_t = tile_id
			match bldg:
				"GH":
					if game.science_unlocked.has("GHA"):
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
			game.hide_tooltip()

func destroy_bldg(id2:int, mass:bool = false):
	var tile = game.tile_data[id2]
	var bldg:String = tile.bldg.name
	items_collected.clear()
	Helper.update_rsrc(p_i, tile)
	if game.icon_animations:
		add_anim_icon(tile, id2)
	Helper.collect_rsrc(items_collected, p_i, tile, id2)
	bldgs[id2].queue_free()
	hboxes[id2].queue_free()
	if is_instance_valid(rsrcs[id2]):
		rsrcs[id2].queue_free()
	var mult:float = tile.bldg.overclock_mult if tile.bldg.has("overclock_mult") else 1.0
	var ac:float = tile.auto_collect if tile.has("auto_collect") else 0.0
	if bldg == "MS":
		if tile.bldg.is_constructing:
			game.mineral_capacity -= tile.bldg.path_1_value - tile.bldg.mineral_cap_upgrade
		else:
			game.mineral_capacity -= tile.bldg.path_1_value
		if game.mineral_capacity < 200:
			game.mineral_capacity = 200
	elif bldg == "NSF":
		if tile.bldg.is_constructing:
			game.neutron_cap -= tile.bldg.path_1_value - tile.bldg.cap_upgrade
		else:
			game.neutron_cap -= tile.bldg.path_1_value
	elif bldg == "ESF":
		if tile.bldg.is_constructing:
			game.electron_cap -= tile.bldg.path_1_value - tile.bldg.cap_upgrade
		else:
			game.electron_cap -= tile.bldg.path_1_value
	elif bldg == "RL":
		if not tile.bldg.is_constructing:
			game.autocollect.rsrc_list[String(game.c_p_g)].SP -= tile.bldg.path_1_value * mult
			game.autocollect.rsrc.SP -= tile.bldg.path_1_value * mult
	elif bldg == "PC":
		if not tile.bldg.is_constructing:
			game.autocollect.particles.proton -= tile.bldg.path_1_value / tile.bldg.planet_pressure * mult
	elif bldg == "NC":
		if not tile.bldg.is_constructing:
			game.autocollect.particles.neutron -= tile.bldg.path_1_value / tile.bldg.planet_pressure * mult
	elif bldg == "EC":
		if not tile.bldg.is_constructing:
			game.autocollect.particles.electron -= tile.bldg.path_1_value * tile.aurora.au_int * mult
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
				if _tile.has("auto_collect_dict"):
					_tile.auto_collect_dict.erase(String(id2))
					if _tile.auto_collect_dict.empty():
						_tile.erase("auto_collect_dict")
						_tile.erase("auto_collect")
					else:
						var new_value:float = 0
						for st in _tile.auto_collect_dict:
							new_value = max(new_value, _tile.auto_collect_dict[st])
						var diff:float = max(0, _tile.auto_collect - new_value)
						_tile.auto_collect = new_value
						if _tile.has("bldg"):
							if _tile.bldg.name == "ME":
								var prod:float = _tile.bldg.path_1_value * (_tile.plant.ash if _tile.has("plant") and _tile.plant.has("ash") else 1.0)
								game.autocollect.rsrc_list[String(game.c_p_g)].minerals -= prod * diff / 100.0
								game.autocollect.rsrc.minerals -= prod * diff / 100.0
							elif _tile.bldg.name == "PP":
								game.autocollect.rsrc_list[String(game.c_p_g)].energy -= _tile.bldg.path_1_value * diff / 100.0
								game.autocollect.rsrc.energy -= _tile.bldg.path_1_value * diff / 100.0
							elif _tile.bldg.name == "SP":
								var prod:float = Helper.get_SP_production(p_i.temperature, _tile.bldg.path_1_value * mult, 1.0 + (_tile.aurora.au_int if _tile.has("aurora") else 0.0))
								game.autocollect.rsrc_list[String(game.c_p_g)].energy -= prod * diff / 100.0
								game.autocollect.rsrc.energy -= prod * diff / 100.0
	else:
		if tile.has("auto_collect"):
			if bldg == "ME":
				var prod:float = tile.bldg.path_1_value * (tile.plant.ash if tile.has("plant") and tile.plant.has("ash") else 1.0)
				game.autocollect.rsrc_list[String(game.c_p_g)].minerals -= prod * mult * ac / 100.0
				game.autocollect.rsrc.minerals -= prod * mult * ac / 100.0
			elif bldg == "PP":
				game.autocollect.rsrc_list[String(game.c_p_g)].energy -= tile.bldg.path_1_value * mult * ac / 100.0
				game.autocollect.rsrc.energy -= tile.bldg.path_1_value * mult * ac / 100.0
			elif bldg == "SP":
				var prod:float = Helper.get_SP_production(p_i.temperature, tile.bldg.path_1_value * mult, 1.0 + (tile.aurora.au_int if tile.has("aurora") else 0.0))
				game.autocollect.rsrc_list[String(game.c_p_g)].energy -= prod * ac / 100.0
				game.autocollect.rsrc.energy -= prod * ac / 100.0
	if tile.has("auto_GH"):
		for p in tile.auto_GH.produce:
			game.autocollect.mets[p] -= tile.auto_GH.produce[p]
		game.autocollect.mats.cellulose += tile.auto_GH.cellulose_drain
		tile.erase("auto_GH")
	tile.erase("bldg")
	if tile.empty():
		game.tile_data[id2] = null
	if not mass:
		game.show_collect_info(items_collected)

func add_shadows():
#	for sh in shadows:
#		remove_child(sh)
#		sh.queue_free()
#	shadows.clear()
	var poly:Rect2 = Rect2(mass_build_rect.rect_position, Vector2.ZERO)
	poly.end = mouse_pos
	poly = poly.abs()
	for i in wid:
		for j in wid:
			var shadow_pos:Vector2 = Vector2(i * 200, j * 200) + Vector2(100, 100)
			var tile_rekt:Rect2 = Rect2(Vector2(i * 200, j * 200), Vector2.ONE * 200)
			var id2:int = i % wid + j * wid
			if is_instance_valid(shadows[id2]) and is_a_parent_of(shadows[id2]):
				if not poly.intersects(tile_rekt):
					remove_child(shadows[id2])
					shadows[id2].queue_free()
					shadow_num -= 1
			else:
				if poly.intersects(tile_rekt) and available_to_build(game.tile_data[id2]):
					shadows[id2] = put_shadow(Sprite.new(), shadow_pos)
					shadow_num += 1

func remove_selected_tiles():
	tiles_selected.clear()
	for white_rect in get_tree().get_nodes_in_group("white_rects"):
		remove_child(white_rect)
		white_rect.queue_free()
		white_rect.remove_from_group("white_rects")

var prev_tile_over = -1
var mouse_pos = Vector2.ZERO

func check_tile_change(event, fn:String, fn_args:Array = []):
	var delta:Vector2 = event.relative / view.scale if event is InputEventMouseMotion else Vector2.ZERO
	var new_x = stepify(round(mouse_pos.x - 100), 200)
	var new_y = stepify(round(mouse_pos.y - 100), 200)
	var old_x = stepify(round(mouse_pos.x - delta.x * 2.0 - 100), 200)
	var old_y = stepify(round(mouse_pos.y - delta.y * 2.0 - 100), 200)
	if new_x > old_x:
		callv(fn, fn_args)
	elif new_x < old_x:
		callv(fn, fn_args)
	#prints(round(mouse_pos.y - 100), round(mouse_pos.y - delta.y - 100))
	if new_y > old_y:
		callv(fn, fn_args)
	elif new_y < old_y:
		callv(fn, fn_args)

func _unhandled_input(event):
	if game.tutorial and game.tutorial.BG_blocked:
		return
	var placing_soil = game.bottom_info_action == "place_soil"
	var about_to_mine = game.bottom_info_action == "about_to_mine"
	var mass_build:bool = Input.is_action_pressed("left_click") and Input.is_action_pressed("shift") and game.bottom_info_action == "building"
	view.move_view = not mass_build
	view.scroll_view = not mass_build
	if tile_over != -1 and game.bottom_info_action != "building":
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
				game.upgrade_panel.planet.clear()
				if tiles_selected.empty():
					game.upgrade_panel.ids = [tile_over]
				else:
					game.upgrade_panel.ids = tiles_selected.duplicate(true)
				game.toggle_panel(game.upgrade_panel)
			elif Input.is_action_just_released("X") and not game.active_panel:
				game.hide_adv_tooltip()
				game.hide_tooltip()
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
			elif Input.is_action_just_released("G") and not tiles_selected.empty():
				items_collected.clear()
				if tile.bldg.name in ["GF", "SE"]:
					for tile_id in tiles_selected:
						var _tile = game.tile_data[tile_id]
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
				elif tile.bldg.name == "SC":
					for tile_id in tiles_selected:
						var _tile = game.tile_data[tile_id]
						if not _tile.bldg.has("stone"):
							var stone_qty = _tile.bldg.path_2_value
							var stone_total = Helper.get_sum_of_dict(game.stone)
							if stone_total >= stone_qty:
								var stone_to_crush:Dictionary = {}
								for el in game.stone:
									stone_to_crush[el] = stone_qty / stone_total * game.stone[el]
									game.stone[el] *= (1.0 - stone_qty / stone_total)
								_tile.bldg.stone = stone_to_crush
								_tile.bldg.stone_qty = stone_qty
								_tile.bldg.start_date = OS.get_system_time_msecs()
								var expected_rsrc:Dictionary = {}
								Helper.get_SC_output(expected_rsrc, stone_qty, _tile.bldg.path_3_value, stone_total)
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
					game.HUD.refresh()
				game.show_collect_info(items_collected)
		if not is_instance_valid(game.active_panel) and Input.is_action_just_pressed("shift") and tile:
			tiles_selected.clear()
			var path_1_value_sum:float = 0
			var path_2_value_sum:float = 0
			var path_3_value_sum:float = 0
			for i in len(game.tile_data):
				var select:bool = false
				var tile2 = game.tile_data[i]
				if not tile2 or not tile2.has("bldg") and not tile2.has("plant"):
					continue
				if tile.has("bldg"):
					if tile2.has("bldg") and tile2.bldg.name == tile.bldg.name:
						if not Input.is_action_pressed("alt") or tile2.has("auto_collect"):
							select = true
				elif tile.has("plant") and tile.plant.has("name"):
					if tile2.has("plant") and tile2.plant.has("name") and tile2.plant.name == tile.plant.name:
						select = true
				if select:
					if tile.has("bldg"):
						if tile.bldg.name in ["ME", "PP", "SP", "AE", "MM", "SC", "SE", "GF"]:
							path_1_value_sum += Helper.get_final_value(p_i, tile2, 1)
							path_2_value_sum += Helper.get_final_value(p_i, tile2, 2)
						elif tile.bldg.name in ["RL", "MS", "PC", "NC", "EC", "NSF", "ESF"]:
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
			if tile.has("bldg"):
				if Data.desc_icons.has(tile.bldg.name):
					game.show_adv_tooltip(Helper.get_bldg_tooltip2(tile.bldg.name, path_1_value_sum, path_2_value_sum, path_3_value_sum) + "\n" + tr("SELECTED_X_BLDGS") % len(tiles_selected), Helper.flatten(Data.desc_icons[tile.bldg.name]))
				else:
					game.show_tooltip(Helper.get_bldg_tooltip2(tile.bldg.name, path_1_value_sum, path_2_value_sum, path_3_value_sum) + "\n" + tr("SELECTED_X_BLDGS") % len(tiles_selected))
	if Input.is_action_just_released("shift"):
		remove_selected_tiles()
		if tile_over != -1 and not game.upgrade_panel.visible and not game.YN_panel.visible:
			if game.tile_data[tile_over] and not is_instance_valid(game.active_panel):
				show_tooltip(game.tile_data[tile_over])
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
		var black_bg = game.get_node("UI/PopupBackground").visible
		$WhiteRect.visible = mouse_on_tiles and not black_bg
		$WhiteRect.position.x = floor(mouse_pos.x / 200) * 200
		$WhiteRect.position.y = floor(mouse_pos.y / 200) * 200
		if mouse_on_tiles:
			var x_over:int = int(mouse_pos.x / 200)
			var y_over:int = int(mouse_pos.y / 200)
			tile_over = x_over % wid + y_over * wid
			if tile_over != prev_tile_over and not_on_button and not game.item_cursor.visible and not black_bg and not game.active_panel:
				game.hide_tooltip()
				game.hide_adv_tooltip()
				if not tiles_selected.empty() and not tile_over in tiles_selected:
					remove_selected_tiles()
				var tile = game.tile_data[tile_over]
				if placing_soil and Input.is_action_pressed("shift") and Input.is_action_pressed("left_click"):
					if not tile:
						tile = {}
					check_tile_change(event, "place_soil", [tile, Vector2(x_over, y_over)])
				show_tooltip(tile)
				for white_rect in get_tree().get_nodes_in_group("CBD_white_rects"):
					remove_child(white_rect)
					white_rect.queue_free()
					white_rect.remove_from_group("CBD_white_rects")
				if tile and tile.has("bldg") and tile.bldg.name == "CBD":
					var n:int = tile.bldg.path_3_value
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
				game.hide_tooltip()
				tile_over = -1
				prev_tile_over = -1
			game.hide_adv_tooltip()
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
				remove_child(shadows[i])
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
	if (Input.is_action_just_pressed("left_click") or event is InputEventScreenTouch) and not view.dragged and not_on_button and Geometry.is_point_in_polygon(mouse_pos, planet_bounds):
		var x_pos = int(mouse_pos.x / 200)
		var y_pos = int(mouse_pos.y / 200)
		var tile_id = get_tile_id_from_pos(mouse_pos)
		var tile = game.tile_data[tile_id]
		if placing_soil:
			if not tile:
				tile = {}
			place_soil(tile, Vector2(x_pos, y_pos))
			return
	if (Input.is_action_just_released("left_click") or event is InputEventScreenTouch) and not view.dragged and not_on_button and Geometry.is_point_in_polygon(mouse_pos, planet_bounds) and not placing_soil:
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
			if tile.has("plant"):#if clicked tile has soil on it
				var orig_num:int = game.item_to_use.num
				if t == "fertilizer":
					if tiles_selected.empty():
						fertilizer_plant(tile, tile_id)
					else:
						for _tile in tiles_selected:
							fertilizer_plant(game.tile_data[_tile], _tile)
							if game.item_to_use.num <= 0:
								break
					game.remove_items(game.item_to_use.name, orig_num - game.item_to_use.num)
				elif t == "":
					if tiles_selected.empty():
						harvest_plant(tile, tile_id)
					else:
						for _tile in tiles_selected:
							harvest_plant(game.tile_data[_tile], _tile)
				elif t == "seeds":
					if tiles_selected.empty():
						if not tile.plant.has("name") and (not game.science_unlocked.has("GHA") or not tile.has("bldg")):
							seeds_plant(tile, tile_id, curr_time)
					else:
						for _tile_id in tiles_selected:
							var _tile = game.tile_data[_tile_id]
							if _tile.has("plant") and not _tile.plant.has("name") and (not game.science_unlocked.has("GHA") or not tile.has("bldg")):
								seeds_plant(_tile, _tile_id, curr_time, true)
								if game.item_to_use.num <= 0:
									break
				game.update_item_cursor()
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
			elif tile.has("cave") or tile.has("ruins") or tile.has("diamond_tower"):
				if tile.has("cave") and tile.cave.has("special_cave") and tile.cave.special_cave == 4:
					if not game.fourth_ship_hints.barrier_broken:
						if not (game.fourth_ship_hints.manipulators[0] and game.fourth_ship_hints.manipulators[1] and game.fourth_ship_hints.manipulators[2] and game.fourth_ship_hints.manipulators[3] and game.fourth_ship_hints.manipulators[4] and game.fourth_ship_hints.manipulators[5]):
							game.popup(tr("CAVE_BLOCKED"), 2.0)
							return
						var rsrc = {"sapphire":1000000, "emerald":1000000, "ruby":1000000, "topaz":1000000, "amethyst":1000000, "quartz":1000000}
						if game.check_enough(rsrc):
							game.deduct_resources(rsrc)
							game.fourth_ship_hints.barrier_broken = true
						else:
							game.popup(tr("CAVE_BLOCKED"), 2.0)
							return
				if game.bottom_info_action == "enter_cave":
					game.c_t = tile_id
					game.rover_id = rover_selected
					if tile.has("cave") or tile.has("diamond_tower"):
						game.switch_view("cave")
					else:
						game.switch_view("ruins")
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
				if tile.wormhole.active:
					if game.universe_data[game.c_u].lv < 18:
						game.long_popup(tr("LV_18_NEEDED_DESC"), tr("LV_18_NEEDED"))
						return
					Helper.update_ship_travel()
					if game.ships_travel_view != "-":
						game.popup(tr("SHIPS_ALREADY_TRAVELLING"), 1.5)
						return
					if Helper.ships_on_planet(id):
						if game.view_tween.is_active():
							return
						game.view_tween.interpolate_property(game.view, "modulate", null, Color(1.0, 1.0, 1.0, 0.0), 0.1)
						game.view_tween.start()
						yield(game.view_tween, "tween_all_completed")
						if tile.wormhole.new:#generate galaxy -> remove tiles -> generate system -> open/close tile_data to update wormhole info -> open destination tile_data to place destination wormhole
							visible = false
							if game.galaxy_data[game.c_g].has("wormholes"):
								game.galaxy_data[game.c_g].wormholes.append({"from":game.c_s, "to":tile.wormhole.l_dest_s_id})
							else:
								game.galaxy_data[game.c_g].wormholes = [{"from":game.c_s, "to":tile.wormhole.l_dest_s_id}]
							if not game.galaxy_data[game.c_g].has("discovered"):#if galaxy generated systems
								yield(game.start_system_generation(), "completed")
							else:
								Helper.save_obj("Clusters", game.c_c_g, game.galaxy_data)
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
							var wh_planet = game.planet_data[Helper.rand_int(0, wh_system.planet_num - 1)]
							while wh_planet.type in [11, 12]:
								wh_planet = game.planet_data[Helper.rand_int(0, wh_system.planet_num - 1)]
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
							var wh_tile:int = Helper.rand_int(0, len(game.tile_data) - 1)
							while game.tile_data[wh_tile] and (game.tile_data[wh_tile].has("ship_locator_depth") or game.tile_data[wh_tile].has("cave")):
								wh_tile = Helper.rand_int(0, len(game.tile_data) - 1)
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
						game.send_ships_panel.dest_p_id = id
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
							tile.wormhole.investigation_date = curr_time
							game.popup(tr("INVESTIGATION_STARTED"), 2.0)
							add_time_bar(tile_id, "wormhole")
						else:
							game.popup(tr("NOT_ENOUGH_SP"), 1.5)
			game.show_collect_info(items_collected)
		game.HUD.refresh()
		if game.planet_HUD:
			game.planet_HUD.refresh()

func place_soil(tile:Dictionary, tile_pos:Vector2):
	if tile.has("plant") and tile.plant.has("ash"):
		return
	if not tile.has("plant"):
		if available_for_plant(tile):
			if game.check_enough({"soil":10}):
				var tile_id:int = int(tile_pos.x) % wid + tile_pos.y * wid
				game.deduct_resources({"soil":10})
				if not tile:
					game.tile_data[tile_id] = {}
				game.tile_data[tile_id].plant = {}
				if not game.tile_data[tile_id].has("adj_lake_state"):
					var lake_data:Dictionary = Helper.check_lake_presence(Vector2(tile_id % wid, int(tile_id / wid)), wid)
					if lake_data.has_lake:
						game.tile_data[tile_id].adj_lake_state = lake_data.lake_state
				$Soil.set_cell(tile_pos.x, tile_pos.y, 0)
				$Soil.update_bitmask_region()
				game.HUD.refresh()
			else:
				game.popup(tr("NOT_ENOUGH_SOIL"), 1.2)
	else:
		if not tile.plant.has("name") and (game.science_unlocked.has("GHA") or not tile.has("auto_GH")):
			game.add_resources({"soil":10})
			tile.erase("plant")
			$Soil.set_cell(tile_pos.x, tile_pos.y, -1)
			$Soil.update_bitmask_region()

func available_for_plant(tile):
	if not tile or not tile.has("plant"):
		return false
	if not tile.has("bldg"):
		return true
	return not is_obstacle(tile, tile.bldg.name != "GH")

func is_obstacle(tile, bldg_is_obstacle:bool = true):
	if not tile:
		return false
	return tile.has("rock") or (tile.has("bldg") if bldg_is_obstacle else true) or tile.has("ship") or tile.has("wormhole") or tile.has("lake") or tile.has("cave") or tile.has("volcano") or ((tile.has("depth") or tile.has("crater")) and not tile.has("bridge"))

func available_for_mining(tile):
	return not tile or not tile.has("bldg") and (not tile.has("plant") or not tile.plant.has("name")) and not tile.has("rock") and not tile.has("ship") and not tile.has("wormhole") and not tile.has("lake") and not tile.has("cave") and not tile.has("volcano")

func available_to_build(tile):
	if bldg_to_construct == "MM":
		return available_for_mining(tile)
	if not tile:
		return true
	if bldg_to_construct == "GH":
		return not is_obstacle(tile)
	if bldg_to_construct == "ME":
		if tile.has("plant") and tile.plant.has("ash"):
			return not is_obstacle(tile)
	return not is_obstacle(tile) and not tile.has("plant")

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
		"plant":
			time_bar.modulate = Color(105/255.0, 65/255.0, 40/255.0, 1)
		"overclock":
			time_bar.modulate = Color(0, 0, 1, 1)
		"wormhole":
			time_bar.modulate = Color(105/255.0, 0, 1, 1)
	time_bars.append({"node":time_bar, "id":id2, "type":type})

func add_plant(id2:int, st:String):
	var plant:AnimatedSprite = AnimatedSprite.new()
	plant.frames = SpriteFrames.new()
	for i in 3:
		plant.frames.add_frame("default", load("res://Graphics/Plants/%s/%s.png" % [st, i]))
	var local_id = id2
	var v = Vector2.ZERO
	v.x = (local_id % wid) * 200
	v.y = floor(local_id / wid) * 200
	v += Vector2(100, 100)
	plant.position = v
	add_child(plant)
	plant_sprites[String(id2)] = plant
	var tile = game.tile_data[id2]
	if tile.has("bldg"):
		move_child(plant, bldgs[id2].get_index() - 1)
	if tile.plant.is_growing:
		add_time_bar(id2, "plant")
	else:
		plant.frame = 2

func add_bldg(id2:int, st:String):
	var bldg = Sprite.new()
	bldg.texture = game.bldg_textures[st]
	bldg.scale *= 0.4
	var local_id = id2
	var v = Vector2.ZERO
	v.x = (local_id % wid) * 200
	v.y = floor(local_id / wid) * 200
	v += Vector2(100, 100)
	bldg.position = v
	add_child(bldg)
	bldgs[id2] = bldg
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
			add_rsrc(v, Color(0.6, 0.6, 0.6, 1), Data.rsrc_icons.MM, id2)
		"SC":
			add_rsrc(v, Color(0.6, 0.6, 0.6, 1), Data.rsrc_icons.SC, id2)
		"GF":
			add_rsrc(v, Color(0.8, 0.9, 0.85, 1), Data.rsrc_icons.GF, id2)
		"SE":
			add_rsrc(v, Color(0, 0.8, 0, 1), Data.rsrc_icons.SE, id2)
		"AMN":
			add_rsrc(v, Color(0.89, 0.55, 1.0, 1), Data.rsrc_icons.AMN, id2)
		"SPR":
			if tile.bldg.has("reaction"):
				add_rsrc(v, Color.white, load("res://Graphics/Atoms/%s.png" % tile.bldg.reaction), id2)
			else:
				add_rsrc(v, Color.white, Data.rsrc_icons.SPR, id2)
	var curr_time = OS.get_system_time_msecs()
	var IR_mult = Helper.get_IR_mult(tile.bldg.name)
	if tile.bldg.IR_mult != IR_mult:
		var diff:float = IR_mult / tile.bldg.IR_mult
		tile.bldg.IR_mult = IR_mult
		if not tile.bldg.is_constructing and tile.bldg.has("collect_date"):
			tile.bldg.collect_date = curr_time - (curr_time - tile.bldg.collect_date) / diff
	var hbox = Helper.add_lv_boxes(tile, v)
	add_child(hbox)
	hboxes[id2] = hbox
	if tile.bldg.has("overclock_mult"):
		add_time_bar(id2, "overclock")
	if tile.bldg.is_constructing:
		add_time_bar(id2, "bldg")
	else:
		Helper.update_rsrc(p_i, tile)

func overclockable(bldg:String):
	return bldg in ["ME", "PP", "RL", "PC", "NC", "EC", "MM", "SP", "AE"]

func add_rsrc(v:Vector2, mod:Color, icon, id2:int):
	var rsrc = game.rsrc_stocked_scene.instance()
	rsrc.visible = get_parent().scale.x >= 0.25
	add_child(rsrc)
	rsrc.get_node("TextureRect").texture = icon
	rsrc.rect_position = v + Vector2(0, 70)
	rsrc.get_node("Control").modulate = mod
	rsrcs[id2] = rsrc

func on_timeout():
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
			if not tile or not tile.has("bldg") or not tile.bldg.is_constructing:
				remove_child(time_bar)
				time_bar.queue_free()
				time_bars.erase(time_bar_obj)
				continue
			start_date = tile.bldg.construction_date
			length = tile.bldg.construction_length
			progress = (curr_time - start_date) / float(length)
			if Helper.update_bldg_constr(tile, p_i):
				if tile.bldg.has("path_1"):
					hboxes[id2].get_node("Path1").text = String(tile.bldg.path_1)
				if tile.bldg.has("path_2"):
					hboxes[id2].get_node("Path2").text = String(tile.bldg.path_2)
				if tile.bldg.has("path_3"):
					hboxes[id2].get_node("Path3").text = String(tile.bldg.path_3)
				update_XP = true
		elif type == "plant":
			if not tile or not tile.has("plant") or not tile.plant.has("name") or not tile.plant.is_growing:
				remove_child(time_bar)
				time_bar.queue_free()
				time_bars.erase(time_bar_obj)
				continue
			start_date = tile.plant.plant_date
			length = tile.plant.grow_time
			progress = (curr_time - start_date) / float(length)
			var plant:AnimatedSprite = plant_sprites[String(id2)]
			plant.frame = min(2, int(progress * 2))
			if progress > 1:
				tile.plant.is_growing = false
		elif type == "overclock":
			if not tile or not tile.has("bldg") or not tile.bldg.has("overclock_date"):
				remove_child(time_bar)
				time_bar.queue_free()
				time_bars.erase(time_bar_obj)
				continue
			start_date = tile.bldg.overclock_date
			length = tile.bldg.overclock_length
			progress = 1 - (curr_time - start_date) / float(length)
			if progress < 0:
				var coll_date = tile.bldg.collect_date
				var mult:float = tile.bldg.overclock_mult
				tile.bldg.collect_date = curr_time - (curr_time - coll_date) * mult
				if tile.bldg.name == "RL":
					game.autocollect.rsrc.SP -= tile.bldg.path_1_value * (mult - 1)
					game.autocollect.rsrc_list[String(tile.bldg.c_p_g)].SP -= tile.bldg.path_1_value * (mult - 1)
				elif tile.bldg.name == "PC":
					game.autocollect.particles.proton -= tile.bldg.path_1_value / tile.bldg.planet_pressure * (mult - 1)
				elif tile.bldg.name == "NC":
					game.autocollect.particles.neutron -= tile.bldg.path_1_value / tile.bldg.planet_pressure * (mult - 1)
				elif tile.bldg.name == "EC":
					game.autocollect.particles.electron -= tile.bldg.path_1_value * tile.aurora.au_int * (mult - 1)
				if tile.has("auto_collect"):
					if tile.bldg.name == "PP":
						game.autocollect.rsrc.energy -= tile.bldg.path_1_value * (mult - 1) * tile.auto_collect / 100.0
						game.autocollect.rsrc_list[String(tile.bldg.c_p_g)].energy -= tile.bldg.path_1_value * (mult - 1) * tile.auto_collect / 100.0
					if tile.bldg.name == "SP":
						var prod:float = Helper.get_SP_production(p_i.temperature, tile.bldg.path_1_value, 1.0 + (tile.aurora.au_int if tile.has("aurora") else 0.0))
						game.autocollect.rsrc.energy -= prod * (mult - 1) * tile.auto_collect / 100.0
						game.autocollect.rsrc_list[String(tile.bldg.c_p_g)].energy -= prod * (mult - 1) * tile.auto_collect / 100.0
					elif tile.bldg.name == "ME":
						var prod:float = tile.bldg.path_1_value * (tile.plant.ash if tile.has("plant") and tile.plant.has("ash") else 1.0)
						game.autocollect.rsrc.minerals -= prod * (mult - 1) * tile.auto_collect / 100.0
						game.autocollect.rsrc_list[String(tile.bldg.c_p_g)].minerals -= prod * (mult - 1) * tile.auto_collect / 100.0
				tile.bldg.erase("overclock_date")
				tile.bldg.erase("overclock_length")
				tile.bldg.erase("overclock_mult")
		elif type == "wormhole":
			if tile.wormhole.active:
				$Obstacles.set_cell(id2 % wid, int(id2 / wid), 8)
				remove_child(time_bar)
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
		if not tile or not tile.has("bldg"):
			continue
		if tile.bldg.is_constructing:
			continue
		Helper.update_rsrc(p_i, tile, rsrcs[i])
	if game.auto_c_p_g == -1:
		game.auto_c_p_g = game.c_p_g
	game.HUD.update_money_energy_SP()
	game.HUD.update_minerals()
	if update_XP:
		game.HUD.update_XP()

func construct(st:String, costs:Dictionary):
	finish_construct()
	game.help_str = "mass_build"
	if game.help.has("mass_build") and game.stats_univ.bldgs_built >= 30 and (not game.tutorial or game.tutorial.tut_num >= 26):
		Helper.put_rsrc(game.get_node("UI/Panel/VBox"), 32, {})
		Helper.add_label(tr("HOLD_SHIFT_TO_MASS_BUILD"), -1, true, true)
		Helper.add_label(tr("HIDE_HELP"), -1, true, true)
		game.get_node("UI/Panel").visible = true
	bldg_to_construct = st
	constr_costs = costs
	shadow = Sprite.new()
	put_shadow(shadow)
	if st == "GH":
		game.HUD.get_node("Top/Resources/Glass").visible = true
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
		remove_child(shadow)
		shadow.free()
	if mass_build_rect.visible:
		mass_build_rect.visible = false
		for i in len(shadows):
			if is_instance_valid(shadows[i]):
				remove_child(shadows[i])
				shadows[i].queue_free()
		shadow_num = 0
	game.get_node("UI/Panel").visible = false

func _on_Planet_tree_exited():
	queue_free()

func add_anim_icon(tile:Dictionary, tile_id:int):
	if not tile.bldg.has("stored") or tile.bldg.stored <= 0:
		return
	var rsrc_icon = preload("res://Scenes/FloatingIcon.tscn").instance()
	var node
	var node2
	if tile.bldg.name == "ME":
		node = game.HUD.get_node("Top/Resources/Minerals")
		node2 = game.HUD.get_node("Top/Resources/Minerals/Texture")
		rsrc_icon.texture = preload("res://Graphics/Icons/minerals.png")
	elif tile.bldg.name in ["PP", "SP"]:
		node = game.HUD.get_node("Top/Resources/Energy")
		node2 = game.HUD.get_node("Top/Resources/Energy/Texture")
		rsrc_icon.texture = preload("res://Graphics/Icons/energy.png")
	if not node:
		return
	var start_pos:Vector2 = to_global(bldgs[tile_id].position)
	var end_pos:Vector2 = node.rect_position + node2.rect_size / 2.0
	rsrc_icon.scale *= 0.15
	rsrc_icon.position = start_pos
	rsrc_icon.end_pos = end_pos
	game.get_node("UI").add_child(rsrc_icon)
		
func collect_all():
	var i:int
	items_collected.clear()
	for tile in game.tile_data:
		if tile and tile.has("bldg"):
			Helper.update_rsrc(p_i, tile)
			if game.icon_animations:
				add_anim_icon(tile, i)
			Helper.collect_rsrc(items_collected, p_i, tile, i, false)
		i += 1
	game.show_collect_info(items_collected)
	game.HUD.refresh()
	if game.tutorial and game.tutorial.tut_num == 7 and not game.tutorial.tween.is_active():
		game.tutorial.fade(0.4, game.minerals > 0)

func get_tile_id_from_pos(pos:Vector2):
	var x_pos = int(pos.x / 200)
	var y_pos = int(pos.y / 200)
	return x_pos % wid + y_pos * wid
