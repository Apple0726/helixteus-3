extends "Panel.gd"

func _ready():
	set_polygon($Background.rect_size)
	for panel in $GridContainer.get_children():
		panel.show_weapon_XPs = false
	refresh()

func _on_close_button_pressed():
	game.toggle_panel(self)

func refresh():
	for panel in $GridContainer.get_children():
		panel.refresh()
	$GridContainer/Panel1.visible = len(game.ship_data) >= 1
	$GridContainer/Panel2.visible = len(game.ship_data) >= 2
	$Drives.refresh()
	set_process(game.ships_travel_view != "-")

func _process(delta):
	$Panel/TravelETA.text = "%s: %s" % [tr("TRAVEL_ETA"), Helper.time_to_str(game.ships_travel_length - OS.get_system_time_msecs() + game.ships_travel_start_date)]
	if not visible:
		set_process(false)

func _on_CheckBox_toggled(button_pressed):
	for panel in $GridContainer.get_children():
		panel.show_weapon_XPs = button_pressed
		panel.set_visibility()

func _on_DriveButton_pressed():
	if game.science_unlocked.CD:
		$GridContainer.visible = false
		$Drives.visible = true
		$Panel/CheckBox.visible = false
		$Panel/DriveButton.visible = false
		$Panel/BackButton.visible = true
	else:
		game.popup(tr("DRIVE_TECHNOLOGY_REQUIRED"), 1.5)

func _on_BackButton_pressed():
	$GridContainer.visible = true
	$Drives.visible = false
	$Panel/CheckBox.visible = true
	$Panel/DriveButton.visible = true
	$Panel/BackButton.visible = false

func _on_GoToShips_mouse_entered():
	game.show_tooltip(tr("GO_TO_SHIPS"))

func _on_mouse_exited():
	game.hide_tooltip()

func _on_GoToShips_pressed():
	game.c_sc = game.ships_dest_coords.sc
	game.c_c_g = game.ships_dest_g_coords.c
	game.c_c = game.ships_dest_coords.c
	game.c_g_g = game.ships_dest_g_coords.g
	game.c_g = game.ships_dest_coords.g
	game.c_s_g = game.ships_dest_g_coords.s
	game.c_s = game.ships_dest_coords.s
	game.switch_view("system")
	_on_close_button_pressed()

func _on_DriveButton_mouse_entered():
	game.show_tooltip(tr("OPEN_DRIVE_MENU"))

func _on_BackButton_mouse_entered():
	game.show_tooltip(tr("CLOSE_DRIVE_MENU"))
