extends Node2D

onready var astar_node = AStar2D.new()
var tiles
var tile_indexes = []
var cave_size = 60
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
onready var slot_scene = preload("res://Scenes/InventorySlot.tscn")
onready var HX1_scene = preload("res://Scenes/HX/HX1.tscn")
onready var enemy_icon_scene = preload("res://Graphics/Cave/MMIcons/Enemy.png")
var minimap_zoom = 0.02
var minimap_center = Vector2(1150, 128)
var curr_slot = 0
var inventory = [{"name":"attack", "cooldown":0.2, "damage":2.0}, {"name":"mining", "cooldown":0.3}, {"name":""}, {"name":""}, {"name":""}]
var inventory_ready = [true, true, true, true, true]
var difficulty = 1
var atk = 5.0
var def = 5.0
var HP = 20.0
var total_HP = 20.0
var rooms = []

func _ready():
	minimap_rover.position = minimap_center
	minimap_cave.scale *= minimap_zoom
	minimap_rover.scale *= minimap_zoom * 3
	var noise = OpenSimplexNoise.new()
	noise.seed = 0
	noise.octaves = 1
	noise.period = 65
	var rover_placed = false
	for i in cave_size:
		for j in cave_size:
			var level = noise.get_noise_2d(i / float(cave_size) * 512, j / float(cave_size) * 512)
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
				astar_node.add_point(get_tile_index(Vector2(i, j)), Vector2(i, j))
				tile_indexes.append(get_tile_index(Vector2(i, j)))
				if randf() < 0.02:
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
					var enemy_icon = Sprite.new()
					enemy_icon.scale *= 0.07
					enemy_icon.texture = enemy_icon_scene
					MM.add_child(enemy_icon)
					HX_node.MM_icon = enemy_icon
			else:
				cave_wall.set_cell(i, j, 0)
	for i in range(-1, cave_size + 1):
		cave_wall.set_cell(i, -1, 0)
	for i in range(-1, cave_size + 1):
		cave_wall.set_cell(i, cave_size, 0)
	for i in range(-1, cave_size + 1):
		cave_wall.set_cell(-1, i, 0)
	for i in range(-1, cave_size + 1):
		cave_wall.set_cell(cave_size, i, 0)
	cave_wall.update_bitmask_region()
	tiles = cave.get_used_cells_by_id(0)
	for tile in tiles:#tile is a Vector2D
		var tile_index = get_tile_index(tile)
		var neighbor_tiles = PoolVector2Array([
			tile + Vector2.RIGHT,
			tile + Vector2.LEFT,
			tile + Vector2.DOWN,
			tile + Vector2.UP,
		])
		for neighbor_tile in neighbor_tiles:
			var neighbor_tile_index = get_tile_index(neighbor_tile)
			if not astar_node.has_point(neighbor_tile_index):
				continue
			if cave.get_cellv(neighbor_tile) == 0:
				astar_node.connect_points(tile_index, neighbor_tile_index, false)
	
	var tiles_remaining = astar_node.get_points()
	while tiles_remaining != []:
		var room = get_connected_tiles(tiles_remaining[0])
		for tile_index in room:
			tiles_remaining.erase(tile_index)
		rooms.append({"tiles":room, "size":len(room)})
	rooms.sort_custom(self, "sort_size")
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var id = get_tile_index(cave.world_to_map(enemy.position))
		var i = 0
		for room in rooms:
			if id in room.tiles:
				enemy.get_node("HX").room = i
			i += 1
	var spawn_edge_tiles = []
	for tile_id in rooms[0].tiles:
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
	$UI2/HP.max_value = total_HP
	update_health_bar(total_HP)

func update_health_bar(_HP):
	HP = _HP
	$UI2/HP.value = HP

var attacking = false
var mouse_pos = Vector2.ZERO

func _input(event):
	if event is InputEventMouseMotion:
		mouse_pos = event.position + camera.position - Vector2(640, 360)
	if event.is_action_released("scroll_up"):
		curr_slot -= 1
		if curr_slot < 0:
			curr_slot = len(inventory) - 1
		if inventory[curr_slot].name != "attack":
			attacking = false
		set_border(curr_slot)
	if event.is_action_released("scroll_down"):
		curr_slot += 1
		if curr_slot >= len(inventory):
			curr_slot = 0
		if inventory[curr_slot].name != "attack":
			attacking = false
		set_border(curr_slot)
	if Input.is_action_pressed("left_click"):
		if inventory[curr_slot].name == "attack":
			if not attacking and inventory_ready[curr_slot]:
				attacking = true
				attack()
	if Input.is_action_just_released("left_click"):
		if inventory[curr_slot].name == "attack":
			attacking = false

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
	if attacking and inventory_ready[curr_slot]:
		attack()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.get_node("HX").MM_icon.position = enemy.position * minimap_zoom

func attack():
	add_proj(false, rover.position, 70.0, atan2(mouse_pos.y - rover.position.y, mouse_pos.x - rover.position.x), load("res://Graphics/Cave/Projectiles/laser.png"), inventory[curr_slot].damage * atk)
	cooldown()

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
	return Vector2(id % cave_size, id / cave_size)

var velocity = Vector2.ZERO
var max_speed = 1000
var acceleration = 8000
var friction = 8000
func _physics_process(delta):
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
