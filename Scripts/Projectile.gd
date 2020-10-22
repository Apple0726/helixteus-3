extends KinematicBody2D

var velocity:Vector2 = Vector2.ZERO
var texture
var damage
var enemy:bool
var cave_ref

func _ready():
	$Sprite.texture = texture

func _physics_process(_delta):
	var target_coll:KinematicCollision2D = move_and_collide(velocity)
	if target_coll != null:
		var target = target_coll.get_collider()
		
		if target is KinematicBody2D:
			if not enemy:
				var dmg_penalty:float = position.distance_to(cave_ref.rover.position) / 200.0
				cave_ref.show_dmg(int(damage / dmg_penalty), target_coll.position)
				target.hit(damage / dmg_penalty)
			else:
				cave_ref.hit_player(damage / cave_ref.def)
				cave_ref.show_dmg(int(damage / cave_ref.def), target_coll.position)
		get_parent().remove_child(self)
