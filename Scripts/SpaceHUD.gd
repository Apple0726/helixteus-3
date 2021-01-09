extends Control
onready var game = get_node("/root/Game")
onready var click_sound = get_node("../click")

func _on_Overlay_mouse_entered():
	game.show_tooltip(tr("OVERLAY") + " (O)\n" + tr("OVERLAY_DESC"))

func _on_Overlay_mouse_exited():
	game.hide_tooltip()

func _on_Overlay_pressed():
	game.overlay.visible = not game.overlay.visible

func _on_Home_mouse_entered():
	game.show_tooltip(tr("CLICK_TO_GO_HOME"))

func _on_mouse_exited():
	game.hide_tooltip()

func _on_Home_pressed():
	game.switch_view("planet", false, "set_home_coords")

func _on_Megastructures_pressed():
	game.toggle_panel(game.megastructures_panel)

func _on_Megastructures_mouse_entered():
	game.show_tooltip(tr("MEGASTRUCTURES") + " (C)")
