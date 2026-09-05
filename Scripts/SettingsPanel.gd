extends "Panel.gd"

"""
audio sliders are set to each bus
(you can find the buses by looking at the bottom of the screen and clicking Audio)
"""
var config = ConfigFile.new()
var err = config.load("user://settings.cfg")
func _ready():
	set_polygon(size, position)
	var current_viewport = get_viewport().size
	$TabContainer/GRAPHICS/DisplayRes.add_item("Auto", 0)
	if DisplayServer.screen_get_size().y > 1440:
		$TabContainer/GRAPHICS/DisplayRes.add_item("3840 x 2160", 1)
	if DisplayServer.screen_get_size().y > 1080:
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
	set_enemy_difficulty_checkboxes()
	$TabContainer/SFX/Master.value = Settings.master_volume
	$TabContainer/SFX/Music.value = Settings.music_volume
	$TabContainer/SFX/SFX.value = Settings.SFX_volume
	$TabContainer/SFX/MusicPitch.button_pressed = Settings.pitch_affected
	$TabContainer/GRAPHICS/Vsync.button_pressed = Settings.vsync
	$TabContainer/GRAPHICS/AutosaveLight.button_pressed = Settings.autosave_light
	$TabContainer/GRAPHICS/EnableShaders.button_pressed = Settings.enable_shaders
	$TabContainer/GRAPHICS/Screenshake.button_pressed = Settings.screen_shake
	$TabContainer/GAME/AutosellMinerals.button_pressed = Settings.autosell
	$TabContainer/GAME/CaveGenInfo.button_pressed = Settings.cave_gen_info
	$TabContainer/GRAPHICS/Fullscreen.set_pressed_no_signal(Settings.fullscreen)
	$TabContainer/GAME/Autosave.value = Settings.autosave_interval
	$TabContainer/GAME/AutoSwitch.button_pressed = Settings.auto_switch_buy_sell
	$TabContainer/GAME/BackupIntervalSlider.value = Settings.backup_interval
	$TabContainer/GAME/MaxBackupsSlider.value = Settings.max_backups
	$TabContainer/GAME/BackupWithMinimalInterruption.mouse_entered.connect(game.show_tooltip.bind(tr("BACKUP_WITH_MINIMAL_INTERRUPTION_DESC")))
	$TabContainer/GAME/BackupWithMinimalInterruption.mouse_exited.connect(game.hide_tooltip)
	$TabContainer/GAME/BackupWithMinimalInterruption.button_pressed = Settings.backup_with_minimal_interruption
	$TabContainer/GRAPHICS/FPS/FPS.value = Settings.max_fps
	$TabContainer/GRAPHICS/SpaceLOD/StaticSpaceLOD.value = Settings.static_space_LOD
	$TabContainer/GRAPHICS/SpaceLOD/DynamicSpaceLOD.value = Settings.dynamic_space_LOD
	$TabContainer/MISC/OPCursor.button_pressed = Settings.op_cursor
	$TabContainer/MISC/ShowFPS.button_pressed = Settings.show_fps
	$TabContainer/MISC/Discord.button_pressed = Settings.discord
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
	$TabContainer/GAME/HBoxContainer/Easy.disabled = game.c_v == "battle"
	$TabContainer/GAME/HBoxContainer/Normal.disabled = game.c_v == "battle"
	$TabContainer/GAME/HBoxContainer/Hard.disabled = game.c_v == "battle"
	if game.c_v != "" and game.science_unlocked.has("ASM"):
		$TabContainer/GAME/AutosellMinerals.disabled = false
		$TabContainer/GAME/AutosellMineralsLabel.modulate = Color.WHITE
	else:
		$TabContainer/GAME/AutosellMinerals.disabled = true
		$TabContainer/GAME/AutosellMineralsLabel.modulate = Color(0.5, 0.5, 0.5, 1.0)
	$TabContainer/GRAPHICS/Fullscreen.text = "%s (F11)" % [tr("FULLSCREEN")]
	$TabContainer/SFX/MusicPitchLabel.text = "%s  [img]Graphics/Icons/help.png[/img]" % tr("TIME_SPEED_AFFECTS_PITCH")
	set_enemy_difficulty_checkboxes()

func _on_Vsync_toggled(button_pressed):
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if (button_pressed) else DisplayServer.VSYNC_DISABLED)
	save_config("graphics", "vsync", button_pressed)


func _on_Autosave_value_changed(value):
	$TabContainer/GAME/Label3.text = "%s %s" % [value, tr("S_SECOND")]
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
	$TabContainer/GRAPHICS/FPS/Label2.text = str(value)
	Engine.max_fps = value
	Settings.max_fps = value
	save_config("graphics", "max_fps", value)


func _on_AutosellMinerals_mouse_entered():
	game.show_tooltip(tr("AUTOSELL_MINERALS_DESC"))

func _on_mouse_exited():
	game.hide_tooltip()

func _on_AutosellMinerals_toggled(button_pressed):
	Settings.autosell = button_pressed
	save_config("game", "autosell", button_pressed)

func _on_Easy_mouse_entered():
	game.show_tooltip("%s: x %s" % [tr("LOOT_XP_BONUS"), 0.8])


func _on_Normal_mouse_entered():
	game.show_tooltip("%s: x %s" % [tr("LOOT_XP_BONUS"), 1.0])


func _on_Hard_mouse_entered():
	game.show_tooltip("%s: x %s" % [tr("LOOT_XP_BONUS"), 1.7])


func set_enemy_difficulty_checkboxes():
	$TabContainer/GAME/HBoxContainer/Easy.button_pressed = Settings.enemy_AI_difficulty == Settings.ENEMY_AI_DIFFICULTY_EASY
	$TabContainer/GAME/HBoxContainer/Normal.button_pressed = Settings.enemy_AI_difficulty == Settings.ENEMY_AI_DIFFICULTY_NORMAL
	$TabContainer/GAME/HBoxContainer/Hard.button_pressed = Settings.enemy_AI_difficulty == Settings.ENEMY_AI_DIFFICULTY_HARD

func _on_Easy_pressed():
	Settings.enemy_AI_difficulty = Settings.ENEMY_AI_DIFFICULTY_EASY
	set_enemy_difficulty_checkboxes()
	save_config("game", "enemy_AI_difficulty", Settings.ENEMY_AI_DIFFICULTY_EASY)

func _on_Normal_pressed():
	Settings.enemy_AI_difficulty = Settings.ENEMY_AI_DIFFICULTY_NORMAL
	set_enemy_difficulty_checkboxes()
	save_config("game", "enemy_AI_difficulty", Settings.ENEMY_AI_DIFFICULTY_NORMAL)

func _on_Hard_pressed():
	Settings.enemy_AI_difficulty = Settings.ENEMY_AI_DIFFICULTY_HARD
	set_enemy_difficulty_checkboxes()
	save_config("game", "enemy_AI_difficulty", Settings.ENEMY_AI_DIFFICULTY_HARD)

func _on_Fullscreen_toggled(button_pressed):
	get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (button_pressed) else Window.MODE_WINDOWED


func _on_Standard_pressed():
	Settings.notation = "standard"
	set_notation()
	save_config("interface", "notation", "standard")

func _on_Standard_mouse_entered():
	game.show_tooltip(tr("STANDARD_LARGE_NUMBER_NOTATION"))


func _on_SI_pressed():
	Settings.notation = "SI"
	set_notation()
	save_config("interface", "notation", "SI")

func _on_Scientific_pressed():
	Settings.notation = "scientific"
	set_notation()
	save_config("interface", "notation", "scientific")

func _on_SI_mouse_entered():
	game.show_tooltip("k < M < G < T < P < E < Z < Y < R < Q")

func set_notation():
	$TabContainer/MISC/HBoxContainer2/Standard.set_pressed_no_signal(Settings.notation == "standard")
	$TabContainer/MISC/HBoxContainer2/SI.set_pressed_no_signal(Settings.notation == "SI")
	$TabContainer/MISC/HBoxContainer2/Scientific.set_pressed_no_signal(Settings.notation == "scientific")
	if is_instance_valid(game.HUD):
		game.HUD.refresh()

func _on_MusicPitch_mouse_entered():
	game.show_tooltip(tr("TIME_SPEED_AFFECTS_PITCH_DESC"))

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
	save_config("audio", "pitch_affected", button_pressed)


func _on_EnableShaders_mouse_entered():
	game.show_tooltip(tr("ENABLE_SHADERS_DESC"))


func _on_EnableShaders_toggled(button_pressed):
	Settings.enable_shaders = button_pressed
	game.get_node("ClusterBG").visible = button_pressed
	game.get_node("Stars/Starfield").visible = button_pressed
	save_config("graphics", "enable_shaders", button_pressed)


func _on_Screenshake_toggled(button_pressed):
	Settings.screen_shake = button_pressed
	save_config("graphics", "screen_shake", button_pressed)


func _on_CaveGenInfo_toggled(button_pressed):
	Settings.cave_gen_info = button_pressed
	save_config("game", "cave_gen_info", button_pressed)

func _on_OPCursor_toggled(button_pressed):
	Settings.op_cursor = button_pressed
	if button_pressed:
		Input.set_custom_mouse_cursor(preload("res://Cursor.png"))
	else:
		Input.set_custom_mouse_cursor(null)
	save_config("misc", "op_cursor", button_pressed)


func _on_OPCursor_mouse_entered():
	game.show_tooltip("it's pretty op")


func _on_OPCursor_mouse_exited():
	if Settings.op_cursor:
		game.show_tooltip(":)")
	else:
		game.show_tooltip(":(")
	await get_tree().create_timer(0.5).timeout
	game.hide_tooltip()


func _on_DisplayRes_item_selected(index):
	var id:int = $TabContainer/GRAPHICS/DisplayRes.get_item_id(index)
	Helper.set_resolution(id)
#	if not $TabContainer/GRAPHICS/KeepWindowSize.button_pressed and id != 0 and id < 9:
#		get_window().size = get_viewport().size


func _on_discord_toggled(button_pressed):
	if button_pressed:
		Helper.setup_discord()
		Helper.refresh_discord()
	else:
		Helper.refresh_discord("clear")
	save_config("misc", "discord", button_pressed)


func _on_fps_pressed(extra_arg_0):
	$TabContainer/GRAPHICS/FPS/FPS.set_value(extra_arg_0)


func _on_auto_switch_toggled(button_pressed):
	Settings.auto_switch_buy_sell = button_pressed
	save_config("game", "auto_switch_buy_sell", button_pressed)


func _on_static_space_lod_value_changed(value):
	Settings.static_space_LOD = value
	game.get_node("ShaderExport/SubViewport/Starfield").material.set_shader_parameter("volsteps", value)
	game.get_node("ShaderExport/SubViewport/Starfield").material.set_shader_parameter("iterations", 14 + value / 2)
	if game.c_v in ["system", "planet", "battle"]:
		game.update_starfield_BG()
	$TabContainer/GRAPHICS/SpaceLOD/StaticSpaceLODValue.text = str(value)
	save_config("graphics", "static_space_LOD", value)


func _on_dynamic_space_lod_value_changed(value):
	Settings.dynamic_space_LOD = value
	game.get_node("StarfieldUniverse").material.set_shader_parameter("volsteps", value)
	game.get_node("StarfieldUniverse").material.set_shader_parameter("iterations", 14 + value / 2)
	if game.c_v == "STM":
		game.STM.get_node("GlowLayer/Background").material.set_shader_parameter("volsteps", value)
		game.STM.get_node("GlowLayer/Background").material.set_shader_parameter("iterations", 14 + value / 2)
	$TabContainer/GRAPHICS/SpaceLOD/DynamicSpaceLODValue.text = str(value)
	save_config("graphics", "dynamic_space_LOD", value)


func _on_show_fps_toggled(toggled_on: bool) -> void:
	Settings.show_fps = toggled_on
	game.fps_text.visible = toggled_on
	save_config("misc", "show_fps", toggled_on)


func _on_backup_interval_slider_value_changed(value: float) -> void:
	Settings.backup_interval = value
	if is_equal_approx(value, 1.0):
		$TabContainer/GAME/BackupIntervalValue.text = tr("1_MINUTE")
	else:
		$TabContainer/GAME/BackupIntervalValue.text = tr("X_MINUTES") % int(value)
	save_config("game", "backup_interval", value)


func _on_max_backups_slider_value_changed(value: float) -> void:
	Settings.max_backups = value
	$TabContainer/GAME/MaxBackupsValue.text = str(int(value))
	save_config("game", "max_backups", value)


func _on_backup_with_minimal_interruption_toggled(toggled_on: bool) -> void:
	Settings.backup_with_minimal_interruption = toggled_on
	save_config("game", "backup_with_minimal_interruption", toggled_on)

func save_config(section:String, setting:String, value):
	if err == OK:
		config.set_value(section, setting, value)
		config.save("user://settings.cfg")
