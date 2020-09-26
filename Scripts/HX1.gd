extends KinematicBody2D

var tween
var tween2
var float_height = 20
var trans_tween = Tween.TRANS_QUAD

func _ready():
	tween = Tween.new()
	tween2 = Tween.new()
	add_child(tween)
	add_child(tween2)
	tween.interpolate_property(self, "position", position, position - Vector2(0, float_height), 0.5, trans_tween, Tween.EASE_IN_OUT)
	tween.start()
	tween.connect("tween_all_completed", self, "on_tween_complete")
	tween2.connect("tween_all_completed", self, "on_tween2_complete")

func on_tween_complete():
	tween2.interpolate_property(self, "position", position, position + Vector2(0, float_height), 0.5, trans_tween, Tween.EASE_IN_OUT)
	tween2.start()

func on_tween2_complete():
	tween.interpolate_property(self, "position", position, position - Vector2(0, float_height), 0.5, trans_tween, Tween.EASE_IN_OUT)
	tween.start()
