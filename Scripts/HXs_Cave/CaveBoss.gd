class_name CaveBoss
extends KinematicBody2D

var cave_ref
var HPBar
var HP:int = 100
var total_HP:int = 100
var bullet_texture = preload("res://Graphics/Cave/Projectiles/enemy_bullet.png")
var laser_texture = preload("res://Graphics/Cave/Boss/Laser.png")
var bomb_scene = preload("res://Scenes/Cave/Bomb.tscn")
var target_pos:Vector2
onready var beam = $Beam
onready var rayL = $Beam/RayL
onready var rayR = $Beam/RayR
onready var rayT = $Beam/RayT
onready var rayB = $Beam/RayB
var next_attack:int = -1
var tween:Tween
var phase:int = 6
var speed:float = 0.0

func _ready():
	tween = Tween.new()
	add_child(tween)
	$AnimationPlayer.play("IdleArms")
	target_pos = Vector2(rand_range(2000, 4000), rand_range(2000, 4000))
	set_process(false)

func _process(delta):
	var diff_v:Vector2 = target_pos - position
	if diff_v.length() > 10:
		position += diff_v.normalized() * speed
	else:
		target_pos = Vector2(rand_range(2000, 4000), rand_range(2000, 4000))
	if next_attack != -1:
		call("attack_%s" % next_attack)
		next_attack = -1
	if beam.visible:
		var fade_speed = 0.01
		if phase <= 4:
			fade_speed = 0.006
		beam.modulate.a -= fade_speed * delta * 60
		cave_ref.shaking.y = rand_range(-300, 300) * beam.modulate.a
		if beam.modulate.a <= 0:
			beam.visible = false
			beam.modulate.a = 1
			rayL.enabled = false
			rayR.enabled = false
			rayT.enabled = false
			rayB.enabled = false
			if phase >= 5:
				next_attack = 4
			return
		if rayL.is_colliding() or rayR.is_colliding() or rayT.is_colliding() or rayB.is_colliding():
			var dmg:float = 1.0
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
			$Particles2D.amount = 30
		elif phase == 5:
			HPBar.get_node("Particles2D").position = Vector2(0, 62)
			$Particles2D.amount = 45
		elif phase == 4:
			HPBar.get_node("Particles2D").position = Vector2(-17, 54)
			$Particles2D.amount = 60
		HPBar.get_node("Particles2D").emitting = true
		phase -= 1
		HPBar.get_node("Orbs").texture = load("res://Graphics/Cave/Boss/HPBar%sOrbs.png" % phase)
		HP = total_HP
	tween.interpolate_property(HPBar.get_node("HPBar"), "value", null, HP, 0.5, Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.start()
	HPBar.get_node("HPText").text = "%s / %s" % [HP, total_HP]

func attack_1():
	$AnimationPlayer.play("IdleArms", -1, 1.0 if phase == 6 else 1.5)
	speed = 0.0
	var rot:float = 0;
	for i in 15:
		for j in 3:
			cave_ref.add_proj(true, cave_ref.boss.position + Vector2(-108, -108), 3 if phase == 6 else 10, deg2rad(-125 - j * 10 + rot), bullet_texture, 5)
		for j in 3:
			cave_ref.add_proj(true, cave_ref.boss.position + Vector2(108, 108), 3 if phase == 6 else 10, deg2rad(35 + j * 10 + rot), bullet_texture, 5)
		for j in 3:
			cave_ref.add_proj(true, cave_ref.boss.position + Vector2(-108, 108), 3 if phase == 6 else 10, deg2rad(125 + j * 10 + rot), bullet_texture, 5)
		for j in 3:
			cave_ref.add_proj(true, cave_ref.boss.position + Vector2(108, -108), 3 if phase == 6 else 10, deg2rad(-35 - j * 10 + rot), bullet_texture, 5)
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
			cave_ref.add_proj(true, cave_ref.boss.position + Vector2(-244, -60), 30, rand_range(-PI/2 - spread, -PI/2 + spread), laser_texture, 5)
		for j in 3:
			cave_ref.add_proj(true, cave_ref.boss.position + Vector2(244, -56), 30, rand_range(-PI/2 - spread, -PI/2 + spread), laser_texture, 5)
		for j in 3:
			cave_ref.add_proj(true, cave_ref.boss.position + Vector2(-244, 60), 30, rand_range(PI/2 - spread, PI/2 + spread), laser_texture, 5)
		for j in 3:
			cave_ref.add_proj(true, cave_ref.boss.position + Vector2(244, 60), 30, rand_range(PI/2 - spread, PI/2 + spread), laser_texture, 5)
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

func attack_4():
	$AnimationPlayer.play("LaserBeams", -1, -1.0 if phase == 6 else -1.5, true)
	yield($AnimationPlayer, "animation_finished")
	next_attack = 1 if phase >= 5 else 5

func attack_5():
	$AnimationPlayer.play("IdleArms", -1, 1.5 if phase == 4 else 2.0)
	speed = 0.0
	for i in 8:
		for j in 36:
			cave_ref.add_proj(true, cave_ref.boss.position, 9 if phase == 4 else 13, deg2rad(j * 10 + (5 if i % 2 == 0 else 0)), bullet_texture, 5)
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
			cave_ref.add_proj(true, cave_ref.boss.position + Vector2(0, -124), 30, rand_range(-PI/2 - spread, -PI/2 + spread), laser_texture, 5)
		for j in 3:
			cave_ref.add_proj(true, cave_ref.boss.position + Vector2(0, 124), 30, rand_range(PI/2 - spread, PI/2 + spread), laser_texture, 5)
		yield(get_tree().create_timer(0.07 if phase == 4 else 0.04), "timeout")
	next_attack = 8


func attack_8():
	$AnimationPlayer.play("LaserBeams", -1, -1.5 if phase == 4 else -2.0, true)
	yield($AnimationPlayer, "animation_finished")
	next_attack = 5 if phase >= 3 else 9

func attack_9():
	pass
