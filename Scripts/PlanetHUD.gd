extends Control
onready var game = self.get_parent()

func _on_StarSystem_pressed():
	game.switch_view("system")


func _on_Construct_pressed():
	if not get_node("../construct_panel").visible:
		game.add_construct_panel()
	else:
		game.remove_construct_panel()


func _on_Construct_mouse_entered():
	game.show_tooltip("Construct (C)")

func _on_Construct_mouse_exited():
	game.hide_tooltip()

func _on_StarSystem_mouse_entered():
	game.show_tooltip("View star system (V)")

func _on_StarSystem_mouse_exited():
	game.hide_tooltip()
