extends "res://Scripts/HX_Cave.gd"

var rand_rot:float = 0.0

func _ready():
	
	move_timer = Timer.new()
	add_child(move_timer)
	move_timer.start(3.0)
	move_timer.autostart = true
	move_timer.connect("timeout", self, "move_HX")
	
	shoot_timer = Timer.new()
	add_child(shoot_timer)
	shoot_timer.wait_time = 1.0
	shoot_timer.start()
	shoot_timer.autostart = true
	shoot_timer.connect("timeout", self, "on_time_out")
	
	if cave_ref.aurora:
		special_attack_timer = Timer.new()
		add_child(special_attack_timer)
		special_attack_timer.wait_time = 3.0
		special_attack_timer.start()
		special_attack_timer.autostart = true
		special_attack_timer.connect("timeout", self, "on_SA_time_out")
	
	ray_length = 1200.0
	idle_move_speed = 200.0 * cave_ref.time_speed
	atk_move_speed = 500.0 * cave_ref.time_speed

func set_rand():
	pass

func on_time_out():
	shoot_timer.wait_time = 1.0 / cave_ref.time_speed / cave_ref.enemy_attack_rate
	if sees_player or is_aggr():
		rand_rot = rand_range(0, PI/4)
		for i in range(0, 8):
			var rot = i * PI/4 + rand_rot
			cave_ref.add_enemy_proj(_class, rot, atk, position)

func on_SA_time_out():
	special_attack_timer.wait_time = 3.0 / cave_ref.time_speed / cave_ref.enemy_attack_rate
	if sees_player or is_aggr():
		for i in range(0, 8):
			var rot = i * PI/4 + rand_rot + PI/8
			cave_ref.add_enemy_proj(_class, rot, atk, position, 1.3)
