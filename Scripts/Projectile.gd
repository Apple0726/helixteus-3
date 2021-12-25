class_name Projectile
extends Area2D

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
	position += velocity * delta * 60
	if type == Data.ProjType.BUBBLE:
		velocity = velocity.move_toward(Vector2.ZERO, delta * 5.0)
		if fading:
			modulate.a -= 0.03 * delta * 60 * time_speed
			if modulate.a <= 0:
				get_parent().remove_child(self)
				queue_free()
	if not enemy:
		laser_fade = min(laser_fade + 0.03 * delta * 60 * time_speed, 1)
		$Sprite.modulate = lerp(init_mod, init_mod / 20.0, laser_fade)

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
				dmg = damage / dmg_penalty / body.def
			Helper.show_dmg(int(dmg), position, cave_ref)
			body.hit(dmg)
		else:
			var dmg:float = damage / cave_ref.def / cave_ref.rover_size
			cave_ref.hit_player(dmg, status_effects)
	get_parent().call_deferred("remove_child", self)
	queue_free()
