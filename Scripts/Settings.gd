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
	$Fullscreen.text = "%s (F11)" % [tr("FULLSCREEN")]
	if err == OK:
		set_difficulty()
		$Master.value = config.get_value("audio", "master", 0)
		update_volumes(0, config.get_value("audio", "master", 0))
		$Music.value = config.get_value("audio", "music", 0)
		update_volumes(1, config.get_value("audio", "music", 0))
		$SFX.value = config.get_value("audio", "SFX", 0)
		update_volumes(2, config.get_value("audio", "SFX", 0))
		$Vsync.pressed = config.get_value("graphics", "vsync", true)
		$AutosaveLight.pressed = config.get_value("saving", "autosave_light", false)
		$EnableAutosave.pressed = config.get_value("saving", "enable_autosave", true)
		$AutosellMinerals.pressed = config.get_value("game", "autosell", false)
		var autosave_interval = config.get_value("saving", "autosave", 10)
		var max_fps = config.get_value("rendering", "max_fps", 60)
		$Fullscreen.pressed = OS.window_fullscreen
		$Autosave.value = autosave_interval
		$FPS/FPS.value = max_fps
		$CollectSpeed/CollectSpeedSlider.value = config.get_value("game", "collect_speed", 1)

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
	set_difficulty()

func _on_Vsync_toggled(button_pressed):
	if err == OK:
		OS.vsync_enabled = button_pressed
		config.set_value("graphics", "vsync", button_pressed)
		config.save("user://settings.cfg")


func _on_Autosave_value_changed(value):
	if err == OK:
		$Label3.text = "%s %s" % [value, tr("S_SECOND")]
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
		$FPS/Label2.text = String(value)
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


func _on_CollectSpeed_mouse_entered():
	game.show_tooltip(tr("COLLECT_SPEED_DESC"))


func _on_CollectSpeedSlider_value_changed(value):
	if err == OK:
		config.set_value("game", "collect_speed", value)
		game.collect_speed_lag_ratio = value
		config.save("user://settings.cfg")


func _on_Easy_mouse_entered():
	game.show_tooltip("%s: x %s" % [tr("LOOT_XP_BONUS"), 1])


func _on_Normal_mouse_entered():
	game.show_tooltip("%s: x %s" % [tr("LOOT_XP_BONUS"), 1.25])


func _on_Hard_mouse_entered():
	game.show_tooltip("%s: x %s" % [tr("LOOT_XP_BONUS"), 1.5])


func set_difficulty():
	$HBoxContainer/Easy.pressed = false
	$HBoxContainer/Normal.pressed = false
	$HBoxContainer/Hard.pressed = false
	if err == OK:
		var diff = config.get_value("game", "e_diff", 1)
		if diff == 0:
			$HBoxContainer/Easy.pressed = true
		elif diff == 1:
			$HBoxContainer/Normal.pressed = true
		else:
			$HBoxContainer/Hard.pressed = true

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
	$HBoxContainer2/Standard.pressed = false
	$HBoxContainer2/SI.pressed = false
	if err == OK:
		var notation = config.get_value("game", "notation", "SI")
		if notation == "standard":
			$HBoxContainer2/Standard.pressed = true
			Helper.SI = false
		else:
			$HBoxContainer2/SI.pressed = true
			Helper.SI = true
	if is_instance_valid(game.HUD):
		game.HUD.refresh()
