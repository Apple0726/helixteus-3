extends "HXBase.gd"

var rot:float
var counter:int = 0
var SA_counter:int = 0
var sgn:int = 1

func _ready():
	super()
	move_timer = Timer.new()
	add_child(move_timer)
	move_timer.start(3.0)
	move_timer.autostart = true
	move_timer.connect("timeout",Callable(self,"move_HX"))
	
	shoot_timer = Timer.new()
	add_child(shoot_timer)
	shoot_timer.wait_time = 0.04
	shoot_timer.start()
	shoot_timer.autostart = true
	shoot_timer.connect("timeout",Callable(self,"on_time_out"))
	
	if cave_ref.is_aurora_cave:
		special_attack_timer = Timer.new()
		add_child(special_attack_timer)
		special_attack_timer.wait_time = 0.05
		special_attack_timer.start()
		special_attack_timer.autostart = true
		special_attack_timer.connect("timeout",Callable(self,"on_SA_time_out"))
	
	ray_length = 1200.0
	idle_move_speed = 200.0 * cave_ref.time_speed
	atk_move_speed = 400.0 * cave_ref.time_speed

func set_rand():
	rot = randf_range(0, 2*PI/5)
	if randf() < 0.5:
		sgn = 1
	else:
		sgn = -1

func on_time_out():
	shoot_timer.wait_time = 0.04
	if SA_counter < 90.0 / cave_ref.time_speed / cave_ref.enemy_attack_rate:
		if (sees_player or is_aggr()) and counter < 6:
			for i in range(0, 5):
				cave_ref.add_enemy_proj(_class, rot + i * 2*PI/5 * sign(sgn), atk, position)
				rot += 0.02
		counter += 1
		if counter >= 6 + 39.0 / cave_ref.time_speed / cave_ref.enemy_attack_rate:
			counter = 0
			rot = randf_range(0, 2*PI/5)
			if randf() < 0.5:
				sgn = 1
			else:
				sgn = -1

func on_SA_time_out():
	special_attack_timer.wait_time = 0.05
	if (sees_player or is_aggr()) and SA_counter >= 90.0 / cave_ref.time_speed / cave_ref.enemy_attack_rate:
		for i in range(0, 5):
			cave_ref.add_enemy_proj(_class, rot + i * 2*PI/5 * sign(sgn), atk, position)
			rot += 0.02
	SA_counter += 1
	if SA_counter >= 90.0 / cave_ref.time_speed / cave_ref.enemy_attack_rate + 16:
		SA_counter = 0
