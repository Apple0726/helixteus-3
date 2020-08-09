extends Control

onready var click_sound = get_node("../click")

func _on_Button_pressed():
	click_sound.play()
	if AudioServer.is_bus_mute(1) == false:
		AudioServer.set_bus_mute(1,true)
	else:
		AudioServer.set_bus_mute(1,false)
