class_name STMProjectile
extends Node2D

enum {BULLET, BOMB}

var type:int
var is_enemy_projectile:bool
var velocity:Vector2
var damage:int

func _ready():
	if is_enemy_projectile:
		$Area2D.collision_layer = 16
		$Area2D.collision_mask = 2

func _process(delta):
	position += delta * velocity
	if position.x >= 1400 or position.x < -120 or position.y < -120 or position.y > 840:
		queue_free()


func _on_area_2d_area_entered(area):
	if type == BULLET:
		var particles = preload("res://Scenes/STM/STMBulletParticles.tscn").instantiate()
		particles.position = position
		particles.queue_free_delay = 0.3
		get_parent().add_child(particles)
	area.get_parent().hit(damage)
	queue_free()
