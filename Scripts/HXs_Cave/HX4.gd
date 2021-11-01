extends "res://Scripts/HX_Cave.gd"

var rot:float
var counter:int = 0

func _ready():
	move_timer = Timer.new()
	add_child(move_timer)
	move_timer.start(3.0)
	move_timer.autostart = true
	move_timer.connect("timeout", self, "move_HX")
	
	shoot_timer = Timer.new()
	add_child(shoot_timer)
	shoot_timer.wait_time = 0.04
	shoot_timer.start()
	shoot_timer.autostart = true
	shoot_timer.connect("timeout", self, "on_time_out")
	
	aggressive_timer = Timer.new()
	aggressive_timer.one_shot = true
	add_child(aggressive_timer)
	
	ray_length = 1200.0
	idle_move_speed = 250.0 * cave_ref.time_speed
	atk_move_speed = 600.0 * cave_ref.time_speed

func set_rand():
	rot = rand_range(0, 2 * PI / 3)

func on_time_out():
	shoot_timer.wait_time = 0.04 / cave_ref.time_speed
	if (sees_player or is_aggr()) and counter < 4:
		for i in range(0, 3):
			if _class == 1:
				cave_ref.add_proj(true, position, 12.0, rot + i * 2*PI/3, cave_ref.bullet_texture, atk * 2.0)
			elif _class == 2:
				cave_ref.add_proj(true, position, 14.0, rot + i * 2*PI/3, cave_ref.laser_texture, atk * 1.3, Color(1.5, 1.5, 0.75), 2, 1.0, {"stun":0.5})
			elif _class == 3:
				cave_ref.add_proj(true, position, 10.0, rot + i * 2*PI/3, cave_ref.bomb_texture, atk * 3.5, Color.white, 1, 1.0, {"burn":5.0})
	counter += 1
	if counter >= 15:
		counter = 0
		rot = rand_range(0, 2 * PI / 3)
