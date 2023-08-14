extends CharacterBody2D

var HP:float
var total_HP:float
var atk:float
var def:float
var _class:int
var MM_icon
var cave_ref
var shoot_timer:Timer
var special_attack_timer:Timer
var check_distance_timer:Timer
var move_timer:Timer
var aggressive_timer:Timer
var sees_player:bool = false
var AI_enabled:bool = false
var a_n:AStar2D
var cave_tm:TileMap
var room:int
var spawn_tile:int#Tile on which the enemy spawned
var move_speed:float = 200.0
var idle_move_speed:float
var atk_move_speed:float
var ray_length:float
var status_effects:Dictionary = {}
@onready var ray:RayCast2D = $RayCast2D

enum {IDLE, MOVE}

var state = IDLE

func _ready():
	$Info/HP.max_value = total_HP
	$Info/HP.value = HP
	
	check_distance_timer = Timer.new()
	add_child(check_distance_timer)
	check_distance_timer.start(0.2)
	check_distance_timer.autostart = true
	check_distance_timer.connect("timeout",Callable(self,"check_distance"))
	connect("tree_exited",Callable(self,"on_tree_exited"))
	
	aggressive_timer = Timer.new()
	aggressive_timer.one_shot = true
	add_child(aggressive_timer)
	

func on_tree_exited():
	queue_free()

func is_aggr():
	return aggressive_timer and not aggressive_timer.is_stopped()

func is_not_aggr():
	return not aggressive_timer or aggressive_timer.is_stopped()

var move_path_v = []
func move_HX():
	if not move_timer:
		return
	var second_condition = true
	if not sees_player:
		second_condition = state == IDLE
	if AI_enabled and second_condition or is_aggr():
		move_timer.stop()
		move_path_v = []
		var target_tile
		var curr_tile = cave_ref.get_tile_index(cave_tm.local_to_map(position))
		var room_tiles = cave_ref.rooms[room].tiles
		var n = len(room_tiles)
		if sees_player or is_aggr():
			target_tile = cave_ref.get_tile_index(cave_tm.local_to_map(cave_tm.to_local(cave_ref.rover.position)))
		else:
			target_tile = room_tiles[randi() % n]
		var i = 0
		while cave_ref.HX_tiles.has(target_tile) and i < 100:#If the tile is occupied by a HX
			var target_neighbours = a_n.get_point_connections(target_tile)
			var m = len(target_neighbours)
			if m == 0:
				break
			target_tile = target_neighbours[randi() % m]
			i += 1
		if target_tile != curr_tile:
			cave_ref.HX_tiles.erase(curr_tile)
			cave_ref.HX_tiles.append(target_tile)
			move_path_v = a_n.get_point_path(curr_tile, target_tile)
			state = MOVE
		
func _process(delta):
	if not status_effects.has("stun"):
		if state == MOVE:
			if len(move_path_v) > 0:
				var move_to = cave_tm.map_to_local(move_path_v[0])
				position = position.move_toward(move_to, delta * move_speed)
				if position == move_to:
					move_path_v.remove_at(0)
			else:
				state = IDLE
				move_timer.start()
		if ray.enabled and is_not_aggr():
			ray.target_position = (cave_ref.rover.position - position).normalized() * ray_length
			if ray.get_collider() is CharacterBody2D:
				if not sees_player:
					sees_player = true
					if move_timer:
						move_HX()
						move_speed = atk_move_speed
			else:
				sees_player = false
				move_speed = idle_move_speed
	for effect in status_effects.keys():
		status_effects[effect] -= delta * cave_ref.time_speed
		if status_effects[effect] < 0:
			status_effects.erase(effect)
			if effect == "stun":
				$Sprite2D/Stun.visible = false

func chase_player():
	var not_chasing = aggressive_timer.is_stopped()
	aggressive_timer.wait_time = 8.0
	aggressive_timer.start()
	if not_chasing:
		move_HX()
	move_speed = atk_move_speed

func check_distance():
	var dist = position.distance_to(cave_ref.rover.position)
	if dist < 2000:
		AI_enabled = true
		ray.enabled = true
	else:
		AI_enabled = false
		ray.enabled = false
		aggressive_timer.stop()
		if move_timer:
			move_timer.start()

var HP_tween

func hit(damage:float):
	HP -= damage
	if is_instance_valid(HP_tween):
		HP_tween.kill()
	if HP <= 0:
		cave_ref.game.stats_univ.enemies_rekt_in_caves += 1
		cave_ref.game.stats_dim.enemies_rekt_in_caves += 1
		cave_ref.game.stats_global.enemies_rekt_in_caves += 1
		cave_ref.enemies_rekt[cave_ref.cave_floor - 1].append(spawn_tile)
		MM_icon.queue_free()
		queue_free()
	else:
		chase_player()
		$Info/HP.modulate = Color.RED
		HP_tween = create_tween()
		HP_tween.set_parallel(true)
		HP_tween.tween_property($Info/HP, "modulate", Color.GREEN, 0.3)
		HP_tween.tween_property($Info/HP, "value", HP, 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	$HurtAnimation.stop()
	$HurtAnimation.play("Hurt")

func RoD_damage():
	var dmg:float = cave_ref.laser_damage / def
	Helper.show_dmg(round(dmg), position, cave_ref, 80)
	hit(dmg)

func on_RoD_timeout():
	if HP > 0 and status_effects.has("RoD"):
		$RoDTimer.start(0.2 / cave_ref.time_speed)
		RoD_damage()

func on_proj_enter(body):#This signal is connected with code (during enemy generation in Cave.gd)
	if body is Projectile and not body.seeking_body:
		body.seeking_body = self
		body.get_node("SeekingRay").enabled = true


func on_proj_exit(body):#This signal is connected with code (during enemy generation in Cave.gd)
	if body is Projectile:
		body.seeking_body = null
		body.get_node("SeekingRay").enabled = false

func give_temporary_invincibility(duration:float):
	collision_mask = 0
	var timer = Timer.new()
	add_child(timer)
	timer.start(duration)
	timer.connect("timeout",Callable(self,"reset_invincibility"))

func reset_invincibility():
	collision_mask = 8
