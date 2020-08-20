extends Control

onready var click_sound = get_node("../click")
onready var game = get_parent()

func _on_Button_pressed():
	click_sound.play()
	if AudioServer.is_bus_mute(1) == false:
		AudioServer.set_bus_mute(1,true)
	else:
		AudioServer.set_bus_mute(1,false)


func _on_Button_mouse_entered():
	game.show_tooltip("(Un)mute (M)")


func _on_Button_mouse_exited():
	game.hide_tooltip()
