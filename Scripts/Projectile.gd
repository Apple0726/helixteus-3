class_name Projectile
extends Area2D

var velocity:Vector2 = Vector2.ZERO
var texture
var damage
var enemy:bool
var cave_ref

func _ready():
	$Sprite.texture = texture

func _physics_process(delta):
	position += velocity * delta * 60

func _on_Sprite_body_entered(body):
	if body is KinematicBody2D:
		if not enemy:#if the shooter of the projectile is not the enemy (i.e. the player)
			var dmg:float
			var dmg_penalty:float = max(1, position.distance_to(cave_ref.rover.position) / 300.0)
			if body is CaveBoss:
				if dmg_penalty == 1:
					dmg = 2
				else:
					dmg = 1
			else:
				dmg = damage / dmg_penalty / pow(body.def, cave_ref.DEF_EXPO)
			Helper.show_dmg(int(dmg), position, cave_ref)
			body.hit(dmg)
		else:
			var dmg:float = damage / pow(cave_ref.def, cave_ref.DEF_EXPO) / cave_ref.rover_size
			cave_ref.hit_player(dmg)
			if cave_ref.HP >= 0:
				Helper.show_dmg(int(dmg), body.position, cave_ref)
	get_parent().call_deferred("remove_child", self)
	queue_free()
