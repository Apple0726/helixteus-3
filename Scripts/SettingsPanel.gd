extends "Panel.gd"

"""
audio sliders are set to each bus
(you can find the buses by looking at the bottom of the screen and clicking Audio)
"""
var config = ConfigFile.new()
var err = config.load("user://settings.cfg")
func _ready():
	set_polygon($GUI.size, $GUI.position)
	$TabBar/Sounds._on_Button_pressed()
	_on_sounds_pressed()
	$Panel/Sounds/Master.value_changed.connect(_on_Main_audio_value_changed)
	$Panel/Sounds/Music.value_changed.connect(_on_Music_value_changed)
	$Panel/Sounds/SFX.value_changed.connect(_on_Sound_Effects_value_changed)
	$Panel/Graphics/Vsync.toggled.connect(_on_Vsync_toggled)
	$Panel/Game/Autosave.value_changed.connect(_on_Autosave_value_changed)
	$Panel/Graphics/AutosaveLight.toggled.connect(_on_AutosaveLight_toggled)
	$Panel/Graphics/FPS/FPS.value_changed.connect(_on_FPS_value_changed)
	$"Panel/Graphics/FPS/30FPS".pressed.connect(_on_fps_pressed.bind(30))
	$"Panel/Graphics/FPS/60FPS".pressed.connect(_on_fps_pressed.bind(60))
	$"Panel/Graphics/FPS/120FPS".pressed.connect(_on_fps_pressed.bind(120))
	$Panel/Game/AutosellMinerals.mouse_entered.connect(game.show_tooltip.bind(tr("AUTOSELL_MINERALS_DESC")))
	$Panel/Game/AutosellMinerals.mouse_exited.connect(game.hide_tooltip)
	$Panel/Game/AutosellMinerals.toggled.connect(_on_AutosellMinerals_toggled)
	$Panel/Graphics/Fullscreen.toggled.connect(_on_Fullscreen_toggled)
	$Panel/Misc/HBoxContainer/Standard.mouse_entered.connect(game.show_tooltip.bind(tr("STANDARD_LARGE_NUMBER_NOTATION")))
	$Panel/Misc/HBoxContainer/Standard.mouse_exited.connect(game.hide_tooltip)
	$Panel/Misc/HBoxContainer/Standard.pressed.connect(_on_Standard_pressed)
	$Panel/Misc/HBoxContainer/SI.mouse_entered.connect(game.show_tooltip.bind("k < M < G < T < P < E < Z < Y < R < Q"))
	$Panel/Misc/HBoxContainer/SI.mouse_exited.connect(game.hide_tooltip)
	$Panel/Misc/HBoxContainer/SI.pressed.connect(_on_SI_pressed)
	$Panel/Misc/HBoxContainer/Scientific.pressed.connect(_on_Scientific_pressed)
	$Panel/Sounds/MusicPitch.mouse_entered.connect(game.show_tooltip.bind(tr("TIME_SPEED_AFFECTS_PITCH_DESC")))
	$Panel/Sounds/MusicPitch.mouse_exited.connect(game.hide_tooltip)
	$Panel/Sounds/MusicPitch.toggled.connect(_on_MusicPitch_toggled)
	$Panel/Graphics/EnableShaders.mouse_entered.connect(game.show_tooltip.bind(tr("ENABLE_SHADERS_DESC")))
	$Panel/Graphics/EnableShaders.mouse_exited.connect(game.hide_tooltip)
	$Panel/Graphics/EnableShaders.toggled.connect(_on_EnableShaders_toggled)
	$Panel/Graphics/Screenshake.toggled.connect(_on_Screenshake_toggled)
	$Panel/Misc/OPCursor.mouse_entered.connect(game.show_tooltip.bind("it's pretty op"))
	$Panel/Misc/OPCursor.mouse_exited.connect(_on_OPCursor_mouse_exited)
	$Panel/Misc/OPCursor.toggled.connect(_on_OPCursor_toggled)
	$Panel/Graphics/SpaceLOD/StaticSpaceLOD.value_changed.connect(_on_static_space_lod_value_changed)
	$Panel/Graphics/SpaceLOD/DynamicSpaceLOD.value_changed.connect(_on_dynamic_space_lod_value_changed)
	$Panel/Misc/ShowFPS.toggled.connect(_on_show_fps_toggled)
	$Panel/Game/BackupIntervalSlider.value_changed.connect(_on_backup_interval_slider_value_changed)
	$Panel/Game/MaxBackupsSlider.value_changed.connect(_on_max_backups_slider_value_changed)
	$Panel/Game/BackupWithMinimalInterruption.toggled.connect(_on_backup_with_minimal_interruption_toggled)
	#var current_viewport = get_viewport().size
	#$Panel/Graphics/DisplayRes.add_item("Auto", 0)
	#if DisplayServer.screen_get_size().y > 1440:
		#$Panel/Graphics/DisplayRes.add_item("3840 x 2160", 1)
	#if DisplayServer.screen_get_size().y > 1080:
		#$Panel/Graphics/DisplayRes.add_item("2560 x 1440", 2)
	#$Panel/Graphics/DisplayRes.add_item("1920 x 1080", 3)
	#$Panel/Graphics/DisplayRes.add_item("1280 x 720", 4)
	#$Panel/Graphics/DisplayRes.add_item("853 x 480", 5)
	#$Panel/Graphics/DisplayRes.add_item("640 x 360", 6)
	#$Panel/Graphics/DisplayRes.add_item("427 x 240", 7)
	#$Panel/Graphics/DisplayRes.add_item("256 x 144", 8)
	#$Panel/Graphics/DisplayRes.add_item("128 x 72", 9)
	#$Panel/Graphics/DisplayRes.add_item("64 x 36", 10)
	#$Panel/Graphics/DisplayRes.add_item("32 x 18", 11)
	#$Panel/Graphics/DisplayRes.add_item("16 x 9", 12)
	$Panel/Sounds/Master.value = Settings.master_volume
	$Panel/Sounds/Music.value = Settings.music_volume
	$Panel/Sounds/SFX.value = Settings.SFX_volume
	$Panel/Sounds/MusicPitch.set_pressed_no_signal(Settings.pitch_affected)
	$Panel/Graphics/Vsync.button_pressed = Settings.vsync
	$Panel/Graphics/AutosaveLight.button_pressed = Settings.autosave_light
	$Panel/Graphics/EnableShaders.button_pressed = Settings.enable_shaders
	$Panel/Graphics/Screenshake.button_pressed = Settings.screen_shake
	$Panel/Game/AutosellMinerals.button_pressed = Settings.autosell
	$Panel/Graphics/Fullscreen.set_pressed_no_signal(Settings.fullscreen)
	$Panel/Game/Autosave.value = Settings.autosave_interval
	$Panel/Game/BackupIntervalSlider.value = Settings.backup_interval
	$Panel/Game/MaxBackupsSlider.value = Settings.max_backups
	$Panel/Game/BackupWithMinimalInterruption.mouse_entered.connect(game.show_tooltip.bind(tr("BACKUP_WITH_MINIMAL_INTERRUPTION_DESC")))
	$Panel/Game/BackupWithMinimalInterruption.mouse_exited.connect(game.hide_tooltip)
	$Panel/Game/BackupWithMinimalInterruption.button_pressed = Settings.backup_with_minimal_interruption
	$Panel/Graphics/FPS/FPS.value = Settings.max_fps
	$Panel/Graphics/SpaceLOD/StaticSpaceLOD.value = Settings.static_space_LOD
	$Panel/Graphics/SpaceLOD/DynamicSpaceLOD.value = Settings.dynamic_space_LOD
	$Panel/Misc/OPCursor.set_pressed_no_signal(Settings.op_cursor)
	$Panel/Misc/ShowFPS.button_pressed = Settings.show_fps
	set_notation()

func _on_Main_audio_value_changed(value):
	Helper.update_volumes(0, value)
	save_config("audio", "master", value)

func _on_Music_value_changed(value):
	Helper.update_volumes(1, value)
	save_config("audio", "music", value)

func _on_Sound_Effects_value_changed(value):
	Helper.update_volumes(2, value)
	save_config("audio", "SFX", value)

func refresh():
	if game.c_v == "STM":
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		game.STM.show_help("")
		game.STM.set_process(false)
	$Panel/Graphics/Fullscreen.text = "%s (F11)" % [tr("FULLSCREEN")]
	$Panel/Sounds/MusicPitchLabel.text = "%s  [img]Graphics/Icons/help.png[/img]" % tr("TIME_SPEED_AFFECTS_PITCH")

func _on_Vsync_toggled(button_pressed):
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if (button_pressed) else DisplayServer.VSYNC_DISABLED)
	save_config("graphics", "vsync", button_pressed)

func _on_Autosave_value_changed(value):
	$Panel/Game/Label3.text = "%d %s" % [value, tr("S_SECOND")]
	Settings.autosave_interval = value
	if game.c_v != "":
		game.get_node("Autosave").stop()
		game.get_node("Autosave").wait_time = value
		game.get_node("Autosave").start()
	save_config("game", "autosave_interval", value)

func _on_AutosaveLight_toggled(button_pressed):
	if is_instance_valid(game.HUD):
		game.HUD.refresh()
	save_config("game", "autosave_light", button_pressed)

func _on_FPS_value_changed(value):
	$Panel/Graphics/FPS/Label2.text = str(int(value))
	Engine.max_fps = value
	Settings.max_fps = value
	save_config("graphics", "max_fps", value)

func _on_AutosellMinerals_toggled(button_pressed):
	Settings.autosell = button_pressed
	save_config("game", "autosell", button_pressed)

func _on_Fullscreen_toggled(button_pressed):
	get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (button_pressed) else Window.MODE_WINDOWED

func _on_Standard_pressed():
	Settings.notation = "standard"
	set_notation()
	save_config("interface", "notation", "standard")

func _on_SI_pressed():
	Settings.notation = "SI"
	set_notation()
	save_config("interface", "notation", "SI")

func _on_Scientific_pressed():
	Settings.notation = "scientific"
	set_notation()
	save_config("interface", "notation", "scientific")

func set_notation():
	$Panel/Misc/HBoxContainer/Standard.set_pressed_no_signal(Settings.notation == "standard")
	$Panel/Misc/HBoxContainer/SI.set_pressed_no_signal(Settings.notation == "SI")
	$Panel/Misc/HBoxContainer/Scientific.set_pressed_no_signal(Settings.notation == "scientific")
	if is_instance_valid(game.HUD):
		game.HUD.refresh()

func _on_MusicPitch_toggled(button_pressed):
	Settings.pitch_affected = button_pressed
	if button_pressed and game.u_i:
		if game.c_v == "cave":
			if game.subject_levels.dimensional_power >= 4:
				game.music_player.pitch_scale = log(game.u_i.time_speed * game.tile_data[game.c_t].get("time_speed_bonus", 1.0) - 1.0 + exp(1.0))
			else:
				game.music_player.pitch_scale = game.u_i.time_speed
		elif game.c_v == "mining":
			if button_pressed and game.tile_data[game.c_t].has("time_speed_bonus"):
				game.pitch_increased_mining = true
			game.music_player.pitch_scale = game.u_i.time_speed * game.tile_data[game.c_t].get("time_speed_bonus", 1.0)
		elif game.c_v == "battle" and game.subject_levels.dimensional_power >= 4:
			game.music_player.pitch_scale = log(game.u_i.time_speed - 1.0 + exp(1.0))
		else:
			game.music_player.pitch_scale = game.u_i.time_speed
	else:
		game.music_player.pitch_scale = 1.0
	if game.c_v == "cave":
		if game.tile_data[game.c_t].has("aurora"):
			game.music_player.pitch_scale *= 0.95
	save_config("audio", "pitch_affected", button_pressed)

func _on_EnableShaders_toggled(button_pressed):
	Settings.enable_shaders = button_pressed
	game.get_node("ClusterBG").visible = button_pressed
	game.get_node("Stars/Starfield").visible = button_pressed
	save_config("graphics", "enable_shaders", button_pressed)

func _on_Screenshake_toggled(button_pressed):
	Settings.screen_shake = button_pressed
	save_config("graphics", "screen_shake", button_pressed)

func _on_OPCursor_toggled(button_pressed):
	Settings.op_cursor = button_pressed
	if button_pressed:
		game.switch_music("")
		Input.set_custom_mouse_cursor(preload("res://Cursor.png"))
	else:
		Input.set_custom_mouse_cursor(null)
	save_config("misc", "op_cursor", button_pressed)

func _on_OPCursor_mouse_exited():
	if Settings.op_cursor:
		game.show_tooltip(":)")
	else:
		game.show_tooltip(":(")
	await get_tree().create_timer(0.5).timeout
	game.hide_tooltip()

#func _on_DisplayRes_item_selected(index):
	#var id:int = $Panel/Graphics/DisplayRes.get_item_id(index)
	#Helper.set_resolution(id)
#	if not $Panel/Graphics/KeepWindowSize.button_pressed and id != 0 and id < 9:
#		get_window().size = get_viewport().size

func _on_fps_pressed(fps:int):
	$Panel/Graphics/FPS/FPS.set_value(fps)

func _on_static_space_lod_value_changed(value):
	Settings.static_space_LOD = value
	game.get_node("ShaderExport/SubViewport/Starfield").material.set_shader_parameter("volsteps", value)
	game.get_node("ShaderExport/SubViewport/Starfield").material.set_shader_parameter("iterations", 14 + value / 2)
	if game.c_v in ["system", "planet", "battle"]:
		game.update_starfield_BG()
	$Panel/Graphics/SpaceLOD/StaticSpaceLODValue.text = str(int(value))
	save_config("graphics", "static_space_LOD", value)

func _on_dynamic_space_lod_value_changed(value):
	Settings.dynamic_space_LOD = value
	game.get_node("StarfieldUniverse").material.set_shader_parameter("volsteps", value)
	game.get_node("StarfieldUniverse").material.set_shader_parameter("iterations", 14 + value / 2)
	if game.c_v == "STM":
		game.STM.get_node("GlowLayer/Background").material.set_shader_parameter("volsteps", value)
		game.STM.get_node("GlowLayer/Background").material.set_shader_parameter("iterations", 14 + value / 2)
	$Panel/Graphics/SpaceLOD/DynamicSpaceLODValue.text = str(int(value))
	save_config("graphics", "dynamic_space_LOD", value)

func _on_show_fps_toggled(toggled_on: bool) -> void:
	Settings.show_fps = toggled_on
	game.fps_text.visible = toggled_on
	save_config("misc", "show_fps", toggled_on)

func _on_backup_interval_slider_value_changed(value: float) -> void:
	Settings.backup_interval = value
	if is_equal_approx(value, 1.0):
		$Panel/Game/BackupIntervalValue.text = tr("1_MINUTE")
	else:
		$Panel/Game/BackupIntervalValue.text = tr("X_MINUTES") % int(value)
	save_config("game", "backup_interval", value)

func _on_max_backups_slider_value_changed(value: float) -> void:
	Settings.max_backups = value
	$Panel/Game/MaxBackupsValue.text = str(int(value))
	save_config("game", "max_backups", value)

func _on_backup_with_minimal_interruption_toggled(toggled_on: bool) -> void:
	Settings.backup_with_minimal_interruption = toggled_on
	save_config("game", "backup_with_minimal_interruption", toggled_on)

func save_config(section:String, setting:String, value):
	if err == OK:
		config.set_value(section, setting, value)
		config.save("user://settings.cfg")

func _on_sounds_pressed() -> void:
	$Panel/Sounds.show()
	$Panel/Graphics.hide()
	$Panel/Game.hide()
	$Panel/Misc.hide()

func _on_graphics_pressed() -> void:
	$Panel/Sounds.hide()
	$Panel/Graphics.show()
	$Panel/Game.hide()
	$Panel/Misc.hide()

func _on_game_pressed() -> void:
	$Panel/Sounds.hide()
	$Panel/Graphics.hide()
	$Panel/Game.show()
	$Panel/Misc.hide()

func _on_misc_pressed() -> void:
	$Panel/Sounds.hide()
	$Panel/Graphics.hide()
	$Panel/Game.hide()
	$Panel/Misc.show()
