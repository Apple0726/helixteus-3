extends Control
onready var game = get_node("/root/Game")
var editable:bool = false
var hovered_over:String = ""
onready var option_btn = $Panel/HBoxContainer/OptionButton

func _ready():
	$Panel/Done.text = "%s (Enter)" % [tr("DONE")]
	$Panel/HBoxContainer/CheckBox.text = tr("TOGGLE") + " (F3)"

func refresh_overlay():
	$Panel/HBoxContainer/HSlider.value = game.overlay_CS
	option_btn.clear()
	match game.c_v:
		"galaxy":
			option_btn.add_item(tr("NUMBER_OF_PLANETS"))
			option_btn.add_item(tr("SYSTEM_ENTERED"))
			option_btn.add_item(tr("SYSTEM_CONQUERED"))
			option_btn.add_item(tr("DIFFICULTY"))
			option_btn.add_item(tr("COLDEST_STAR_TEMPERATURE"))
			option_btn.add_item(tr("BIGGEST_STAR_SIZE"))
			option_btn.add_item(tr("BRIGHTEST_STAR_LUMINOSITY"))
		"cluster":
			option_btn.add_item(tr("NUMBER_OF_SYSTEMS"))
			option_btn.add_item(tr("GALAXY_ENTERED"))
			option_btn.add_item(tr("DIFFICULTY"))
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

func get_obj_min_max(obj:String, property:String):
	var overlays = game.view.obj.overlays
	var _min = game["%s_data" % [obj]][overlays[0].id][property]
	var _max = _min
	for i in range(1, len(overlays)):
		var id:int = overlays[i].id
		var prop = game["%s_data" % [obj]][id][property]
		if prop < _min:
			_min = prop
		if prop > _max:
			_max = prop
	return {"_min":_min, "_max":_max}

func get_CST_min_max():
	var overlays = game.view.obj.overlays
	var _min = game.get_coldest_star_temp(overlays[0].id)
	var _max = _min
	for i in range(1, len(overlays)):
		var id:int = overlays[i].id
		var T = game.get_coldest_star_temp(id)
		if T < _min:
			_min = T
		if T > _max:
			_max = T
	return {"_min":_min, "_max":_max}

func get_BSS_min_max():
	var overlays = game.view.obj.overlays
	var _min = game.get_biggest_star_size(overlays[0].id)
	var _max = _min
	for i in range(1, len(overlays)):
		var id:int = overlays[i].id
		var T = game.get_biggest_star_size(id)
		if T < _min:
			_min = T
		if T > _max:
			_max = T
	return {"_min":_min, "_max":_max}

func get_BSL_min_max():
	var overlays = game.view.obj.overlays
	var _min = game.get_brightest_star_luminosity(overlays[0].id)
	var _max = _min
	for i in range(1, len(overlays)):
		var id:int = overlays[i].id
		var T = game.get_brightest_star_luminosity(id)
		if T < _min:
			_min = T
		if T > _max:
			_max = T
	return {"_min":_min, "_max":_max}

func refresh_options(index:int, recalculate:bool = true):
	var c_vl = game.overlay_data[game.c_v].custom_values[index]
	var is_int:bool = true
	var min_max:Dictionary
	$Panel/Reset.visible = false if not c_vl else c_vl.modified
	match game.c_v:
		"galaxy":
			match index:
				0:
					if recalculate and not c_vl.modified:
						min_max = get_obj_min_max("system", "planet_num")
						c_vl.left = min_max._min
						c_vl.right = min_max._max
					editable = true
					$Panel/LeftNum.text = "%s" % [c_vl.left]
					$Panel/RightNum.text = "%s" % [c_vl.right]
				1, 2:
					editable = false
					$Panel/LeftNum.text = tr("YES")
					$Panel/RightNum.text = tr("NO")
				3:
					if recalculate and not c_vl.modified:
						min_max = get_obj_min_max("system", "diff")
						c_vl.left = min_max._min
						c_vl.right = min_max._max
					editable = true
					is_int = false
					$Panel/LeftNum.text = "%s" % [c_vl.left]
					$Panel/RightNum.text = "%s" % [c_vl.right]
				4:
					if recalculate and not c_vl.modified:
						min_max = get_CST_min_max()#CST: coldest star temperature
						c_vl.left = min_max._min
						c_vl.right = min_max._max
					editable = true
					is_int = false
					$Panel/LeftNum.text = "%s K" % [c_vl.left]
					$Panel/RightNum.text = "%s K" % [c_vl.right]
				5:
					if recalculate and not c_vl.modified:
						min_max = get_BSS_min_max()#CST: coldest star temperature
						c_vl.left = min_max._min
						c_vl.right = min_max._max
					editable = true
					is_int = false
					$Panel/LeftNum.text = "%s" % [c_vl.left]
					$Panel/RightNum.text = "%s" % [c_vl.right]
				6:
					if recalculate and not c_vl.modified:
						min_max = get_BSL_min_max()#CST: coldest star temperature
						c_vl.left = min_max._min
						c_vl.right = min_max._max
					editable = true
					is_int = false
					$Panel/LeftNum.text = "%s" % [c_vl.left]
					$Panel/RightNum.text = "%s" % [c_vl.right]
		"cluster":
			match index:
				0:
					if recalculate and not c_vl.modified:
						min_max = get_obj_min_max("galaxy", "system_num")
						c_vl.left = min_max._min
						c_vl.right = min_max._max
					editable = true
					$Panel/LeftNum.text = "%s" % [c_vl.left]
					$Panel/RightNum.text = "%s" % [c_vl.right]
				1:
					editable = false
					$Panel/LeftNum.text = tr("YES")
					$Panel/RightNum.text = tr("NO")
				2:
					if recalculate and not c_vl.modified:
						min_max = get_obj_min_max("galaxy", "diff")
						c_vl.left = min_max._min
						c_vl.right = min_max._max
					editable = true
					is_int = false
					$Panel/LeftNum.text = "%s" % [c_vl.left]
					$Panel/RightNum.text = "%s" % [c_vl.right]
				3:
					if recalculate and not c_vl.modified:
						min_max = get_obj_min_max("galaxy", "B_strength")
						c_vl.left = min_max._min * e(1, 9)
						c_vl.right = min_max._max * e(1, 9)
					editable = true
					$Panel/LeftNum.text = "%s nT" % [c_vl.left]
					$Panel/RightNum.text = "%s nT" % [c_vl.right]
				4:
					if recalculate and not c_vl.modified:
						min_max = get_obj_min_max("galaxy", "dark_matter")
						c_vl.left = min_max._min
						c_vl.right = min_max._max
					editable = true
					is_int = false
					$Panel/LeftNum.text = "%s" % [c_vl.left]
					$Panel/RightNum.text = "%s" % [c_vl.right]
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

func e(n, e):
	return n * pow(10, e)

func send_overlay_info(index):
	game.view.obj.change_overlay(index, $Panel/TextureRect.texture.gradient)

func _on_HSlider_mouse_entered():
	game.show_tooltip(tr("CIRCLE_SIZE"))

func _on_mouse_exited():
	game.hide_tooltip()

func _on_HSlider_value_changed(value):
	if game.view.obj:
		game.overlay_CS = value
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
		game.overlay_data[game.c_v].custom_values[option_btn.selected].modified = true
		$Panel/LeftNumEdit.visible = false
	elif hovered_over == "right":
		game.overlay_data[game.c_v].custom_values[option_btn.selected].right = $Panel/RightNumEdit.value
		game.overlay_data[game.c_v].custom_values[option_btn.selected].modified = true
		$Panel/RightNumEdit.visible = false
	$Panel/Done.visible = false
	hovered_over = ""
	refresh_options(option_btn.selected, false)

func _on_Done_pressed():
	apply_changes()


func _on_close_button_pressed():
	visible = false


func _on_Reset_mouse_entered():
	game.show_tooltip("RESET_TO_DEFAULT")

func _on_Reset_pressed():
	game.overlay_data[game.c_v].custom_values[option_btn.selected].modified = false
	refresh_options(option_btn.selected, true)
