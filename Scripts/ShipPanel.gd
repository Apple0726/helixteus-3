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
	$Drives.refresh(50)

func _on_CheckBox_toggled(button_pressed):
	for panel in $GridContainer.get_children():
		panel.show_weapon_XPs = button_pressed
		panel.set_visibility()

func _on_DriveButton_pressed():
	if game.science_unlocked["CD"] == true:
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
