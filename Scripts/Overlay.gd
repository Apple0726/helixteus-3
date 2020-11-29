extends Control
onready var game = get_node("/root/Game")
var editable:bool = false
var hovered_over:String = ""
onready var option_btn = $Panel/HBoxContainer/OptionButton

func _ready():
	$Panel/Done.text = "%s (Enter)" % [tr("DONE")]
	$Panel/HBoxContainer/CheckBox.text = tr("TOGGLE") + " (F3)"

func refresh_overlay():
	option_btn.clear()
	match game.c_v:
		"galaxy":
			option_btn.add_item(tr("NUMBER_OF_PLANETS"))
			option_btn.add_item(tr("SYSTEM_ENTERED"))
			option_btn.add_item(tr("COLDEST_STAR_TEMPERATURE"))
		"cluster":
			option_btn.add_item(tr("NUMBER_OF_SYSTEMS"))
			option_btn.add_item(tr("GALAXY_ENTERED"))
			option_btn.add_item(tr("MAGNETIC_FIELD_STRENGTH"))
			option_btn.add_item(tr("DARK_MATTER"))
	$Panel/HBoxContainer/CheckBox.pressed = game.overlay_data[game.c_v].visible
	option_btn.selected = game.overlay_data[game.c_v].overlay
	refresh_options(game.overlay_data[game.c_v].overlay)

func _on_CheckBox_pressed():
	game.overlay_data[game.c_v].visible = not game.overlay_data[game.c_v].visible
	if game.overlay_data[game.c_v].visible:
		send_overlay_info(game.overlay_data[game.c_v].overlay)
	$Panel/HBoxContainer/CheckBox.pressed = game.overlay_data[game.c_v].visible
	Helper.toggle_overlay(game.view.obj.obj_btns, game.view.obj.overlays)

func _on_OptionButton_item_selected(index):
	refresh_options(index)

func refresh_options(index:int):
	var c_vl = game.overlay_data[game.c_v].custom_values[index]
	var is_int:bool = true
	match game.c_v:
		"galaxy":
			match index:
				0:
					editable = true
					$Panel/LeftNum.text = "%s" % [c_vl.left]
					$Panel/RightNum.text = "%s+" % [c_vl.right]
				1:
					editable = false
					$Panel/LeftNum.text = tr("YES")
					$Panel/RightNum.text = tr("NO")
				2:
					editable = true
					$Panel/LeftNum.text = "%s K" % [c_vl.left]
					$Panel/RightNum.text = "%s+ K" % [c_vl.right]
		"cluster":
			match index:
				0:
					editable = true
					$Panel/LeftNum.text = "%s" % [c_vl.left]
					$Panel/RightNum.text = "%s" % [c_vl.right]
				1:
					editable = false
					$Panel/LeftNum.text = tr("YES")
					$Panel/RightNum.text = tr("NO")
				2:
					editable = true
					$Panel/LeftNum.text = "%s nT" % [c_vl.left]
					$Panel/RightNum.text = "%s nT" % [c_vl.right]
				3:
					editable = true
					is_int = false
					$Panel/LeftNum.text = "<%s" % [c_vl.left]
					$Panel/RightNum.text = ">%s" % [c_vl.right]
	if editable:
		$Panel/LeftNum["custom_colors/font_color"] = Color.yellow
		$Panel/RightNum["custom_colors/font_color"] = Color.yellow
	else:
		$Panel/LeftNum["custom_colors/font_color"] = Color.white
		$Panel/RightNum["custom_colors/font_color"] = Color.white
	$Panel/LeftNumEdit.rounded = is_int
	$Panel/RightNumEdit.rounded = is_int
	game.overlay_data[game.c_v].overlay = index
	send_overlay_info(index)

func send_overlay_info(index):
	game.view.obj.change_overlay(index, $Panel/TextureRect.texture.gradient)

func _on_HSlider_mouse_entered():
	game.show_tooltip(tr("CIRCLE_SIZE"))

func _on_HSlider_mouse_exited():
	game.hide_tooltip()

func _on_HSlider_value_changed(value):
	if game.view.obj:
		Helper.change_circle_size(value, game.view.obj.overlays)

func _on_num_mouse_entered(type:String):
	if editable and not $Panel/Done.visible:
		hovered_over = type
		game.show_tooltip(tr("CLICK_TO_EDIT"))

func _on_num_mouse_exited():
	if not $Panel/Done.visible:
		hovered_over = ""
		game.hide_tooltip()

func _input(event):
	if $Panel/Done.visible and Input.is_action_just_released("enter"):
		apply_changes()
	if hovered_over != "" and editable and not $Panel/Done.visible and Input.is_action_just_released("left_click"):
		$Panel/Done.visible = true
		game.hide_tooltip()
		if hovered_over == "left":
			$Panel/LeftNumEdit.visible = true
			$Panel/LeftNumEdit.value = game.overlay_data[game.c_v].custom_values[option_btn.selected].left
		elif hovered_over == "right":
			$Panel/RightNumEdit.visible = true
			$Panel/RightNumEdit.value = game.overlay_data[game.c_v].custom_values[option_btn.selected].right

func apply_changes():
	if hovered_over == "left":
		game.overlay_data[game.c_v].custom_values[option_btn.selected].left = $Panel/LeftNumEdit.value
		$Panel/LeftNumEdit.visible = false
	elif hovered_over == "right":
		game.overlay_data[game.c_v].custom_values[option_btn.selected].right = $Panel/RightNumEdit.value
		$Panel/RightNumEdit.visible = false
	$Panel/Done.visible = false
	hovered_over = ""
	refresh_options(option_btn.selected)

func _on_Done_pressed():
	apply_changes()


func _on_close_button_pressed():
	visible = false
