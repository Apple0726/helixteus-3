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

func _on_CheckBox_toggled(button_pressed):
	for panel in $GridContainer.get_children():
		panel.show_weapon_XPs = button_pressed
		panel.set_visibility()
