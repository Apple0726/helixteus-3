extends Node2D

export var fog_size:float = 4.0
export var fog_mvt_spd:float = 0.05
export var octaves:int = 5
export var color:Color = Color.white
onready var tween:Tween = $Tween
onready var tween2:Tween = $Tween2

func _ready():
	$Nebula.material.set_shader_param("color", color)
	$Nebula.material.set_shader_param("fog_size", fog_size)
	$Nebula.material.set_shader_param("fog_mvt_spd", fog_mvt_spd)
	$Nebula.material.set_shader_param("octaves", octaves)

func fade_out():
	tween.remove_all()
	tween.interpolate_property(self, "modulate", null, Color(1, 1, 1, 0), 3.0)
	tween.start()
	yield(tween, "tween_all_completed")
	if modulate.a == 0:
		visible = false

func fade_in():
	visible = true
	tween.stop_all()
	tween.remove_all()
	tween.interpolate_property(self, "modulate", null, Color(1, 1, 1, 0.15), 3.0)
	tween.start()

func change_color(color:Color):
	tween2.stop_all()
	tween2.reset_all()
	tween2.interpolate_property($Nebula.material, "shader_param/color", null, color, 3.0)
	tween2.start()
