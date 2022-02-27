extends "res://Scripts/HX_Cave.gd"

func _ready():
	shoot_timer = Timer.new()
	add_child(shoot_timer)
	shoot_timer.wait_time = 0.2
	shoot_timer.start()
	shoot_timer.autostart = true
	shoot_timer.connect("timeout", self, "on_time_out")
	ray_length = 1400.0

func set_rand():
	pass

func on_time_out():
	shoot_timer.wait_time = 0.3 / cave_ref.time_speed / cave_ref.enemy_attack_rate
	if sees_player:
		var rand_rot = rand_range(0, PI/2)
		for i in range(0, 4):
			var rot = i * PI/2 + rand_rot
			cave_ref.add_enemy_proj(_class, rot, atk, position)
