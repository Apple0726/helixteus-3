extends Control
onready var game = self.get_parent()
onready var click_sound = get_node("../click")

func _on_StarSystem_pressed():
	click_sound.play()
	game.switch_view("system")


func _on_Construct_pressed():
	click_sound.play()
	game.toggle_construct_panel()

func _on_Mine_pressed():
	click_sound.play()
	if game.pickaxe != null:
		game.about_to_mine = true
		game.put_bottom_info("Click a tile to mine")
	else:
		game.long_popup(tr("NO_PICKAXE"), tr("NO_PICKAXE_TITLE"), [tr("BUY_ONE")], ["open_shop_pickaxe"], tr("LATER"))

func _on_Construct_mouse_entered():
	game.show_tooltip(tr("CONSTRUCT") + " (C)")

func _on_Construct_mouse_exited():
	game.hide_tooltip()

func _on_StarSystem_mouse_entered():
	game.show_tooltip(tr("VIEW_STAR_SYSTEM") + " (V)")

func _on_StarSystem_mouse_exited():
	game.hide_tooltip()

func _on_Mine_mouse_entered():
	game.show_tooltip(tr("MINE") + " (N)")

func _on_Mine_mouse_exited():
	game.hide_tooltip()
