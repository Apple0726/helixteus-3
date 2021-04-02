extends Control
onready var game = get_node("/root/Game")
onready var click_sound = game.get_node("click")

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

func _on_ConquerAll_mouse_entered():
	game.show_tooltip(tr("CONQUER_ALL_DESC"))

func _on_ConquerAll_pressed():
	var info = Helper.get_conquer_all_data()
	game.show_YN_panel("conquer_all", tr("CONQUER_ALL_INFO") % [len(info.HX_data), Helper.format_num(info.energy_cost)], [info.energy_cost, len(info.HX_data) == 0])

func _on_Annotate_pressed():
	game.annotator.visible = not game.annotator.visible

func _on_Annotate_mouse_entered():
	game.show_tooltip(tr("ANNOTATE") + " (N)")
