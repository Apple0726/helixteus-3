extends Node2D

onready var time_scene = load("res://Scenes/TimeLeft.tscn")
onready var rsrc_scene = load("res://Scenes/ResourceStocked.tscn")
onready var particles_scene = load("res://Scenes/LiquidParticles.tscn")
onready var game = get_node("/root/Game")
onready var view = game.view
onready var id = game.c_p
onready var p_i = game.planet_data[id]
onready var id_offset = p_i.tile_id_start

#If true, clicking any tile initiates mining
var about_to_mine:bool = false
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

onready var wid:int = round(pow(p_i.tile_num, 0.5))
#A rectangle enclosing all tiles
onready var planet_bounds:PoolVector2Array = [Vector2.ZERO, Vector2(0, wid * 200), Vector2(wid * 200, wid * 200), Vector2(wid * 200, 0)]

func _ready():
	if p_i.has("lake_1"):
		var phase_1_scene = load("res://Scenes/PhaseDiagrams/" + p_i.lake_1 + ".tscn")
		var phase_1 = phase_1_scene.instance()
		$Lakes1.modulate = phase_1.colors[Helper.get_state(p_i.temperature, p_i.pressure, phase_1)]
	if p_i.has("lake_2"):
		var phase_2_scene = load("res://Scenes/PhaseDiagrams/" + p_i.lake_2 + ".tscn")
		var phase_2 = phase_2_scene.instance()
		$Lakes2.modulate = phase_2.colors[Helper.get_state(p_i.temperature, p_i.pressure, phase_2)]
	for i in wid:
		for j in wid:
			if p_i.temperature > 1000:
				$TileMap.set_cell(i, j, 8)
			else:
				$TileMap.set_cell(i, j, p_i.type - 3)
			var id2 = i % wid + j * wid + id_offset
			var tile = game.tile_data[id2]
			if tile.tile_str == "rock":
				$Obstacles.set_cell(i, j, 0)
			elif tile.tile_str == "cave":
				$Obstacles.set_cell(i, j, 1)
			if tile.has("type"):
				match tile.type:
					"plant":
						$Soil.set_cell(i, j, 0)
						if tile.tile_str != "":
							add_plant(id2, tile.tile_str)
					"bldg":
						add_bldg(id2, tile.tile_str)
	if p_i.has("lake_1"):
		for i in wid:
			for j in wid:
				var tile = game.tile_data[i % wid + j * wid + id_offset]
				var lake = tile.tile_str.split("_")
				if len(lake) == 3 and lake[2] != "1":
					continue
				if lake[0] == "liquid":
					$Lakes1.set_cell(i, j, 2)
					add_particles(Vector2(i*200, j*200))
				elif lake[0] == "solid":
					$Lakes1.set_cell(i, j, 0)
				elif lake[0] == "supercritical":
					$Lakes1.set_cell(i, j, 1)
	if p_i.has("lake_2"):
		for i in wid:
			for j in wid:
				var tile = game.tile_data[i % wid + j * wid + id_offset]
				var lake = tile.tile_str.split("_")
				if len(lake) == 3 and lake[2] != "2":
					continue
				if lake[0] == "liquid":
					add_particles(Vector2(i*200, j*200))
					$Lakes2.set_cell(i, j, 2)
				elif lake[0] == "solid":
					$Lakes2.set_cell(i, j, 0)
				elif lake[0] == "supercritical":
					$Lakes2.set_cell(i, j, 1)
	$Lakes1.update_bitmask_region()
	$Lakes2.update_bitmask_region()
	$Soil.update_bitmask_region()

func add_particles(pos:Vector2):
	var particle = particles_scene.instance()
	particle.position = pos + Vector2(30, 30)
	add_child(particle)

func show_tooltip(tile):
	var strs = tile.tile_str.split("_")
	var tooltip:String = ""
	var icons = []
	var adv = false
	if tile.has("type"):
		if tile.type == "bldg":
			var mult = 1
			if tile.has("overclock_mult"):
				mult = tile.overclock_mult
			match strs[0]:
				"ME":
					tooltip = tr("EXTRACTS_X") % [(Data.path_1[tile.tile_str].desc + "\n" + Data.path_2[tile.tile_str].desc) % [tile.path_1_value * mult, tile.path_2_value]]
					icons = [Data.icons.ME, Data.icons.ME]
					adv = true
				"PP":
					tooltip = tr("GENERATES_X") % [(Data.path_1[tile.tile_str].desc + "\n" + Data.path_2[tile.tile_str].desc) % [tile.path_1_value * mult, tile.path_2_value]]
					icons = [Data.icons.PP, Data.icons.PP]
					adv = true
				"RL":
					tooltip = tr("PRODUCES_X") % [(Data.path_1[tile.tile_str].desc) % [tile.path_1_value * mult]]
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
			if tile.tile_str == "":
				if game.help.plant_something_here:
					tooltip = tr("PLANT_STH") + "\n" + tr("HIDE_HELP")
					game.help_str = "plant_something_here"
			else:
				tooltip = Helper.get_plant_name(tile.tile_str)
				if OS.get_system_time_msecs() >= tile.construction_date + tile.construction_length:
					tooltip += "\n" + tr("CLICK_TO_HARVEST")
		elif tile.type == "lake":
			match strs[0]:
				"liquid":
					tooltip = tr("LAKE_CONTENTS").format({"state":tr("LIQUID"), "contents":tr(strs[1].to_upper())})
				"solid":
					tooltip = tr("LAKE_CONTENTS").format({"state":tr("SOLID"), "contents":tr(strs[1].to_upper())})
				"supercritical":
					tooltip = tr("LAKE_CONTENTS").format({"state":tr("SUPERCRITICAL"), "contents":tr(strs[1].to_upper())})
		elif tile.type == "obstacle":
			match strs[0]:
				"rock":
					if game.help.boulder_desc:
						tooltip = tr("BOULDER_DESC") + "\n" + tr("HIDE_HELP")
						game.help_str = "boulder_desc"
				"cave":
					tooltip = tr("CAVE")
					if game.help.cave_desc:
						tooltip += "\n%s\n%s\n%s\n%s" % [tr("CAVE_DESC"), tr("HIDE_HELP"), tr("NUM_FLOORS") % game.cave_data[tile.cave_id].num_floors, tr("FLOOR_SIZE").format({"size":game.cave_data[tile.cave_id].floor_size})]
						game.help_str = "cave_desc"
					else:
						tooltip += "\n%s\n%s" % [tr("NUM_FLOORS") % game.cave_data[tile.cave_id].num_floors, tr("FLOOR_SIZE").format({"size":game.cave_data[tile.cave_id].floor_size})]
	elif tile.depth > 0:
		tooltip += tr("HOLE_DEPTH") + ": %s m" % [tile.depth]
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

var prev_tile_over = -1
func _input(event):
	if tile_over != -1:
		var tile = game.tile_data[tile_over + id_offset]
		if tile.has("type") and tile.type == "bldg":
			if Input.is_action_just_released("duplicate"):
				game.put_bottom_info(tr("STOP_CONSTRUCTION"))
				construct(tile.tile_str, Data.costs[tile.tile_str])
			if Input.is_action_just_released("upgrade"):
				game.add_upgrade_panel([tile_over + id_offset])
	if event is InputEventMouseMotion:
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
		var mouse_pos = to_local(event.position)
		var mouse_on_tiles = Geometry.is_point_in_polygon(mouse_pos, planet_bounds)
		var black_bg = game.get_node("PopupBackground").visible
		$WhiteRect.visible = mouse_on_tiles and not black_bg
		$WhiteRect.position.x = floor(mouse_pos.x / 200) * 200
		$WhiteRect.position.y = floor(mouse_pos.y / 200) * 200
		if mouse_on_tiles:
# warning-ignore:narrowing_conversion
			tile_over = int(mouse_pos.x / 200) % wid + floor(mouse_pos.y / 200) * wid
			if tile_over != prev_tile_over and not game.planet_HUD.on_button and not game.HUD.on_button and not game.item_cursor.visible and not black_bg:
				game.hide_tooltip()
				show_tooltip(game.tile_data[tile_over + id_offset])
			prev_tile_over = tile_over
		else:
			if tile_over != -1 and not game.planet_HUD.on_button and not game.HUD.on_button:
				game.hide_tooltip()
				tile_over = -1
				prev_tile_over = -1
			game.hide_adv_tooltip()
		if shadow:
			shadow.visible = mouse_on_tiles
			shadow.position.x = floor(mouse_pos.x / 200) * 200
			shadow.position.y = floor(mouse_pos.y / 200) * 200
			shadow.position += Vector2(100, 100)
	var placing_soil = game.HUD.get_node("Resources/Soil").visible
	if Input.is_action_just_released("left_click") and not view.dragged:
		var curr_time = OS.get_system_time_msecs()
		var mouse_pos = to_local(event.position)
		if not Geometry.is_point_in_polygon(mouse_pos, planet_bounds):
			return
		if len(game.panels) > 0:
			var i = 0
			while not game.panels[i].polygon:
				i += 1
			if Geometry.is_point_in_polygon(event.position, game.panels[i].polygon):
				return
		var x_pos = int(mouse_pos.x / 200)
		var y_pos = int(mouse_pos.y / 200)
		var tile_id = x_pos % wid + y_pos * wid
		var tile = game.tile_data[tile_id + id_offset]
		if not tile.has("type"):
			if bldg_to_construct != "":
				if game.check_enough(constr_costs):
					game.deduct_resources(constr_costs)
					tile.tile_str = bldg_to_construct
					if not game.show.minerals and tile.tile_str == "ME":
						game.show.minerals = true
					tile.is_constructing = true
					tile.construction_date = curr_time
					tile.construction_length = constr_costs.time * 1000
					tile.type = "bldg"
					tile.XP = round(constr_costs.money / 100.0)
					match bldg_to_construct:
						"ME", "PP":
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
					add_bldg(tile_id + id_offset, bldg_to_construct)
					add_time_bar(tile_id + id_offset, "bldg")
				else:
					game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.2)
			elif about_to_mine:
				game.get_node("Control/BottomInfo").visible = false
				game.c_t = tile_id + id_offset
				game.switch_view("mining")
			elif placing_soil:
				if game.check_enough({"soil":10}):
					game.deduct_resources({"soil":10})
					tile.type = "plant"
					$Soil.set_cell(x_pos, y_pos, 0)
					$Soil.update_bitmask_region()
				else:
					game.popup(tr("NOT_ENOUGH_SOIL"), 1.2)
		elif tile.type == "plant":
			if placing_soil:
				game.add_resources({"soil":10})
				tile.erase("type")
				$Soil.set_cell(x_pos, y_pos, -1)
				$Soil.update_bitmask_region()
			elif tile.tile_str == "":
				if game.item_to_use.type == "seeds":
					#Plants can't grow when not adjacent to lakes
					var check_lake = check_lake(tile_id)
					if check_lake[0]:
						tile.tile_str = game.item_to_use.name
						game.remove_items(game.item_to_use.name)
						game.item_to_use.num -= 1
						if game.item_to_use.num == 0:
							game.get_node("Control/BottomInfo").visible = false
						tile.construction_date = curr_time
						tile.construction_length = game.craft_agric_info[game.item_to_use.name].grow_time
						if check_lake[1] == "liquid":
							tile.construction_length /= 2
						elif check_lake[1] == "supercritical":
							tile.construction_length /= 4
						tile.is_growing = true
						add_plant(tile_id + id_offset, game.item_to_use.name)
						game.update_item_cursor()
						game.get_node("PlantingSounds/%s" % [Helper.rand_int(1,3)]).play()
					else:
						game.popup(tr("NOT_ADJACENT_TO_LAKE") % [game.craft_agric_info[game.item_to_use.name].lake], 2)
			else:#When clicking a planted crop
				if curr_time >= tile.construction_length + tile.construction_date:
					game.mets[Helper.get_plant_produce(tile.tile_str)] += game.craft_agric_info[tile.tile_str].produce
					tile.tile_str = ""
					remove_child(plant_sprites[String(tile_id + id_offset)])
				elif game.item_to_use.type == "fertilizer":
					tile.construction_date -= game.craft_agric_info.fertilizer.speed_up_time
					game.remove_items("fertilizer")
					game.item_to_use.num -= 1
					game.update_item_cursor()
		elif tile.type == "bldg":
			if game.item_to_use.type == "speedup":
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
			elif game.item_to_use.type == "overclock" and overclockable(tile.tile_str) and not tile.is_constructing:
				tile.overclock_date = curr_time
				if not tile.has("overclock_mult"):
					tile.overclock_length = game.overclock_info[game.item_to_use.name].duration
					tile.overclock_mult = game.overclock_info[game.item_to_use.name].mult
					var coll_date = tile.collect_date
					tile.collect_date = curr_time - (curr_time - coll_date) / tile.overclock_mult
					add_time_bar(tile_id + id_offset, "overclock")
				game.remove_items(game.item_to_use.name)
				game.item_to_use.num -= 1
				game.update_item_cursor()
			else:
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
					"RCC":
						if not tile.is_constructing:
							game.c_t = tile_id + id_offset
							game.toggle_panel(game.RC_panel)
		elif tile.type == "obstacle":
			if tile.tile_str == "cave":
				if not rover_selected.empty():
					game.c_t = tile_id + id_offset
					game.switch_view("cave")
					game.cave.rover_data = rover_selected
					game.cave.set_rover_data()
	if Input.is_action_just_released("right_click"):
		about_to_mine = false
		finish_construct()
		placing_soil = false
		game.item_to_use.num = 0
		game.update_item_cursor()
		game.HUD.get_node("Resources/Soil").visible = false

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
					var id2 = i % wid + j * wid + id_offset
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
	var local_id = id2 - id_offset
	var v = Vector2.ZERO
	v.x = (local_id % wid) * 200
	v.y = floor(local_id / wid) * 200
	v += Vector2(100, 15)
	var time_bar = time_scene.instance()
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
	var local_id = id2 - id_offset
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
	var local_id = id2 - id_offset
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
	return bldg == "ME" or bldg == "PP" or bldg == "RL"

func on_path_enter(path:String, tile):
	game.hide_adv_tooltip()
	game.show_tooltip("%s %s %s %s" % [tr("PATH"), path, tr("LEVEL"), tile["path_" + path]])

func on_path_exit():
	game.hide_tooltip()

func add_rsrc(v:Vector2, mod:Color, icon, id2:int):
	var rsrc = rsrc_scene.instance()
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
			plant.frame = int(progress * 4)
		if progress > 1:
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
