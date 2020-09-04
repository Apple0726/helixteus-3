extends Control
onready var game = get_node("/root/Game")

func _ready():
	$Panel/CheckBox.text = tr("TOGGLE") + " (F3)"
	refresh_overlay()

func refresh_overlay():
	$Panel/OptionButton.clear()
	match game.c_v:
		"galaxy":
			$Panel/OptionButton.add_item(tr("NUMBER_OF_PLANETS"))
			$Panel/OptionButton.add_item(tr("SYSTEM_ENTERED"))
			$Panel/OptionButton.selected = game.overlay_data.galaxy.overlay
			send_overlay_info(game.overlay_data.galaxy.overlay)
			$Panel/CheckBox.pressed = game.overlay_data.galaxy.visible

func _on_CheckBox_pressed():
	game.overlay_data.galaxy.visible = not game.overlay_data.galaxy.visible
	game.view.obj.toggle_overlay()

func _on_CheckBox_mouse_entered():
	game.show_tooltip("TOGGLE_OVERLAY_DESC")

func _on_CheckBox_mouse_exited():
	game.hide_tooltip()


func _on_OptionButton_item_selected(index):
	match index:
		0:
			$Panel/LeftNum.text = "2"
			$Panel/RightNum.text = "30+"
		1:
			$Panel/LeftNum.text = tr("YES")
			$Panel/RightNum.text = tr("NO")
	game.overlay_data.galaxy.overlay = index
	send_overlay_info(index)

func send_overlay_info(index):
	match index:
		0:
			game.view.obj.change_overlay("planet_num", $Panel/TextureRect.texture.gradient)
		1:
			game.view.obj.change_overlay("discovered", $Panel/TextureRect.texture.gradient)

func _on_HSlider_mouse_entered():
	game.show_tooltip("CIRCLE_SIZE")
	game.view.move_view = false


func _on_HSlider_mouse_exited():
	game.hide_tooltip()
	game.view.move_view = true


func _on_HSlider_value_changed(value):
	if game.view.obj:
		game.view.obj.change_circle_size(value)
