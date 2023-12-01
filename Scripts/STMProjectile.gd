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
	if type == BOMB or is_enemy_projectile:
		$CollisionShape2DBullet.disabled = true
		$CollisionShape2DBomb.disabled = false

func _process(delta):
	position += delta * velocity * STM_node.minigame_time_speed
	if position.x >= 1400 or position.x < -120 or position.y < -120 or position.y > 840:
		queue_free()

func add_effects(scene, particle_amount, impact_light_queue_free_delay, impact_light_scale = 1.0):
	var particles = scene.instantiate()
	particles.position = position
	particles.emitting = true
	particles.amount = particle_amount
	STM_node.get_node("GlowLayer").add_child(particles)
	var impact_light = Sprite2D.new()
	impact_light.texture = preload("res://Graphics/Misc/bullet.png")
	impact_light.scale *= impact_light_scale
	impact_light.position = position
	var tween = get_tree().create_tween()
	tween.tween_property(impact_light, "modulate:a", 0.0, impact_light_queue_free_delay)
	tween.tween_callback(impact_light.queue_free)
	STM_node.get_node("GlowLayer").add_child(impact_light)
	particles.finished.connect(particles.queue_free)


func _on_area_entered(area):
	if type == BULLET:
		add_effects(preload("res://Scenes/STM/STMBulletParticles.tscn"), 16, 0.1)
	elif type == BOMB:
		add_effects(preload("res://Scenes/STM/STMBombParticles.tscn"), 104 + STM_node.bomb_lv * 24, 0.2, 3.4 + STM_node.bomb_lv * 0.6)
		var white_rect:ColorRect = STM_node.get_node("WhiteRect")
		white_rect.color.a = 0.04 + STM_node.bomb_lv * 0.01
		var tween = get_tree().create_tween()
		tween.tween_property(white_rect, "color:a", 0.0, 0.3 + STM_node.bomb_lv * 0.02)
		if Settings.screen_shake:
			STM_node.get_node("Camera2D/Screenshake").start(0.5, 15, 4)
	area.get_parent().hit(damage)
	queue_free()
