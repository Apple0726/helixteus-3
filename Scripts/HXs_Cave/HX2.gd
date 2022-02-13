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
			if _class == 1:
				cave_ref.add_proj(true, position, 12.0, rot, cave_ref.bullet_texture, atk * Data.cave_enemy_proj[0].dmg_mult, Data.cave_enemy_proj[0].mod / min(1.0, cave_ref.enemy_projectile_size))
			elif _class == 2:
				cave_ref.add_proj(true, position, 14.0, rot, cave_ref.laser_texture, atk  * Data.cave_enemy_proj[1].dmg_mult, Data.cave_enemy_proj[1].mod / min(1.0, cave_ref.enemy_projectile_size), Data.ProjType.LASER, 1.0, {"stun":0.75})
			elif _class == 3:
				cave_ref.add_proj(true, position, 10.0, rot, cave_ref.bubble_texture, atk * Data.cave_enemy_proj[2].dmg_mult, Data.cave_enemy_proj[2].mod / min(1.0, cave_ref.enemy_projectile_size), Data.ProjType.BUBBLE)
