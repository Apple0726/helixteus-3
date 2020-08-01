extends Control

func _ready():
	pass

func _on_Button_pressed():
	if AudioServer.is_bus_mute(1) == false:
		AudioServer.set_bus_mute(1,true)
		print('audio muted')
	else:
		AudioServer.set_bus_mute(1,false)
		print('audio unmuted')
