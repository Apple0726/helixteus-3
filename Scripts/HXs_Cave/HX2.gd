extends "res://Scripts/HX_Cave.gd"

func _ready():
	super()
	shoot_timer = Timer.new()
	add_child(shoot_timer)
	shoot_timer.wait_time = 0.2
	shoot_timer.start()
	shoot_timer.autostart = true
	shoot_timer.connect("timeout",Callable(self,"on_time_out"))
	ray_length = 1400.0

	if cave_ref.aurora:
		special_attack_timer = Timer.new()
		add_child(special_attack_timer)
		special_attack_timer.wait_time = 4.0
		special_attack_timer.start()
		special_attack_timer.autostart = true
		special_attack_timer.connect("timeout",Callable(self,"on_SA_time_out"))

func set_rand():
	pass

func on_time_out():
	shoot_timer.wait_time = 0.3 / cave_ref.time_speed / cave_ref.enemy_attack_rate
	if (sees_player or is_aggr()) and modulate.a == 1.0:
		var rand_rot = randf_range(0, PI/2)
		for i in range(0, 4):
			var rot = i * PI/2 + rand_rot
			cave_ref.add_enemy_proj(_class, rot, atk, position)

func on_SA_time_out():
	special_attack_timer.wait_time = 3.0 / cave_ref.time_speed / cave_ref.enemy_attack_rate
	if sees_player or is_aggr():
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
		tween.tween_callback(Callable(self,"teleport")).set_delay(0.5)

func teleport():
	var curr_tile:int = cave_ref.get_tile_index(cave_tm.local_to_map(position))
	var target_tile:int = cave_ref.get_tile_index(cave_tm.local_to_map(cave_ref.rover.position))
	var i = 0
	while cave_ref.HX_tiles.has(target_tile) and i < 100:#If the tile is occupied by a HX
		var target_neighbours = a_n.get_point_connections(target_tile)
		var m = len(target_neighbours)
		if m == 0:
			break
		target_tile = target_neighbours[Helper.rand_int(0, m-1)]
		i += 1
	cave_ref.HX_tiles.erase(curr_tile)
	cave_ref.HX_tiles.append(target_tile)
	position.x = target_tile % cave_ref.cave_size * 200 + 100
	position.y = target_tile / cave_ref.cave_size * 200 + 100
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.5)
