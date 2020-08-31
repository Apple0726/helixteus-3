extends Control
onready var game = self.get_parent()
onready var click_sound = get_node("../click")

func _on_StarSystem_pressed():
	click_sound.play()
	game.switch_view("system")


func _on_Construct_pressed():
	click_sound.play()
	if not get_node("../construct_panel").visible:
		game.add_construct_panel()
	else:
		game.remove_construct_panel()

func _on_Mine_pressed():
	click_sound.play()
	if game.pickaxe != null:
		game.about_to_mine = true
		game.put_bottom_info("Click a tile to mine")
	else:
		game.long_popup("You don't have a pickaxe to mine! Buy one from the shop.", "No pickaxe", ["Buy one"], ["open_shop_pickaxe"], "Later")

func _on_Construct_mouse_entered():
	game.show_tooltip("Construct (C)")

func _on_Construct_mouse_exited():
	game.hide_tooltip()

func _on_StarSystem_mouse_entered():
	game.show_tooltip("View star system (V)")

func _on_StarSystem_mouse_exited():
	game.hide_tooltip()

func _on_Mine_mouse_entered():
	game.show_tooltip("Mine (N)")

func _on_Mine_mouse_exited():
	game.hide_tooltip()
