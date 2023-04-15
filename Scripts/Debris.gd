class_name Debris
extends Node2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var id:int
var sprite_frame:int
var particle_lifetime:float = 4.0
var particle_amount:int
var aurora_intensity:float = 0.0
var lava_intensity:float = 0.0
var debris_collision_shape:CollisionPolygon2D
var crack_threshold:float = 0
var cracked_mining_factor:float = 1.0
var time_speed:float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready():
	$Sprite2D.frame = sprite_frame
	debris_collision_shape = get_node(str(sprite_frame) + "/CollisionPolygon2D")
	debris_collision_shape.disabled = false
	$LightOccluder2D.occluder.polygon = debris_collision_shape.polygon
	$Sprite2D.material.set_shader_parameter("aurora", aurora_intensity > 0.0)
	if lava_intensity > 0.0:
		$Lava.enabled = true
		$Lava.rotation = randf_range(0, 2 * PI)
		$Lava.position.x = randf_range(-128, 128)
		$Lava.position.y = randf_range(-128, 128)
	$GPUParticles2D.modulate = self_modulate
	$Sprite2D.modulate = self_modulate
	crack_threshold = 60 * randf() / pow(scale.x, 3)

func set_crack():
	$Crack.monitoring = true
	var L = len(debris_collision_shape.polygon)
	var idx = randi() % L
	var pos = debris_collision_shape.polygon[idx]
	var next_pos:Vector2
	if idx == L-1:
		next_pos = debris_collision_shape.polygon[0]
	else:
		next_pos = debris_collision_shape.polygon[idx+1]
	$Crack/AnimationPlayer.play("New Anim", -1, time_speed)
	$Crack/GPUParticles2D.speed_scale = time_speed
	$Crack/GPUParticles2D.emitting = true
	$Crack/Sprite2D.visible = true
	$Crack.position = (next_pos + pos) / 2.0
	$Crack.rotation = atan2(next_pos.y - pos.y, next_pos.x - pos.x) - PI/2


func destroy_rock():
	_on_Timer_timeout()
	particle_amount = int(scale.x * 20)
	$GPUParticles2D.process_material.damping = clamp(remap(scale.x, 1.2, 0.5, 800, 1500), 800, 1500)
	$Sprite2D.visible = false
	debris_collision_shape.disabled = true
	$LightOccluder2D.light_mask = 0
	$GPUParticles2D.emitting = true
	var timer = Timer.new()
	add_child(timer)
	timer.connect("timeout",Callable(self,"remove_debris"))
	timer.start(particle_lifetime)

func remove_debris():
	queue_free()


func _on_Crack_area_entered(area):
	if $Crack/Timer.is_stopped():
		$Crack/Timer.start((1.5 + 1.5 * randf()) / time_speed)
	cracked_mining_factor = 2.0


func _on_Crack_area_exited(area):
	cracked_mining_factor = 1.0


func _on_Timer_timeout():
	$Crack.monitoring = false
	if $Crack/AnimationPlayer.is_playing():
		$Crack/AnimationPlayer.stop()
		$Crack/Sprite2D.visible = false
	$Crack/GPUParticles2D.emitting = false
	cracked_mining_factor = 1.0
