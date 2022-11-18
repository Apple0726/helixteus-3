extends "Panel.gd"

"""
audio sliders are set to each bus
(you can find the buses by looking at the bottom of the screen and clicking Audio)
"""
var config = ConfigFile.new()
var err = config.load("user://settings.cfg")
func _ready():
	set_polygon(rect_size)
	tween = Tween.new()
	add_child(tween)
	var current_viewport = get_viewport().size
	$TabContainer/GRAPHICS/DisplayRes.add_item("Auto", 0)
	if OS.get_screen_size().y > 1440:
		$TabContainer/GRAPHICS/DisplayRes.add_item("3840 x 2160", 1)
	if OS.get_screen_size().y > 1080:
		$TabContainer/GRAPHICS/DisplayRes.add_item("2560 x 1440", 2)
	$TabContainer/GRAPHICS/DisplayRes.add_item("1920 x 1080", 3)
	$TabContainer/GRAPHICS/DisplayRes.add_item("1280 x 720", 4)
	$TabContainer/GRAPHICS/DisplayRes.add_item("853 x 480", 5)
	$TabContainer/GRAPHICS/DisplayRes.add_item("640 x 360", 6)
	$TabContainer/GRAPHICS/DisplayRes.add_item("427 x 240", 7)
	$TabContainer/GRAPHICS/DisplayRes.add_item("256 x 144", 8)
	$TabContainer/GRAPHICS/DisplayRes.add_item("128 x 72", 9)
	$TabContainer/GRAPHICS/DisplayRes.add_item("64 x 36", 10)
	$TabContainer/GRAPHICS/DisplayRes.add_item("32 x 18", 11)
	$TabContainer/GRAPHICS/DisplayRes.add_item("16 x 9", 12)
	$TabContainer/GRAPHICS/Fullscreen.text = "%s (F11)" % [tr("FULLSCREEN")]
	if err == OK:
		set_difficulty()
		$TabContainer/SFX/Master.value = config.get_value("audio", "master", 0)
		update_volumes(0, config.get_value("audio", "master", 0))
		$TabContainer/SFX/Music.value = config.get_value("audio", "music", 0)
		update_volumes(1, config.get_value("audio", "music", 0))
		$TabContainer/SFX/SFX.value = config.get_value("audio", "SFX", 0)
		update_volumes(2, config.get_value("audio", "SFX", 0))
		$TabContainer/SFX/MusicPitch.pressed = config.get_value("audio", "pitch_affected", true)
		$TabContainer/GRAPHICS/Vsync.pressed = config.get_value("graphics", "vsync", true)
		$TabContainer/GRAPHICS/AutosaveLight.pressed = config.get_value("saving", "autosave_light", true)
		$TabContainer/GRAPHICS/EnableShaders.pressed = config.get_value("graphics", "enable_shaders", true)
		$TabContainer/GAME/EnableAutosave.pressed = config.get_value("saving", "enable_autosave", true)
		$TabContainer/GAME/AutosellMinerals.pressed = config.get_value("game", "autosell", true)
		$TabContainer/GAME/CaveGenInfo.pressed = config.get_value("game", "cave_gen_info", false)
		var autosave_interval = config.get_value("saving", "autosave", 10)
		var max_fps = config.get_value("rendering", "max_fps", 60)
		$TabContainer/GRAPHICS/Fullscreen.pressed = OS.window_fullscreen
		$TabContainer/GAME/Autosave.value = autosave_interval
		$TabContainer/GRAPHICS/FPS/FPS.value = max_fps
		$TabContainer/MISC/OPCursor.pressed = config.get_value("misc", "op_cursor", false)
		set_notation()

func _on_Main_audio_value_changed(value):
	update_volumes(0, value)
	if err == OK:
		config.set_value("audio", "master", value)
		config.save("user://settings.cfg")

func _on_Music_value_changed(value):
	update_volumes(1, value)
	if err == OK:
		config.set_value("audio", "music", value)
		config.save("user://settings.cfg")

func _on_Sound_Effects_value_changed(value):
	update_volumes(2, value)
	if err == OK:
		config.set_value("audio", "SFX", value)
		config.save("user://settings.cfg")

func update_volumes(bus:int, value:float):
	AudioServer.set_bus_volume_db(bus, value)
	if value > -40:
		AudioServer.set_bus_mute(bus,false)
	else:
		AudioServer.set_bus_mute(bus,true)

func refresh():
	if game.c_v == "STM":
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		game.STM.show_help("")
		game.STM.set_process(false)
	$TabContainer/SFX/MusicPitchLabel.bbcode_text = "[right]%s  [img]Graphics/Icons/help.png[/img][/right]" % tr("TIME_SPEED_AFFECTS_PITCH")
	set_difficulty()

func _on_Vsync_toggled(button_pressed):
	if err == OK:
		OS.vsync_enabled = button_pressed
		config.set_value("graphics", "vsync", button_pressed)
		config.save("user://settings.cfg")


func _on_Autosave_value_changed(value):
	if err == OK:
		$TabContainer/GAME/Label3.text = "%s %s" % [value, tr("S_SECOND")]
		game.autosave_interval = value
		config.set_value("saving", "autosave", value)
		config.save("user://settings.cfg")
		if game.c_v != "":
			game.get_node("Autosave").stop()
			game.get_node("Autosave").wait_time = value
			game.get_node("Autosave").start()


func _on_AutosaveLight_toggled(button_pressed):
	if err == OK:
		config.set_value("saving", "autosave_light", button_pressed)
		config.save("user://settings.cfg")
		if game.HUD:
			game.HUD.refresh()


func _on_EnableAutosave_toggled(button_pressed):
	if err == OK:
		config.set_value("saving", "enable_autosave", button_pressed)
		config.save("user://settings.cfg")
		if game.HUD:
			game.HUD.refresh()

func _on_FPS_value_changed(value):
	if err == OK:
		$TabContainer/GRAPHICS/FPS/Label2.text = String(value)
		OS.low_processor_usage_mode_sleep_usec = 1000000 / value
		config.set_value("rendering", "max_fps", value)
		config.save("user://settings.cfg")


func _on_AutosellMinerals_mouse_entered():
	game.show_tooltip(tr("AUTOSELL_MINERALS_DESC"))

func _on_mouse_exited():
	game.hide_tooltip()

func _on_AutosellMinerals_toggled(button_pressed):
	if err == OK:
		config.set_value("game", "autosell", button_pressed)
		game.autosell = button_pressed
		config.save("user://settings.cfg")

func _on_Easy_mouse_entered():
	game.show_tooltip("%s: x %s" % [tr("LOOT_XP_BONUS"), 1])


func _on_Normal_mouse_entered():
	game.show_tooltip("%s: x %s" % [tr("LOOT_XP_BONUS"), 1.25])


func _on_Hard_mouse_entered():
	game.show_tooltip("%s: x %s" % [tr("LOOT_XP_BONUS"), 1.5])


func set_difficulty():
	$TabContainer/GAME/HBoxContainer/Easy.pressed = false
	$TabContainer/GAME/HBoxContainer/Normal.pressed = false
	$TabContainer/GAME/HBoxContainer/Hard.pressed = false
	if err == OK:
		var diff = config.get_value("game", "e_diff", 1)
		if diff == 0:
			$TabContainer/GAME/HBoxContainer/Easy.pressed = true
		elif diff == 1:
			$TabContainer/GAME/HBoxContainer/Normal.pressed = true
		else:
			$TabContainer/GAME/HBoxContainer/Hard.pressed = true

func _on_Easy_pressed():
	if err == OK:
		config.set_value("game", "e_diff", 0)
		config.save("user://settings.cfg")
		set_difficulty()

func _on_Normal_pressed():
	if err == OK:
		config.set_value("game", "e_diff", 1)
		config.save("user://settings.cfg")
		set_difficulty()

func _on_Hard_pressed():
	if err == OK:
		config.set_value("game", "e_diff", 2)
		config.save("user://settings.cfg")
		set_difficulty()

func _on_Fullscreen_toggled(button_pressed):
	OS.window_fullscreen = button_pressed


func _on_Standard_pressed():
	if err == OK:
		config.set_value("game", "notation", "standard")
		config.save("user://settings.cfg")
		set_notation()

func _on_Standard_mouse_entered():
	game.show_tooltip("k < M < B < T < q < Q < s < S")


func _on_SI_pressed():
	if err == OK:
		config.set_value("game", "notation", "SI")
		config.save("user://settings.cfg")
		set_notation()

func _on_SI_mouse_entered():
	game.show_tooltip("k < M < G < T < P < E < Z < Y")

func set_notation():
	$TabContainer/MISC/HBoxContainer2/Standard.pressed = false
	$TabContainer/MISC/HBoxContainer2/SI.pressed = false
	$TabContainer/MISC/HBoxContainer2/Scientific.pressed = false
	if err == OK:
		var notation = config.get_value("game", "notation", "SI")
		if notation == "standard":
			$TabContainer/MISC/HBoxContainer2/Standard.pressed = true
			Helper.notation = 0
		elif notation == "SI":
			$TabContainer/MISC/HBoxContainer2/SI.pressed = true
			Helper.notation = 1
		else:
			$TabContainer/MISC/HBoxContainer2/Scientific.pressed = true
			Helper.notation = 2
	if is_instance_valid(game.HUD):
		game.HUD.refresh()


func _on_Scientific_pressed():
	if err == OK:
		config.set_value("game", "notation", "scientific")
		config.save("user://settings.cfg")
		set_notation()


func _on_MusicPitch_mouse_entered():
	game.show_tooltip(tr("TIME_SPEED_AFFECTS_PITCH_DESC"))


func _on_MusicPitch_toggled(button_pressed):
	if err == OK:
		game.pitch_affected = button_pressed
		if button_pressed and game.u_i:
			game.music_player.pitch_scale = game.u_i.time_speed
		else:
			game.music_player.pitch_scale = 1.0
		config.set_value("audio", "pitch_affected", button_pressed)
		config.save("user://settings.cfg")


func _on_EnableShaders_mouse_entered():
	game.show_tooltip(tr("ENABLE_SHADERS_DESC"))


func _on_EnableShaders_toggled(button_pressed):
	if err == OK:
		game.enable_shaders = button_pressed
		game.get_node("ClusterBG").visible = button_pressed
		config.set_value("graphics", "enable_shaders", button_pressed)
		config.save("user://settings.cfg")


func _on_ResetTooltips_pressed():
	for h in game.help:
		if h != "tutorial":
			game.help[h] = true


func _on_Screenshake_toggled(button_pressed):
	if err == OK:
		game.screen_shake = button_pressed
		config.set_value("graphics", "screen_shake", button_pressed)
		config.save("user://settings.cfg")


func _on_CaveGenInfo_toggled(button_pressed):
	if err == OK:
		game.cave_gen_info = button_pressed
		config.set_value("game", "cave_gen_info", button_pressed)
		config.save("user://settings.cfg")

func _on_OPCursor_toggled(button_pressed):
	game.op_cursor = button_pressed
	if err == OK:
		config.set_value("misc", "op_cursor", button_pressed)
		config.save("user://settings.cfg")
	if button_pressed:
		Input.set_custom_mouse_cursor(preload("res://Cursor.png"))
	else:
		Input.set_custom_mouse_cursor(null)


func _on_OPCursor_mouse_entered():
	game.show_tooltip("it's pretty op")


func _on_OPCursor_mouse_exited():
	if game.op_cursor:
		game.show_tooltip(":)")
	else:
		game.show_tooltip(":(")
	yield(get_tree().create_timer(0.5), "timeout")
	game.hide_tooltip()


func _on_DisplayRes_item_selected(index):
	var id:int = $TabContainer/GRAPHICS/DisplayRes.get_item_id(index)
	Helper.set_resolution(id)
	if not $TabContainer/GRAPHICS/KeepWindowSize.pressed and id != 0 and id < 9:
		OS.window_size = get_viewport().size
