class_name STMProjectile
extends Area2D

enum {BULLET, BOMB}

var type:int
var is_enemy_projectile:bool
var velocity:Vector2
var damage:int
var STM_node:Node2D

func _ready():
	if is_enemy_projectile:
		collision_layer = 16
		collision_mask = 2

func _process(delta):
	position += delta * velocity
	if position.x >= 1400 or position.x < -120 or position.y < -120 or position.y > 840:
		queue_free()

func add_effects(scene, particles_queue_free_delay, impact_light_queue_free_delay, impact_light_scale = 1.0):
	var particles = scene.instantiate()
	particles.position = position
	particles.emitting = true
	particles.queue_free_delay = particles_queue_free_delay
	STM_node.get_node("GlowLayer").add_child(particles)
	var impact_light = Sprite2D.new()
	impact_light.texture = preload("res://Graphics/Misc/bullet.png")
	impact_light.set_script(preload("res://Scripts/STMParticles.gd"))
	impact_light.scale *= impact_light_scale
	impact_light.position = position
	var tween = get_tree().create_tween()
	tween.tween_property(impact_light, "modulate:a", 0.0, impact_light_queue_free_delay)
	impact_light.queue_free_delay = impact_light_queue_free_delay
	STM_node.get_node("GlowLayer").add_child(impact_light)


func _on_area_entered(area):
	if type == BULLET:
		add_effects(preload("res://Scenes/STM/STMBulletParticles.tscn"), 0.3, 0.1)
	elif type == BOMB:
		add_effects(preload("res://Scenes/STM/STMBombParticles.tscn"), 2.0, 0.2, 4.0)
		var white_rect:ColorRect = STM_node.get_node("WhiteRect")
		white_rect.color.a = 0.05
		var tween = get_tree().create_tween()
		tween.tween_property(white_rect, "color:a", 0.0, 0.3)
		if Settings.screen_shake:
			STM_node.get_node("Camera2D/Screenshake").start(0.5, 15, 4)
	area.get_parent().hit(damage)
	queue_free()
