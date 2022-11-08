class_name Debris
extends StaticBody2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var id:int
var sprite_frame:int
var particle_lifetime:float = 4.0
var particle_amount:int
var aurora:bool


# Called when the node enters the scene tree for the first time.
func _ready():
	$Sprite.frame = sprite_frame
	$Sprite.material.set_shader_param("aurora", aurora)

func destroy_rock():
	particle_amount = int(scale.x * 20)
	$Particles2D.process_material.damping = clamp(range_lerp(scale.x, 1.2, 0.5, 800, 1500), 800, 1500)
	$Sprite.visible = false
	$CollisionShape2D.disabled = true
	$LightOccluder2D.light_mask = 0
	$Particles2D.emitting = true
	var timer = Timer.new()
	add_child(timer)
	timer.connect("timeout", self, "remove_debris")
	timer.start(particle_lifetime)

func remove_debris():
	queue_free()
