extends Node2D

onready var astar_node = AStar2D.new()

onready var game = get_node("/root/Game")
onready var p_i = game.planet_data[game.c_p]
onready var tile_type = p_i.type - 3

onready var cave = $TileMap
onready var cave_wall = $Walls
onready var minimap_cave = $UI/Minimap/TileMap
onready var minimap_rover = $UI/Rover
onready var MM_hole = $UI/Minimap/Hole
onready var MM_exit = $UI/Minimap/Exit
onready var MM = $UI/Minimap
onready var rover = $Rover
onready var camera = $Camera2D
onready var exit = $Exit
onready var hole = $Hole
onready var hbox = $UI2/HBoxContainer
onready var ray = $Rover/RayCast2D
onready var mining_laser = $Rover/MiningLaser
onready var mining_p = $MiningParticles
onready var tile_highlight = $TileHighlight
onready var slot_scene = preload("res://Scenes/InventorySlot.tscn")
onready var HX1_scene = preload("res://Scenes/HX/HX1.tscn")
onready var deposit_scene = preload("res://Scenes/Cave/MetalDeposit.tscn")
onready var enemy_icon_scene = preload("res://Graphics/Cave/MMIcons/Enemy.png")
onready var chest_scene = preload("res://Scenes/Cave/Chest.tscn")
onready var sq_bar_scene = preload("res://Scenes/SquareBar.tscn")

var minimap_zoom:float = 0.02
var minimap_center:Vector2 = Vector2(1150, 128)
var curr_slot:int = 0
var difficulty:float = 1.0
var floor_seeds = []
var id:int#Cave id
var rover_data:Dictionary = {}
var cave_data:Dictionary

#Rover stats
var atk:float = 5.0
var def:float = 5.0
var HP:float = 20.0
var total_HP:float = 20.0
var inventory:Array
var inventory_ready:Array = []#For cooldowns
var i_w_w:Dictionary = {}#inventory_with_weight
var weight:float = 0.0
var weight_cap:float = 1500.0

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
var hole_exits:Array = []#id of hole and exit on each floor

### End cave save data ###

func _ready():
	id = game.tile_data[game.c_t].cave_id
	cave_data = game.cave_data[id]
	num_floors = cave_data.num_floors
	cave_size = cave_data.floor_size
	if cave_data.has("enemies_rekt"):
		seeds = cave_data.seeds
		tiles_mined = cave_data.tiles_mined
		enemies_rekt = cave_data.enemies_rekt
		chests_looted = cave_data.chests_looted
		hole_exits = cave_data.hole_exits
	minimap_rover.position = minimap_center
	minimap_cave.scale *= minimap_zoom
	minimap_rover.scale *= 0.1
	generate_cave(true, false)

func set_rover_data():
	HP = rover_data.HP
	total_HP = rover_data.HP
	atk = rover_data.atk
	def = rover_data.def
	weight_cap = rover_data.weight_cap
	inventory = rover_data.inventory.duplicate(true)
	for i in len(inventory):
		inventory_ready.append(true)
	for i in range(0, len(inventory)):
		var slot = slot_scene.instance()
		hbox.add_child(slot)
		slots.append(slot)
		if inventory[i].empty():
			continue
		var dir = Directory.new()
		var dir_str = "res://Graphics/Cave/InventoryItems/" + inventory[i].name + ".png"
		var texture_exists = dir.file_exists(dir_str)
		if texture_exists:
			slot.get_node("TextureRect").texture = load(dir_str)
	set_border(curr_slot)
	$UI2/HP/Bar.max_value = total_HP
	$UI2/Inventory/Bar.value = weight
	$UI2/Inventory/Bar.max_value = weight_cap
	update_health_bar(total_HP)
	$UI2/Inventory/Label.text = "%s / %s kg" % [weight, weight_cap]

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
		remove_child(enemy)
	for enemy_icon in get_tree().get_nodes_in_group("enemy_icons"):
		MM.remove_child(enemy_icon)
	for deposit in deposits:
		remove_child(deposits[deposit])
	for chest_str in chests:
		remove_child(chests[chest_str].node)
	for tile in tiles_touched_by_laser:
		remove_child(tiles_touched_by_laser[tile].bar)
	tiles_touched_by_laser.clear()
	chests.clear()
	deposits.clear()

func generate_cave(first_floor:bool, going_up:bool):
	$UI2/Floor.text = "B%sF" % [cave_floor]
	var noise = OpenSimplexNoise.new()
	var first_time:bool = cave_floor > len(seeds)
	if first_time:
		var sd = randi()
		seed(sd)
		noise.seed = sd
		seeds.append(sd)
		tiles_mined.append([])
		enemies_rekt.append([])
		chests_looted.append([])
		hole_exits.append({"hole":-1, "exit":-1})
	else:
		noise.seed = seeds[cave_floor - 1]
		seed(seeds[cave_floor - 1])
	noise.octaves = 1
	noise.period = 65
	#Generate cave
	for i in cave_size:
		for j in cave_size:
			var level = noise.get_noise_2d(i * 10.0, j * 10.0)
			var tile_id:int = get_tile_index(Vector2(i, j))
			if level > 0:
				cave.set_cell(i, j, tile_type)
				minimap_cave.set_cell(i, j, tile_type)
				astar_node.add_point(tile_id, Vector2(i, j))
				if randf() < 0.005:
					var HX = HX1_scene.instance()
					var HX_node = HX.get_node("HX")
					HX_node.HP = round(10 * difficulty * rand_range(1, 1.4))
					HX_node.atk = round(4 * difficulty * rand_range(1, 1.2))
					HX_node.def = round(4 * difficulty * rand_range(1, 1.2))
					if enemies_rekt[cave_floor - 1].has(tile_id):
						continue
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
				if randf() < 0.02:
					var deposit = deposit_scene.instance()
					deposit.dir = "Metals"
					deposit.rsrc_name = "lead"
					deposit.amount = Helper.rand_int(2, 15)
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
	tiles = cave.get_used_cells_by_id(tile_type)
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
	for room in rooms:
		var n = room.size
		for tile in room.tiles:
			var rand = randf()
			var formula = 0.7 / pow(n, 0.7)
			if rand < formula:
				var tier:int = int(clamp(pow(formula / rand, 0.35), 1, 5))
				var contents:Dictionary = generate_treasure(tier)
				if contents.empty() or chests_looted[cave_floor - 1].has(int(tile)):
					continue
				var chest = chest_scene.instance()
				add_child(chest)
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
				chest.get_node("Area2D").connect("body_entered", self, "on_chest_entered", [String(tile)])
				chest.get_node("Area2D").connect("body_exited", self, "on_chest_exited")
				chest.scale *= 0.8
				chest.position = cave.map_to_world(get_tile_pos(tile)) + Vector2(100, 100)
				chests[String(tile)] = {"node":chest, "contents":contents}
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
	var rand_hole:int = rooms[0].tiles[Helper.rand_int(0, len(rooms[0]) - 1)]
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
		exit.get_node("Sprite").texture = load("res://Graphics/Cave/exit.png")
		exit.get_node("ExitColl").disabled = false
		var rot = spawn_edge_tiles[0].dir
		exit.get_node("GoUpColl").disabled = true
		while rand_hole == rand_spawn:
			var rand_id = Helper.rand_int(0, len(spawn_edge_tiles) - 1)
			rand_spawn = spawn_edge_tiles[rand_id].id
			rot = spawn_edge_tiles[rand_id].dir
		pos = get_tile_pos(rand_spawn) * 200 + Vector2(100, 100)
		exit.rotation = rot
		MM_exit.rotation = rot
	else:
		MM_exit.rotation = 0
		exit.get_node("Sprite").texture = load("res://Graphics/Cave/go_up.png")
		exit.get_node("ExitColl").disabled = true
		exit.get_node("GoUpColl").disabled = false
		pos = tiles[Helper.rand_int(0, len(tiles) - 1)] * 200 + Vector2(100, 100)
		while rand_hole == rand_spawn:
			rand_spawn = get_tile_index(tiles[Helper.rand_int(0, len(tiles) - 1)])
	if cave_floor == num_floors:
		hole.get_node("CollisionShape2D").disabled = true
		MM_hole.visible = false
	else:
		hole.get_node("CollisionShape2D").disabled = false
		MM_hole.visible = true
	#No treasure chests at spawn/hole
	if chests.has(String(rand_hole)):
		remove_child(chests[String(rand_hole)].node)
		chests.erase(String(rand_hole))
	if chests.has(String(rand_spawn)):
		remove_child(chests[String(rand_spawn)].node)
		chests.erase(String(rand_spawn))
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

func on_chest_entered(_body, tile:String):
	var chest_rsrc = chests[tile].contents
	active_chest = tile
	active_type = "chest"
	var vbox = $UI2/Panel/VBoxContainer
	reset_panel_anim()
	Helper.put_rsrc(vbox, 32, chest_rsrc)
	var take_all = Label.new()
	take_all.align = Label.ALIGN_CENTER
	take_all.text = tr("TAKE_ALL")
	vbox.add_child(take_all)
	$UI2/Panel.visible = true
	$UI2/Panel.modulate.a = 1

func on_chest_exited(_body):
	active_chest = "-1"
	active_type = ""
	$UI2/Panel.visible = false

func generate_treasure(tier:int):
	var contents = {	"money":round(rand_range(20000, 50000) * pow(tier, 3.0)),
						"minerals":round(rand_range(4000, 10000) * pow(tier, 3.0)),
						"hx_core":Helper.rand_int(1, 5 * pow(tier, 1.5))}
	for met in game.met_info:
		var met_value = game.met_info[met]
		if randf() < 0.5 / met_value.rarity:
			contents[met] = game.clever_round(rand_range(0.8, 1.2) * met_value.amount * pow(tier, 1.5), 3)
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
		if cave.get_cellv(neighbor_tile) != -1:
			astar_node.connect_points(tile_index, neighbor_tile_index, bidir)

func update_health_bar(_HP):
	HP = _HP
	$UI2/HP/Bar.value = HP

var mouse_pos = Vector2.ZERO
var tile_highlighted:int = -1

func update_ray():
	ray.enabled = inventory[curr_slot].name == "mining"
	if ray.enabled:
		var laser_reach = 250.0
		ray.cast_to = (mouse_pos - rover.position).normalized() * laser_reach
		var coll = ray.get_collider()
		var holding_left_click = Input.is_action_pressed("left_click")
		if coll is TileMap:
			var pos = ray.get_collision_point() + ray.cast_to / 200.0
			laser_reach = rover.position.distance_to(pos)
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
		if Input.is_action_just_released("map"):
			$UI/Minimap.visible = not $UI/Minimap.visible
			$UI/Rover.visible = not $UI/Rover.visible
			$UI/MinimapBG.visible = not $UI/MinimapBG.visible
		elif Input.is_action_just_released("hotbar_1") and curr_slot != 0:
			curr_slot = 0
			set_border(curr_slot)
		elif Input.is_action_just_released("hotbar_2") and curr_slot != 1:
			curr_slot = 1
			set_border(curr_slot)
		elif Input.is_action_just_released("hotbar_3") and curr_slot != 2:
			curr_slot = 2
			set_border(curr_slot)
		elif Input.is_action_just_released("hotbar_4") and curr_slot != 3:
			curr_slot = 3
			set_border(curr_slot)
		elif Input.is_action_just_released("hotbar_5") and curr_slot != 4:
			curr_slot = 4
			set_border(curr_slot)
		if Input.is_action_just_released("upgrade"):
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
						var remainder = add_weight_rsrc(rsrc, contents[rsrc])
						if remainder != 0:
							remainders[rsrc] = remainder
					else:
						for i in len(inventory):
							if rsrc != inventory[i].name and inventory[i].name != "":
								continue
							var slot = slots[i]
							if inventory[i].name == "":
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
					Helper.put_rsrc($UI2/Panel/VBoxContainer, 32, remainders)
					$UI2/Panel.visible = true
					game.popup(tr("WEIGHT_INV_FULL"), 1.7)
				else:
					var temp = active_chest
					remove_child(chests[active_chest].node)
					chests.erase(temp)
					chests_looted[cave_floor - 1].append(int(temp))
			elif active_type == "exit":
				if not cave_data.has("enemies_rekt"):
					cave_data.seeds = seeds.duplicate(true)
					cave_data.tiles_mined = tiles_mined.duplicate(true)
					cave_data.enemies_rekt = enemies_rekt.duplicate(true)
					cave_data.chests_looted = chests_looted.duplicate(true)
					cave_data.hole_exits = hole_exits.duplicate(true)
				game.switch_view("planet")
			elif active_type == "go_down":
				remove_cave()
				cave_floor += 1
				generate_cave(false, false)
			elif active_type == "go_up":
				remove_cave()
				cave_floor -= 1
				generate_cave(true if cave_floor == 1 else false, true)
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
		update_ray()

func cooldown():
	inventory_ready[curr_slot] = false
	var timer = Timer.new()
	add_child(timer)
	timer.start(inventory[curr_slot].cooldown)
	timer.connect("timeout", self, "on_timeout", [curr_slot, timer])

func on_timeout(slot, timer):
	inventory_ready[slot] = true
	remove_child(timer)

func _process(_delta):
	if Input.is_action_pressed("left_click") and inventory_ready[curr_slot]:
		if inventory[curr_slot].name == "attack":
			attack()
		elif inventory[curr_slot].name == "mining" and tile_highlighted != -1:
			hit_rock()
			update_ray()
	if MM.visible:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			enemy.get_node("HX").MM_icon.position = enemy.position * minimap_zoom

func attack():
	add_proj(false, rover.position, 70.0, atan2(mouse_pos.y - rover.position.y, mouse_pos.x - rover.position.x), load("res://Graphics/Cave/Projectiles/laser.png"), inventory[curr_slot].damage * atk)
	cooldown()

func hit_rock():
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
		tiles_touched_by_laser[st].progress += 1
		sq_bar.set_progress(tiles_touched_by_laser[st].progress)
		if tiles_touched_by_laser[st].progress >= 100:
			var map_pos = cave_wall.world_to_map(tile_highlight.position)
			var rsrc = {"stone":Helper.rand_int(150, 200)}
			#var wall_type = cave_wall.get_cellv(map_pos)
			for mat in p_i.surface.keys():
				if randf() < p_i.surface[mat].chance / 2.5:
					var amount = game.clever_round(p_i.surface[mat].amount * rand_range(0.1, 0.12), 3)
					if amount < 1:
						continue
					rsrc[mat] = amount
			if deposits.has(st):
				var deposit = deposits[st]
				rsrc[deposit.rsrc_name] = game.clever_round(deposit.amount * rand_range(0.95, 1.05), 3)
				remove_child(deposit)
				deposits.erase(st)
			for r in rsrc:
				add_weight_rsrc(r, rsrc[r])
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
	var diff = weight - weight_cap
	if weight > weight_cap:
		weight -= diff
		i_w_w[r] -= diff
	$UI2/Inventory/Bar.value = weight
	$UI2/Inventory/Label.text = "%s / %s kg" % [weight, weight_cap]
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
	update_health_bar(HP - damage / def)

#Basic projectile that has a fixed velocity and disappears once hitting something
func add_proj(enemy:bool, pos:Vector2, spd:float, rot:float, texture, damage:float):
	var proj = load("res://Scenes/Cave/Projectile.tscn").instance()
	proj.texture = texture
	proj.rotation = rot
	proj.velocity = polar2cartesian(spd, rot)
	proj.position = pos
	proj.damage = damage
	proj.enemy = enemy
	if enemy:
		proj.collision_layer = 16
		proj.collision_mask = 1 + 2
	else:
		proj.collision_layer = 8
		proj.collision_mask = 1 + 4
	proj.cave_ref = self
	add_child(proj)

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
			slot.remove_child(slot.get_node("border"))

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

func get_tile_pos(_id:int):
# warning-ignore:integer_division
	return Vector2(_id % cave_size, _id / cave_size)

var velocity = Vector2.ZERO
var max_speed = 1000
var acceleration = 8000
var friction = 8000
func _physics_process(delta):
	mouse_pos = global_mouse_pos + camera.position - Vector2(640, 360)
	update_ray()
	var input_vector = Vector2.ZERO
	input_vector.x = - Input.get_action_strength("ui_left") + Input.get_action_strength("ui_right")
	input_vector.y = - Input.get_action_strength("ui_up") + Input.get_action_strength("ui_down")
	input_vector = input_vector.normalized()
	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * max_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
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

func _on_Exit_body_exited(_body):
	$UI2/Panel.visible = false
	active_type = ""

func _on_Hole_body_exited(_body):
	$UI2/Panel.visible = false
	active_type = ""

func _on_Floor_mouse_entered():
	game.show_tooltip(tr("CAVE_FLOOR") % [cave_floor])

func _on_Floor_mouse_exited():
	game.hide_tooltip()
