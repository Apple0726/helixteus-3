extends Node2D

onready var game = get_node("/root/Game")
onready var view = game.view
onready var id = game.c_p
onready var p_i = game.planet_data[id]

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

var icons_hidden:bool = false#To save performance

onready var wid:int = round(Helper.get_wid(p_i.size))
#A rectangle enclosing all tiles
onready var planet_bounds:PoolVector2Array = [Vector2.ZERO, Vector2(0, wid * 200), Vector2(wid * 200, wid * 200), Vector2(wid * 200, 0)]

var mass_build_rect:NinePatchRect
var mass_build_rect_size:Vector2

func _ready():
	mass_build_rect = game.mass_build_rect.instance()
	mass_build_rect.visible = false
	add_child(mass_build_rect)
	bldgs = []
	bldgs.resize(wid * wid)
	hboxes = []
	hboxes.resize(wid * wid)
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
	if p_i.has("lake_2"):
		$Lakes2.tile_set = game.lake_TS
		var phase_2_scene = load("res://Scenes/PhaseDiagrams/" + p_i.lake_2 + ".tscn")
		var phase_2 = phase_2_scene.instance()
		lake_2_phase = Helper.get_state(p_i.temperature, p_i.pressure, phase_2)
		if lake_2_phase != "G":
			$Lakes2.modulate = phase_2.colors[lake_2_phase]
			#$Lakes2.modulate = Color(0.3, 0.3, 0.3, 1)
	
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
			if tile.has("aurora"):
				var aurora = Sprite.new()
				aurora.position = Vector2(i, j) * 200 + Vector2(100, 100)
				if tile.aurora.type == 1:
					aurora.texture = game.aurora1_texture
					aurora.modulate = Color(rand_range(0.7, 1), 0, rand_range(0.7, 1))
				else:
					aurora.texture = game.aurora2_texture
					aurora.modulate = Color(1, 1, rand_range(0.7, 1))
				add_child(aurora)
			if tile.has("crater"):
				var metal = Sprite.new()
				metal.texture = load("res://Graphics/Metals/%s.png" % [tile.crater.metal])
				metal.scale *= 0.4
				add_child(metal)
				metal.position = Vector2(i, j) * 200 + Vector2(100, 100)
				$Obstacles.set_cell(i, j, 1 + tile.crater.variant)
			if tile.has("soil"):
				$Soil.set_cell(i, j, 0)
			if tile.has("plant"):
				add_plant(id2, tile.plant.name)
			if tile.has("bldg"):
				add_bldg(id2, tile.bldg.name)
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
		var bldg:String = tile.bldg.name
		var mult:float = get_prod_mult(tile)
		var path_1_value = game.clever_round(tile.bldg.path_1_value * mult, 3)
		var path_2_value
		if tile.bldg.has("path_2_value"):
			path_2_value = round(tile.bldg.path_2_value * mult)
		match bldg:
			"ME", "PP":
				tooltip = (Data.path_1[bldg].desc + "\n" + Data.path_2[bldg].desc) % [path_1_value, path_2_value]
				icons = [Data.icons[bldg], Data.icons[bldg]]
				adv = true
			"MM":
				tooltip = (Data.path_1[bldg].desc + "\n" + Data.path_2[bldg].desc) % [path_1_value, path_2_value]
			"SC", "GF", "SE":
				tooltip = (Data.path_1[bldg].desc + "\n" + Data.path_2[bldg].desc) % [path_1_value, path_2_value] + "\n" + tr("CLICK_TO_CONFIGURE")
				icons = [Data.icons[bldg], Data.icons[bldg]]
				adv = true
			"RL":
				tooltip = (Data.path_1[bldg].desc) % [path_1_value]
				icons = [Data.icons.RL]
				adv = true
			"MS":
				tooltip = (Data.path_1[bldg].desc) % [round(path_1_value)]
				icons = [Data.icons.MS]
				adv = true
			"RCC":
				tooltip = (Data.path_1[bldg].desc) % [tile.bldg.path_1_value]
		if game.help.tile_shortcuts:
			game.help_str = "tile_shortcuts"
			tooltip += "\n%s\n%s\n%s\n%s\n%s" % [tr("PRESS_F_TO_UPGRADE"), tr("PRESS_Q_TO_DUPLICATE"), tr("PRESS_X_TO_DESTROY"), tr("HOLD_SHIFT_TO_SELECT_SIMILAR"), tr("HIDE_SHORTCUTS")]
	if tile.has("soil"):
		if not tile.has("plant"):
			if game.help.plant_something_here:
				tooltip = tr("PLANT_STH") + "\n" + tr("HIDE_HELP")
				game.help_str = "plant_something_here"
		else:
			tooltip = Helper.get_plant_name(tile.plant.name)
			if OS.get_system_time_msecs() >= tile.plant.plant_date + tile.grow_time:
				tooltip += "\n" + tr("CLICK_TO_HARVEST")
	if tile.has("lake"):
		if tile.lake.state == "s" and tile.lake.element == "water":
			tooltip = tr("ICE")
		elif tile.lake.state == "l" and tile.lake.element == "water":
			tooltip = tr("WATER")
		else:
			match tile.lake.state:
				"l":
					tooltip = tr("LAKE_CONTENTS").format({"state":tr("LIQUID"), "contents":tr(tile.lake.element.to_upper())})
				"s":
					tooltip = tr("LAKE_CONTENTS").format({"state":tr("SOLID"), "contents":tr(tile.lake.element.to_upper())})
				"sc":
					tooltip = tr("LAKE_CONTENTS").format({"state":tr("SUPERCRITICAL"), "contents":tr(tile.lake.element.to_upper())})
	if tile.has("crater") and tile.has("init_depth"):
		if game.help.crater_desc:
			tooltip = tr("METAL_CRATER").format({"metal":tr(tile.crater.metal.to_upper()), "crater":tr("CRATER")}) + "\n%s\n%s\n%s" % [tr("CRATER_DESC"), tr("HIDE_HELP"), tr("HOLE_DEPTH") + ": %s m"  % [tile.depth]]
			game.help_str = "crater_desc"
		else:
			tooltip = tr("METAL_CRATER").format({"metal":tr(tile.crater.metal.to_upper()), "crater":tr("CRATER")}) + "\n%s" % [tr("HOLE_DEPTH") + ": %s m"  % [tile.depth]]
	if tile.has("rock"):
		if game.help.boulder_desc:
			tooltip = tr("BOULDER_DESC") + "\n" + tr("HIDE_HELP")
			game.help_str = "boulder_desc"
	if tile.has("ship"):
		if game.science_unlocked.SCT:
			tooltip = tr("CLICK_TO_CONTROL_SHIP")
		else:
			if game.help.abandoned_ship:
				tooltip = tr("ABANDONED_SHIP") + "\n" + tr("HIDE_HELP")
				game.help_str = "abandoned_ship"
	if tile.has("cave"):
		tooltip = tr("CAVE")
		if game.help.cave_desc:
			tooltip += "\n%s\n%s\n%s\n%s" % [tr("CAVE_DESC"), tr("HIDE_HELP"), tr("NUM_FLOORS") % game.cave_data[tile.cave.id].num_floors, tr("FLOOR_SIZE").format({"size":game.cave_data[tile.cave.id].floor_size})]
			game.help_str = "cave_desc"
		else:
			tooltip += "\n%s\n%s" % [tr("NUM_FLOORS") % game.cave_data[tile.cave_id].num_floors, tr("FLOOR_SIZE").format({"size":game.cave_data[tile.cave_id].floor_size})]
	if tile.has("depth"):
		tooltip += tr("HOLE_DEPTH") + ": %s m" % [tile.depth]
	elif tile.has("aurora") and tooltip == "":
		if game.help.aurora_desc:
			tooltip = "%s\n%s\n%s\n%s" % [tr("AURORA"), tr("AURORA_DESC"), tr("HIDE_HELP"), tr("AURORA_INTENSITY") + ": %s" % [tile.aurora.au_int]]
			game.help_str = "aurora_desc"
		else:
			tooltip = tr("AURORA_INTENSITY") + ": %s" % [tile.aurora.au_int]
	if adv:
		if not tile.has("bldg"):
			game.hide_adv_tooltip()
		else:
			if not game.get_node("Tooltips/Tooltip").visible:
				game.show_adv_tooltip(tooltip, icons)
	else:
		game.hide_adv_tooltip()
		if tooltip == "":
			game.hide_tooltip()
		else:
			game.show_tooltip(tooltip)

func constr_bldg(tile_id:int, mass_build:bool = false):
	if bldg_to_construct == "":
		return
	var tile = game.tile_data[tile_id]
	if game.check_enough(constr_costs):
		game.deduct_resources(constr_costs)
		var curr_time = OS.get_system_time_msecs()
		if not tile:
			tile = {}
		tile.bldg = {}
		tile.bldg.name = bldg_to_construct
		if not game.show.minerals and bldg_to_construct == "ME":
			game.show.minerals = true
		tile.bldg.is_constructing = true
		tile.bldg.construction_date = curr_time
		tile.bldg.construction_length = constr_costs.time * 1000
		tile.bldg.XP = round(constr_costs.money / 100.0)
		match bldg_to_construct:
			"ME", "PP", "SC", "GF", "SE", "MM":
				tile.bldg.collect_date = tile.bldg.construction_date + tile.bldg.construction_length
				tile.bldg.stored = 0
				tile.bldg.path_1 = 1
				tile.bldg.path_1_value = Data.path_1[bldg_to_construct].value
				tile.bldg.path_2 = 1
				tile.bldg.path_2_value = Data.path_2[bldg_to_construct].value
				if bldg_to_construct == "MM" and not tile.has("depth"):
					tile.depth = 0
			"RL":
				game.show.SP = true
				tile.bldg.collect_date = tile.bldg.construction_date + tile.bldg.construction_length
				tile.bldg.stored = 0
				tile.bldg.path_1 = 1
				tile.bldg.path_1_value = Data.path_1.RL.value
			"MS":
				tile.bldg.path_1 = 1
				tile.bldg.path_1_value = Data.path_1.MS.value#Flat cap value
				tile.bldg.mineral_cap_upgrade = Data.path_1.MS.value#The amount of cap to add once construction is done
			"RCC":
				tile.bldg.path_1 = 1
				tile.bldg.path_1_value = Data.path_1.RCC.value
		if bldg_to_construct in ["ME", "PP", "RL", "MS"]:
			tile.bldg.IR_mult = Helper.get_IR_mult(tile)
		game.tile_data[tile_id] = tile
		add_bldg(tile_id, bldg_to_construct)
		add_time_bar(tile_id, "bldg")
	elif not mass_build:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.2)

func seeds_plant(tile, tile_id:int):
	#Plants can't grow when not adjacent to lakes
	var check_lake = check_lake(tile_id)
	if check_lake[0]:
		var curr_time = OS.get_system_time_msecs()
		tile.plant.name = game.item_to_use.name
		game.item_to_use.num -= 1
		tile.plant.plant_date = curr_time
		tile.plant.grow_time = game.craft_agric_info[game.item_to_use.name].grow_time
		if tile.has("aurora"):
			tile.plant.grow_time /= pow(1 + tile.aurora.au_int, Helper.get_AIE())
		if check_lake[1] == "l":
			tile.plant.grow_time /= 2
		elif check_lake[1] == "sc":
			tile.plant.grow_time /= 4
		tile.plant.is_growing = true
		add_plant(tile_id, game.item_to_use.name)
		game.update_item_cursor()
		game.get_node("PlantingSounds/%s" % [Helper.rand_int(1,3)]).play()
	else:
		game.popup(tr("NOT_ADJACENT_TO_LAKE") % [game.craft_agric_info[game.item_to_use.name].lake], 2)

func fertilizer_plant(tile, tile_id:int):
	var curr_time = OS.get_system_time_msecs()
	tile.construction_date -= game.craft_agric_info.fertilizer.speed_up_time
	game.item_to_use.num -= 1

func harvest_plant(tile, tile_id:int):
	if tile.plant.empty():
		return
	var curr_time = OS.get_system_time_msecs()
	if curr_time >= tile.plant.grow_time + tile.plant.plant_date:
		var plant:String = Helper.get_plant_produce(tile.plant.name)
		game.mets[plant] += game.craft_agric_info[tile.plant.name].produce * (pow(1 + tile.aurora.au_int, Helper.get_AIE()) if tile.has("aurora") else 1)
		game.show[plant] = true
		game.show.metals = true
		tile.plant.clear()
		remove_child(plant_sprites[String(tile_id)])

func speedup_bldg(tile, tile_id:int):
	var curr_time = OS.get_system_time_msecs()
	if tile.bldg.is_constructing:
		var speedup_time = game.speedup_info[game.item_to_use.name].time
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

func overclock_bldg(tile, tile_id:int):
	var curr_time = OS.get_system_time_msecs()
	if overclockable(tile.tile_str) and not tile.bldg.is_constructing:
		tile.bldg.overclock_date = curr_time
		if not tile.bldg.has("overclock_mult"):
			tile.bldg.overclock_length = game.overclock_info[game.item_to_use.name].duration
			tile.bldg.overclock_mult = game.overclock_info[game.item_to_use.name].mult
			var coll_date = tile.bldg.collect_date
			tile.bldg.collect_date = curr_time - (curr_time - coll_date) / tile.bldg.overclock_mult
			add_time_bar(tile_id, "overclock")
		game.item_to_use.num -= 1

func click_tile(tile, tile_id:int):
	if not tile.has("bldg"):
		return
	var bldg:String = tile.bldg.name
	if bldg in ["ME", "PP", "RL", "MM"]:
		collect_rsrc(tile, tile_id)
	else:
		if not tile.bldg.is_constructing:
			game.c_t = tile_id
			match bldg:
				"RCC":
					game.toggle_panel(game.RC_panel)
				"SC":
					game.toggle_panel(game.SC_panel)
					game.SC_panel.hslider.value = game.SC_panel.hslider.max_value
				"GF":
					game.toggle_panel(game.production_panel)
					game.production_panel.refresh2(bldg, "sand", "glass", "mats", "mats")
				"SE":
					game.toggle_panel(game.production_panel)
					game.production_panel.refresh2(bldg, "coal", "energy", "mats", "")
			game.hide_tooltip()

func collect_rsrc(tile, tile_id:int):
	if not tile.has("tile_str"):
		return
	var bldg:String = tile.bldg.name
	var curr_time = OS.get_system_time_msecs()
	match bldg:
		"ME":
			var stored = tile.bldg.stored
			tile.bldg.stored = Helper.add_minerals(stored)
			if stored == tile.bldg.path_2_value:
				tile.bldg.collect_date = curr_time
		"PP":
			var stored = tile.bldg.stored
			if stored == tile.bldg.path_2_value:
				tile.bldg.collect_date = curr_time
			game.energy += stored
			tile.bldg.stored = 0
		"RL":
			game.SP += tile.bldg.stored
			tile.bldg.stored = 0
		"MM":
			if tile.bldg.stored >= 1 and not tile.has("depth"):
				tile.depth = 0
			for i in tile.bldg.stored:
				Helper.get_rsrc_from_rock(Helper.generate_rock(tile, p_i), tile, p_i, true)
			if tile.bldg.stored == tile.bldg.path_2_value:
				tile.bldg.collect_date = curr_time
			tile.bldg.stored = 0

func destroy_bldg(id2:int):
	var tile = game.tile_data[id2]
	var bldg:String = tile.bldg.name
	collect_rsrc(tile, id2)
	remove_child(bldgs[id2])
	remove_child(hboxes[id2])
	if bldg == "MS":
		game.mineral_capacity -= tile.bldg.path_1_value * Helper.get_IR_mult(tile)
	tile.erase("bldg")
	if tile.empty():
		game.tile_data[id2] = null

func add_shadows():
	for sh in shadows:
		remove_child(sh)
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

var prev_tile_over = -1
var mouse_pos = Vector2.ZERO
func _input(event):
	var mass_build:bool = Input.is_action_pressed("left_click") and Input.is_action_pressed("shift") and game.bottom_info_action == "building"
	if tile_over != -1 and not mass_build:
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
			if Input.is_action_just_pressed("shift"):
				tiles_selected.clear()
				for i in len(game.tile_data):
					var tile2 = game.tile_data[i]
					if not tile2 or not tile2.has("bldg") and not tile2.has("plant"):
						continue
					if tile2.has("bldg") and tile2.bldg.name == tile.bldg.name or tile2.has("plant") and tile2.plant.name == tile.plant.name:
						tiles_selected.append(i)
						var white_rect = game.white_rect_scene.instance()
						white_rect.position.x = (i % wid) * 200
						white_rect.position.y = (i / wid) * 200
						add_child(white_rect)
						white_rect.add_to_group("white_rects")
	if Input.is_action_just_released("shift"):
		tiles_selected.clear()
		for white_rect in get_tree().get_nodes_in_group("white_rects"):
			remove_child(white_rect)
			white_rect.remove_from_group("white_rects")
				
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
		if len(game.panels) > 0:
			var i = 0
			while not game.panels[i].polygon:
				i += 1
			if Geometry.is_point_in_polygon(event.position, game.panels[i].polygon):
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
				show_tooltip(game.tile_data[tile_over])
			prev_tile_over = tile_over
		else:
			if tile_over != -1 and not_on_button:
				game.hide_tooltip()
				tile_over = -1
				prev_tile_over = -1
			game.hide_adv_tooltip()
		if shadow:
			shadow.visible = mouse_on_tiles and not mass_build
			shadow.modulate.a = 0
			shadow.position.x = floor(mouse_pos.x / 200) * 200
			shadow.position.y = floor(mouse_pos.y / 200) * 200
			shadow.position += Vector2(100, 100)
	#finish mass build
	if Input.is_action_just_released("left_click") and mass_build_rect.visible:
		mass_build_rect.visible = false
		for i in len(shadows):
			constr_bldg(get_tile_id_from_pos(shadows[i].position), true)
			remove_child(shadows[i])
		shadows.clear()
		view.move_view = true
		view.scroll_view = true
		return
	#initiate mass build
	if Input.is_action_just_pressed("left_click") and Input.is_action_pressed("shift") and game.bottom_info_action == "building":
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
		if len(game.panels) > 0:
			var i = 0
			while not game.panels[i].polygon:
				i += 1
			if Geometry.is_point_in_polygon(to_global(mouse_pos), game.panels[i].polygon):
				return
		var x_pos = int(mouse_pos.x / 200)
		var y_pos = int(mouse_pos.y / 200)
		var tile_id = get_tile_id_from_pos(mouse_pos)
		var tile = game.tile_data[tile_id]
		if bldg_to_construct != "":
			if available_to_build(tile):
				constr_bldg(tile_id)
		if about_to_mine and available_for_mining(tile):
			mine_tile(tile_id)
		if placing_soil and available_for_plant(tile):
			if game.check_enough({"soil":10}):
				game.deduct_resources({"soil":10})
				if not tile:
					game.tile_data[tile_id] = {}
				game.tile_data[tile_id].plant = {}
				$Soil.set_cell(x_pos, y_pos, 0)
				$Soil.update_bitmask_region()
			else:
				game.popup(tr("NOT_ENOUGH_SOIL"), 1.2)
		if tile:
			var t:String = game.item_to_use.type
			if tile.has("plant"):#if clicked tile has soil on it
				if placing_soil and tile.plant.empty():
					game.add_resources({"soil":10})
					tile.erase("type")
					$Soil.set_cell(x_pos, y_pos, -1)
					$Soil.update_bitmask_region()
				else:
					if t in ["fertilizer", ""]:
						var orig_num:int = game.item_to_use.num
						if tiles_selected.empty():
							call("%s_plant" % ["harvest" if t == "" else t], tile, tile_id)
						else:
							for _tile in tiles_selected:
								call("%s_plant" % ["harvest" if t == "" else t], game.tile_data[_tile], _tile)
								if t != "" and game.item_to_use.num <= 0:
									break
						game.remove_items(game.item_to_use.name, orig_num - game.item_to_use.num)
						game.update_item_cursor()
					elif t == "seeds" and not tile.has("tile_str"):
						seeds_plant(tile, tile_id)
						game.remove_items(game.item_to_use.name, 1)
						game.update_item_cursor()
			elif tile.has("bldg"):
				if t in ["speedup", "overclock"]:
					var orig_num:int = game.item_to_use.num
					if tiles_selected.empty():
						call("%s_bldg" % [t], tile, tile_id)
					else:
						for _tile in tiles_selected:
							call("%s_bldg" % [t], game.tile_data[_tile], _tile)
							if game.item_to_use.num <= 0:
								break
					game.remove_items(game.item_to_use.name, orig_num - game.item_to_use.num)
					game.update_item_cursor()
				else:
					click_tile(tile, tile_id)
					mouse_pos = Vector2.ZERO
			elif tile.has("cave"):
				if game.bottom_info_action == "enter_cave":
					game.c_t = tile_id
					game.rover_id = rover_selected
					game.switch_view("cave")
				else:
					if (game.show.vehicles_button or len(game.rover_data) > 0) and not game.vehicle_panel.visible:
						game.toggle_panel(game.vehicle_panel)
						game.vehicle_panel.tile_id = tile_id
			elif tile.has("ship"):
				if game.science_unlocked.SCT:
					game.tile_data[tile_id].erase("ship")
					$Obstacles.set_cell(x_pos, y_pos, -1)
					game.popup(tr("SHIP_CONTROL_SUCCESS"), 1.5)
					game.ship_data.append({"lv":1, "HP":40, "total_HP":40, "atk":15, "def":15, "acc":15, "eva":15, "XP":0, "XP_to_lv":20, "bullet":{"lv":1, "XP":0, "XP_to_lv":10}, "laser":{"lv":1, "XP":0, "XP_to_lv":10}, "bomb":{"lv":1, "XP":0, "XP_to_lv":10}, "light":{"lv":1, "XP":0, "XP_to_lv":20}})
					if len(game.ship_data) == 2:
						Helper.add_ship_XP(1, 181)
						Helper.add_weapon_XP(1, "bullet", 10)
						Helper.add_weapon_XP(1, "laser", 10)
						Helper.add_weapon_XP(1, "bomb", 10)
						Helper.add_weapon_XP(1, "light", 20)
				else:
					if game.show.SP:
						game.popup(tr("SHIP_CONTROL_FAIL"), 1.5)
					elif not game.get_node("UI/PopupBackground").visible:
						game.long_popup("%s %s" % [tr("SHIP_CONTROL_FAIL"), tr("SHIP_CONTROL_HELP")], tr("RESEARCH_NEEDED"))
		game.HUD.refresh()
		if game.planet_HUD:
			game.planet_HUD.refresh()

func available_for_plant(tile):
	return not tile or available_for_mining(tile) and not tile.has("crater")

func available_for_mining(tile):
	return not tile or not tile.has("bldg") and not tile.has("plant") and not tile.has("rock") and not tile.has("ship") and not tile.has("lake") and not tile.has("cave")

func available_to_build(tile):
	if bldg_to_construct == "MM":
		return not tile or available_for_mining(tile)
	return not tile or available_for_plant(tile)

func mine_tile(id2:int):
	game.c_t = id2
	game.switch_view("mining")

func lake_bool(id2:int):
	return game.tile_data[id2].tile_str.split("_")

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
					var okay = lake_bool(id2)[1] == game.craft_agric_info[game.item_to_use.name].lake
					has_lake = has_lake or okay
					if okay:
						state = lake_bool(id2)[0]
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
	time_bars.append({"node":time_bar, "id":id2, "type":type})

func add_plant(id2:int, st:String):
	var plant:AnimatedSprite = AnimatedSprite.new()
	plant.frames = SpriteFrames.new()
	for i in 5:
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
	if tile.plant.is_growing:
		add_time_bar(id2, "plant")
	else:
		plant.frame = 4

func add_bldg(id2:int, st:String):
	var bldg = Sprite.new()
	bldg.texture = load("res://Graphics/Buildings/" + st + ".png")
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
			add_rsrc(v, Color(0, 0.5, 0.9, 1), Data.icons.ME, id2)
		"PP":
			add_rsrc(v, Color(0, 0.8, 0, 1), Data.icons.PP, id2)
		"RL":
			add_rsrc(v, Color(0.3, 1.0, 0.3, 1), Data.icons.RL, id2)
		"MM":
			add_rsrc(v, Color(0.6, 0.6, 0.6, 1), Data.icons.MM, id2)
		"SC":
			add_rsrc(v, Color(0.6, 0.6, 0.6, 1), Data.icons.SC, id2)
		"GF":
			add_rsrc(v, Color(0.8, 0.9, 0.85, 1), Data.icons.GF, id2)
		"SE":
			add_rsrc(v, Color(0, 0.8, 0, 1), Data.icons.SE, id2)
		"MS":
			if not tile.bldg.is_constructing:
				update_MS(tile)
	var hbox = HBoxContainer.new()
	hbox.alignment = hbox.ALIGN_CENTER
	hbox.theme = load("res://Resources/panel_theme.tres")
	hbox["custom_constants/separation"] = -1
	var path_1 = Label.new()
	path_1.name = "Path1"
	path_1.text = String(tile.bldg.path_1)
	path_1.connect("mouse_entered", self, "on_path_enter", ["1", tile])
	path_1.connect("mouse_exited", self, "on_path_exit")
	path_1["custom_styles/normal"] = load("res://Resources/TextBorder.tres")
	hbox.add_child(path_1)
	hbox.mouse_filter = hbox.MOUSE_FILTER_IGNORE
	path_1.mouse_filter = path_1.MOUSE_FILTER_PASS
	if tile.bldg.has("path_2"):
		var path_2 = Label.new()
		path_2.name = "Path2"
		path_2.text = String(tile.bldg.path_2)
		path_2.connect("mouse_entered", self, "on_path_enter", ["2", tile])
		path_2.connect("mouse_exited", self, "on_path_exit")
		path_2["custom_styles/normal"] = load("res://Resources/TextBorder.tres")
		path_2.mouse_filter = path_2.MOUSE_FILTER_PASS
		hbox.add_child(path_2)
	if tile.bldg.has("path_3"):
		var path_3 = Label.new()
		path_3.name = "Path3"
		path_3.text = String(tile.bldg.path_3)
		path_3.connect("mouse_entered", self, "on_path_enter", ["3", tile])
		path_3.connect("mouse_exited", self, "on_path_exit")
		path_3["custom_styles/normal"] = load("res://Resources/TextBorder.tres")
		path_3.mouse_filter = path_3.MOUSE_FILTER_PASS
		hbox.add_child(path_3)
	hbox.rect_size.x = 200
	hbox.rect_position = v - Vector2(100, 90)
	hbox.visible = get_parent().scale.x >= 0.25
	add_child(hbox)
	hboxes[id2] = hbox
	if tile.bldg.is_constructing:
		add_time_bar(id2, "bldg")
	if tile.bldg.has("overclock_mult"):
		add_time_bar(id2, "overclock")

func update_MS(tile):
	var new_IR_mult:float = Helper.get_IR_mult(tile)
	if tile.bldg.IR_mult != new_IR_mult:
		game.mineral_capacity += tile.bldg.path_1_value * (new_IR_mult - tile.bldg.IR_mult)
		tile.bldg.IR_mult = new_IR_mult
	
func overclockable(bldg:String):
	return bldg in ["ME", "PP", "RL", "MM", "SC", "GF", "SE"]

func on_path_enter(path:String, tile):
	game.hide_adv_tooltip()
	game.show_tooltip("%s %s %s %s" % [tr("PATH"), path, tr("LEVEL"), tile.bldg["path_" + path]])

func on_path_exit():
	game.hide_tooltip()

func add_rsrc(v:Vector2, mod:Color, icon, id2:int):
	var rsrc = game.rsrc_stocked_scene.instance()
	rsrc.visible = get_parent().scale.x >= 0.25
	add_child(rsrc)
	rsrc.get_node("TextureRect").texture = icon
	rsrc.rect_position = v + Vector2(0, 70)
	rsrc.get_node("Control").modulate = mod
	rsrcs.append({"node":rsrc, "id":id2})
	var tile = game.tile_data[id2]
	var curr_time = OS.get_system_time_msecs()
	if tile.bldg.has("IR_mult"):
		var IR_mult = Helper.get_IR_mult(tile)
		if tile.bldg.IR_mult != IR_mult:
			var diff:float = IR_mult / tile.bldg.IR_mult
			tile.bldg.IR_mult = IR_mult
			if not tile.bldg.is_constructing:
				tile.bldg.collect_date = curr_time - (curr_time - tile.bldg.collect_date) / diff
	update_rsrc(rsrc, game.tile_data[id2])

func _process(_delta):
	var curr_time = OS.get_system_time_msecs()
	for time_bar_obj in time_bars:
		var time_bar = time_bar_obj.node
		var id2 = time_bar_obj.id
		var tile = game.tile_data[id2]
		if not tile or tile.has("bldg") and not tile.bldg.has("construction_date") or tile.has("plant") and not tile.plant.has("plant_date"):
			remove_child(time_bar)
			time_bars.erase(time_bar_obj)
			continue
		var start_date
		var length
		if tile.has("bldg"):
			start_date = tile.bldg.construction_date
			length = tile.bldg.construction_length
		elif tile.has("plant"):
			start_date = tile.plant.plant_date
			length = tile.plant.grow_time
		var progress:float
		if time_bar_obj.type == "overclock":
			progress = 1 - (curr_time - tile.bldg.overclock_date) / float(tile.bldg.overclock_length)
			time_bar.get_node("TimeString").text = Helper.time_to_str(tile.bldg.overclock_length - curr_time + tile.bldg.overclock_date)
		else:
			progress = (curr_time - start_date) / float(length)
			time_bar.get_node("TimeString").text = Helper.time_to_str(length - curr_time + start_date)
		time_bar.get_node("Bar").value = progress
		if tile.has("plant"):
			var plant:AnimatedSprite = plant_sprites[String(id2)]
			plant.frame = min(4, int(progress * 4))
			if progress > 1:
				tile.plant.is_growing = false
				remove_child(time_bar)
				time_bars.erase(time_bar_obj)
		elif progress > 1:
			if tile.bldg.is_constructing:
				tile.bldg.is_constructing = false
				game.xp += tile.bldg.XP
				if tile.bldg.has("rover_id"):
					game.rover_data[tile.rover_id].ready = true
					tile.bldg.erase("rover_id")
				hboxes[id2].get_node("Path1").text = String(tile.bldg.path_1)
				if tile.bldg.has("path_2"):
					hboxes[id2].get_node("Path2").text = String(tile.bldg.path_2)
				if tile.bldg.has("path_3"):
					hboxes[id2].get_node("Path3").text = String(tile.bldg.path_3)
				if tile.bldg.name == "MS":
					tile.bldg.IR_mult = Helper.get_IR_mult(tile)
					game.mineral_capacity += tile.bldg.mineral_cap_upgrade * tile.bldg.IR_mult
				game.HUD.refresh()
			remove_child(time_bar)
			time_bars.erase(time_bar_obj)
		if progress < 0:
			var coll_date = tile.bldg.collect_date
			tile.bldg.collect_date = curr_time - (curr_time - coll_date) * tile.bldg.overclock_mult
			tile.bldg.erase("overclock_date")
			tile.bldg.erase("overclock_length")
			tile.bldg.erase("overclock_mult")
			remove_child(time_bar)
			time_bars.erase(time_bar_obj)
	for rsrc_obj in rsrcs:
		var tile = game.tile_data[rsrc_obj.id]
		var rsrc = rsrc_obj.node
		if not tile or not tile.bldg.has("is_constructing"):
			remove_child(rsrc_obj.node)
			rsrcs.erase(rsrc_obj)
			continue
		if tile.bldg.is_constructing:
			continue
		update_rsrc(rsrc, tile)

func get_prod_mult(tile):
	var mult = Helper.get_IR_mult(tile)
	if tile.has("overclock_mult"):
		mult *= tile.bldg.overclock_mult
	return mult
	
func update_rsrc(rsrc, tile):
	var curr_time = OS.get_system_time_msecs()
	match tile.bldg.name:
		"ME", "PP", "MM":
			#Number of seconds needed per mineral
			var prod = 1000 / tile.bldg.path_1_value
			prod /= get_prod_mult(tile)
			var cap = round(tile.bldg.path_2_value * Helper.get_IR_mult(tile))
			var stored = tile.bldg.stored
			#print(stored < cap)
			var c_d = tile.bldg.collect_date
			var c_t = curr_time
			var current_bar = rsrc.get_node("Control/CurrentBar")
			var capacity_bar = rsrc.get_node("Control/CapacityBar")
			if stored < cap:
				current_bar.value = min((c_t - c_d) / prod, 1)
				capacity_bar.value = min(stored / float(cap), 1)
				if c_t - c_d > prod:
					var rsrc_num = floor((c_t - c_d) / prod)
					tile.bldg.stored += rsrc_num
					tile.bldg.collect_date += prod * rsrc_num
					if tile.bldg.stored >= tile.bldg.path_2_value:
						tile.bldg.stored = tile.bldg.path_2_value
						current_bar.value = 0
						capacity_bar.value = 1
			else:
				current_bar.value = 0
				capacity_bar.value = 1
			if tile.bldg.name == "MM":
				rsrc.get_node("Control/Label").text = "%s / %s m" % [tile.depth + tile.bldg.stored, tile.depth + cap]
			else:
				rsrc.get_node("Control/Label").text = String(stored)
		"RL":
			var prod = 1000 / tile.bldg.path_1_value
			prod /= get_prod_mult(tile)
			var stored = tile.bldg.stored
			var c_d = tile.bldg.collect_date
			var c_t = curr_time
			var current_bar = rsrc.get_node("Control/CurrentBar")
			current_bar.value = min((c_t - c_d) / prod, 1)
			if c_t - c_d > prod:
				var rsrc_num = floor((c_t - c_d) / prod)
				tile.bldg.stored += rsrc_num
				tile.bldg.collect_date += prod * rsrc_num
			rsrc.get_node("Control/Label").text = String(stored)
		"SC":
			if tile.has("stone"):
				var c_i = Helper.get_crush_info(tile)
				rsrc.get_node("Control/Label").text = String(c_i.qty_left)
				rsrc.get_node("Control/CapacityBar").value = 1 - c_i.progress
			else:
				rsrc.get_node("Control/Label").text = ""
				rsrc.get_node("Control/CapacityBar").value = 0
		"GF":
			if tile.has("qty1"):
				var prod_i = Helper.get_prod_info(tile)
				rsrc.get_node("Control/Label").text = "%s kg" % [prod_i.qty_made]
				rsrc.get_node("Control/CapacityBar").value = prod_i.progress
			else:
				rsrc.get_node("Control/Label").text = ""
				rsrc.get_node("Control/CapacityBar").value = 0
		"SE":
			if tile.has("qty1"):
				var prod_i = Helper.get_prod_info(tile)
				rsrc.get_node("Control/Label").text = "%s" % [round(prod_i.qty_made)]
				rsrc.get_node("Control/CapacityBar").value = prod_i.progress
			else:
				rsrc.get_node("Control/Label").text = ""
				rsrc.get_node("Control/CapacityBar").value = 0

func construct(st:String, costs:Dictionary):
	finish_construct()
	if game.help.mass_build:
		Helper.put_rsrc(game.get_node("UI/Panel/VBox"), 32, {})
		Helper.add_label(tr("HOLD_SHIFT_TO_MASS_BUILD"), -1, true, true)
		game.help_str = "mass_build"
		Helper.add_label(tr("HIDE_HELP"), -1, true, true)
		game.get_node("UI/Panel").visible = true
	bldg_to_construct = st
	constr_costs = costs
	shadow = Sprite.new()
	put_shadow(shadow)

func put_shadow(spr:Sprite, pos:Vector2 = Vector2.ZERO):
	spr.texture = load("res://Graphics/Buildings/%s.png" % bldg_to_construct)
	spr.scale *= 0.4
	spr.modulate.a = 0.5
	spr.position.x = floor(pos.x / 200) * 200 + 100
	spr.position.y = floor(pos.y / 200) * 200 + 100
	add_child(spr)
	return spr
	
func finish_construct():
	if shadow:
		bldg_to_construct = ""
		remove_child(shadow)
		shadow = null
	game.get_node("UI/Panel").visible = false

func _on_Planet_tree_exited():
	queue_free()

func collect_all():
	var i:int
	for tile in game.tile_data:
		if tile:
			collect_rsrc(tile, i)
		i += 1
	game.HUD.refresh()

func get_tile_id_from_pos(pos:Vector2):
	var x_pos = int(pos.x / 200)
	var y_pos = int(pos.y / 200)
	return x_pos % wid + y_pos * wid
