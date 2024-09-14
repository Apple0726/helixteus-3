extends Control
@onready var game = get_node("/root/Game")
@onready var click_sound = game.get_node("click")

func _ready():
	$AnimationPlayer.play("MoveButtons")

func _on_Overlay_mouse_entered():
	game.show_tooltip(tr("OVERLAY") + " (O)\n" + tr("OVERLAY_DESC"))

func _on_Overlay_mouse_exited():
	game.hide_tooltip()

func _on_Overlay_pressed():
	game.overlay.visible = not game.overlay.visible

func _on_Megastructures_pressed():
	if $ConstructPanel.visible:
		$ConstructPanel.hide()
	else:
		game.hide_tooltip()
		$ConstructPanel.tab = "megastructures"
		$ConstructPanel/AnimationPlayer.play("Fade")
		$ConstructPanel.visible = true
		$ConstructPanel.set_process_input(true)
		$ConstructPanel.refresh()
	if $StarPanel.visible:
		$StarPanel/AnimationPlayer.play_backwards("Fade")

func _on_Megastructures_mouse_entered():
	game.show_tooltip(tr("MEGASTRUCTURES") + " (C)")

func _on_ConquerAll_mouse_entered():
	game.show_tooltip(tr("CONQUER_ALL_DESC"))

func _on_ConquerAll_pressed():
	var info = Helper.get_conquer_all_data()
	game.show_YN_panel("conquer_all", tr("CONQUER_ALL_INFO") % [min(12, len(info.HX_data)), Helper.format_num(info.energy_cost)], [info.energy_cost, len(info.HX_data) == 0])

func _on_Annotate_pressed():
	game.annotator.visible = not game.annotator.visible

func _on_Annotate_mouse_entered():
	game.show_tooltip(tr("ANNOTATE") + " (N)")


func _on_SendFighters_pressed():
	if game.c_v == "galaxy":
		game.send_fighters_panel.fighter_type = 0
	if game.c_v == "cluster":
		game.send_fighters_panel.fighter_type = 1
	game.toggle_panel(game.send_fighters_panel)


func _on_SendProbes_pressed():
	game.toggle_panel(game.send_probes_panel)


func _on_Gigastructures_pressed():
	if game.c_v == "cluster":
		game.put_bottom_info(tr("SELECT_GALAXY_TO_CONVERT"), "convert_to_GS")
	elif game.c_v == "galaxy":
		if game.c_g_g == 0:
			game.popup(tr("GS_ERROR"), 1.5)
		elif not game.galaxy_data[game.c_g].has("conquered"):
			game.popup(tr("NO_GS"), 2.0)
		else:
			game.gigastructures_panel.g_i = game.galaxy_data[game.c_g]
			game.gigastructures_panel.galaxy_id_g = game.c_g_g
			game.toggle_panel(game.gigastructures_panel)


func _on_Gigastructures_mouse_entered():
	if game.c_v == "cluster":
		game.show_tooltip(tr("CONVERT_TO_GS2") + " (C)")
	elif game.c_v == "galaxy":
		game.show_tooltip(tr("CONVERT_TO_GS") + " (C)")


func _on_mouse_exited():
	game.hide_tooltip()


func _on_ElementOverlay_mouse_entered():
	game.show_tooltip(tr("ELEMENT_OVERLAY") + " (O)\n" + tr("ELEMENT_OVERLAY_DESC"))


func _on_ElementOverlay_pressed():
	if is_instance_valid(game.element_overlay):
		game.get_node("UI").move_child(game.element_overlay, game.get_node("UI").get_child_count())
		game.element_overlay.visible = not game.element_overlay.visible
	else:
		game.element_overlay = load("res://Scenes/ElementOverlay.tscn").instantiate()
		game.get_node("UI").add_child(game.element_overlay)
	
func _on_stars_mouse_entered():
	game.show_tooltip(tr("STARS"))


func _on_stars_pressed():
	$StarPanel/AnimationPlayer.play("Fade")
	$StarPanel.visible = true
	$StarPanel.set_process_input(true)
