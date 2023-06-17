extends Node2D

@export var fog_size:float = 4.0
@export var fog_mvt_spd:float = 0.05
@export var octaves:int = 5
@export var color:Color = Color.WHITE

func _ready():
	$Nebula.material.set_shader_parameter("color", color)
	$Nebula.material.set_shader_parameter("fog_size", fog_size)
	$Nebula.material.set_shader_parameter("fog_mvt_spd", fog_mvt_spd)
	$Nebula.material.set_shader_parameter("octaves", octaves)

func fade_out():
	$AnimationPlayer.play_backwards("Fade")

func fade_in():
	$AnimationPlayer.play("Fade")

func change_color(color:Color):
	$Nebula.material.set_shader_parameter("color", color)

