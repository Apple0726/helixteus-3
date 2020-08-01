extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Button_pressed():
	if AudioServer.is_bus_mute(1) == false:
		AudioServer.set_bus_mute(1,true)
		print('audio muted')
	else:
		AudioServer.set_bus_mute(1,false)
		print('audio unmuted')

