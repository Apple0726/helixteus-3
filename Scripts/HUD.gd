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

func _process(delta):
	$Resources/Money/Text.text = String(game.money)
	$Resources/Minerals/Text.text = String(game.minerals) + " / " + String(game.mineral_capacity)
	$Resources/Energy/Text.text = String(game.energy)


func _on_TextureButton_mouse_entered():
	game.show_tooltip("Shop (Q)")


func _on_TextureButton_mouse_exited():
	game.hide_tooltip()


func _on_TextureButton_pressed():
	click_sound.play()
	game.toggle_shop_panel()
