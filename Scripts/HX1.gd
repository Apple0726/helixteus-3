extends KinematicBody2D

var tween
var tween2
var float_height = 20
var trans_tween = Tween.TRANS_QUAD
var HP
var total_HP
var atk
var def
var MM_icon
var cave_ref
var shoot_timer:Timer
var check_distance_timer:Timer
var move_timer:Timer
var sees_player:bool = false
var AI_enabled:bool = false
var a_n:AStar2D
var cave_tm:TileMap
var room:int
var spawn_tile:int#Tile on which the enemy spawned
var move_speed:float = 200.0
var ray_length:float = 1200.0
onready var pr = get_parent()
onready var ray:RayCast2D = $RayCast2D

enum States {IDLE, MOVE}

var state = States.IDLE

func _ready():
	tween = Tween.new()
	tween2 = Tween.new()
	add_child(tween)
	add_child(tween2)
	tween.interpolate_property(self, "position", position, position - Vector2(0, float_height), 0.5, trans_tween, Tween.EASE_IN_OUT)
	tween.start()
	tween.connect("tween_all_completed", self, "on_tween_complete")
	tween2.connect("tween_all_completed", self, "on_tween2_complete")
	$HP.max_value = total_HP
	$HP.value = HP
	
	shoot_timer = Timer.new()
	add_child(shoot_timer)
	shoot_timer.wait_time = 1.0
	shoot_timer.start()
	shoot_timer.autostart = true
	shoot_timer.connect("timeout", self, "on_time_out")
	
	check_distance_timer = Timer.new()
	add_child(check_distance_timer)
	check_distance_timer.start(0.2)
	check_distance_timer.autostart = true
	check_distance_timer.connect("timeout", self, "check_distance")
	
	move_timer = Timer.new()
	add_child(move_timer)
	move_timer.start(3.0)
	move_timer.autostart = true
	move_timer.connect("timeout", self, "move_HX")

func on_time_out():
	shoot_timer.wait_time = 1.0
	if sees_player:
		var rand_rot = rand_range(0, PI/4)
		for i in range(0, 8):
			var rot = i * PI/4 + rand_rot
			cave_ref.add_proj(true, pr.position, 15.0, rot, load("res://Graphics/Cave/Projectiles/enemy_bullet.png"), atk * 2.0)

var move_path_v = []
func move_HX():
	var second_condition = true
	if not sees_player:
		second_condition = state == States.IDLE
	if AI_enabled and second_condition:
		move_timer.stop()
		move_path_v = []
		var target_tile
		var curr_tile = cave_ref.get_tile_index(cave_tm.world_to_map(pr.position))
		var room_tiles = cave_ref.rooms[room].tiles
		var n = len(room_tiles)
		if sees_player:
			target_tile = cave_ref.get_tile_index(cave_tm.world_to_map(cave_ref.rover.position))
		else:
			target_tile = room_tiles[Helper.rand_int(0, n-1)]
		var i = 0
		while cave_ref.HX_tiles.has(target_tile) and i < 100:#If the tile is occupied by a HX
			var target_neighbours = a_n.get_point_connections(target_tile)
			var m = len(target_neighbours)
			target_tile = target_neighbours[Helper.rand_int(0, m-1)]
			i += 1
		if target_tile != curr_tile:
			cave_ref.HX_tiles.erase(curr_tile)
			cave_ref.HX_tiles.append(target_tile)
			move_path_v = a_n.get_point_path(curr_tile, target_tile)
			state = States.MOVE
		
func _process(delta):
	if state == States.MOVE:
		if len(move_path_v) > 0:
			var move_to = cave_tm.map_to_world(move_path_v[0]) + Vector2(100, 100)
			pr.position = pr.position.move_toward(move_to, delta * move_speed)
			if pr.position == move_to:
				move_path_v.remove(0)
		else:
			state = States.IDLE
			move_timer.start()
	if ray.enabled:
		ray.cast_to = (cave_ref.rover.position - pr.position).normalized() * ray_length
		if ray.get_collider() is KinematicBody2D:
			if not sees_player:
				sees_player = true
				move_HX()
				move_speed = 500.0
		else:
			sees_player = false
			move_speed = 200.0

func check_distance():
	var dist = pr.position.distance_to(cave_ref.rover.position)
	if dist < 2000:
		AI_enabled = true
		ray.enabled = true
	else:
		AI_enabled = false
		ray.enabled = false
		move_timer.start()

func on_tween_complete():
	tween2.interpolate_property(self, "position", position, position + Vector2(0, float_height), 0.5, trans_tween, Tween.EASE_IN_OUT)
	tween2.start()

func on_tween2_complete():
	tween.interpolate_property(self, "position", position, position - Vector2(0, float_height), 0.5, trans_tween, Tween.EASE_IN_OUT)
	tween.start()

func hit(damage:float):
	HP -= damage / def
	$HP.value = HP
	if HP <= 0:
		cave_ref.enemies_rekt[cave_ref.cave_floor - 1].append(spawn_tile)
		cave_ref.get_node("UI/Minimap").remove_child(MM_icon)
		cave_ref.remove_child(pr)
