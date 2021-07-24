extends "res://Scripts/HX_Cave.gd"

var rot:float
var counter:int = 0
var sgn:int = 1

func _ready():
	$Sprite.texture = load("res://Graphics/HX/3.png")
	
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
	idle_move_speed = 200.0 * cave_ref.time_speed
	atk_move_speed = 400.0 * cave_ref.time_speed

func set_rand():
	rot = rand_range(0, 2*PI/5)
	if randf() < 0.5:
		sgn = 1
	else:
		sgn = -1

func on_time_out():
	shoot_timer.wait_time = 0.04 / cave_ref.time_speed
	if (sees_player or is_aggr()) and counter < 6:
		for i in range(0, 5):
			cave_ref.add_proj(true, position, 10.0, rot + i * 2*PI/5 * sign(sgn), cave_ref.bullet_texture, atk * 2.0)
			rot += 0.02
	counter += 1
	if counter >= 50:
		counter = 0
		rot = rand_range(0, 2*PI/5)
		if randf() < 0.5:
			sgn = 1
		else:
			sgn = -1
