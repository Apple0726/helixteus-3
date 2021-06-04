class_name CaveBoss
extends KinematicBody2D

var cave_ref
var HPBar
var HP:int = 200
var total_HP:int = 200
var bullet_texture = preload("res://Graphics/Cave/Projectiles/enemy_bullet.png")
var laser_texture = preload("res://Graphics/Cave/Boss/Laser.png")
var bomb_scene = preload("res://Scenes/Cave/Bomb.tscn")
var target_pos:Vector2
onready var beam = $Beam
onready var beam2 = $Beam2
onready var rayL = $Beam/RayL
onready var rayR = $Beam/RayR
onready var rayT = $Beam/RayT
onready var rayB = $Beam/RayB
var next_attack:int = -1
var tween:Tween
var tween2:Tween
var phase:int = 6
var speed:float = 0.0
var rekt:bool = false

func _ready():
	tween = Tween.new()
	tween2 = Tween.new()
	add_child(tween)
	add_child(tween2)
	$AnimationPlayer.play("IdleArms")
	target_pos = Vector2(rand_range(1000, 4000), rand_range(1000, 4000))
	set_process(false)
	rayL.add_to_group("rays")
	rayR.add_to_group("rays")
	rayT.add_to_group("rays")
	rayB.add_to_group("rays")
	$Beam2/RayL.add_to_group("rays")
	$Beam2/RayR.add_to_group("rays")
	$Beam2/RayT.add_to_group("rays")
	$Beam2/RayB.add_to_group("rays")

func _process(delta):
	if not rekt:
		var diff_v:Vector2 = target_pos - position
		if diff_v.length() > speed * 1.5:
			position += diff_v.normalized() * speed
		else:
			target_pos = Vector2(rand_range(1000, 4000), rand_range(1000, 4000))
		if next_attack != -1:
			call("attack_%s" % next_attack)
			next_attack = -1
	if beam.visible:
		var fade_speed = 0.01
		if phase <= 4:
			fade_speed = 0.006
		if phase <= 2:
			fade_speed = 0.015
		beam.modulate.a -= fade_speed * delta * 60
		cave_ref.shaking.y = rand_range(-300, 300) * beam.modulate.a
		if beam.modulate.a <= 0:
			beam.visible = false
			beam.modulate.a = 1
			for ray in get_tree().get_nodes_in_group("rays"):
				ray.enabled = false
			return
	if beam2.visible:
		beam2.modulate.a -= 0.015 * delta * 60
		cave_ref.shaking.y = rand_range(-300, 300) * beam2.modulate.a
		if beam2.modulate.a <= 0:
			beam2.visible = false
			beam2.modulate.a = 1
			for ray in get_tree().get_nodes_in_group("rays"):
				ray.enabled = false
			return
	if beam.visible or beam2.visible:
		var colliding = false
		for ray in get_tree().get_nodes_in_group("rays"):
			if ray.is_colliding():
				colliding = true
				break
		if colliding:
			var dmg:float = 2000.0 * delta * 60
			cave_ref.hit_player(dmg)
			if cave_ref.HP >= 0:
				Helper.show_dmg(int(dmg), cave_ref.rover.position, cave_ref)

func hit(dmg:int):
	if HPBar:
		HP -= dmg
		refresh_bar()

func refresh_bar():
	if HP <= 0:
		if phase == 6:
			HPBar.get_node("Particles2D").position = Vector2(17, 54)
		elif phase == 5:
			HPBar.get_node("Particles2D").position = Vector2(0, 62)
		elif phase == 4:
			HPBar.get_node("Particles2D").position = Vector2(-17, 54)
		elif phase == 3:
			HPBar.get_node("Particles2D").position = Vector2(17, 20)
		elif phase == 2:
			HPBar.get_node("Particles2D").position = Vector2(0, 13)
		elif phase == 1:
			HPBar.get_node("Particles2D").position = Vector2(-17, 20)
		HPBar.get_node("Particles2D").emitting = true
		phase -= 1
		if phase >= 1:
			$Particles2D.amount += 15
			HPBar.get_node("Orbs").texture = load("res://Graphics/Cave/Boss/HPBar%sOrbs.png" % phase)
			HP = total_HP
		else:
			$Particles2D.visible = false
			$CollisionPolygon2D.disabled = true
			$Light2D.enabled = false
			cave_ref.game.fourth_ship_hints.boss_rekt = true
			next_attack = -1
			$AnimationPlayer.play("Death")
			HPBar.get_node("Orbs").texture = null
			HP = 0
			rekt = true
	tween.interpolate_property(HPBar.get_node("HPBar"), "value", null, HP, 0.5, Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.start()
	HPBar.get_node("HPText").text = "%s / %s" % [HP, total_HP]

func attack_1():
	$AnimationPlayer.play("IdleArms", -1, 1.0 if phase == 6 else 1.5)
	speed = 0.0
	var rot:float = 0;
	for i in 15:
		for j in 3:
			cave_ref.add_proj(true, cave_ref.boss.position + Vector2(-108, -108), 3 if phase == 6 else 10, deg2rad(-125 - j * 10 + rot), bullet_texture, 5000000)
		for j in 3:
			cave_ref.add_proj(true, cave_ref.boss.position + Vector2(108, 108), 3 if phase == 6 else 10, deg2rad(35 + j * 10 + rot), bullet_texture, 5000000)
		for j in 3:
			cave_ref.add_proj(true, cave_ref.boss.position + Vector2(-108, 108), 3 if phase == 6 else 10, deg2rad(125 + j * 10 + rot), bullet_texture, 5000000)
		for j in 3:
			cave_ref.add_proj(true, cave_ref.boss.position + Vector2(108, -108), 3 if phase == 6 else 10, deg2rad(-35 - j * 10 + rot), bullet_texture, 5000000)
		#rot += 15
		yield(get_tree().create_timer(0.2 if phase == 6 else 0.1), "timeout")
	next_attack = 2 if phase >= 5 else 5

func attack_2():
	speed = 7.0 if phase == 6 else 10.0
	$AnimationPlayer.play("Bullets", -1, 1.0 if phase == 6 else 1.5)
	yield($AnimationPlayer, "animation_finished")
	var spread:float = 0.5 if phase == 6 else 1.0
	for i in 25:
		for j in 3:
			cave_ref.add_proj(true, cave_ref.boss.position + Vector2(-244, -60), 30, rand_range(-PI/2 - spread, -PI/2 + spread), laser_texture, 2000000, Color.white, 2)
		for j in 3:
			cave_ref.add_proj(true, cave_ref.boss.position + Vector2(244, -56), 30, rand_range(-PI/2 - spread, -PI/2 + spread), laser_texture, 2000000, Color.white, 2)
		for j in 3:
			cave_ref.add_proj(true, cave_ref.boss.position + Vector2(-244, 60), 30, rand_range(PI/2 - spread, PI/2 + spread), laser_texture, 2000000, Color.white, 2)
		for j in 3:
			cave_ref.add_proj(true, cave_ref.boss.position + Vector2(244, 60), 30, rand_range(PI/2 - spread, PI/2 + spread), laser_texture, 2000000, Color.white, 2)
		yield(get_tree().create_timer(0.1 if phase == 6 else 0.07), "timeout")
	$AnimationPlayer.play("Bullets", -1, -1.0 if phase == 6 else -1.5, true)
	yield($AnimationPlayer, "animation_finished")
	next_attack = 3 if phase >= 5 else 5

func attack_3():
	speed = 8.0 if phase == 6 else 13.0
	$AnimationPlayer.play("LaserBeams", -1, 1.0 if phase == 6 else 1.5)
	yield($AnimationPlayer, "animation_finished")
	beam.visible = true
	rayL.enabled = true
	rayR.enabled = true
	rayT.enabled = true
	rayB.enabled = true
	yield(get_tree().create_timer(1.6), "timeout")
	next_attack = 4

func attack_4():
	$AnimationPlayer.play("LaserBeams", -1, -1.0 if phase == 6 else -1.5, true)
	yield($AnimationPlayer, "animation_finished")
	next_attack = 1 if phase >= 5 else 5

func attack_5():
	$AnimationPlayer.play("IdleArms", -1, 1.5 if phase == 4 else 2.0)
	speed = 0.0
	for i in 8:
		for j in 36:
			cave_ref.add_proj(true, cave_ref.boss.position, 9 if phase == 4 else 13, deg2rad(j * 10 + (5 if i % 2 == 0 else 0)), bullet_texture, 5000000)
		yield(get_tree().create_timer(0.7 if phase == 4 else 0.4), "timeout")
	next_attack = 6

func attack_6():
	$AnimationPlayer.play("IdleArms", -1, 1.5 if phase == 4 else 2.0)
	speed = 0.0
	for i in 5:
		for j in 4:
			var bomb = bomb_scene.instance()
			bomb.velocity = Vector2(rand_range(-1, 1), rand_range(-1, 1))
			bomb.speed = rand_range(12, 46)
			bomb.cave_ref = cave_ref
			bomb.laser_texture = laser_texture
			bomb.position = position
			cave_ref.add_child(bomb)
		yield(get_tree().create_timer(1 if phase == 4 else 0.8), "timeout")
	yield(get_tree().create_timer(2 if phase == 4 else 1), "timeout")
	next_attack = 7

func attack_7():
	$AnimationPlayer.play("LaserBeams", -1, 1.5 if phase == 4 else 2.0)
	yield($AnimationPlayer, "animation_finished")
	beam.visible = true
	$Beam/BeamT.visible = false
	$Beam/BeamB.visible = false
	rayL.enabled = true
	rayR.enabled = true
	var spread:float = 1.0 if phase == 4 else 1.3
	for i in 40:
		for j in 3:
			cave_ref.add_proj(true, cave_ref.boss.position + Vector2(0, -124), 30, rand_range(-PI/2 - spread, -PI/2 + spread), laser_texture, 2000000, Color.white, 2)
		for j in 3:
			cave_ref.add_proj(true, cave_ref.boss.position + Vector2(0, 124), 30, rand_range(PI/2 - spread, PI/2 + spread), laser_texture, 2000000, Color.white, 2)
		yield(get_tree().create_timer(0.07 if phase == 4 else 0.04), "timeout")
	next_attack = 8


func attack_8():
	speed = 10.0
	$AnimationPlayer.play("LaserBeams", -1, -1.5 if phase == 4 else -2.0, true)
	yield($AnimationPlayer, "animation_finished")
	next_attack = 5 if phase >= 3 else 9

func attack_9():
	speed = 17.0 if phase == 2 else 25.0
	$AnimationPlayer.play("LaserBeams", -1, 2.0)
	yield($AnimationPlayer, "animation_finished")
	for i in 50:
		cave_ref.add_proj(true, cave_ref.boss.position + Vector2(-324, 0), 30, PI, laser_texture, 2000000, Color.red, 2)
		cave_ref.add_proj(true, cave_ref.boss.position + Vector2(324, 0), 30, 0, laser_texture, 2000000, Color.red, 2)
		cave_ref.add_proj(true, cave_ref.boss.position + Vector2(0, -124), 30, -PI/2, laser_texture, 2000000, Color.red, 2)
		cave_ref.add_proj(true, cave_ref.boss.position + Vector2(0, 124), 30, PI/2, laser_texture, 2000000, Color.red, 2)
		yield(get_tree().create_timer(0.03), "timeout")
		if rekt:
			return
	tween2.interpolate_property(self, "modulate", null, Color(1, 1, 1, 0), 0.8 if phase == 2 else 0.4)
	tween2.start()
	yield(tween2, "tween_all_completed")
	if rekt:
		modulate.a = 1
		return
	position = Vector2(rand_range(1000, 4000), rand_range(1000, 4000))
	target_pos = Vector2(rand_range(1000, 4000), rand_range(1000, 4000))
	tween2.interpolate_property(self, "modulate", null, Color(1, 1, 1, 1), 0.8 if phase == 2 else 0.4)
	tween2.start()
	yield(tween2, "tween_all_completed")
	for i in 50:
		cave_ref.add_proj(true, cave_ref.boss.position + Vector2(-324, 0), 30, PI, laser_texture, 2000000, Color.red, 2)
		cave_ref.add_proj(true, cave_ref.boss.position + Vector2(324, 0), 30, 0, laser_texture, 2000000, Color.red, 2)
		cave_ref.add_proj(true, cave_ref.boss.position + Vector2(0, -124), 30, -PI/2, laser_texture, 2000000, Color.red, 2)
		cave_ref.add_proj(true, cave_ref.boss.position + Vector2(0, 124), 30, PI/2, laser_texture, 2000000, Color.red, 2)
		yield(get_tree().create_timer(0.03), "timeout")
		if rekt:
			return
	next_attack = 10

func attack_10():
	speed = 0.0
	for i in 72:
		if phase == 2 and i >= 36:
			break
		var bomb = bomb_scene.instance()
		bomb.velocity = Vector2(cos(deg2rad(i * 10)), sin(deg2rad(i * 10)))
		bomb.speed = 10 if i < 36 else 5
		bomb.cave_ref = cave_ref
		bomb.laser_texture = laser_texture
		bomb.position = position
		cave_ref.add_child(bomb)
	yield(get_tree().create_timer(3), "timeout")
	if rekt:
		return
	next_attack = 11

func attack_11():
	speed = 15.0
	$Beam/BeamT.visible = true
	$Beam/BeamB.visible = true
	beam.visible = true
	rayL.enabled = true
	rayR.enabled = true
	rayT.enabled = true
	rayB.enabled = true
	yield(get_tree().create_timer(1.5), "timeout")
	if rekt:
		return
	$AnimationPlayer.play("LaserBeams", -1, -2.0, true)
	yield($AnimationPlayer, "animation_finished")
	beam2.visible = true
	$Beam2/RayT.enabled = true
	$Beam2/RayB.enabled = true
	$Beam2/RayL.enabled = true
	$Beam2/RayR.enabled = true
	yield(get_tree().create_timer(1.5), "timeout")
	next_attack = 9

func fade_away():#Only executed when boss is bribed with 50T money
	tween2.interpolate_property(self, "modulate", null, Color(1, 1, 1, 0), 1.2)
	tween2.start()
	yield(tween2, "tween_all_completed")
	$Particles2D.visible = false
	$CollisionPolygon2D.disabled = true
	$Light2D.enabled = false
	cave_ref.game.fourth_ship_hints.boss_rekt = true
