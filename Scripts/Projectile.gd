class_name Projectile
extends KinematicBody2D

var velocity:Vector2 = Vector2.ZERO
var type:int
var texture
var damage
var enemy:bool
var cave_ref
var status_effects:Dictionary = {}
var timer:Timer
var fading:bool = false
var time_speed:float
var init_mod:Color
var laser_fade:float = 0.0
var deflected:bool = false
var pierce:int = 1

func _ready():
	$Sprite.texture = texture
	if type == Data.ProjType.LASER:
		$Round.disabled = true
		$Line.disabled = false
	elif type == Data.ProjType.BUBBLE:
		timer = Timer.new()
		add_child(timer)
		timer.start(3.0)
		timer.one_shot = true
		timer.connect("timeout", self, "on_timeout")
	if not enemy and not deflected:
		if cave_ref.enhancements.has("laser_1"):
			pierce = 3
		elif cave_ref.enhancements.has("laser_0"):
			pierce = 2
	init_mod = $Sprite.modulate

func on_timeout():
	fading = true

func _physics_process(delta):
	if type == Data.ProjType.BUBBLE:
		velocity = velocity.move_toward(Vector2.ZERO, delta * 5.0)
		if fading:
			modulate.a -= 0.03 * delta * 60 * time_speed
			if modulate.a <= 0:
				set_physics_process(false)
				queue_free()
	var collision = move_and_collide(velocity)
	if collision:
		collide(collision)
	if not enemy and not deflected:
		laser_fade = min(laser_fade + 0.03 * delta * 60 * time_speed, 1)
		$Sprite.modulate = lerp(init_mod, init_mod / 20.0, laser_fade)

func collide(collision:KinematicCollision2D):
	var body = collision.collider
	if body is KinematicBody2D:#If the projectile collides with an entity (not walls)
		if not enemy:#if the projectile comes from the player
			if deflected:#No distance penalty for deflected projectiles
				var dmg:float = damage / body.def
				Helper.show_dmg(round(dmg), position, cave_ref)
				body.hit(dmg)
			else:
				var dmg_penalty:float = max(1, position.distance_to(cave_ref.rover.position) / 300.0)
				var dmg:float = damage / dmg_penalty / body.def
				Helper.show_dmg(round(dmg), position, cave_ref)
				body.hit(dmg)
				pierce -= 1
			if pierce <= 0:
				set_physics_process(false)
				queue_free()
		else:#if the projectile comes from the enemy
			if not cave_ref.ability_timer.is_stopped() and cave_ref.ability == "armor_3":
				deflected = true
			elif cave_ref.enhancements.has("armor_2"):
				deflected = randf() < 0.3
			elif cave_ref.enhancements.has("armor_0"):
				deflected = randf() < 0.15
			if deflected:
				velocity = -2.0 * velocity.reflect(collision.normal)
				collision_layer = 8
				collision_mask = 5
				enemy = false
				if cave_ref.enhancements.has("armor_1"):
					damage *= 4.0
				$DeflectedParticles.emitting = true
			else:
				var dmg:float = damage / cave_ref.def / cave_ref.rover_size
				cave_ref.hit_player(dmg, status_effects)
				set_physics_process(false)
				queue_free()
	else:
		if type == Data.ProjType.BUBBLE:#Bubble projectiles reflect off of walls
			velocity = -velocity.reflect(collision.normal)
		else:#Other projectiles get destroyed
			set_physics_process(false)
			queue_free()
