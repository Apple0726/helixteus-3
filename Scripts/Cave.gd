extends Node2D

var astar_node = AStar2D.new()
const DEF_EXPO = 0.7

onready var game = get_node("/root/Game")
onready var p_i = game.planet_data[game.c_p]
onready var tile_type = p_i.type - 3
onready var tile = game.tile_data[game.c_t]
onready var aurora = tile.has("aurora")
#Aurora intensity
onready var au_int:float = tile.aurora.au_int if aurora else 0
onready var aurora_mult:float = game.clever_round(pow(1 + au_int, 1.5), 3)
onready var difficulty:float = game.system_data[game.c_s].diff * aurora_mult

onready var cave = $TileMap
onready var cave_wall = $Walls
onready var minimap_cave = $UI/Minimap/TileMap
onready var minimap_rover = $UI/Rover
onready var MM_hole = $UI/Minimap/Hole
onready var MM_exit = $UI/Minimap/Exit
onready var MM = $UI/Minimap
onready var rover = $Rover
onready var rover_light = $Rover/Light2D
onready var camera = $Camera2D
onready var exit = $Exit
onready var hole = $Hole
onready var inventory_slots = $UI2/InventorySlots
onready var ray = $Rover/RayCast2D
onready var mining_laser = $Rover/MiningLaser
onready var mining_p = $MiningParticles
onready var tile_highlight = $TileHighlight
onready var canvas_mod = $CanvasModulate
onready var aurora_mod = $AuroraModulate
onready var slot_scene = preload("res://Scenes/InventorySlot.tscn")
onready var HX1_scene = preload("res://Scenes/HX/HX1.tscn")
onready var deposit_scene = preload("res://Scenes/Cave/MetalDeposit.tscn")
onready var enemy_icon_scene = preload("res://Graphics/Cave/MMIcons/Enemy.png")
onready var object_scene = preload("res://Scenes/Cave/Object.tscn")
onready var sq_bar_scene = preload("res://Scenes/SquareBar.tscn")

var minimap_zoom:float = 0.02
var minimap_center:Vector2 = Vector2(1150, 128)
var curr_slot:int = 0
var floor_seeds = []
var id:int#Cave id
var rover_data:Dictionary = {}
var cave_data:Dictionary
var light_amount:float = 1.0
var dont_gen_anything:bool = false
var wormhole

var velocity = Vector2.ZERO
var max_speed = 1000
var acceleration = 12000
var friction = 12000
var rover_size = 1.0

#Rover stats
var atk:float = 5.0
var def:float = 5.0
var HP:float = 20.0
var total_HP:float = 20.0
var speed_mult:float = 1.0
var inventory:Array
var inventory_ready:Array = []#For cooldowns
var i_w_w:Dictionary = {}#inventory_with_weight
var weight:float = 0.0
var weight_cap:float = 1500.0

var moving_fast:bool = false
var cave_floor:int = 1
var num_floors:int
var cave_size:int
var tiles:PoolVector2Array
var rooms:Array = []
var HX_tiles:Array = []#Tile ids occupied by HX
var deposits:Dictionary = {}#Random metal/material deposits
var chests:Dictionary = {}#Random chests and their contents
var active_chest:String = "-1"#Chest id of currently active chest (rover is touching it)
var active_type:String = ""
var tiles_touched_by_laser:Dictionary = {}

### Cave save data ###

var seeds = []
var tiles_mined:Array = []#Contains data of mined tiles so they don't show up again when regenerating floor
var enemies_rekt:Array = []#idem
var chests_looted:Array = []
var partially_looted_chests:Array = []
var hole_exits:Array = []#id of hole and exit on each floor

### End cave save data ###

func _ready():
	id = game.tile_data[game.c_t].cave.id
	cave_data = game.cave_data[id]
	num_floors = cave_data.num_floors
	cave_size = cave_data.floor_size
	if cave_data.has("enemies_rekt"):
		seeds = cave_data.seeds
		tiles_mined = cave_data.tiles_mined
		enemies_rekt = cave_data.enemies_rekt
		chests_looted = cave_data.chests_looted
		partially_looted_chests = cave_data.partially_looted_chests
		hole_exits = cave_data.hole_exits
	minimap_rover.position = minimap_center
	minimap_cave.scale *= minimap_zoom
	minimap_rover.scale *= 0.1
	generate_cave(true, false)
	if cave_data.has("special_cave") and cave_data.special_cave in [1, 3]:
		$UI/Error.visible = true
		$UI/Minimap.visible = false
	if game.help.cave_controls:
		$UI2/Controls.visible = true
		game.help_str = "cave_controls"
		$UI2/Controls.text = "%s\n%s" % [tr("CAVE_CONTROLS"), tr("HIDE_HELP")]
	if not game.objective.empty() and game.objective.id == 2:
		game.objective = {"type":game.ObjectiveType.MINE, "id":3, "current":0, "goal":3}
	if aurora:
		$AuroraPlayer.play("Aurora", -1, 0.2)

func set_rover_data():
	HP = rover_data.HP
	total_HP = rover_data.HP
	atk = rover_data.atk
	def = rover_data.def
	speed_mult = rover_data.spd
	weight_cap = rover_data.weight_cap
	inventory = rover_data.inventory
	i_w_w = rover_data.i_w_w
	for w in i_w_w:
		weight += i_w_w[w]
	for i in len(inventory):
		inventory_ready.append(true)
	for i in range(0, len(inventory)):
		var slot = slot_scene.instance()
		inventory_slots.add_child(slot)
		var rsrc = inventory[i].type
		slots.append(slot)
		if rsrc == "":
			continue
		if rsrc == "rover_weapons":
			slot.get_node("TextureRect").texture = load("res://Graphics/Cave/Weapons/" + inventory[i].name + ".png")
		elif rsrc == "rover_mining":
			slot.get_node("TextureRect").texture = load("res://Graphics/Cave/Mining/" + inventory[i].name + ".png")
		else:
			slot.get_node("TextureRect").texture = load("res://Graphics/%s/%s.png" % [Helper.get_dir_from_name(inventory[i].name), inventory[i].name])
			if inventory[i].has("num"):
				slot.get_node("Label").text = Helper.format_num(inventory[i].num, 3)
	set_border(curr_slot)
	$UI2/HP/Bar.max_value = total_HP
	$Rover/Bar.max_value = total_HP
	$UI2/Inventory/Bar.max_value = weight_cap
	$UI2/Inventory/Bar.value = weight
	update_health_bar(total_HP)
	$UI2/Inventory/Label.text = "%s / %s kg" % [round(weight), weight_cap]
	if game.help.sprint_mode and speed_mult > 1:
		game.long_popup(tr("PRESS_E_TO_SPRINT"), tr("SPRINT_MODE"))
		game.help.sprint_mode = false

func remove_cave():
	astar_node.clear()
	rooms.clear()
	tiles = []
	HX_tiles.clear()
	active_type = ""
	cave.clear()
	cave_wall.clear()
	minimap_cave.clear()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.remove_from_group("enemies")
		remove_child(enemy)
		enemy.free()
	for object in get_tree().get_nodes_in_group("misc_objects"):
		object.remove_from_group("misc_objects")
		remove_child(object)
		object.free()
	for light in get_tree().get_nodes_in_group("lights"):
		light.remove_from_group("lights")
		remove_child(light)
		light.free()
	for enemy_icon in get_tree().get_nodes_in_group("enemy_icons"):
		enemy_icon.remove_from_group("enemy_icons")
		MM.remove_child(enemy_icon)
		enemy_icon.free()
	for proj in get_tree().get_nodes_in_group("projectiles"):
		proj.remove_from_group("projectiles")
		if is_a_parent_of(proj):
			remove_child(proj)
			proj.free()
	for deposit in deposits:
		remove_child(deposits[deposit])
		deposits[deposit].free()
	for chest_str in chests:
		remove_child(chests[chest_str].node)
		chests[chest_str].node.free()
	for tile in tiles_touched_by_laser:
		remove_child(tiles_touched_by_laser[tile].bar)
		tiles_touched_by_laser[tile].bar.free()
	tiles_touched_by_laser.clear()
	chests.clear()
	deposits.clear()

func generate_cave(first_floor:bool, going_up:bool):
	$UI2/CaveInfo/Difficulty.text = "%s: %s" % [tr("DIFFICULTY"), game.clever_round(difficulty, 3)]
	var rng = RandomNumberGenerator.new()
	$UI2/CaveInfo/Floor.text = "B%sF" % [cave_floor]
	var noise = OpenSimplexNoise.new()
	var first_time:bool = cave_floor > len(seeds)
	if first_time:
		var sd = randi()
		rng.set_seed(sd)
		noise.seed = sd
		seeds.append(sd)
		tiles_mined.append([])
		enemies_rekt.append([])
		chests_looted.append([])
		partially_looted_chests.append({})
		hole_exits.append({"hole":-1, "exit":-1})
	else:
		rng.set_seed(seeds[cave_floor - 1])
		noise.seed = seeds[cave_floor - 1]
	noise.octaves = 1
	if cave_size == 20 and num_floors == 3:
		noise.period = 20
	elif cave_data.has("special_cave"):
		if cave_data.special_cave == 3:
			noise.period = 35
		elif cave_data.special_cave == 2:
			noise.period = 150
		elif cave_data.special_cave == 1:
			if cave_floor == 30:
				noise.period = 65
				cave_size = 16
			else:
				noise.period = 50 - cave_floor
				cave_size = 16 + cave_floor / 2
		else:
			noise.period = 65
			$Camera2D.zoom = Vector2.ONE
			$Rover.scale = Vector2(0.4, 0.4)
			rover_size = 0.4
	else:
		noise.period = 65
	dont_gen_anything = cave_data.has("special_cave") and cave_data.special_cave == 1
	#Generate cave
	for i in cave_size:
		for j in cave_size:
			var level = noise.get_noise_2d(i * 10.0, j * 10.0)
			var tile_id:int = get_tile_index(Vector2(i, j))
			cave.set_cell(i, j, tile_type)
			if level > 0:
				minimap_cave.set_cell(i, j, tile_type)
				tiles.append(Vector2(i, j))
				astar_node.add_point(tile_id, Vector2(i, j))
				if not dont_gen_anything and rng.randf() < 0.005 * min(5, cave_floor):
					var HX = HX1_scene.instance()
					var HX_node = HX.get_node("HX")
					HX_node.set_script(load("res://Scripts/HXs_Cave/HX%s.gd" % [rng.randi_range(1, 4)]))
					HX_node.HP = round(10 * pow(difficulty, 0.8) * rng.randf_range(0.8, 1.2))
					HX_node.atk = round(6 * difficulty * rng.randf_range(0.9, 1.1))
					HX_node.def = round(6 * pow(difficulty, 0.85) * rng.randf_range(0.9, 1.1))
					if enemies_rekt[cave_floor - 1].has(tile_id):
						HX.free()
						continue
					HX.get_node("Info").visible = false
					HX_node.total_HP = HX_node.HP
					HX_node.cave_ref = self
					HX_node.a_n = astar_node
					HX_node.cave_tm = cave
					HX_node.spawn_tile = tile_id
					HX.add_to_group("enemies")
					HX.position = Vector2(i, j) * 200 + Vector2(100, 100)
					add_child(HX)
					HX_tiles.append(tile_id)
					var enemy_icon = Sprite.new()
					enemy_icon.scale *= 0.08
					enemy_icon.texture = enemy_icon_scene
					MM.add_child(enemy_icon)
					HX_node.MM_icon = enemy_icon
					enemy_icon.add_to_group("enemy_icons")
			else:
				cave_wall.set_cell(i, j, 0)
				if not dont_gen_anything:
					var rand:float = rng.randf()
					var rand2:float = rng.randf()
					var ch = 0.02 * pow(pow(2, cave_floor - 1) / 3.0, 0.4)
					if rand < ch:
						var met_spawned:String = "lead"
						for met in game.met_info:
							var rarity = game.met_info[met].rarity
							if rarity > difficulty:
								break
							if rand2 < 1 / (rarity + 1):
								met_spawned = met
						if met_spawned != "":
							var deposit = deposit_scene.instance()
							deposit.rsrc_texture = game.metal_textures[met_spawned]
							deposit.rsrc_name = met_spawned
							deposit.amount = int(rng.randf_range(0.1, 0.15) * game.met_info[met_spawned].amount * min(5, pow(difficulty, 0.3)))
							add_child(deposit)
							deposit.position = cave_wall.map_to_world(Vector2(i, j))
							deposits[String(tile_id)] = deposit
	#Add unpassable tiles at the cave borders
	for i in range(-1, cave_size + 1):
		cave_wall.set_cell(i, -1, 1)
	for i in range(-1, cave_size + 1):
		cave_wall.set_cell(i, cave_size, 1)
	for i in range(-1, cave_size + 1):
		cave_wall.set_cell(-1, i, 1)
	for i in range(-1, cave_size + 1):
		cave_wall.set_cell(cave_size, i, 1)
	#tiles = cave_wall.get_used_cells_by_id(-1)
	for tile in tiles:#tile is a Vector2D
		connect_points(tile)
	var tiles_remaining = astar_node.get_points()
	#Create rooms for logic that uses the size of rooms
	while tiles_remaining != []:
		var room = get_connected_tiles(tiles_remaining[0])
		for tile_index in room:
			tiles_remaining.erase(tile_index)
		rooms.append({"tiles":room, "size":len(room)})
	rooms.sort_custom(self, "sort_size")
	#Generate treasure chests
	if not dont_gen_anything:
		for room in rooms:
			var n = room.size
			for tile in room.tiles:
				var rand = rng.randf()
				var formula = 0.2 / pow(n, 0.9) * pow(cave_floor, 0.8)
				if rand < formula:
					var tier:int = int(clamp(pow(formula / rand * aurora_mult, 0.2), 1, 5))
					var contents:Dictionary = generate_treasure(tier, rng)
					if contents.empty() or chests_looted[cave_floor - 1].has(int(tile)):
						continue
					if partially_looted_chests[cave_floor - 1].has(String(tile)):
						contents = partially_looted_chests[cave_floor - 1][String(tile)].duplicate(true)
					var chest = object_scene.instance()
					if tier == 1:
						chest.modulate = Color(0.83, 0.4, 0.27, 1.0)
					elif tier == 2:
						chest.modulate = Color(0, 0.79, 0.0, 1.0)
					elif tier == 3:
						chest.modulate = Color(0, 0.5, 0.79, 1.0)
					elif tier == 4:
						chest.modulate = Color(0.7, 0, 0.79, 1.0)
					elif tier == 5:
						chest.modulate = Color(0.85, 1.0, 0, 1.0)
					chest.get_node("Sprite").texture = load("res://Graphics/Cave/Objects/Chest.png")
					chest.get_node("Area2D").connect("body_entered", self, "on_chest_entered", [String(tile)])
					chest.get_node("Area2D").connect("body_exited", self, "on_chest_exited")
					chest.scale *= 0.8
					chest.position = cave.map_to_world(get_tile_pos(tile)) + Vector2(100, 100)
					chests[String(tile)] = {"node":chest, "contents":contents, "tier":tier}
					add_child(chest)
	#Remove already-mined tiles
	for i in cave_size:
		for j in cave_size:
			var tile_id:int = get_tile_index(Vector2(i, j))
			if tiles_mined[cave_floor - 1].has(tile_id):
				cave.set_cell(i, j, tile_type)
				minimap_cave.set_cell(i, j, tile_type)
				astar_node.add_point(tile_id, Vector2(i, j))
				cave_wall.set_cell(i, j, -1)
				if deposits.has(String(tile_id)):
					remove_child(deposits[String(tile_id)])
					deposits[String(tile_id)].queue_free()
					deposits.erase(String(tile_id))
	cave_wall.update_bitmask_region()
	#Assigns each enemy the room number they're in
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var _id = get_tile_index(cave.world_to_map(enemy.position))
		var i = 0
		for room in rooms:
			if _id in room.tiles:
				enemy.get_node("HX").room = i
			i += 1
	var pos:Vector2
	var rand_hole:int = rooms[0].tiles[rng.randi_range(0, len(rooms[0]) - 1)]
	var rand_spawn:int
	if first_time:
		rand_spawn = rand_hole
		hole_exits[cave_floor - 1].hole = rand_hole
	else:
		rand_hole = hole_exits[cave_floor - 1].hole
		rand_spawn = hole_exits[cave_floor - 1].exit
	if first_floor:
		#Determines the tile where the entrance will be. It has to be adjacent to an unpassable tile
		var spawn_edge_tiles = []
		var j = 0
		while len(spawn_edge_tiles) == 0:
			for tile_id in rooms[j].tiles:
				if first_time or tile_id == rand_spawn:
					var top = tile_id / cave_size == 0
					var left = tile_id % cave_size == 0
					var bottom = tile_id / cave_size == cave_size - 1
					var right = tile_id % cave_size == cave_size - 1
					if left:
						spawn_edge_tiles.append({"id":tile_id, "dir":-PI/2})
					elif right:
						spawn_edge_tiles.append({"id":tile_id, "dir":PI/2})
					elif top:
						spawn_edge_tiles.append({"id":tile_id, "dir":0})
					elif bottom:
						spawn_edge_tiles.append({"id":tile_id, "dir":PI})
			j += 1
		exit.get_node("Sprite").texture = load("res://Graphics/Cave/Objects/exit.png")
		exit.get_node("ExitColl").disabled = false
		var rot = spawn_edge_tiles[0].dir
		exit.get_node("GoUpColl").disabled = true
		var breaker:int = 0
		while rand_hole == rand_spawn and breaker < 10:
			breaker += 1
			var rand_id = rng.randi_range(0, len(spawn_edge_tiles) - 1)
			rand_spawn = spawn_edge_tiles[rand_id].id
			rot = spawn_edge_tiles[rand_id].dir
		pos = get_tile_pos(rand_spawn) * 200 + Vector2(100, 100)
		exit.rotation = rot
		MM_exit.rotation = rot
	else:
		MM_exit.rotation = 0
		exit.get_node("Sprite").texture = load("res://Graphics/Cave/Objects/go_up.png")
		exit.get_node("ExitColl").disabled = true
		exit.get_node("GoUpColl").disabled = false
		while rand_hole == rand_spawn:
			rand_spawn = get_tile_index(tiles[rng.randi_range(0, len(tiles) - 1)])
		pos = get_tile_pos(rand_spawn) * 200 + Vector2(100, 100)
	if cave_floor == num_floors:
		hole.get_node("CollisionShape2D").disabled = true
		hole.visible = false
		MM_hole.visible = false
	else:
		hole.get_node("CollisionShape2D").disabled = false
		hole.visible = true
		MM_hole.visible = true
	#No treasure chests at spawn/hole
	if chests.has(String(rand_hole)):
		remove_child(chests[String(rand_hole)].node)
		chests[String(rand_hole)].node.queue_free()
		chests.erase(String(rand_hole))
	if chests.has(String(rand_spawn)):
		remove_child(chests[String(rand_spawn)].node)
		chests[String(rand_spawn)].node.queue_free()
		chests.erase(String(rand_spawn))
	#A way to check whether cave has the relic for 2nd ship
	if cave_size == 20 and num_floors == 3 and cave_floor == 3:
		var relic = object_scene.instance()
		relic.get_node("Sprite").texture = load("res://Graphics/Cave/Objects/Relic.png")
		relic.get_node("Area2D").connect("body_entered", self, "on_relic_entered")
		relic.get_node("Area2D").connect("body_exited", self, "on_relic_exited")
		var relic_tile = rooms[0].tiles[-1]
		relic.position = cave.map_to_world(get_tile_pos(relic_tile)) + Vector2(100, 100)
		add_child(relic)
		relic.add_to_group("misc_objects")
	
	#Wormhole
	if cave_floor == num_floors:
		wormhole = object_scene.instance()
		wormhole.get_node("Sprite").texture = null
		var wormhole_texture = load("res://Scenes/Wormhole.tscn").instance()
		wormhole.add_child(wormhole_texture)
		wormhole.get_node("Area2D").connect("body_entered", self, "on_WH_entered")
		wormhole.get_node("Area2D").connect("body_exited", self, "_on_body_exited")
		var wormhole_tile = rooms[0].tiles[1]
		wormhole.position = cave.map_to_world(get_tile_pos(wormhole_tile)) + Vector2(100, 100)
		add_child(wormhole)
		add_light(wormhole)
	else:
		if wormhole:
			remove_child(wormhole)
			wormhole.free()
	
	#A map is hidden on the first 8th floor of the cave you reach in a galaxy outside Milky Way
	if len(game.ship_data) == 2 and game.c_g_g != 0 and game.c_c_g == 0:
		if cave_data.has("special_cave") and not game.third_ship_hints.parts[cave_data.special_cave] and cave_floor == num_floors:
			var part = object_scene.instance()
			part.get_node("Sprite").texture = load("res://Graphics/Cave/Objects/ShipPart.png")
			part.get_node("Area2D").connect("body_entered", self, "on_ShipPart_entered")
			var part_tile = rooms[0].tiles[0]
			part.position = cave.map_to_world(get_tile_pos(part_tile)) + Vector2(100, 100)
			add_child(part)
			part.add_to_group("misc_objects")
			add_light(part)
		if game.third_ship_hints.has("map_found_at") and cave_floor == 8 and (game.third_ship_hints.map_found_at in [-1, id]) and game.third_ship_hints.spawn_galaxy == game.c_g:
			var map = object_scene.instance()
			map.get_node("Sprite").texture = load("res://Graphics/Cave/Objects/Map.png")
			map.get_node("Area2D").connect("body_entered", self, "on_map_entered")
			map.get_node("Area2D").connect("body_exited", self, "on_map_exited")
			var map_tile:Vector2
			if game.third_ship_hints.map_found_at == -1:
				map_tile = pos
				if map_tile.x < 400:
					map_tile.x += 400
				elif map_tile.x > cave_size * 200 - 400:
					map_tile.x -= 400
				else:
					map_tile.x += sign(rand_range(-1, 1)) * 400
				if map_tile.y < 400:
					map_tile.y += 400
				elif map_tile.y > cave_size * 200 - 400:
					map_tile.y -= 400
				else:
					map_tile.y += sign(rand_range(-1, 1)) * 400
				game.third_ship_hints.map_found_at = id
				game.third_ship_hints.map_pos = map_tile
			else:
				map_tile = game.third_ship_hints.map_pos
			$UI2/Ship2Map.refresh()
			map.position = map_tile
			add_child(map)
			add_light(map)
			map.add_to_group("misc_objects")
			cave.set_cellv(cave.world_to_map(map_tile), tile_type)
			cave_wall.set_cellv(cave_wall.world_to_map(map_tile), -1)
			minimap_cave.set_cellv(minimap_cave.world_to_map(map_tile), tile_type)
			cave_wall.update_bitmask_region()
			var st = String(get_tile_index(cave.world_to_map(map_tile)))
			if deposits.has(st):
				var deposit = deposits[st]
				remove_child(deposit)
				deposits.erase(st)
				deposit.free()
		
	var hole_pos = get_tile_pos(rand_hole) * 200 + Vector2(100, 100)
	if first_time:
		hole_exits[cave_floor - 1].exit = rand_spawn
	hole.position = hole_pos
	MM_hole.position = hole_pos * minimap_zoom
	MM_exit.position = pos * minimap_zoom
	if going_up:
		rover.position = hole_pos
		camera.position = hole_pos
	else:
		rover.position = pos
		camera.position = pos
	exit.position = pos
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.get_node("HX").set_rand()

func add_light(node):
	#node.get_node("Light2D").enabled = true
	node.get_node("Shadow").visible = false
	
func on_chest_entered(_body, tile:String):
	var chest_rsrc = chests[tile].contents
	active_chest = tile
	active_type = "chest"
	var vbox = $UI2/Panel/VBoxContainer
	reset_panel_anim()
	for child in vbox.get_children():
		vbox.remove_child(child)
		child.free()
	var tier_txt = Label.new()
	tier_txt.align = Label.ALIGN_CENTER
	tier_txt.text = tr("TIER_X_CHEST") % [chests[tile].tier]
	vbox.add_child(tier_txt)
	Helper.put_rsrc(vbox, 32, chest_rsrc, false)
	var take_all = Label.new()
	take_all.align = Label.ALIGN_CENTER
	take_all.text = tr("TAKE_ALL")
	vbox.add_child(take_all)
	$UI2/Panel.visible = true
	$UI2/Panel.modulate.a = 1

func on_relic_entered(_body):
	$UI2/Relic.visible = true

func on_ShipPart_entered(_body):
	if not game.third_ship_hints.parts[cave_data.special_cave]:
		game.objective.current += 1
		game.popup(tr("SHIP_PART_FOUND"), 2.5)
		game.third_ship_hints.parts[cave_data.special_cave] = true
		for object in get_tree().get_nodes_in_group("misc_objects"):
			object.visible = false

func on_map_entered(_body):
	$UI2/Ship2Map.visible = true
	$UI2/Ship2Map/AnimationPlayer.play("Map fade")
	active_type = "map"
	show_right_info(tr("TAKE_ALL"))

func on_chest_exited(_body):
	active_chest = "-1"
	active_type = ""
	$UI2/Panel.visible = false

func on_relic_exited(_body):
	$UI2/Relic.visible = false

func on_map_exited(_body):
	$UI2/Ship2Map.visible = false
	$UI2/Panel.visible = false
	active_type = ""

func generate_treasure(tier:int, rng:RandomNumberGenerator):
	var contents = {	"money":round(rng.randf_range(1500, 1800) * pow(tier, 3.0) * pow(difficulty, 1.25)),
						"minerals":round(rng.randf_range(150, 250) * pow(tier, 3.0) * pow(difficulty, 1.2)),
						"hx_core":int(rng.randi_range(1, 5) * pow(tier, 1.5) * pow(difficulty, 0.3))}
	if contents.hx_core > 8:
		contents.hx_core2 = floor(contents.hx_core / 8.0)
		contents.hx_core %= 8
		if contents.hx_core == 0:
			contents.erase("hx_core")
	for met in game.met_info:
		var met_value = game.met_info[met]
		if met_value.rarity > difficulty:
			break
		if rng.randf() < 0.5 / met_value.rarity:
			contents[met] = game.clever_round(rng.randf_range(0.2, 0.35) * met_value.amount * pow(tier, 2.0) * pow(difficulty, 1.1), 3)
	return contents

func connect_points(tile:Vector2, bidir:bool = false):
	var tile_index = get_tile_index(tile)
	var neighbor_tiles = PoolVector2Array([
		tile + Vector2.RIGHT,
		tile + Vector2.LEFT,
		tile + Vector2.DOWN,
		tile + Vector2.UP,
		tile + Vector2.UP + Vector2.RIGHT,
		tile + Vector2.RIGHT + Vector2.DOWN,
		tile + Vector2.DOWN + Vector2.LEFT,
		tile + Vector2.LEFT + Vector2.UP,
	])
	for neighbor_tile in neighbor_tiles:
		var neighbor_tile_index = get_tile_index(neighbor_tile)
		if not astar_node.has_point(neighbor_tile_index):
			continue
		if cave_wall.get_cellv(neighbor_tile) == -1:
			astar_node.connect_points(tile_index, neighbor_tile_index, bidir)

func update_health_bar(_HP):
	HP = _HP
	if HP <= 0:
		for inv in inventory:
			if inv.has("num"):
				inv.num /= 2
		for w in i_w_w:
			i_w_w[w] /= 2
		var st = tr("ROVER_REKT")
		if randf() < 0.01:
			st = st.replace("wrecked", "rekt")
		exit_cave()
		game.long_popup(st, tr("ROVER_REKT_TITLE"))
	$UI2/HP/Bar.value = HP
	$Rover/Bar.value = HP
	$UI2/HP/Label.text = "%s / %s" % [ceil(HP), total_HP]

var mouse_pos = Vector2.ZERO
var tile_highlighted:int = -1

func update_ray():
	ray.enabled = inventory[curr_slot].type == "rover_mining"
	if ray.enabled:
		var laser_reach = Data.rover_mining[inventory[curr_slot].name].rnge
		ray.cast_to = (mouse_pos - rover.position).normalized() * laser_reach
		var coll = ray.get_collider()
		var holding_left_click = Input.is_action_pressed("left_click")
		if coll is TileMap:
			var pos = ray.get_collision_point() + ray.cast_to / 200.0
			laser_reach = rover.position.distance_to(pos) / rover_size
			tile_highlighted = get_tile_index(cave_wall.world_to_map(pos))
			var is_minable = cave_wall.get_cellv(cave_wall.world_to_map(pos)) == 0
			if tile_highlighted != -1 and is_minable:
				tile_highlight.visible = true
				tile_highlight.position.x = floor(pos.x / 200) * 200 + 100
				tile_highlight.position.y = floor(pos.y / 200) * 200 + 100
				mining_p.emitting = holding_left_click
				if holding_left_click:
					mining_p.position = pos
			else:
				mining_p.emitting = false
				tile_highlighted = -1
		else:
			tile_highlighted = -1
			tile_highlight.visible = false
			mining_p.emitting = false
		mining_laser.visible = holding_left_click
		if holding_left_click:
			mining_laser.region_rect.end = Vector2(laser_reach, 16)
			mining_laser.rotation = atan2(mouse_pos.y - rover.position.y, mouse_pos.x - rover.position.x)
	else:
		mining_laser.visible = false
		mining_p.emitting = false
		tile_highlight.visible = false

var global_mouse_pos = Vector2.ZERO

func _input(event):
	if event is InputEventMouseMotion:
		global_mouse_pos = event.position
		mouse_pos = global_mouse_pos + camera.position - Vector2(640, 360)
		update_ray()
	else:
		if event.is_action_released("scroll_up"):
			curr_slot -= 1
			if curr_slot < 0:
				curr_slot = len(inventory) - 1
			set_border(curr_slot)
		if event.is_action_released("scroll_down"):
			curr_slot += 1
			if curr_slot >= len(inventory):
				curr_slot = 0
			set_border(curr_slot)
		if Input.is_action_just_released("M"):
			if not $UI/Error.visible:
				$UI/Minimap.visible = not $UI/Minimap.visible
			$UI/Rover.visible = not $UI/Rover.visible
			$UI/MinimapBG.visible = not $UI/MinimapBG.visible
		elif Input.is_action_just_released("1") and curr_slot != 0:
			curr_slot = 0
			set_border(curr_slot)
		elif Input.is_action_just_released("2") and curr_slot != 1:
			curr_slot = 1
			set_border(curr_slot)
		elif Input.is_action_just_released("3") and curr_slot != 2:
			curr_slot = 2
			set_border(curr_slot)
		elif Input.is_action_just_released("4") and curr_slot != 3:
			curr_slot = 3
			set_border(curr_slot)
		elif Input.is_action_just_released("5") and curr_slot != 4:
			curr_slot = 4
			set_border(curr_slot)
		if Input.is_action_just_released("E"):
			moving_fast = not moving_fast
			if moving_fast:
				$AnimationPlayer.play("RoverSprint")
			else:
				$AnimationPlayer.play_backwards("RoverSprint")
		if Input.is_action_just_released("F"):
			if active_type == "chest":
				var remainders = {}
				var contents = chests[active_chest].contents
				for rsrc in contents:
					var has_weight = true
					for item_group in game.item_groups:
						if item_group.dict.has(rsrc):
							has_weight = false
					if rsrc == "money" or rsrc == "minerals":
						has_weight = false
					if has_weight:
						var remainder:float = round(add_weight_rsrc(rsrc, contents[rsrc]) * 100) / 100.0
						if remainder != 0:
							remainders[rsrc] = remainder
					else:
						for i in len(inventory):
							if inventory[i].has("name") and rsrc != inventory[i].name:
								if i == len(inventory) - 1:
									remainders[rsrc] = contents[rsrc]
								continue
							var slot = slots[i]
							if inventory[i].type == "":
								inventory[i].type = "item"
								inventory[i].name = rsrc
								slot.get_node("TextureRect").texture = load("res://Graphics/%s/%s.png" % [Helper.get_dir_from_name(rsrc), rsrc])
								slot.get_node("Label").text = Helper.format_num(contents[rsrc], 3)
								inventory[i].num = contents[rsrc]
							else:
								inventory[i].num += contents[rsrc]
								slot.get_node("Label").text = Helper.format_num(inventory[i].num, 3)
							break
				if not remainders.empty():
					chests[active_chest].contents = remainders.duplicate(true)
					partially_looted_chests[cave_floor - 1][String(active_chest)] = remainders.duplicate(true)
					Helper.put_rsrc($UI2/Panel/VBoxContainer, 32, remainders)
					$UI2/Panel.visible = true
					game.popup(tr("WEIGHT_INV_FULL_CHEST"), 1.7)
				else:
					var temp = active_chest
					remove_child(chests[active_chest].node)
					chests[temp].node.queue_free()
					chests.erase(temp)
					chests_looted[cave_floor - 1].append(int(temp))
			elif active_type == "exit":
				exit_cave()
			elif active_type == "go_down":
				remove_cave()
				cave_floor += 1
				difficulty *= 2
				if dont_gen_anything:
					if cave_floor < 19:
						light_amount = clamp((11 - cave_floor) * 0.1, 0.25, 1)
					else:
						light_amount = clamp((23 - cave_floor) * 0.05, 0, 0.2)
				else:
					light_amount = clamp((11 - cave_floor) * 0.1, 0.3, 1)
				rover_light.energy = (1 - light_amount) * 1.4
				rover_light.visible = true
				generate_cave(false, false)
			elif active_type == "go_up":
				remove_cave()
				cave_floor -= 1
				difficulty /= 2
				if dont_gen_anything:
					if cave_floor < 19:
						light_amount = clamp((11 - cave_floor) * 0.1, 0.25, 1)
					else:
						light_amount = clamp((20 - cave_floor) * 0.05, 0, 0.1)
				else:
					light_amount = clamp((11 - cave_floor) * 0.1, 0.3, 1)
				rover_light.energy = (1 - light_amount) * 1.4
				rover_light.visible = cave_floor != 1
				generate_cave(true if cave_floor == 1 else false, true)
			elif active_type == "map":
				game.third_ship_hints.erase("map_found_at")
				game.third_ship_hints.erase("map_pos")
				for object in get_tree().get_nodes_in_group("misc_objects"):
					object.remove_from_group("misc_objects")
					remove_child(object)
					object.free()
				game.long_popup(tr("MAP_COLLECTED_DESC"), tr("MAP_COLLECTED"))
			$UI2/Panel.visible = false
		if Input.is_action_just_released("minus"):
			minimap_zoom /= 1.5
			minimap_cave.scale = Vector2.ONE * minimap_zoom
			MM_hole.position /= 1.5
			MM_exit.position /= 1.5
		elif Input.is_action_just_released("plus"):
			minimap_zoom *= 1.5
			minimap_cave.scale = Vector2.ONE * minimap_zoom
			MM_hole.position *= 1.5
			MM_exit.position *= 1.5
		if Input.is_action_just_released("hide_help"):
			$UI2/Controls.visible = false
		update_ray()

func exit_cave():
	cave_data.seeds = seeds.duplicate(true)
	cave_data.tiles_mined = tiles_mined.duplicate(true)
	cave_data.enemies_rekt = enemies_rekt.duplicate(true)
	cave_data.chests_looted = chests_looted.duplicate(true)
	cave_data.partially_looted_chests = partially_looted_chests.duplicate(true)
	cave_data.hole_exits = hole_exits.duplicate(true)
	for i in len(inventory):
		if not inventory[i].has("name"):
			continue
		if inventory[i].name == "money":
			game.money += inventory[i].num
			inventory[i] = {"type":""}
		elif inventory[i].name == "minerals":
			inventory[i].num = Helper.add_minerals(inventory[i].num).remainder
			if inventory[i].num <= 0:
				inventory[i] = {"type":""}
		elif inventory[i].type != "rover_weapons" and inventory[i].type != "rover_mining" and inventory[i].has("name"):
			var remaining:int = game.add_items(inventory[i].name, inventory[i].num)
			if remaining > 0:
				inventory[i].num = remaining
			else:
				inventory[i] = {"type":""}
	var i_w_w2 = i_w_w.duplicate(true)
	if i_w_w.has("stone"):
		i_w_w2.stone = Helper.get_stone_comp_from_amount(p_i.crust, i_w_w.stone)
	i_w_w.clear()
	game.switch_view("planet")
	game.add_resources(i_w_w2)
	queue_free()

func cooldown():
	inventory_ready[curr_slot] = false
	var timer = Timer.new()
	add_child(timer)
	timer.start(Data.rover_weapons[inventory[curr_slot].name].cooldown)
	timer.connect("timeout", self, "on_timeout", [curr_slot, timer])

func on_timeout(slot, timer):
	inventory_ready[slot] = true
	remove_child(timer)
	timer.queue_free()

func _process(delta):
	if Input.is_action_pressed("left_click") and inventory_ready[curr_slot]:
		if inventory[curr_slot].type == "rover_weapons":
			attack()
		elif inventory[curr_slot].type == "rover_mining" and tile_highlighted != -1:
			hit_rock(delta)
			update_ray()
	if aurora:
		canvas_mod.color = aurora_mod.modulate * light_amount
		canvas_mod.color.a = 1
	else:
		canvas_mod.color = Color.white * light_amount
		canvas_mod.color.a = 1
	if MM.visible:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			enemy.get_node("HX").MM_icon.position = enemy.position * minimap_zoom

func attack():
	add_proj(false, rover.position, 70.0 * rover_size, atan2(mouse_pos.y - rover.position.y, mouse_pos.x - rover.position.x), load("res://Graphics/Cave/Projectiles/laser.png"), Data.rover_weapons[inventory[curr_slot].name].damage * atk * rover_size, get_color(inventory[curr_slot].name.split("_")[0]))
	cooldown()

func hit_rock(delta):
	var st = String(tile_highlighted)
	if not tiles_touched_by_laser.has(st):
		tiles_touched_by_laser[st] = {}
		var tile = tiles_touched_by_laser[st]
		tile.progress = 0
		var sq_bar = sq_bar_scene.instance()
		add_child(sq_bar)
		sq_bar.rect_position = cave.map_to_world(get_tile_pos(tile_highlighted))
		tile.bar = sq_bar
	if st != "-1":
		var sq_bar = tiles_touched_by_laser[st].bar
		tiles_touched_by_laser[st].progress += Data.rover_mining[inventory[curr_slot].name].speed * delta * 60 * pow(rover_size, 2)
		sq_bar.set_progress(tiles_touched_by_laser[st].progress)
		if tiles_touched_by_laser[st].progress >= 100:
			var map_pos = cave_wall.world_to_map(tile_highlight.position)
			var rsrc = {"stone":Helper.rand_int(150, 200)}
			#var wall_type = cave_wall.get_cellv(map_pos)
			if not dont_gen_anything:
				for mat in p_i.surface.keys():
					if randf() < p_i.surface[mat].chance / 2.5:
						var amount = game.clever_round(p_i.surface[mat].amount * rand_range(0.1, 0.12) * pow(difficulty, 0.85), 3)
						if amount < 1:
							continue
						rsrc[mat] = amount
			if deposits.has(st):
				var deposit = deposits[st]
				rsrc[deposit.rsrc_name] = game.clever_round(pow(deposit.amount, 1.5) * rand_range(0.95, 1.05) * pow(difficulty, 0.75), 3)
				remove_child(deposit)
				deposit.queue_free()
				deposits.erase(st)
			var remainder:float = 0
			for r in rsrc:
				remainder += add_weight_rsrc(r, rsrc[r])
			if remainder != 0:
				game.popup(tr("WEIGHT_INV_FULL_MINING"), 1.7)
			cave_wall.set_cellv(map_pos, -1)
			minimap_cave.set_cellv(map_pos, tile_type)
			cave_wall.update_bitmask_region()
			var vbox = $UI2/Panel/VBoxContainer
			var you_mined = Label.new()
			you_mined.align = Label.ALIGN_CENTER
			you_mined.text = tr("YOU_MINED")
			reset_panel_anim()
			Helper.put_rsrc(vbox, 32, rsrc)
			vbox.add_child(you_mined)
			vbox.move_child(you_mined, 0)
			$UI2/Panel.visible = true
			$UI2/Panel.modulate.a = 1
			var timer = $UI2/Panel/Timer
			timer.wait_time = 0.5 + 0.5 * vbox.get_child_count()
			timer.start()
			astar_node.add_point(tile_highlighted, Vector2(map_pos.x, map_pos.y))
			connect_points(map_pos, true)
			remove_child(tiles_touched_by_laser[st].bar)
			tiles_touched_by_laser[st].bar.queue_free()
			tiles_touched_by_laser.erase(st)
			cave.set_cellv(map_pos, tile_type)
			tiles_mined[cave_floor - 1].append(tile_highlighted)
			tile_highlighted = -1

func add_weight_rsrc(r, rsrc_amount):
	weight += rsrc_amount
	if i_w_w.has(r):
		i_w_w[r] += rsrc_amount
	else:
		i_w_w[r] = rsrc_amount
	var diff:float = floor((weight - weight_cap) * 100) / 100.0
	if weight > weight_cap:
		weight -= diff
		i_w_w[r] -= diff
		var float_error:float = weight - weight_cap
		weight -= float_error
		i_w_w[r] -= float_error
	$UI2/Inventory/Bar.value = weight
	$UI2/Inventory/Label.text = "%s / %s kg" % [round(weight), weight_cap]
	return max(diff, 0.0)

func _on_Timer_timeout():
	var tween = $UI2/Panel/Tween
	tween.interpolate_property($UI2/Panel, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.5)
	tween.start()
	$UI2/Panel/Timer.stop()
	yield(tween, "tween_all_completed")
	$UI2/Panel.visible = false
	$UI2/Panel.modulate.a = 1
	tween.stop_all()

func hit_player(damage:float):
	update_health_bar(HP - damage)

#Basic projectile that has a fixed velocity and disappears once hitting something
func add_proj(enemy:bool, pos:Vector2, spd:float, rot:float, texture, damage:float, mod:Color = Color(1, 1, 1, 1)):
	var proj = load("res://Scenes/Cave/Projectile.tscn").instance()
	proj.texture = texture
	proj.rotation = rot
	proj.velocity = polar2cartesian(spd, rot)
	proj.position = pos
	proj.damage = damage
	proj.enemy = enemy
	proj.modulate = mod
	if enemy:
		proj.collision_layer = 16
		proj.collision_mask = 1 + 2
	else:
		proj.scale *= rover_size
		proj.collision_layer = 8
		proj.collision_mask = 1 + 4
	proj.cave_ref = self
	add_child(proj)
	proj.add_to_group("projectiles")

var slots = []
func set_border(i:int):
	for j in range(0, len(slots)):
		var slot = slots[j]
		if i == j and not slot.has_node("border"):
			var border = TextureRect.new()
			border.texture = load("res://Graphics/Cave/SlotBorder.png")
			slot.add_child(border)
			border.name = "border"
		elif slot.has_node("border"):
			var border = slot.get_node("border")
			slot.remove_child(border)
			border.queue_free()
	if inventory[i].type == "rover_mining":
		mining_laser.modulate = get_color(inventory[i].name.split("_")[0])
		var speed = Data.rover_mining[inventory[i].name].speed
		mining_p.amount = int(25 * pow(speed, 0.7) * pow(rover_size, 2))
		mining_p.process_material.initial_velocity = int(500 * pow(speed, 0.7) * pow(rover_size, 2))
		$UI2/ActiveItem.text = Helper.get_rover_mining_name(inventory[i].name)
	elif inventory[i].type == "rover_weapons":
		$UI2/ActiveItem.text = Helper.get_rover_weapon_name(inventory[i].name)
	elif inventory[i].has("name"):
		$UI2/ActiveItem.text = tr(inventory[i].name.to_upper())
	else:
		$UI2/ActiveItem.text = ""

func get_color(color:String):
	match color:
		"red":
			return Color.red
		"orange":
			return Color.orange
		"yellow":
			return Color.yellow
		"green":
			return Color.green
		"blue":
			return Color.blue
		"purple":
			return Color.purple
		"UV":
			return Color.violet
		"xray":
			return Color.lightgray
		"gammaray":
			return Color.lightgreen
		"ultragammaray":
			return Color.white

func sort_size(a, b):
	if a.size > b.size:
		return true
	return false

func get_connected_tiles(_id:int):#Returns the list of all tiles connected to tile with index id, useful to get size of enclosed rooms for example
	var unique_c_tiles = [_id]
	var c_tiles = [_id]
	while len(c_tiles) != 0:
		var new_c_tiles = []
		for c_tile in c_tiles:
			for i in astar_node.get_point_connections(c_tile):
				if unique_c_tiles.find(i) == -1:
					new_c_tiles.append(i)
					unique_c_tiles.append(i)
		c_tiles = new_c_tiles
	return unique_c_tiles
		
func get_tile_index(pt:Vector2):
	return pt.x + cave_size * pt.y

#returns unit positions
func get_tile_pos(_id:int):
	return Vector2(_id % cave_size, _id / cave_size)

func _physics_process(delta):
	var speed_mult2 = (speed_mult if moving_fast else 1.0) * rover_size
	mouse_pos = global_mouse_pos + camera.position - Vector2(640, 360)
	update_ray()
	var input_vector = Vector2.ZERO
	if OS.get_latin_keyboard_variant() == "AZERTY":
		input_vector.x = int(Input.is_action_pressed("D")) - int(Input.is_action_pressed("Q"))
		input_vector.y = int(Input.is_action_pressed("S")) - int(Input.is_action_pressed("Z"))
	else:
		input_vector.x = int(Input.is_action_pressed("D")) - int(Input.is_action_pressed("A"))
		input_vector.y = int(Input.is_action_pressed("S")) - int(Input.is_action_pressed("W"))
	input_vector = input_vector.normalized()
	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * max_speed * speed_mult2, acceleration * delta * speed_mult2)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta * speed_mult2)
	velocity = rover.move_and_slide(velocity)
	camera.position = rover.position
	MM.position = minimap_center - rover.position * minimap_zoom

func reset_panel_anim():
	var timer = $UI2/Panel/Timer
	timer.stop()
	var tween = $UI2/Panel/Tween
	tween.stop_all()
	$UI2/Panel.visible = false
	$UI2/Panel.modulate.a = 1

func _on_Exit_body_entered(_body):
	if cave_floor == 1:
		show_right_info(tr("F_TO_EXIT"))
		active_type = "exit"
	else:
		show_right_info(tr("F_TO_GO_UP"))
		active_type = "go_up"

func on_WH_entered(_body):
	show_right_info(tr("F_TO_EXIT"))
	active_type = "exit"

func _on_Hole_body_entered(_body):
	show_right_info(tr("F_TO_GO_DOWN"))
	active_type = "go_down"

func show_right_info(txt:String):
	var vbox = $UI2/Panel/VBoxContainer
	reset_panel_anim()
	Helper.put_rsrc(vbox, 32, {})
	var info = Label.new()
	info.align = Label.ALIGN_CENTER
	info.text = txt
	vbox.add_child(info)
	$UI2/Panel.visible = true

func _on_body_exited(_body):
	$UI2/Panel.visible = false
	active_type = ""

func _on_Floor_mouse_entered():
	game.show_tooltip(tr("CAVE_FLOOR") % [cave_floor])

func _on_mouse_exited():
	game.hide_tooltip()

func _on_Difficulty_mouse_entered():
	var tooltip:String = "%s: %s\n%s: %s\n%s: %s" % [tr("STAR_SYSTEM_DIFFICULTY"), game.system_data[game.c_s].diff, tr("AURORA_MULTIPLIER"), aurora_mult, tr("FLOOR_MULTIPLIER"), pow(2, cave_floor - 1)]
	if game.help.cave_diff_info:
		game.help_str = "cave_diff_info"
		game.show_tooltip("%s\n%s\n%s" % [tr("CAVE_DIFF_INFO"), tr("HIDE_HELP"), tooltip])
	else:
		game.show_tooltip(tooltip)
