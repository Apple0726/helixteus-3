extends Control

signal new_game
var tween:Tween
var tut:bool = false

func _ready():
	tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(self, "modulate", null, Color.white, 0.2)
	tween.start()

func _on_Button_pressed():
	tut = true
	disconnect_things()

func _on_Button2_pressed():
	disconnect_things()

func disconnect_things():
	tween.interpolate_property(self, "modulate", null, Color(1, 1, 1, 0), 0.2)
	tween.start()
	tween.connect("tween_all_completed", self, "on_tween_complete")
	$Button.disconnect("pressed", self, "_on_Button_pressed")
	$Button2.disconnect("pressed", self, "_on_Button2_pressed")
	
func on_tween_complete():
	emit_signal("new_game", tut)
