extends "Panel.gd"
var editable:bool = false
var is_int:bool = true
var hovered_over:String = ""
@onready var option_btn = $HBoxContainer/OptionButton
@onready var toggle_btn = $HBoxContainer/CheckBox
@onready var colorblind_btn = $SettingsPanel/VBox/Colorblind
@onready var hide_obj_btn = $SettingsPanel/VBox/HideObj
var config = ConfigFile.new()
var err = config.load("user://settings.cfg")

func _ready():
	set_polygon(size, Vector2(0, 308))
	toggle_btn.text = tr("TOGGLE") + " (F3)"
	$ClickToEdit.visible = not game.help.has("overlay")

func refresh_overlay():
	$HBoxContainer/HSlider.value = game.overlay_CS
	option_btn.clear()
	match game.c_v:
		"galaxy":
			option_btn.add_item(tr("NUMBER_OF_PLANETS"))
			option_btn.add_item(tr("STAR_NUM"))
			option_btn.add_item(tr("SYSTEM_ENTERED"))
			option_btn.add_item(tr("ENTERED_BY_SHIPS"))
			option_btn.add_item(tr("SYSTEM_CONQUERED"))
			option_btn.add_item(tr("DIFFICULTY"))
			option_btn.add_item(tr("HOTTEST_STAR_TEMPERATURE"))
			option_btn.add_item(tr("BIGGEST_STAR_SIZE"))
			option_btn.add_item(tr("BRIGHTEST_STAR_LUMINOSITY"))
			option_btn.add_item(tr("HAS_MEGASTRUCTURE"))
		"cluster":
			option_btn.add_item(tr("NUMBER_OF_SYSTEMS"))
			option_btn.add_item(tr("GALAXY_ENTERED"))
			option_btn.add_item(tr("ENTERED_BY_SHIPS"))
			option_btn.add_item(tr("GALAXY_CONQUERED"))
			option_btn.add_item(tr("DIFFICULTY"))
			option_btn.add_item(tr("B_STRENGTH"))
			option_btn.add_item(tr("DARK_MATTER"))
			option_btn.add_item(tr("IS_GIGASTRUCTURE"))
	toggle_btn.button_pressed = game.overlay_data[game.c_v].visible
	if err == OK:
		colorblind_btn.button_pressed = config.get_value("misc", "colorblind", false)
		hide_obj_btn.button_pressed = config.get_value("misc", "hide_obj", false)
		if colorblind_btn.button_pressed:
			$TextureRect.texture.gradient = load("res://Resources/ColorblindOverlay.tres")
		else:
			$TextureRect.texture.gradient = load("res://Resources/DefaultOverlay.tres")
	option_btn.selected = game.overlay_data[game.c_v].overlay
	refresh_options(game.overlay_data[game.c_v].overlay)

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

func get_star_prop_min_max(prop:String):
	var overlays = game.view.obj.overlays
	var _min = game.get_highest_star_prop(overlays[0].id, prop)
	var _max = _min
	for i in range(1, len(overlays)):
		var id:int = overlays[i].id
		var T = game.get_highest_star_prop(id, prop)
		if T < _min:
			_min = T
		if T > _max:
			_max = T
	return {"_min":_min, "_max":_max}

func get_star_num_min_max():
	var overlays = game.view.obj.overlays
	var _min = 1
	var _max = 1
	for i in range(0, len(overlays)):
		var id:int = overlays[i].id
		var n = len(game.system_data[id][9])
		if n > _max:
			_max = n
	return {"_min":_min, "_max":_max}

func refresh_options(index:int, recalculate:bool = true):
	var c_vl = game.overlay_data[game.c_v].custom_values[index]
	var min_max:Dictionary
	$Reset.visible = false if c_vl == null else c_vl.modified
	var unit:String = ""
	match game.c_v:
		"galaxy":
			match index:
				0:
					if recalculate and not c_vl.modified:
						min_max = get_obj_min_max("system", "planet_num")
						c_vl.left = min_max._min
						c_vl.right = min_max._max
					editable = true
					unit = ""
				1:
					if recalculate and not c_vl.modified:
						min_max = get_star_num_min_max()
						c_vl.left = min_max._min
						c_vl.right = min_max._max
					editable = true
					unit = ""
				2, 3, 4, 9:
					editable = false
				5:
					if recalculate and not c_vl.modified:
						min_max = get_obj_min_max("system", "diff")
						c_vl.left = min_max._min
						c_vl.right = min_max._max
					editable = true
					is_int = false
					unit = ""
				6:
					if recalculate and not c_vl.modified:
						min_max = get_star_prop_min_max("temperature")
						c_vl.left = min_max._min
						c_vl.right = min_max._max
					editable = true
					is_int = false
					unit = " K"
				7:
					if recalculate and not c_vl.modified:
						min_max = get_star_prop_min_max("size")
						c_vl.left = min_max._min
						c_vl.right = min_max._max
					editable = true
					is_int = false
					unit = ""
				8:
					if recalculate and not c_vl.modified:
						min_max = get_star_prop_min_max("luminosity")
						c_vl.left = min_max._min
						c_vl.right = min_max._max
					editable = true
					is_int = false
					unit = ""
		"cluster":
			match index:
				0:
					if recalculate and not c_vl.modified:
						min_max = get_obj_min_max("galaxy", "system_num")
						c_vl.left = min_max._min
						c_vl.right = min_max._max
					editable = true
					unit = ""
				1, 2, 3, 7:
					editable = false
				4:
					if recalculate and not c_vl.modified:
						min_max = get_obj_min_max("galaxy", "diff")
						c_vl.left = min_max._min
						c_vl.right = min_max._max
					editable = true
					is_int = false
					unit = ""
				5:
					if recalculate and not c_vl.modified:
						min_max = get_obj_min_max("galaxy", "B_strength")
						c_vl.left = min_max._min * e(1, 9)
						c_vl.right = min_max._max * e(1, 9)
					editable = true
					is_int = false
					unit = " nT"
				6:
					if recalculate and not c_vl.modified:
						min_max = get_obj_min_max("galaxy", "dark_matter")
						c_vl.left = min_max._min
						c_vl.right = min_max._max
					editable = true
					is_int = false
					unit = ""
	if editable:
		$LeftNumEdit.text = "%s%s" % [Helper.e_notation(c_vl.left) if c_vl.left >= 1000000 else c_vl.left, unit]
		$RightNumEdit.text = "%s%s" % [Helper.e_notation(c_vl.right) if c_vl.right >= 1000000 else c_vl.right, unit]
	$LeftNumEdit.visible = editable
	$RightNumEdit.visible = editable
	$Yes.visible = not editable
	$No.visible = not editable
	game.overlay_data[game.c_v].overlay = index
	send_overlay_info(index)

func e(n, e):
	return n * pow(10, e)

func send_overlay_info(index):
	game.view.obj.change_overlay(index, $TextureRect.texture.gradient)

func _on_HSlider_mouse_entered():
	game.show_tooltip(tr("CIRCLE_SIZE"))

func _on_mouse_exited():
	game.hide_tooltip()

func _on_HSlider_value_changed(value):
	if game.view.obj:
		game.overlay_CS = value
		Helper.change_circle_size(value, game.view.obj.overlays)

func _on_close_button_pressed():
	visible = false
	game.block_scroll = false

func _on_Reset_mouse_entered():
	game.show_tooltip("RESET_TO_DEFAULT")

func _on_Reset_pressed():
	game.overlay_data[game.c_v].custom_values[option_btn.selected].modified = false
	refresh_options(option_btn.selected, true)
	game.hide_tooltip()

func _on_Overlay_visibility_changed():
	if not is_inside_tree():
		return
	if visible:
		get_parent().move_child(self, get_parent().get_child_count())
		game.sub_panel = self
	else:
		game.sub_panel = null


func _on_Colorblind_toggled(button_pressed):
	if colorblind_btn.button_pressed and toggle_btn.button_pressed:
		game.get_node("GrayscaleRect/AnimationPlayer").play("Fade")
	else:
		if game.get_node("GrayscaleRect").modulate.a > 0:
			game.get_node("GrayscaleRect/AnimationPlayer").play_backwards("Fade")
	if button_pressed:
		$TextureRect.texture.gradient = load("res://Resources/ColorblindOverlay.tres")
	else:
		$TextureRect.texture.gradient = load("res://Resources/DefaultOverlay.tres")
	if err == OK:
		config.set_value("misc", "colorblind", button_pressed)
		config.save("user://settings.cfg")
	send_overlay_info(game.overlay_data[game.c_v].overlay)


func _on_CheckBox_toggled(button_pressed):
	if colorblind_btn.button_pressed:
		if button_pressed:
			game.get_node("GrayscaleRect/AnimationPlayer").play("Fade")
		else:
			game.get_node("GrayscaleRect/AnimationPlayer").play_backwards("Fade")
	game.overlay_data[game.c_v].visible = button_pressed
	if game.overlay_data[game.c_v].visible:
		send_overlay_info(game.overlay_data[game.c_v].overlay)
	toggle_btn.button_pressed = game.overlay_data[game.c_v].visible
	Helper.toggle_overlay(game.view.obj.obj_btns, game.view.obj.overlays, button_pressed)


func _on_LeftNumEdit_text_entered(new_text):
	if is_int:
		game.overlay_data[game.c_v].custom_values[option_btn.selected].left = int(new_text)
	else:
		game.overlay_data[game.c_v].custom_values[option_btn.selected].left = float(new_text)
	game.overlay_data[game.c_v].custom_values[option_btn.selected].modified = true
	refresh_options(option_btn.selected, false)
	$LeftNumEdit.release_focus()
	game.help.overlay = true
	$ClickToEdit.visible = false

func _on_RightNumEdit_text_entered(new_text):
	if is_int:
		game.overlay_data[game.c_v].custom_values[option_btn.selected].right = int(new_text)
	else:
		game.overlay_data[game.c_v].custom_values[option_btn.selected].right = float(new_text)
	game.overlay_data[game.c_v].custom_values[option_btn.selected].modified = true
	refresh_options(option_btn.selected, false)
	$RightNumEdit.release_focus()
	game.help.overlay = true
	$ClickToEdit.visible = false


func _on_Settings_mouse_entered():
	game.show_tooltip(tr("OVERLAY_SETTINGS"))


func _on_Settings_mouse_exited():
	game.hide_tooltip()


func _on_HideObj_toggled(button_pressed):
	if err == OK:
		config.set_value("misc", "hide_obj", button_pressed)
		config.save("user://settings.cfg")
	send_overlay_info(game.overlay_data[game.c_v].overlay)


func _on_Settings_pressed():
	game.hide_tooltip()
	$SettingsPanel.visible = not $SettingsPanel.visible
