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
var hboxes
var time_bars = []
var rsrcs = []
var bldgs#Tiles with a bldg
var plant_sprites = {}
var tiles_selected = []
var items_collected = {}

var icons_hidden:bool = false#To save performance

onready var wid:int = round(Helper.get_wid(p_i.size))
#A rectangle enclosing all tiles
onready var planet_bounds:PoolVector2Array = [Vector2.ONE, Vector2(1, wid * 200), Vector2(wid * 200, wid * 200), Vector2(wid * 200, 1)]

var mass_build_rect:NinePatchRect
var mass_build_rect_size:Vector2
var wormhole

func _ready():
	mass_build_rect = game.mass_build_rect.instance()
	mass_build_rect.visible = false
	add_child(mass_build_rect)
	bldgs = []
	bldgs.resize(wid * wid)
	hboxes = []
	hboxes.resize(wid * wid)
	dimensions = wid * 200
	$TileMap.tile_set = game.planet_TS
	$Obstacles.tile_set = game.obstacles_TS
	var lake_1_phase = "G"
	var lake_2_phase = "G"
	if p_i.has("lake_1"):
		$Lakes1.tile_set = game.lake_TS
		var phase_1_scene = load("res://Scenes/PhaseDiagrams/" + p_i.lake_1 + ".tscn")
		var phase_1 = phase_1_scene.instance()
		lake_1_phase = Helper.get_state(p_i.temperature, p_i.pressure, phase_1)
		if lake_1_phase != "G":
			$Lakes1.modulate = phase_1.colors[lake_1_phase]
			#$Lakes1.modulate = Color(0.3, 0.3, 0.3, 1)
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
			if p_i.temperature > 1000:
				$TileMap.set_cell(i, j, 8)
			else:
				$TileMap.set_cell(i, j, p_i.type - 3)
			if not tile:
				continue
			if tile.has("bldg"):
				add_bldg(id2, tile.bldg.name)
			if tile.has("aurora"):
				var aurora = game.aurora_scene.instance()
				aurora.position = Vector2(i, j) * 200 + Vector2(100, 100)
				aurora.get_node("Particles2D").amount = min(5 + int(tile.aurora.au_int * 10), 50)
				var hue:float = 0.4 + max(0, pow(tile.aurora.au_int, 0.35) - pow(4, 0.25)) / 10
				aurora.modulate = Color.from_hsv(fmod(hue, 1.0), 1.0, 1.0)
				aurora.modulate.a = 0.5
				add_child(aurora)
			if tile.has("crater"):
				var metal = Sprite.new()
				metal.texture = game.metal_textures[tile.crater.metal]
				metal.scale *= 0.4
				add_child(metal)
				metal.position = Vector2(i, j) * 200 + Vector2(100, 100)
				$Obstacles.set_cell(i, j, 1 + tile.crater.variant)
			if tile.has("plant"):
				$Soil.set_cell(i, j, 0)
				if not tile.plant.empty():
					add_plant(id2, tile.plant.name)
			if tile.has("depth") and not tile.has("crater"):
				$Obstacles.set_cell(i, j, 6)
			if tile.has("rock"):
				$Obstacles.set_cell(i, j, 0)
			if tile.has("cave"):
				$Obstacles.set_cell(i, j, 1)
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
	if p_i.has("lake_1"):
		$Lakes1.update_bitmask_region()
	if p_i.has("lake_2"):
		$Lakes2.update_bitmask_region()
	$Soil.update_bitmask_region()
	game.HUD.refresh()

func add_particles(pos:Vector2):
	var particle = game.particles_scene.instance()
	particle.position = pos + Vector2(30, 30)
	add_child(particle)

func show_tooltip(tile):
	var tooltip:String = ""
	var icons = []
	var adv = false
	if not tile:
		return
	if tile.has("bldg"):
		tooltip += Helper.get_bldg_tooltip(p_i, tile, icons)
		adv = len(icons) > 0
		if game.help.tile_shortcuts and (not game.tutorial or game.tutorial.tut_num >= 26):
			game.help_str = "tile_shortcuts"
			tooltip += "\n%s\n%s\n%s\n%s\n%s" % [tr("PRESS_F_TO_UPGRADE"), tr("PRESS_Q_TO_DUPLICATE"), tr("PRESS_X_TO_DESTROY"), tr("HOLD_SHIFT_TO_SELECT_SIMILAR"), tr("HIDE_SHORTCUTS")]
	elif tile.has("plant"):
		if tile.plant.empty():
			if game.help.plant_something_here:
				tooltip = tr("PLANT_STH") + "\n" + tr("HIDE_HELP")
				game.help_str = "plant_something_here"
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
	elif tile.has("crater") and tile.crater.has("init_depth"):
		if game.help.crater_desc:
			tooltip = tr("METAL_CRATER").format({"metal":tr(tile.crater.metal.to_upper()), "crater":tr("CRATER")}) + "\n%s\n%s\n%s" % [tr("CRATER_DESC"), tr("HIDE_HELP"), tr("HOLE_DEPTH") + ": %s m"  % [tile.depth]]
			game.help_str = "crater_desc"
		else:
			tooltip = tr("METAL_CRATER").format({"metal":tr(tile.crater.metal.to_upper()), "crater":tr("CRATER")}) + "\n%s" % [tr("HOLE_DEPTH") + ": %s m"  % [tile.depth]]
	elif tile.has("rock"):
		if game.help.boulder_desc:
			tooltip = tr("BOULDER_DESC") + "\n" + tr("HIDE_HELP")
			game.help_str = "boulder_desc"
	elif tile.has("ship"):
		if game.science_unlocked.SCT:
			tooltip = tr("CLICK_TO_CONTROL_SHIP")
		else:
			if game.help.abandoned_ship:
				tooltip = tr("ABANDONED_SHIP") + "\n" + tr("HIDE_HELP")
				game.help_str = "abandoned_ship"
	elif tile.has("wormhole"):
		if tile.wormhole.active:
			if game.help.active_wormhole:
				tooltip = "%s\n%s\n%s" % [tr("ACTIVE_WORMHOLE"), tr("ACTIVE_WORMHOLE_DESC"), tr("HIDE_HELP")]
				game.help_str = "active_wormhole"
			else:
				tooltip = tr("ACTIVE_WORMHOLE")
		else:
			if game.help.inactive_wormhole:
				tooltip = "%s\n%s\n%s" % [tr("INACTIVE_WORMHOLE"), tr("INACTIVE_WORMHOLE_DESC"), tr("HIDE_HELP")]
				game.help_str = "inactive_wormhole"
			else:
				tooltip = tr("INACTIVE_WORMHOLE")
			var wh_costs:Dictionary = get_wh_costs()
			if not tile.wormhole.has("investigation_length"):
				tooltip += "\n%s: @i %s  @i %s" % [tr("INVESTIGATION_COSTS"), Helper.format_num(wh_costs.SP, 6), Helper.time_to_str(wh_costs.time * 1000)]
				icons = [Data.SP_icon, Data.time_icon]
				adv = true
	elif tile.has("cave"):
		var cave = game.cave_data[tile.cave.id]
		tooltip = tr("CAVE")
		var floor_size:String = tr("FLOOR_SIZE").format({"size":cave.floor_size})
		if cave.has("special_cave") and cave.special_cave == 1:
			floor_size = tr("FLOOR_SIZE").format({"size":"?"})
		if not game.science_unlocked.RC:
			tooltip += "\n%s\n%s\n%s" % [tr("CAVE_DESC"), tr("NUM_FLOORS") % cave.num_floors, floor_size]
		else:
			tooltip += "\n%s\n%s\n%s" % [tr("CLICK_CAVE_TO_EXPLORE"), tr("NUM_FLOORS") % cave.num_floors, floor_size]
	elif tile.has("diamond_tower"):
		var floor_size:String = tr("FLOOR_SIZE").format({"size":"?"})
		tooltip = "%s\n%s\n%s\n%s" % [tr("DIAMOND_TOWER"), tr("DIAMOND_TOWER_DESC"), tr("NUM_FLOORS") % 25, floor_size]
	if tile.has("depth") and not tile.has("bldg") and not tile.has("crater"):
		tooltip += tr("HOLE_DEPTH") + ": %s m" % [tile.depth]
	elif tile.has("aurora") and tooltip == "":
		if game.help.aurora_desc:
			tooltip = "%s\n%s\n%s\n%s" % [tr("AURORA"), tr("AURORA_DESC"), tr("HIDE_HELP"), tr("AURORA_INTENSITY") + ": %s" % [tile.aurora.au_int]]
			game.help_str = "aurora_desc"
		else:
			tooltip = tr("AURORA_INTENSITY") + ": %s" % [tile.aurora.au_int]
	if tile.has("ruins"):
		tooltip = "%s\n%s" % [tr("ABANDONED_RUINS"), tr("AR_DESC")]
	if adv:
		if not game.get_node("Tooltips/Tooltip").visible:
			game.show_adv_tooltip(tooltip, icons)
	else:
		game.hide_adv_tooltip()
		if tooltip == "":
			game.hide_tooltip()
		else:
			game.show_tooltip(tooltip)

func get_wh_costs():
	return {"SP":round(10000 * pow(game.stats.wormholes_activated + 1, 0.8)), "time":1200 * pow(game.stats.wormholes_activated + 1, 0.2)}

func constr_bldg(tile_id:int, curr_time:int, _bldg_to_construct:String, mass_build:bool = false):
	if _bldg_to_construct == "":
		return
	var tile = game.tile_data[tile_id]
	if game.check_enough(constr_costs):
		game.deduct_resources(constr_costs)
		game.stats.bldgs_built += 1
		if not tile:
			tile = {}
		if game.tutorial:
			if game.tutorial.tut_num in [9, 10, 11] and game.tutorial.visible:
				game.tutorial.fade(0.4, false)
			elif game.tutorial.tut_num == 18 and _bldg_to_construct == "RL":
				game.tutorial.begin()
		tile.bldg = {}
		tile.bldg.name = _bldg_to_construct
		if not game.show.minerals and _bldg_to_construct == "ME":
			game.show.minerals = true
		tile.bldg.is_constructing = true
		tile.bldg.construction_date = curr_time
		tile.bldg.construction_length = constr_costs.time * 1000
		tile.bldg.XP = round(constr_costs.money / 100.0)
		if _bldg_to_construct != "PCC":
			tile.bldg.path_1 = 1
			tile.bldg.path_1_value = Data.path_1[_bldg_to_construct].value
		if _bldg_to_construct in ["ME", "PP", "MM", "SC", "GF", "SE", "GH", "SP", "AE"]:
			tile.bldg.path_2 = 1
			tile.bldg.path_2_value = Data.path_2[_bldg_to_construct].value
		if _bldg_to_construct in ["ME", "PP", "MM", "SC", "GF", "SE", "SP", "AE"]:
			tile.bldg.collect_date = tile.bldg.construction_date + tile.bldg.construction_length
			tile.bldg.stored = 0
		if _bldg_to_construct in ["SC", "GF", "SE"]:
			tile.bldg.path_3 = 1
			tile.bldg.path_3_value = Data.path_3[_bldg_to_construct].value
		if _bldg_to_construct == "RL":
			game.show.SP = true
			tile.bldg.collect_date = tile.bldg.construction_date + tile.bldg.construction_length
			tile.bldg.stored = 0
		if _bldg_to_construct == "MS":
			tile.bldg.mineral_cap_upgrade = Data.path_1.MS.value#The amount of cap to add once construction is done
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
	var check_lake = check_lake(tile_id)
	if check_lake[0]:
		tile.plant.name = game.item_to_use.name
		game.item_to_use.num -= 1
		tile.plant.plant_date = curr_time
		tile.plant.grow_time = game.craft_agriculture_info[game.item_to_use.name].grow_time
		tile.plant.grow_time /= Helper.get_au_mult(tile)
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
		game.popup(tr("NOT_ADJACENT_TO_LAKE") % [tr("%s_NAME" % game.craft_agriculture_info[game.item_to_use.name].lake)], 2)

func fertilizer_plant(tile, tile_id:int):
	var curr_time = OS.get_system_time_msecs()
	tile.plant.plant_date -= game.craft_agriculture_info.fertilizer.speed_up_time
	game.item_to_use.num -= 1

func harvest_plant(tile, tile_id:int):
	if tile.plant.empty():
		return
	var curr_time = OS.get_system_time_msecs()
	if curr_time >= tile.plant.grow_time + tile.plant.plant_date:
		var plant:String = Helper.get_plant_produce(tile.plant.name)
		var produce:float = game.craft_agriculture_info[tile.plant.name].produce
		produce *= Helper.get_au_mult(tile)
		if tile.has("bldg") and tile.bldg.name == "GH":
			produce *= tile.bldg.path_2_value
		game.show[plant] = true
		game.show.metals = true
		Helper.add_item_to_coll(items_collected, plant, produce)
		tile.plant.clear()
		remove_child(plant_sprites[String(tile_id)])
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
	if overclockable(tile.bldg.name) and not tile.bldg.is_constructing and (not tile.bldg.has("overclock_mult") or tile.bldg.overclock_mult <= mult):
		if not tile.bldg.has("overclock_mult"):
			add_time_bar(tile_id, "overclock")
		tile.bldg.overclock_date = curr_time
		tile.bldg.overclock_length = game.overclocks_info[game.item_to_use.name].duration
		tile.bldg.overclock_mult = mult
		var coll_date = tile.bldg.collect_date
		tile.bldg.collect_date = curr_time - (curr_time - coll_date) / tile.bldg.overclock_mult
		game.item_to_use.num -= 1

func click_tile(tile, tile_id:int):
	if not tile.has("bldg"):
		return
	var bldg:String = tile.bldg.name
	if bldg in ["ME", "PP", "RL", "MM", "SP", "AE"]:
		Helper.collect_rsrc(items_collected, p_i, tile, tile_id)
	else:
		if not tile.bldg.is_constructing:
			game.c_t = tile_id
			match bldg:
				"RCC":
					game.toggle_panel(game.RC_panel)
				"SY":
					game.toggle_panel(game.shipyard_panel)
				"PCC":
					game.toggle_panel(game.PC_panel)
				"SC":
					game.toggle_panel(game.SC_panel)
					game.SC_panel.hslider.value = game.SC_panel.hslider.max_value
				"GF":
					game.toggle_panel(game.production_panel)
					game.production_panel.refresh2(bldg, "sand", "glass", "mats", "mats")
				"SE":
					game.toggle_panel(game.production_panel)
					game.production_panel.refresh2(bldg, "coal", "energy", "mats", "")
				"AMN":
					game.toggle_panel(game.AMN_panel)
				"SPR":
					game.toggle_panel(game.SPR_panel)
					if tile.bldg.has("reaction"):
						game.SPR_panel._on_Atom_pressed(tile.bldg.reaction)
			game.hide_tooltip()

func destroy_bldg(id2:int):
	var tile = game.tile_data[id2]
	var bldg:String = tile.bldg.name
	items_collected.clear()
	Helper.collect_rsrc(items_collected, p_i, tile, id2)
	remove_child(bldgs[id2])
	bldgs[id2].queue_free()
	remove_child(hboxes[id2])
	hboxes[id2].queue_free()
	if bldg == "MS":
		if tile.bldg.is_constructing:
			game.mineral_capacity -= tile.bldg.path_1_value - tile.bldg.mineral_cap_upgrade
		else:
			game.mineral_capacity -= tile.bldg.path_1_value
	tile.erase("bldg")
	if tile.empty():
		game.tile_data[id2] = null
	game.show_collect_info(items_collected)

func destroy_bldgs(arr:Array):
	items_collected.clear()
	for id2 in arr:
		var tile = game.tile_data[id2]
		var bldg:String = tile.bldg.name
		Helper.collect_rsrc(items_collected, p_i, tile, id2)
		remove_child(bldgs[id2])
		bldgs[id2].queue_free()
		remove_child(hboxes[id2])
		hboxes[id2].queue_free()
		if bldg == "MS":
			if tile.bldg.is_constructing:
				game.mineral_capacity -= tile.bldg.path_1_value - tile.bldg.mineral_cap_upgrade
			else:
				game.mineral_capacity -= tile.bldg.path_1_value
		tile.erase("bldg")
		if tile.empty():
			game.tile_data[id2] = null

func add_shadows():
	for sh in shadows:
		remove_child(sh)
		sh.queue_free()
	shadows.clear()
	var poly:Rect2 = Rect2(mass_build_rect.rect_position, Vector2.ZERO)
	poly.end = mouse_pos
	poly = poly.abs()
	for i in wid:
		for j in wid:
			var shadow_pos:Vector2 = Vector2(i * 200, j * 200) + Vector2(100, 100)
			var tile_rekt:Rect2 = Rect2(Vector2(i * 200, j * 200), Vector2.ONE * 200)
			if poly.intersects(tile_rekt) and available_to_build(game.tile_data[get_tile_id_from_pos(shadow_pos)]):
				shadows.append(put_shadow(Sprite.new(), shadow_pos))
	game.HUD.refresh()

func remove_selected_tiles():
	tiles_selected.clear()
	for white_rect in get_tree().get_nodes_in_group("white_rects"):
		remove_child(white_rect)
		white_rect.queue_free()
		white_rect.remove_from_group("white_rects")

var prev_tile_over = -1
var mouse_pos = Vector2.ZERO
var thread:Thread
var mutex:Mutex

func _input(event):
	if game.tutorial and game.tutorial.BG_blocked:
		return
	var mass_build:bool = Input.is_action_pressed("left_click") and Input.is_action_pressed("shift") and game.bottom_info_action == "building"
	if tile_over != -1 and game.bottom_info_action != "building":
		var tile = game.tile_data[tile_over]
		if tile and tile.has("bldg"):
			if Input.is_action_just_released("Q"):
				game.put_bottom_info(tr("CLICK_TILE_TO_CONSTRUCT"), "building", "cancel_building")
				construct(tile.bldg.name, Data.costs[tile.bldg.name])
			if Input.is_action_just_released("F"):
				if tiles_selected.empty():
					game.add_upgrade_panel([tile_over])
				else:
					game.add_upgrade_panel(tiles_selected)
			if Input.is_action_just_released("X"):
				game.hide_adv_tooltip()
				game.hide_tooltip()
				if tiles_selected.empty():
					destroy_bldg(tile_over)
					game.HUD.refresh()
				else:
					game.show_YN_panel("destroy_buildings", tr("DESTROY_X_BUILDINGS") % [len(tiles_selected)], [tiles_selected.duplicate(true)])
		if Input.is_action_just_pressed("shift") and tile:
			tiles_selected.clear()
			for i in len(game.tile_data):
				var select:bool = false
				var tile2 = game.tile_data[i]
				if not tile2 or not tile2.has("bldg") and not tile2.has("plant"):
					continue
				if tile.has("bldg"):
					if tile2.has("bldg") and tile2.bldg.name == tile.bldg.name:
						select = true
				elif tile.has("plant") and not tile.plant.empty():
					if tile2.has("plant") and not tile2.plant.empty() and tile2.plant.name == tile.plant.name:
						select = true
				if select:
					tiles_selected.append(i)
					var white_rect = game.white_rect_scene.instance()
					white_rect.position.x = (i % wid) * 200
					white_rect.position.y = (i / wid) * 200
					add_child(white_rect)
					white_rect.add_to_group("white_rects")
	if Input.is_action_just_released("shift"):
		remove_selected_tiles()
				
	var not_on_button:bool = not game.planet_HUD.on_button and not game.HUD.on_button and not game.close_button_over
	if event is InputEventMouseMotion:
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
			var delta:Vector2 = event.relative / view.scale
			var new_x = stepify(round(mouse_pos.x - 100), 200)
			var new_y = stepify(round(mouse_pos.y - 100), 200)
			var old_x = stepify(round(mouse_pos.x - delta.x - 100), 200)
			var old_y = stepify(round(mouse_pos.y - delta.y - 100), 200)
			if new_x > old_x:
				add_shadows()
			elif new_x < old_x:
				add_shadows()
			if new_y > old_y:
				add_shadows()
			elif new_y < old_y:
				add_shadows()
		if game.active_panel:
			if game.active_panel.polygon and Geometry.is_point_in_polygon(event.position, game.active_panel.polygon):
				if tile_over != -1:
					tile_over = -1
					game.hide_tooltip()
					game.hide_adv_tooltip()
				return
		var black_bg = game.get_node("UI/PopupBackground").visible
		$WhiteRect.visible = mouse_on_tiles and not black_bg
		$WhiteRect.position.x = floor(mouse_pos.x / 200) * 200
		$WhiteRect.position.y = floor(mouse_pos.y / 200) * 200
		if mouse_on_tiles:
			tile_over = int(mouse_pos.x / 200) % wid + floor(mouse_pos.y / 200) * wid
			if tile_over != prev_tile_over and not_on_button and not game.item_cursor.visible and not black_bg:
				game.hide_tooltip()
				game.hide_adv_tooltip()
				if not tiles_selected.empty() and not tile_over in tiles_selected:
					remove_selected_tiles()
				show_tooltip(game.tile_data[tile_over])
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
		if OS.get_name() == "HTML5":
			for i in len(shadows):
				constr_bldg(get_tile_id_from_pos(shadows[i].position), curr_time, bldg_to_construct, true)
				remove_child(shadows[i])
				shadows[i].queue_free()
			shadows.clear()
			game.HUD.refresh()
		else:
			mutex = Mutex.new()
			if thread:
				thread.wait_to_finish()
			thread = Thread.new()
			thread.start(self, "test", bldg_to_construct)
		view.move_view = true
		view.scroll_view = true
		return
	#initiate mass build
	if Input.is_action_just_pressed("left_click") and len(shadows) == 0 and Input.is_action_pressed("shift") and game.bottom_info_action == "building":
		view.move_view = false
		view.scroll_view = false
		mass_build_rect.rect_position = mouse_pos
		mass_build_rect.rect_size = Vector2.ZERO
		mass_build_rect.visible = true
		mass_build_rect_size = Vector2.ONE
		shadows = [put_shadow(Sprite.new(), mouse_pos)]
		shadow.visible = false
	if mass_build:
		return
	var placing_soil = game.bottom_info_action == "place_soil"
	var about_to_mine = game.bottom_info_action == "about_to_mine"
	if Input.is_action_just_released("left_click") and not view.dragged and not_on_button and Geometry.is_point_in_polygon(mouse_pos, planet_bounds):
		var curr_time = OS.get_system_time_msecs()
		if game.block_scroll:
			return
		var x_pos = int(mouse_pos.x / 200)
		var y_pos = int(mouse_pos.y / 200)
		var tile_id = get_tile_id_from_pos(mouse_pos)
		var tile = game.tile_data[tile_id]
		if bldg_to_construct != "":
			if available_to_build(tile):
				constr_bldg(tile_id, curr_time, bldg_to_construct)
		if about_to_mine and available_for_mining(tile) or tile and tile.has("depth") and not tile.has("bldg") and bldg_to_construct == "":
			game.mine_tile(tile_id)
		if placing_soil and available_for_plant(tile):
			if game.check_enough({"soil":10}):
				game.deduct_resources({"soil":10})
				if not tile:
					game.tile_data[tile_id] = {}
				game.tile_data[tile_id].plant = {}
				$Soil.set_cell(x_pos, y_pos, 0)
				$Soil.update_bitmask_region()
				game.HUD.refresh()
			else:
				game.popup(tr("NOT_ENOUGH_SOIL"), 1.2)
			return
		if tile and bldg_to_construct == "":
			items_collected.clear()
			var t:String = game.item_to_use.type
			if tile.has("plant"):#if clicked tile has soil on it
				if placing_soil and tile.plant.empty():
					game.add_resources({"soil":10})
					tile.erase("plant")
					$Soil.set_cell(x_pos, y_pos, -1)
					$Soil.update_bitmask_region()
				else:
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
							if tile.plant.empty():
								seeds_plant(tile, tile_id, curr_time)
						else:
							for _tile_id in tiles_selected:
								var _tile = game.tile_data[_tile_id]
								if _tile.has("plant") and _tile.plant.empty():
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
				if tile.has("cave") and game.cave_data[tile.cave.id].has("special_cave") and game.cave_data[tile.cave.id].special_cave == 4:
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
					if (game.show.vehicles_button or len(game.rover_data) > 0) and not game.vehicle_panel.visible:
						game.toggle_panel(game.vehicle_panel)
						game.vehicle_panel.tile_id = tile_id
			elif tile.has("ship"):
				if game.science_unlocked.SCT:
					if len(game.ship_data) == 0:
						game.tile_data[tile_id].erase("ship")
						$Obstacles.set_cell(x_pos, y_pos, -1)
						game.popup(tr("SHIP_CONTROL_SUCCESS"), 1.5)
						game.ship_data.append({"lv":1, "HP":25, "total_HP":25, "atk":10, "def":5, "acc":10, "eva":10, "XP":0, "XP_to_lv":20, "bullet":{"lv":1, "XP":0, "XP_to_lv":10}, "laser":{"lv":1, "XP":0, "XP_to_lv":10}, "bomb":{"lv":1, "XP":0, "XP_to_lv":10}, "light":{"lv":1, "XP":0, "XP_to_lv":20}})
					elif len(game.ship_data) == 1:
						game.tile_data[tile_id].erase("ship")
						$Obstacles.set_cell(x_pos, y_pos, -1)
						game.popup(tr("SHIP_CONTROL_SUCCESS"), 1.5)
						if not game.objective.empty() and game.objective.type == game.ObjectiveType.DAVID:
							game.objective = {"type":game.ObjectiveType.LEVEL, "id":-1, "current":game.lv, "goal":35}
						game.ship_data.append({"lv":1, "HP":18, "total_HP":18, "atk":15, "def":3, "acc":13, "eva":8, "XP":0, "XP_to_lv":20, "bullet":{"lv":1, "XP":0, "XP_to_lv":10}, "laser":{"lv":1, "XP":0, "XP_to_lv":10}, "bomb":{"lv":1, "XP":0, "XP_to_lv":10}, "light":{"lv":1, "XP":0, "XP_to_lv":20}})
						Helper.add_ship_XP(1, 2000)
						Helper.add_weapon_XP(1, "bullet", 50)
						Helper.add_weapon_XP(1, "laser", 50)
						Helper.add_weapon_XP(1, "bomb", 50)
						Helper.add_weapon_XP(1, "light", 60)
					elif len(game.ship_data) == 2:
						if game.third_ship_hints.parts[0] and game.third_ship_hints.parts[1] and game.third_ship_hints.parts[2] and game.third_ship_hints.parts[3] and game.third_ship_hints.parts[4]:
							game.tile_data[tile_id].erase("ship")
							$Obstacles.set_cell(x_pos, y_pos, -1)
							game.popup(tr("SHIP_CONTROL_SUCCESS"), 1.5)
							game.objective = {"type":game.ObjectiveType.LEVEL, "id":-1, "current":game.lv, "goal":50}
							game.ship_data.append({"lv":1, "HP":22, "total_HP":22, "atk":12, "def":4, "acc":12, "eva":15, "XP":0, "XP_to_lv":20, "bullet":{"lv":1, "XP":0, "XP_to_lv":10}, "laser":{"lv":1, "XP":0, "XP_to_lv":10}, "bomb":{"lv":1, "XP":0, "XP_to_lv":10}, "light":{"lv":1, "XP":0, "XP_to_lv":20}})
							Helper.add_ship_XP(2, 40000)
							Helper.add_weapon_XP(2, "bullet", 140)
							Helper.add_weapon_XP(2, "laser", 140)
							Helper.add_weapon_XP(2, "bomb", 140)
							Helper.add_weapon_XP(2, "light", 180)
						else:
							game.popup(tr("MISSING_PARTS"), 2.5)
				else:
					if game.show.SP:
						game.popup(tr("SHIP_CONTROL_FAIL"), 1.5)
					elif not game.get_node("UI/PopupBackground").visible:
						game.long_popup("%s %s" % [tr("SHIP_CONTROL_FAIL"), tr("SHIP_CONTROL_HELP")], tr("RESEARCH_NEEDED"))
			elif tile.has("wormhole"):
				if tile.wormhole.active:
					if game.lv < 18:
						game.long_popup(tr("LV_18_NEEDED_DESC"), tr("LV_18_NEEDED"))
						return
					Helper.update_ship_travel()
					if game.ships_travel_view != "-":
						game.popup(tr("SHIPS_ALREADY_TRAVELLING"), 1.5)
						return
					if Helper.ships_on_planet(id):
						if tile.wormhole.new:#generate galaxy -> remove tiles -> generate system -> open/close tile_data to update wormhole info -> open destination tile_data to place destination wormhole
							visible = false
							if game.galaxy_data[game.c_g].has("wormholes"):
								game.galaxy_data[game.c_g].wormholes.append({"from":game.c_s, "to":tile.wormhole.l_dest_s_id})
							else:
								game.galaxy_data[game.c_g].wormholes = [{"from":game.c_s, "to":tile.wormhole.l_dest_s_id}]
							if not game.galaxy_data[game.c_g].discovered:#if galaxy generated systems
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
							if wh_system.discovered:#if system generated planets
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
							if not wh_planet.discovered:
								game.generate_tiles(wh_planet.l_id)
							game.tile_data = game.open_obj("Planets", wh_planet.id)
							var wh_tile:int = Helper.rand_int(0, len(game.tile_data) - 1)
							game.erase_tile(wh_tile)
							game.tile_data[wh_tile].wormhole = {"active":true, "new":false, "l_dest_s_id":orig_s_l, "g_dest_s_id":orig_s_g, "l_dest_p_id":orig_p_l, "g_dest_p_id":orig_p_g}
							Helper.save_obj("Planets", wh_planet.id, game.tile_data)#update new tile info (destination wormhole)
						else:
							game.switch_view("")
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
						game.switch_view("planet", false, "", [], false)
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
							game.stats.wormholes_activated += 1
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

func test(_bldg_to_construct:String):
	mutex.lock()
	var curr_time = OS.get_system_time_msecs()
	for i in len(shadows):
		if not is_inside_tree():
			mutex.unlock()
			return
		constr_bldg(get_tile_id_from_pos(shadows[i].position), curr_time, _bldg_to_construct, true)
		#call_deferred("constr_bldg", get_tile_id_from_pos(shadows[i].position), curr_time, _bldg_to_construct, true)
		call_deferred("remove_child", shadows[i])
		shadows[i].queue_free()
	shadows.clear()
	game.HUD.call_deferred("refresh")
	mutex.unlock()

func _exit_tree():
	if thread and thread.is_active():
		thread.wait_to_finish()

func available_for_plant(tile):
	if not tile:
		return true
	var bool1 = not tile.has("plant") and not tile.has("rock") and not tile.has("ship") and not tile.has("wormhole") and not tile.has("lake") and not tile.has("cave") and not tile.has("crater") and not tile.has("depth")
	if tile.has("bldg") and tile.bldg.name == "GH":
		return bool1
	else:
		return not tile.has("bldg") and bool1

func available_for_mining(tile):
	return not tile or not tile.has("bldg") and not tile.has("plant") and not tile.has("rock") and not tile.has("ship") and not tile.has("wormhole") and not tile.has("lake") and not tile.has("cave")

func available_to_build(tile):
	if bldg_to_construct == "MM":
		return not tile or available_for_mining(tile)
	if bldg_to_construct == "GH":
		return not tile or not tile.has("rock") and not tile.has("ship") and not tile.has("wormhole") and not tile.has("lake") and not tile.has("cave") and not tile.has("crater") and not tile.has("depth") and not tile.has("bldg")
	return not tile or available_for_plant(tile) and not tile.has("plant")

func check_lake(local_id:int):
# warning-ignore:integer_division
	var v = Vector2(local_id % wid, int(local_id / wid))
	var state
	var has_lake = false
	for i in range(v.x - 1, v.x + 2):
		for j in range(v.y - 1, v.y + 2):
			if Vector2(i, j) != v:
				if $Lakes1.get_cell(i, j) != -1 or $Lakes2.get_cell(i, j) != -1:
					var id2 = i % wid + j * wid
					var okay = game.tile_data[id2].lake.element == game.craft_agriculture_info[game.item_to_use.name].lake
					has_lake = has_lake or okay
					if okay:
						state = game.tile_data[id2].lake.state
	return [has_lake, state]

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
	return bldg in ["ME", "PP", "RL", "MM", "SP", "AE"]

func add_rsrc(v:Vector2, mod:Color, icon, id2:int):
	var rsrc = game.rsrc_stocked_scene.instance()
	rsrc.visible = get_parent().scale.x >= 0.25
	add_child(rsrc)
	rsrc.get_node("TextureRect").texture = icon
	rsrc.rect_position = v + Vector2(0, 70)
	rsrc.get_node("Control").modulate = mod
	rsrcs.append({"node":rsrc, "id":id2})

func _process(_delta):
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
			if Helper.update_bldg_constr(tile):
				if tile.bldg.has("path_1"):
					hboxes[id2].get_node("Path1").text = String(tile.bldg.path_1)
				if tile.bldg.has("path_2"):
					hboxes[id2].get_node("Path2").text = String(tile.bldg.path_2)
				if tile.bldg.has("path_3"):
					hboxes[id2].get_node("Path3").text = String(tile.bldg.path_3)
				update_XP = true
		elif type == "plant":
			if not tile or not tile.has("plant") or tile.plant.empty() or not tile.plant.is_growing:
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
			if not tile or not tile.bldg.has("overclock_date"):
				remove_child(time_bar)
				time_bar.queue_free()
				time_bars.erase(time_bar_obj)
				continue
			start_date = tile.bldg.overclock_date
			length = tile.bldg.overclock_length
			progress = 1 - (curr_time - start_date) / float(length)
			if progress < 0:
				var coll_date = tile.bldg.collect_date
				tile.bldg.collect_date = curr_time - (curr_time - coll_date) * tile.bldg.overclock_mult
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
	for rsrc_obj in rsrcs:
		var tile = game.tile_data[rsrc_obj.id]
		var rsrc = rsrc_obj.node
		if not tile or not tile.has("bldg"):
			remove_child(rsrc_obj.node)
			rsrc_obj.node.queue_free()
			rsrcs.erase(rsrc_obj)
			continue
		if tile.bldg.is_constructing:
			continue
		Helper.update_rsrc(p_i, tile, rsrc)
	if update_XP:
		game.HUD.update_XP()
		game.HUD.update_minerals()

func construct(st:String, costs:Dictionary):
	finish_construct()
	if game.help.mass_build and game.stats.bldgs_built >= 30 and (not game.tutorial or game.tutorial.tut_num >= 26):
		Helper.put_rsrc(game.get_node("UI/Panel/VBox"), 32, {})
		Helper.add_label(tr("HOLD_SHIFT_TO_MASS_BUILD"), -1, true, true)
		game.help_str = "mass_build"
		Helper.add_label(tr("HIDE_HELP"), -1, true, true)
		game.get_node("UI/Panel").visible = true
	bldg_to_construct = st
	constr_costs = costs
	shadow = Sprite.new()
	put_shadow(shadow)
	if st == "GH":
		game.HUD.get_node("Resources/Glass").visible = true
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
			remove_child(shadows[i])
			shadows[i].queue_free()
		shadows.clear()
		view.move_view = true
		view.scroll_view = true
	game.get_node("UI/Panel").visible = false

func _on_Planet_tree_exited():
	queue_free()

func collect_all():
	var i:int
	items_collected.clear()
	for tile in game.tile_data:
		if tile:
			Helper.collect_rsrc(items_collected, p_i, tile, i)
		i += 1
	game.show_collect_info(items_collected)
	game.HUD.refresh()
	if game.tutorial and game.tutorial.tut_num == 7 and not game.tutorial.tween.is_active():
		game.tutorial.fade(0.4, game.minerals > 0)

func get_tile_id_from_pos(pos:Vector2):
	var x_pos = int(pos.x / 200)
	var y_pos = int(pos.y / 200)
	return x_pos % wid + y_pos * wid
