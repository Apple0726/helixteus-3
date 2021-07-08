extends "res://Scripts/HX_Cave.gd"

func _ready():
	$Sprite.texture = load("res://Graphics/HX/2.png")
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
	shoot_timer.wait_time = 0.3 / cave_ref.time_speed
	if sees_player:
		var rand_rot = rand_range(0, PI/2)
		for i in range(0, 4):
			var rot = i * PI/2 + rand_rot
			cave_ref.add_proj(true, pr.position, 12.0, rot, cave_ref.bullet_texture, atk * 2.0)
