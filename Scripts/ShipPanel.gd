extends "Panel.gd"

func _ready():
	set_polygon(rect_size)
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
	$GridContainer/Panel3.visible = len(game.ship_data) >= 3
	$GridContainer/Panel4.visible = len(game.ship_data) >= 4
	$Panel/UpgradeButton.visible = game.science_unlocked.UP1
	$Drives.refresh()
	$Upgrade._refresh()
	if game.ships_travel_view != "-":
		set_process(true)
	else:
		set_process(false)
		$Panel/TravelETA.text = ""

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
		$Panel/UpgradeButton.visible = false
	else:
		game.popup(tr("DRIVE_TECHNOLOGY_REQUIRED"), 1.5)

func _on_BackButton_pressed():
	$GridContainer.visible = true
	$Drives.visible = false
	$Upgrade.visible = false
	$Panel/CheckBox.visible = true
	$Panel/DriveButton.visible = true
	$Panel/BackButton.visible = false
	$Panel/UpgradeButton.visible = true

func _on_UpgradeButton_pressed():
	$GridContainer.visible = false
	$Drives.visible = false
	$Upgrade.visible = true
	$Panel/CheckBox.visible = false
	$Panel/DriveButton.visible = false
	$Panel/BackButton.visible = true
	$Panel/UpgradeButton.visible = false

func _on_GoToShips_mouse_entered():
	game.show_tooltip(tr("GO_TO_SHIPS"))

func _on_mouse_exited():
	game.hide_tooltip()

func _on_GoToShips_pressed():
	game.switch_view("system", false, "set_to_ship_coords")
	_on_close_button_pressed()

func _on_DriveButton_mouse_entered():
	game.show_tooltip(tr("OPEN_DRIVE_MENU"))

func _on_BackButton_mouse_entered():
	game.show_tooltip(tr("GO_BACK"))

func _on_UpgradeButton_mouse_entered():
	game.show_tooltip("UP1_SC")
