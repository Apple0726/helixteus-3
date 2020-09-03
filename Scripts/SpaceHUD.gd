extends Control
onready var game = get_node("/root/Game")
onready var click_sound = get_node("../click")

func _on_Overlay_mouse_entered():
	game.show_tooltip(tr("OVERLAY") + " (O)\n" + tr("OVERLAY_DESC"))

func _on_Overlay_mouse_exited():
	game.hide_tooltip()

func _on_Overlay_pressed():
	game.overlay.visible = not game.overlay.visible
