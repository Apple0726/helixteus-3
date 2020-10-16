extends Panel

"""
audio sliders are set to each bus
(you can find the buses by looking at the bottom of the screen and clicking Audio)
"""
var tween
var polygon = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
func _ready():
	tween = Tween.new()
	add_child(tween)

func _on_Main_audio_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), value)
	if value > -40:
		AudioServer.set_bus_mute(0,false)
	else:
		AudioServer.set_bus_mute(0,true)

func _on_Music_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), value)
	if value > -40:
		AudioServer.set_bus_mute(1,false)
	else:
		AudioServer.set_bus_mute(1,true)


func _on_Sound_Effects_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), value)
	if value > -40:
		AudioServer.set_bus_mute(2,false)
	else:
		AudioServer.set_bus_mute(2,true)

func refresh():
	pass
