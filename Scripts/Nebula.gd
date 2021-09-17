extends Node2D

onready var tween:Tween = $Tween
onready var tween2:Tween = $Tween2

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
	tween.interpolate_property(self, "modulate", null, Color(1, 1, 1, 0.18), 3.0)
	tween.start()

func change_color(color:Color):
	tween2.stop_all()
	tween2.reset_all()
	tween2.interpolate_property($Nebula.material, "shader_param/color", null, color, 3.0)
	tween2.start()
