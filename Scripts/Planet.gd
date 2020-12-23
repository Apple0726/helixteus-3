extends Node2D

onready var game = get_node("/root/Game")
onready var view = game.view
onready var id = game.c_p
onready var p_i = game.planet_data[id]

#For exploring a cave
var rover_selected:Dictionary = {}
#The building you selected in construct panel
var bldg_to_construct:String = ""
#The cost of the above building
var constr_costs:Dictionary = {}
#The transparent sprite
var shadow:Sprite
#Local id of the tile hovered
var tile_over:int = -1

onready var wid:int = round(Helper.get_wid(p_i.size))
#A rectangle enclosing all tiles
onready var planet_bounds:PoolVector2Array = [Vector2.ZERO, Vector2(0, wid * 200), Vector2(wid * 200, wid * 200), Vector2(wid * 200, 0)]

func _ready():
	$TileMap.tile_set = game.planet_TS
	$Obstacles.tile_set = game.obstacles_TS
	var planet_save:File = File.new()
	var file_path:String = "user://Save1/Planets/%s.hx3" % [id]
	planet_save.open(file_path, File.READ)
	game.tile_data = planet_save.get_var()
	planet_save.close()
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
			if tile.has("type"):
				match tile.type:
					"plant":
						$Soil.set_cell(i, j, 0)
						if tile.has("tile_str"):
							add_plant(id2, tile.tile_str)
					"bldg":
						add_bldg(id2, tile.tile_str)
			if tile.has("aurora"):
				var aurora = Sprite.new()
				aurora.position = Vector2(i, j) * 200 + Vector2(100, 100)
				if tile.aurora == 1:
					aurora.texture = game.aurora1_texture
					aurora.modulate = Color(rand_range(0.7, 1), 0, rand_range(0.7, 1))
				else:
					aurora.texture = game.aurora2_texture
					aurora.modulate = Color(1, 1, rand_range(0.7, 1))
				add_child(aurora)
			if not tile.has("tile_str"):
				continue
			if tile.tile_str == "rock":
				$Obstacles.set_cell(i, j, 0)
			elif tile.tile_str == "cave":
				$Obstacles.set_cell(i, j, 1)
			elif tile.tile_str == "crater" and tile.has("init_depth"):
				var metal = Sprite.new()
				metal.texture = load("res://Graphics/Metals/%s.png" % [tile.crater_metal])
				metal.scale *= 0.4
				add_child(metal)
				metal.position = Vector2(i, j) * 200 + Vector2(100, 100)
				$Obstacles.set_cell(i, j, 1 + tile.crater_variant)
			elif tile.tile_str == "ship":
				$Obstacles.set_cell(i, j, 5)
			var lake = tile.tile_str.split("_")
			if p_i.has("lake_1") and len(lake) == 3 and lake[2] == "1":
				if lake[0] == "l":
					$Lakes1.set_cell(i, j, 2)
					add_particles(Vector2(i*200, j*200))
				elif lake[0] == "s":
					$Lakes1.set_cell(i, j, 0)
				elif lake[0] == "sc":
					$Lakes1.set_cell(i, j, 1)
			if p_i.has("lake_2") and len(lake) == 3 and lake[2] == "2":
				if lake[0] == "l":
					$Lakes2.set_cell(i, j, 2)
					add_particles(Vector2(i*200, j*200))
				elif lake[0] == "s":
					$Lakes2.set_cell(i, j, 0)
				elif lake[0] == "sc":
					$Lakes2.set_cell(i, j, 1)
	$Lakes1.update_bitmask_region()
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
	if tile.has("type"):
		if tile.type == "bldg":
			var mult = 1
			if tile.has("overclock_mult"):
				mult = tile.overclock_mult
			match tile.tile_str:
				"ME", "PP":
					tooltip = (Data.path_1[tile.tile_str].desc + "\n" + Data.path_2[tile.tile_str].desc) % [tile.path_1_value * mult, tile.path_2_value]
					icons = [Data.icons[tile.tile_str], Data.icons[tile.tile_str]]
					adv = true
				"SC", "GF":
					tooltip = (Data.path_1[tile.tile_str].desc + "\n" + Data.path_2[tile.tile_str].desc) % [tile.path_1_value * mult, tile.path_2_value] + "\n" + tr("CLICK_TO_CONFIGURE")
					icons = [Data.icons[tile.tile_str], Data.icons[tile.tile_str]]
					adv = true
				"RL":
					tooltip = (Data.path_1[tile.tile_str].desc) % [tile.path_1_value * mult]
					icons = [Data.icons.RL]
					adv = true
				"MS":
					tooltip = (Data.path_1[tile.tile_str].desc) % [tile.path_1_value]
					icons = [Data.icons.MS]
					adv = true
				"RCC":
					tooltip = (Data.path_1[tile.tile_str].desc) % [tile.path_1_value]
			if game.help.tile_shortcuts:
				game.help_str = "tile_shortcuts"
				tooltip += "\n" + tr("PRESS_F_TO_UPGRADE") + "\n" + tr("PRESS_Q_TO_DUPLICATE") + "\n" + tr("HIDE_SHORTCUTS")
		elif tile.type == "plant":
			if not tile.has("tile_str"):
				if game.help.plant_something_here:
					tooltip = tr("PLANT_STH") + "\n" + tr("HIDE_HELP")
					game.help_str = "plant_something_here"
			else:
				tooltip = Helper.get_plant_name(tile.tile_str)
				if OS.get_system_time_msecs() >= tile.construction_date + tile.construction_length:
					tooltip += "\n" + tr("CLICK_TO_HARVEST")
		elif tile.type == "lake":
			var strs = tile.tile_str.split("_")
			if strs[0] == "s" and strs[1] == "water":
				tooltip = tr("ICE")
			elif strs[0] == "l" and strs[1] == "water":
				tooltip = tr("WATER")
			else:
				match strs[0]:
					"l":
						tooltip = tr("LAKE_CONTENTS").format({"state":tr("LIQUID"), "contents":tr(strs[1].to_upper())})
					"s":
						tooltip = tr("LAKE_CONTENTS").format({"state":tr("SOLID"), "contents":tr(strs[1].to_upper())})
					"sc":
						tooltip = tr("LAKE_CONTENTS").format({"state":tr("SUPERCRITICAL"), "contents":tr(strs[1].to_upper())})
		elif tile.type == "obstacle":
			match tile.tile_str:
				"rock":
					if game.help.boulder_desc:
						tooltip = tr("BOULDER_DESC") + "\n" + tr("HIDE_HELP")
						game.help_str = "boulder_desc"
				"ship":
					if game.science_unlocked.SCT:
						tooltip = tr("CLICK_TO_CONTROL_SHIP")
					else:
						if game.help.abandoned_ship:
							tooltip = tr("ABANDONED_SHIP") + "\n" + tr("HIDE_HELP")
							game.help_str = "abandoned_ship"
				"cave":
					tooltip = tr("CAVE")
					if game.help.cave_desc:
						tooltip += "\n%s\n%s\n%s\n%s" % [tr("CAVE_DESC"), tr("HIDE_HELP"), tr("NUM_FLOORS") % game.cave_data[tile.cave_id].num_floors, tr("FLOOR_SIZE").format({"size":game.cave_data[tile.cave_id].floor_size})]
						game.help_str = "cave_desc"
					else:
						tooltip += "\n%s\n%s" % [tr("NUM_FLOORS") % game.cave_data[tile.cave_id].num_floors, tr("FLOOR_SIZE").format({"size":game.cave_data[tile.cave_id].floor_size})]
				"crater":
					if game.help.crater_desc:
						tooltip = tr("METAL_CRATER").format({"metal":tr(tile.crater_metal.to_upper()), "crater":tr("CRATER")}) + "\n%s\n%s\n%s" % [tr("CRATER_DESC"), tr("HIDE_HELP"), tr("HOLE_DEPTH") + ": %s m"  % [tile.depth]]
						game.help_str = "crater_desc"
					else:
						tooltip = tr("METAL_CRATER").format({"metal":tr(tile.crater_metal.to_upper()), "crater":tr("CRATER")}) + "\n%s" % [tr("HOLE_DEPTH") + ": %s m"  % [tile.depth]]
	elif tile.has("depth"):
		tooltip += tr("HOLE_DEPTH") + ": %s m" % [tile.depth]
	elif tile.has("aurora"):
		if game.help.aurora_desc:
			tooltip = "%s\n%s\n%s\n%s" % [tr("AURORA"), tr("AURORA_DESC"), tr("HIDE_HELP"), tr("AURORA_INTENSITY") + ": %s" % [tile.au_int]]
			game.help_str = "aurora_desc"
		else:
			tooltip = tr("AURORA_INTENSITY") + ": %s" % [tile.au_int]
	if adv:
		if tile.tile_str == "":
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

func constr_bldg(tile, tile_id:int):
	if game.check_enough(constr_costs):
		game.deduct_resources(constr_costs)
		var curr_time = OS.get_system_time_msecs()
		tile = {}
		tile.tile_str = bldg_to_construct
		if not game.show.minerals and tile.tile_str == "ME":
			game.show.minerals = true
		tile.is_constructing = true
		tile.construction_date = curr_time
		tile.construction_length = constr_costs.time * 1000
		tile.type = "bldg"
		tile.XP = round(constr_costs.money / 100.0)
		match bldg_to_construct:
			"ME", "PP", "SC", "GF":
				tile.collect_date = tile.construction_date + tile.construction_length
				tile.stored = 0
				tile.path_1 = 1
				tile.path_1_value = Data.path_1[tile.tile_str].value
				tile.path_2 = 1
				tile.path_2_value = Data.path_2[tile.tile_str].value
			"RL":
				game.show.SP = true
				tile.collect_date = tile.construction_date + tile.construction_length
				tile.stored = 0
				tile.path_1 = 1
				tile.path_1_value = Data.path_1.RL.value
			"MS":
				tile.path_1 = 1
				tile.path_1_value = Data.path_1.MS.value#Flat cap value
				tile.mineral_cap_upgrade = Data.path_1.MS.value#The amount of cap to add once construction is done
			"RCC":
				tile.path_1 = 1
				tile.path_1_value = Data.path_1.RCC.value
		game.tile_data[tile_id] = tile
		add_bldg(tile_id, bldg_to_construct)
		add_time_bar(tile_id, "bldg")
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.2)

func plant_seed(tile, tile_id:int):
	if game.item_to_use.type == "seeds":
		#Plants can't grow when not adjacent to lakes
		var check_lake = check_lake(tile_id)
		if check_lake[0]:
			var curr_time = OS.get_system_time_msecs()
			tile.tile_str = game.item_to_use.name
			game.remove_items(game.item_to_use.name)
			game.item_to_use.num -= 1
			tile.construction_date = curr_time
			tile.construction_length = game.craft_agric_info[game.item_to_use.name].grow_time
			if check_lake[1] == "l":
				tile.construction_length /= 2
			elif check_lake[1] == "sc":
				tile.construction_length /= 4
			tile.is_growing = true
			add_plant(tile_id, game.item_to_use.name)
			game.update_item_cursor()
			game.get_node("PlantingSounds/%s" % [Helper.rand_int(1,3)]).play()
		else:
			game.popup(tr("NOT_ADJACENT_TO_LAKE") % [game.craft_agric_info[game.item_to_use.name].lake], 2)

func harvest_plant(tile, tile_id:int):
	var curr_time = OS.get_system_time_msecs()
	if curr_time >= tile.construction_length + tile.construction_date:
		game.mets[Helper.get_plant_produce(tile.tile_str)] += game.craft_agric_info[tile.tile_str].produce
		tile.erase("tile_str")
		remove_child(plant_sprites[String(tile_id)])
	elif game.item_to_use.type == "fertilizer":
		tile.construction_date -= game.craft_agric_info.fertilizer.speed_up_time
		game.remove_items("fertilizer")
		game.item_to_use.num -= 1
		game.update_item_cursor()

func speedup_bldg(tile):
	var curr_time = OS.get_system_time_msecs()
	if tile.is_constructing:
		var speedup_time = game.speedup_info[game.item_to_use.name].time
		#Time remaining to finish construction
		var time_remaining = tile.construction_date + tile.construction_length - curr_time
		var num_needed = min(game.item_to_use.num, ceil((time_remaining) / float(speedup_time)))
		tile.construction_date -= speedup_time * num_needed
		if tile.has("collect_date"):
			tile.collect_date -= min(speedup_time * num_needed, time_remaining)
		game.remove_items(game.item_to_use.name, num_needed)
		game.item_to_use.num -= num_needed
		game.update_item_cursor()

func overclock_bldg(tile, tile_id:int):
	var curr_time = OS.get_system_time_msecs()
	if overclockable(tile.tile_str) and not tile.is_constructing:
		tile.overclock_date = curr_time
		if not tile.has("overclock_mult"):
			tile.overclock_length = game.overclock_info[game.item_to_use.name].duration
			tile.overclock_mult = game.overclock_info[game.item_to_use.name].mult
			var coll_date = tile.collect_date
			tile.collect_date = curr_time - (curr_time - coll_date) / tile.overclock_mult
			add_time_bar(tile_id, "overclock")
		game.remove_items(game.item_to_use.name)
		game.item_to_use.num -= 1
		game.update_item_cursor()

func click_tile(tile, tile_id:int):
	if not tile.has("tile_str"):
		return
	if tile.tile_str in ["ME", "PP", "RL"]:
		collect_rsrc(tile, tile_id)
	else:
		if not tile.is_constructing:
			game.c_t = tile_id
			match tile.tile_str:
				"RCC":
					game.toggle_panel(game.RC_panel)
				"SC":
					game.toggle_panel(game.SC_panel)
				"GF":
					game.toggle_panel(game.GF_panel)
					game.hide_tooltip()

func collect_rsrc(tile, tile_id:int):
	if not tile.has("tile_str"):
		return
	var curr_time = OS.get_system_time_msecs()
	match tile.tile_str:
		"ME":
			var mineral_space_available = game.mineral_capacity - game.minerals
			var stored = tile.stored
			if mineral_space_available >= stored:
				tile.stored = 0
				game.minerals += stored
			else:
				game.minerals = game.mineral_capacity
				tile.stored -= mineral_space_available
			if stored == tile.path_2_value:
				tile.collect_date = curr_time
		"PP":
			var stored = tile.stored
			if stored == tile.path_2_value:
				tile.collect_date = curr_time
			game.energy += stored
			tile.stored = 0
		"RL":
			game.SP += tile.stored
			tile.stored = 0

var prev_tile_over = -1
var mouse_pos = Vector2.ZERO
func _input(event):
	if tile_over != -1:
		var tile = game.tile_data[tile_over]
		if tile and tile.has("type") and tile.type == "bldg":
			if Input.is_action_just_released("Q"):
				game.put_bottom_info(tr("CLICK_TILE_TO_CONSTRUCT"), "building", "cancel_building")
				construct(tile.tile_str, Data.costs[tile.tile_str])
			if Input.is_action_just_released("F"):
				game.add_upgrade_panel([tile_over])
	var not_on_button = not game.planet_HUD.on_button and not game.HUD.on_button and not game.close_button_over
	if event is InputEventMouseMotion:
		mouse_pos = to_local(event.position)
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
		var mouse_on_tiles = Geometry.is_point_in_polygon(mouse_pos, planet_bounds)
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
			shadow.visible = mouse_on_tiles
			shadow.position.x = floor(mouse_pos.x / 200) * 200
			shadow.position.y = floor(mouse_pos.y / 200) * 200
			shadow.position += Vector2(100, 100)
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
		var tile_id = x_pos % wid + y_pos * wid
		var tile = game.tile_data[tile_id]
		if not tile:
			if about_to_mine:
				mine_tile(tile_id)
			elif bldg_to_construct != "":
				constr_bldg(tile, tile_id)
			elif placing_soil:
				if game.check_enough({"soil":10}):
					game.deduct_resources({"soil":10})
					game.tile_data[tile_id] = {"type":"plant"}
					$Soil.set_cell(x_pos, y_pos, 0)
					$Soil.update_bitmask_region()
				else:
					game.popup(tr("NOT_ENOUGH_SOIL"), 1.2)
		else:
			if about_to_mine and tile.has("depth") or tile.has("aurora"):
				mine_tile(tile_id)
			elif tile.has("type"):
				if tile.type == "plant":#if clicked tile has soil on it
					if placing_soil:
						game.add_resources({"soil":10})
						tile.erase("type")
						$Soil.set_cell(x_pos, y_pos, -1)
						$Soil.update_bitmask_region()
					elif not tile.has("tile_str"):#if there are no plants
						plant_seed(tile, tile_id)
					else:#When clicking a planted crop
						harvest_plant(tile, tile_id)
				elif tile.type == "bldg":
					if game.item_to_use.type == "speedup":
						speedup_bldg(tile)
					elif game.item_to_use.type == "overclock":
						overclock_bldg(tile, tile_id)
					else:
						click_tile(tile, tile_id)
						mouse_pos = Vector2.ZERO
				elif tile.type == "obstacle":
					if tile.tile_str == "cave":
						if game.bottom_info_action == "enter_cave":
							game.c_t = tile_id
							game.switch_view("cave")
							game.cave.rover_data = rover_selected
							game.cave.set_rover_data()
						else:
							if (game.show.vehicles_button or len(game.rover_data) > 0) and not game.vehicle_panel.visible:
								game.toggle_panel(game.vehicle_panel)
								game.vehicle_panel.tile_id = tile_id
					elif tile.tile_str == "ship":
						if game.science_unlocked.SCT:
							game.tile_data[tile_id] = null
							$Obstacles.set_cell(x_pos, y_pos, -1)
							game.popup(tr("SHIP_CONTROL_SUCCESS"), 1.5)
							game.show.vehicles_button = true
							game.ship_data.append({"lv":1, "HP":40, "total_HP":40, "atk":15, "def":15, "acc":15, "eva":15, "XP":0, "XP_to_lv":20, "bullet":{"lv":1, "XP":0, "XP_to_lv":10}, "laser":{"lv":1, "XP":0, "XP_to_lv":10}, "bomb":{"lv":1, "XP":0, "XP_to_lv":10}, "light":{"lv":1, "XP":0, "XP_to_lv":20}})
						else:
							if game.show.SP:
								game.popup(tr("SHIP_CONTROL_FAIL"), 1.5)
							elif not game.get_node("UI/PopupBackground").visible:
								game.long_popup("%s %s" % [tr("SHIP_CONTROL_FAIL"), tr("SHIP_CONTROL_HELP")], tr("RESEARCH_NEEDED"))
		game.HUD.refresh()
		if game.planet_HUD:
			game.planet_HUD.refresh()

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

var time_bars = []
var rsrcs = []
var bldgs = []#Tiles with a bldg
var plant_sprites = {}
var hboxes = {}

func add_time_bar(id2:int, type:String):
	var local_id = id2
	var v = Vector2.ZERO
	v.x = (local_id % wid) * 200
	v.y = floor(local_id / wid) * 200
	v += Vector2(100, 15)
	var time_bar = game.time_scene.instance()
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
	var plant_scene = load("res://Scenes/Plants/" + st + ".tscn")
	var plant = plant_scene.instance()
	var local_id = id2
	var v = Vector2.ZERO
	v.x = (local_id % wid) * 200
	v.y = floor(local_id / wid) * 200
	v += Vector2(100, 100)
	plant.position = v
	add_child(plant)
	plant_sprites[String(id2)] = plant
	var tile = game.tile_data[id2]
	if tile.is_growing:
		add_time_bar(id2, "plant")

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
	var tile = game.tile_data[id2]
	bldgs.append(tile)
	match st:
		"ME":
			add_rsrc(v, Color(0, 0.5, 0.9, 1), Data.icons.ME, id2)
		"PP":
			add_rsrc(v, Color(0, 0.8, 0, 1), Data.icons.PP, id2)
		"RL":
			add_rsrc(v, Color(0.3, 1.0, 0.3, 1), Data.icons.RL, id2)
		"SC":
			add_rsrc(v, Color(0.6, 0.6, 0.6, 1), Data.icons.SC, id2)
		"GF":
			add_rsrc(v, Color(0.8, 0.9, 0.85, 1), Data.icons.GF, id2)
	var hbox = HBoxContainer.new()
	hbox.alignment = hbox.ALIGN_CENTER
	hbox.theme = load("res://Resources/panel_theme.tres")
	hbox["custom_constants/separation"] = -1
	var path_1 = Label.new()
	path_1.name = "Path1"
	path_1.text = String(tile.path_1)
	path_1.connect("mouse_entered", self, "on_path_enter", ["1", tile])
	path_1.connect("mouse_exited", self, "on_path_exit")
	path_1["custom_styles/normal"] = load("res://Resources/TextBorder.tres")
	hbox.add_child(path_1)
	hbox.mouse_filter = hbox.MOUSE_FILTER_IGNORE
	path_1.mouse_filter = path_1.MOUSE_FILTER_PASS
	if tile.has("path_2"):
		var path_2 = Label.new()
		path_2.name = "Path2"
		path_2.text = String(tile.path_2)
		path_2.connect("mouse_entered", self, "on_path_enter", ["2", tile])
		path_2.connect("mouse_exited", self, "on_path_exit")
		path_2["custom_styles/normal"] = load("res://Resources/TextBorder.tres")
		path_2.mouse_filter = path_2.MOUSE_FILTER_PASS
		hbox.add_child(path_2)
	if tile.has("path_3"):
		var path_3 = Label.new()
		path_3.name = "Path3"
		path_3.text = String(tile.path_3)
		path_3.connect("mouse_entered", self, "on_path_enter", ["3", tile])
		path_3.connect("mouse_exited", self, "on_path_exit")
		path_3["custom_styles/normal"] = load("res://Resources/TextBorder.tres")
		path_3.mouse_filter = path_3.MOUSE_FILTER_PASS
		hbox.add_child(path_3)
	hbox.rect_size.x = 200
	hbox.rect_position = v - Vector2(100, 90)
	add_child(hbox)
	hboxes[String(id2)] = hbox
	if tile.is_constructing:
		add_time_bar(id2, "bldg")
	if tile.has("overclock_mult"):
		add_time_bar(id2, "overclock")

func overclockable(bldg:String):
	return bldg in ["ME", "PP", "RL", "SC", "GF"]

func on_path_enter(path:String, tile):
	game.hide_adv_tooltip()
	game.show_tooltip("%s %s %s %s" % [tr("PATH"), path, tr("LEVEL"), tile["path_" + path]])

func on_path_exit():
	game.hide_tooltip()

func add_rsrc(v:Vector2, mod:Color, icon, id2:int):
	var rsrc = game.rsrc_stocked_scene.instance()
	add_child(rsrc)
	rsrc.get_node("TextureRect").texture = icon
	rsrc.rect_position = v + Vector2(0, 70)
	rsrc.get_node("Control").modulate = mod
	rsrcs.append({"node":rsrc, "id":id2})
	update_rsrc(rsrc, game.tile_data[id2])

func _process(_delta):
	var curr_time = OS.get_system_time_msecs()
	for time_bar_obj in time_bars:
		var time_bar = time_bar_obj.node
		var id2 = time_bar_obj.id
		var tile = game.tile_data[id2]
		var progress = (curr_time - tile.construction_date) / float(tile.construction_length)
		if time_bar_obj.type == "overclock":
			progress = 1 - (curr_time - tile.overclock_date) / float(tile.overclock_length)
			time_bar.get_node("TimeString").text = Helper.time_to_str(tile.overclock_length - curr_time + tile.overclock_date)
		else:
			progress = (curr_time - tile.construction_date) / float(tile.construction_length)
			time_bar.get_node("TimeString").text = Helper.time_to_str(tile.construction_length - curr_time + tile.construction_date)
		time_bar.get_node("Bar").value = progress
		if tile.type == "plant":
			var plant:AnimatedSprite = plant_sprites[String(id2)]
			plant.frame = min(4, int(progress * 4))
			if progress > 1:
				tile.is_growing = false
				remove_child(time_bar)
				time_bars.erase(time_bar_obj)
		elif progress > 1:
			if tile.is_constructing:
				tile.is_constructing = false
				game.xp += tile.XP
				if tile.has("rover_id"):
					game.rover_data[tile.rover_id].ready = true
					tile.erase("rover_id")
				hboxes[String(id2)].get_node("Path1").text = String(tile.path_1)
				if tile.has("path_2"):
					hboxes[String(id2)].get_node("Path2").text = String(tile.path_2)
				if tile.has("path_3"):
					hboxes[String(id2)].get_node("Path3").text = String(tile.path_3)
				if tile.tile_str == "MS":
					game.mineral_capacity += tile.mineral_cap_upgrade
				game.HUD.refresh()
			remove_child(time_bar)
			time_bars.erase(time_bar_obj)
		if progress < 0:
			var coll_date = tile.collect_date
			tile.collect_date = curr_time - (curr_time - coll_date) * tile.overclock_mult
			tile.erase("overclock_date")
			tile.erase("overclock_length")
			tile.erase("overclock_mult")
			remove_child(time_bar)
			time_bars.erase(time_bar_obj)
	for rsrc_obj in rsrcs:
		var tile = game.tile_data[rsrc_obj.id]
		if tile.is_constructing:
			continue
		var rsrc = rsrc_obj.node
		update_rsrc(rsrc, tile)

func update_rsrc(rsrc, tile):
	var curr_time = OS.get_system_time_msecs()
	match tile.tile_str:
		"ME", "PP":
			#Number of seconds needed per mineral
			var prod = 1 / tile.path_1_value
			if tile.has("overclock_mult"):
				prod /= tile.overclock_mult
			var cap = tile.path_2_value
			var stored = tile.stored
			var c_d = tile.collect_date
			var c_t = curr_time
			var current_bar = rsrc.get_node("Control/CurrentBar")
			var capacity_bar = rsrc.get_node("Control/CapacityBar")
			if stored < cap:
				current_bar.value = min((c_t - c_d) / (prod * 1000), 1)
				capacity_bar.value = min(stored / float(cap), 1)
				if c_t - c_d > prod * 1000:
					tile.stored += 1
					tile.collect_date += prod * 1000
			else:
				current_bar.value = 0
				capacity_bar.value = 1
			rsrc.get_node("Control/Label").text = String(stored)
		"RL":
			var prod = 1 / tile.path_1_value
			if tile.has("overclock_mult"):
				prod /= tile.overclock_mult
			var stored = tile.stored
			var c_d = tile.collect_date
			var c_t = curr_time
			var current_bar = rsrc.get_node("Control/CurrentBar")
			current_bar.value = min((c_t - c_d) / (prod * 1000), 1)
			if c_t - c_d > prod * 1000:
				tile.stored += 1
				tile.collect_date += prod * 1000
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
				rsrc.get_node("Control/Label").text = "%s kg " % [prod_i.qty_made]
				rsrc.get_node("Control/CapacityBar").value = prod_i.progress
			else:
				rsrc.get_node("Control/Label").text = ""
				rsrc.get_node("Control/CapacityBar").value = 0

func construct(st:String, costs:Dictionary):
	finish_construct()
	bldg_to_construct = st
	constr_costs = costs
	shadow = Sprite.new()
	shadow.texture = load("res://Graphics/Buildings/" + st + ".png")
	shadow.scale *= 0.4
	shadow.modulate.a = 0.5
	add_child(shadow)

func finish_construct():
	if shadow:
		bldg_to_construct = ""
		remove_child(shadow)
		shadow = null

func _on_Planet_tree_exited():
	queue_free()

func collect_all():
	var i:int
	for tile in game.tile_data:
		if tile:
			collect_rsrc(tile, i)
		i += 1
	game.HUD.refresh()
