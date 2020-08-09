extends Control

func _on_Button_pressed():
	if AudioServer.is_bus_mute(1) == false:
		AudioServer.set_bus_mute(1,true)
	else:
		AudioServer.set_bus_mute(1,false)
