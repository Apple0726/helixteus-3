class_name Projectile
extends KinematicBody2D

onready var seeking_ray:RayCast2D = $SeekingRay
onready var sprite = $Sprite

var speed:float = 0.0
var direction:Vector2 = Vector2.ZERO#Normalized
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
var deflected:bool = false
var pierce:int = 1
var seeking_body:KinematicBody2D = null
var seek_speed:float = 1.0
var dont_hit_again = []

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
	init_mod = $Sprite.modulate

func on_timeout():
	fading = true

func _physics_process(delta):
	if type == Data.ProjType.BUBBLE:
		speed = move_toward(speed, 0.0, delta * 5.0)
		if fading:
			modulate.a -= 0.03 * delta * 60 * time_speed
			if modulate.a <= 0:
				queue_free()
	elif type == Data.ProjType.PURPLE:
		speed += 0.35 * delta * 60.0 * time_speed
	var collision = move_and_collide(speed * direction)
	if collision:
		collide(collision)
	if not enemy and not deflected:
		if seeking_body and is_instance_valid(seeking_body):
			var th:float = atan2(seeking_body.position.y - position.y, seeking_body.position.x - position.x)
			seeking_ray.cast_to = polar2cartesian(1500, th - rotation)
			if seeking_ray.get_collider() is KinematicBody2D:
				direction = direction.move_toward(polar2cartesian(1, th), delta * 60.0 * speed / 1500.0 * seek_speed).normalized()
				rotation = direction.angle()

func collide(collision:KinematicCollision2D):
	var body = collision.collider
	if body is KinematicBody2D:#If the projectile collides with an entity (not walls)
		if not enemy:#if the projectile comes from the player
			if deflected:#No distance penalty for deflected projectiles
				var dmg:float = damage / body.def
				Helper.show_dmg(round(dmg), position, cave_ref)
				body.hit(dmg)
			else:
				if body.spawn_tile in dont_hit_again:
					body.give_temporary_invincibility(0.2)
					return
				var dmg_penalty:float = max(1, position.distance_to(cave_ref.rover.position) / 300.0)
				var dmg:float = damage / dmg_penalty / body.def
				Helper.show_dmg(round(dmg), position, cave_ref)
				for effect in status_effects:
					if not body.status_effects.has(effect):
						body.status_effects[effect] = status_effects[effect]
						if effect == "stun":
							body.get_node("Sprite/Stun").visible = true
				body.hit(dmg)
				pierce -= 1
				dont_hit_again.append(body.spawn_tile)
			if pierce <= 0:
				queue_free()
		else:#if the projectile comes from the enemy
			if not cave_ref.ability_timer.is_stopped() and cave_ref.ability == "armor_3":
				deflected = true
			elif cave_ref.enhancements.has("armor_2"):
				deflected = randf() < 0.3
			elif cave_ref.enhancements.has("armor_0"):
				deflected = randf() < 0.15
			if deflected:
				direction = -direction.reflect(collision.normal)
				speed *= 2.0
				collision_layer = 8
				collision_mask = 5
				enemy = false
				if cave_ref.enhancements.has("armor_1"):
					damage *= 4.0
				$DeflectedParticles.emitting = true
			else:
				var dmg:float = damage / cave_ref.def / cave_ref.rover_size
				cave_ref.hit_player(dmg, status_effects)
				queue_free()
	else:
		if type == Data.ProjType.BUBBLE:#Bubble projectiles reflect off of walls
			direction = -direction.reflect(collision.normal)
		else:#Other projectiles get destroyed
			queue_free()
