extends KinematicBody2D

var velocity:Vector2 = Vector2.ZERO
var texture
var damage
var enemy:bool
var cave_ref

func _ready():
	$Sprite.texture = texture

func _physics_process(_delta):
	var target_coll = move_and_collide(velocity)
	if target_coll != null:
		var target = target_coll.get_collider()
		if target is KinematicBody2D:
			if not enemy:
				var dmg_penalty:float = position.distance_to(cave_ref.rover.position) / 200.0
				target.hit(damage / dmg_penalty)
			else:
				cave_ref.hit_player(damage)
		get_parent().remove_child(self)
