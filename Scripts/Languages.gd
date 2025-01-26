extends Control

@onready var game = get_node("/root/Game")
var moused_over = false

func _input(event):
	if event is InputEventMouseMotion:
		if moused_over:
			if not Geometry2D.is_point_in_polygon(event.position, $MouseOut.polygon):
				$AnimationPlayer.play_backwards("MoveLanguages")
				moused_over = false
		elif Geometry2D.is_point_in_polygon(event.position, $MouseOver.polygon):
			$AnimationPlayer.play("MoveLanguages")
			moused_over = true

func change_language():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		config.set_value("interface", "language", TranslationServer.get_locale())
		config.save("user://settings.cfg")
	if tr("TRANSLATORS_CREDITS") == "TRANSLATORS_CREDITS":
		$Control/TranslatedBy.visible = false
	else:
		$Control/TranslatedBy.text = tr("TRANSLATED_BY").format({"translators":tr("TRANSLATORS_CREDITS")})
		await get_tree().process_frame
		$Control/TranslatedBy.size.x = 0.0
		$Control/TranslatedBy.visible = true
	game.refresh_continue_button()
	game.hide_tooltip()
	Data.reload()

func _on_lg_pressed(extra_arg_0):
	TranslationServer.set_locale(extra_arg_0)
	change_language()

func _on_lg_mouse_entered(extra_arg_0):
	var lg:String = ""
	var locale_stats_file = FileAccess.open("res://Text/localeStats.json", FileAccess.READ)
	var locale_stats_json = JSON.new()
	locale_stats_json = locale_stats_json.parse_string(locale_stats_file.get_as_text())
	var lines_translated:int = locale_stats_json[extra_arg_0]["lines"]
	var words_translated:int = locale_stats_json[extra_arg_0]["words"]
	var chars_translated:int = locale_stats_json[extra_arg_0]["chars"]
	match extra_arg_0:
		"en":
			lg = "English"
		"fr":
			lg = "Français"
		"it":
			lg = "Italiano"
		"zh":
			lg = "中文"
		"de":
			lg = "Deutsch"
		"es":
			lg = "Español"
		"ko":
			lg = "한국어"
		"sv":
			lg = "Svenska"
		"hu":
			lg = "Magyar"
		"ja":
			lg = "日本語"
		"nl":
			lg = "Nederlands"
		"ru":
			lg = "Русский"
	if extra_arg_0 in ["zh", "ja"]:
		game.show_tooltip("%s\n%s\n%s" % [lg, tr("LINES") % lines_translated, tr("CHARACTERS") % chars_translated])
	else:
		game.show_tooltip("%s\n%s\n%s\n%s" % [lg, tr("LINES") % lines_translated, tr("WORDS") % words_translated, tr("CHARACTERS") % chars_translated])

func _on_lg_mouse_exited():
	game.hide_tooltip()
