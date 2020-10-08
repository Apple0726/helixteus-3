extends Node2D

onready var astar_node = AStar2D.new()

var tiles:PoolVector2Array
var cave_size:int = 60
onready var game = get_node("/root/Game")
onready var p_i = game.planet_data[game.c_p]

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

var minimap_zoom = 0.02
var minimap_center = Vector2(1150, 128)
var curr_slot = 0
var difficulty = 1

#Rover stats
var atk = 5.0
var def = 5.0
var HP = 20.0
var total_HP = 20.0
var inventory = [{"name":"attack", "cooldown":0.2, "damage":2.0}, {"name":"mining", "cooldown":0.3}, {"name":""}, {"name":""}, {"name":""}]
var inventory_ready = [true, true, true, true, true]#For cooldowns
var i_w_w = {}#inventory_with_weight
var weight = 0.0
var weight_cap = 1500.0

var rooms = []
var HX_tiles = []#Tile ids occupied by HX
var deposits = {}#Random metal/material deposits
var chests = {}#Random chests and their contents

func _ready():
	minimap_rover.position = minimap_center
	minimap_cave.scale *= minimap_zoom
	minimap_rover.scale *= minimap_zoom * 3
	var noise = OpenSimplexNoise.new()
	noise.seed = 1
	noise.octaves = 1
	noise.period = 65
	var rover_placed = false
	#Generate cave
	for i in cave_size:
		for j in cave_size:
			var level = noise.get_noise_2d(i / float(cave_size) * 512, j / float(cave_size) * 512)
			var tile_id = get_tile_index(Vector2(i, j))
			if level > 0:
				var edge = i == 0 or j == 0 or i == cave_size - 1 or j == cave_size - 1
				if not rover_placed and edge and randf() < 0.01:
					rover_placed = true
					rover.position.x = i * 200
					rover.position.y = j * 200
					camera.position.x = i * 200
					camera.position.y = j * 200
				cave.set_cell(i, j, 0)
				minimap_cave.set_cell(i, j, 0)
				astar_node.add_point(tile_id, Vector2(i, j))
				if randf() < 0.005:
					var HX = HX1_scene.instance()
					HX.position = Vector2(i, j) * 200 + Vector2(100, 100)
					var HX_node = HX.get_node("HX")
					HX_node.HP = round(10 * difficulty * rand_range(1, 1.4))
					HX_node.atk = round(4 * difficulty * rand_range(1, 1.2))
					HX_node.def = round(4 * difficulty * rand_range(1, 1.2))
					HX_node.total_HP = HX_node.HP
					HX_node.cave_ref = self
					HX_node.a_n = astar_node
					HX_node.cave_tm = cave
					HX.add_to_group("enemies")
					add_child(HX)
					HX_tiles.append(tile_id)
					var enemy_icon = Sprite.new()
					enemy_icon.scale *= 0.07
					enemy_icon.texture = enemy_icon_scene
					MM.add_child(enemy_icon)
					HX_node.MM_icon = enemy_icon
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
	cave_wall.update_bitmask_region()
	tiles = cave.get_used_cells_by_id(0)
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
	#Assigns each enemy the room number they're in
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var id = get_tile_index(cave.world_to_map(enemy.position))
		var i = 0
		for room in rooms:
			if id in room.tiles:
				enemy.get_node("HX").room = i
			i += 1
	#Generate treasure chests. Smaller rooms have higher chances of having one
	for room in rooms:
		var n = room.size
		for tile in room.tiles:
			var rand = randf()
			var formula = 3.0 / pow(n, 1.5)
			if rand < formula:
				var tier:int = int(clamp(pow(formula / rand, 0.6), 1, 5))
				var contents:Dictionary = generate_treasure(tier)
				if contents.empty():
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
	#Determines the tile where the entrance will be. It has to be adjacent to an unpassable tile
	var spawn_edge_tiles = []
	var j = 0
	while len(spawn_edge_tiles) == 0:
		for tile_id in rooms[j].tiles:
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
			
	var rand_spawn = Helper.rand_int(0, len(spawn_edge_tiles) - 1)
	var rand_exit = Helper.rand_int(0, len(rooms[0]) - 1)
	var pos = get_tile_pos(spawn_edge_tiles[rand_spawn].id) * 200 + Vector2(100, 100)
	rover.position = pos
	exit.position = pos
	exit.rotation = spawn_edge_tiles[rand_spawn].dir
	hole.position = get_tile_pos(rooms[0].tiles[rand_exit]) * 200 + Vector2(100, 100)
	MM_hole.position = (get_tile_pos(rooms[0].tiles[rand_exit]) * 200 + Vector2(100, 100)) * minimap_zoom
	MM_exit.position = pos * minimap_zoom
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

func on_chest_entered(body, tile:String):
	print(tile)

func on_chest_exited():
	pass

func generate_treasure(tier:int):
	var contents = {	"money":round(rand_range(20000, 50000) * pow(tier, 3.0)),
						"minerals":round(rand_range(4000, 10000) * pow(tier, 3.0)),
						"hx_core":Helper.rand_int(0, 5 * pow(tier, 1.5))}
	for met in game.met_info.values():
		if randf() < 0.5 / met.rarity:
			contents[met] = game.clever_round(rand_range(0.8, 1.2) * met.amount * pow(tier, 1.5), 3)
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
		if cave.get_cellv(neighbor_tile) == 0:
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
			if tile_highlighted != -1 and cave_wall.get_cellv(cave_wall.world_to_map(pos)) == 0:
				tile_highlight.visible = true
				tile_highlight.position.x = floor(pos.x / 200) * 200 + 100
				tile_highlight.position.y = floor(pos.y / 200) * 200 + 100
				mining_p.emitting = holding_left_click
				if holding_left_click:
					mining_p.position = pos
			else:
				mining_p.emitting = false
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
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.get_node("HX").MM_icon.position = enemy.position * minimap_zoom

func attack():
	add_proj(false, rover.position, 70.0, atan2(mouse_pos.y - rover.position.y, mouse_pos.x - rover.position.x), load("res://Graphics/Cave/Projectiles/laser.png"), inventory[curr_slot].damage * atk)
	cooldown()

var tiles_mined = {}
var sq_bar_scene = load("res://Scenes/SquareBar.tscn")

func hit_rock():
	var st = String(tile_highlighted)
	if not tiles_mined.has(st):
		tiles_mined[st] = {}
		var tile = tiles_mined[st]
		tile.progress = 0
		var sq_bar = sq_bar_scene.instance()
		add_child(sq_bar)
		sq_bar.rect_position = cave.map_to_world(get_tile_pos(tile_highlighted))
		tile.bar = sq_bar
	if st != "-1":
		var sq_bar = tiles_mined[st].bar
		tiles_mined[st].progress += 1
		sq_bar.set_progress(tiles_mined[st].progress)
		if tiles_mined[st].progress >= 100:
			var map_pos = cave_wall.world_to_map(tile_highlight.position)
			var rsrc = {"stone":Helper.rand_int(150, 200)}
			var wall_type = cave_wall.get_cellv(map_pos)
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
			for r in rsrc:
				weight += rsrc[r]
				if i_w_w.has(r):
					i_w_w[r] += rsrc[r]
				else:
					i_w_w[r] = rsrc[r]
				if weight > weight_cap:
					var diff = weight - weight_cap
					weight -= diff
					i_w_w[r] -= diff
					break
			$UI2/Inventory/Bar.value = weight
			cave_wall.set_cellv(map_pos, -1)
			minimap_cave.set_cellv(map_pos, 0)
			cave_wall.update_bitmask_region()
			var vbox = $UI2/Panel/VBoxContainer
			$UI2/Panel.visible = false
			Helper.put_rsrc(vbox, 32, rsrc)
			$UI2/Panel.visible = true
			$UI2/Panel.modulate.a = 1
			var tween = $UI2/Panel/Tween
			tween.remove_all()
			var timer = $UI2/Panel/Timer
			timer.stop()
			timer.wait_time = 0.5 + 0.5 * vbox.get_child_count()
			timer.start()
			astar_node.add_point(tile_highlighted, Vector2(map_pos.x, map_pos.y))
			connect_points(map_pos, true)
			remove_child(tiles_mined[st].bar)
			tiles_mined.erase(st)
			cave.set_cellv(map_pos, 0)
			tile_highlighted = -1

func _on_Timer_timeout():
	var tween = $UI2/Panel/Tween
	tween.interpolate_property($UI2/Panel, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.5)
	tween.start()
	yield(tween, "tween_all_completed")
	$UI2/Panel.visible = false
	$UI2/Panel.modulate.a = 1

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

func get_connected_tiles(id:int):#Returns the list of all tiles connected to tile with index id, useful to get size of enclosed rooms for example
	var unique_c_tiles = [id]
	var c_tiles = [id]
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

func get_tile_pos(id:int):
# warning-ignore:integer_division
	return Vector2(id % cave_size, id / cave_size)

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

func _on_Exit_body_entered(body):
	if body is KinematicBody2D:
		print("exit")


func _on_Hole_body_entered(body):
	if body is KinematicBody2D:
		print("next floor")
