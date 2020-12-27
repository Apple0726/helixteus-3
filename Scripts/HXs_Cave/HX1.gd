extends "res://Scripts/HX_Cave.gd"

func _ready():
	$Sprite.texture = load("res://Graphics/HX/1.png")
	
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
	
	aggressive_timer = Timer.new()
	aggressive_timer.one_shot = true
	add_child(aggressive_timer)
	
	ray_length = 1200.0
	idle_move_speed = 200.0
	atk_move_speed = 500.0

func set_rand():
	pass

func on_time_out():
	shoot_timer.wait_time = 1.0
	if sees_player or is_aggr():
		var rand_rot = rand_range(0, PI/4)
		for i in range(0, 8):
			var rot = i * PI/4 + rand_rot
			cave_ref.add_proj(true, pr.position, 12.0, rot, load("res://Graphics/Cave/Projectiles/enemy_bullet.png"), atk * 2.0)
