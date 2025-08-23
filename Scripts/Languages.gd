extends Control

@onready var game = get_node("/root/Game")
var moused_over = false
var language_data = {}

func _ready() -> void:
	var locale_stats_file = FileAccess.open("res://Text/localeStats.json", FileAccess.READ)
	var locale_stats_json = JSON.new()
	locale_stats_json = locale_stats_json.parse_string(locale_stats_file.get_as_text())
	for language_btn in $Control/PanelContainer/Languages.get_children():
		var language_name = language_btn.name
		var lines_translated:int = locale_stats_json[language_name]["lines"]
		var words_translated:int = locale_stats_json[language_name]["words"]
		var chars_translated:int = locale_stats_json[language_name]["chars"]
		language_data[language_name] = {"lines":lines_translated, "words":words_translated, "chars":chars_translated}
		match language_name:
			"en":
				language_data[language_name].name = "English"
			"fr":
				language_data[language_name].name = "Français"
			"it":
				language_data[language_name].name = "Italiano"
			"zh":
				language_data[language_name].name = "中文"
			"de":
				language_data[language_name].name = "Deutsch"
			"es":
				language_data[language_name].name = "Español"
			"ko":
				language_data[language_name].name = "한국어"
			"sv":
				language_data[language_name].name = "Svenska"
			"hu":
				language_data[language_name].name = "Magyar"
			"ja":
				language_data[language_name].name = "日本語"
			"nl":
				language_data[language_name].name = "Nederlands"
			"ru":
				language_data[language_name].name = "Русский"
			"pl":
				language_data[language_name].name = "Polski"
		language_btn.set_instance_shader_parameter("progress", float(lines_translated) / locale_stats_json["en"]["lines"])
		language_data[language_name].progress = float(lines_translated) / locale_stats_json["en"]["lines"]
		

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

func _on_lg_mouse_entered(language:String):
	if language in ["zh", "ja"]:
		game.show_tooltip("%s (%.1f%%)\n%s\n%s" % [language_data[language].name, language_data[language].progress * 100.0, tr("LINES") % language_data[language].lines, tr("CHARACTERS") % language_data[language].chars])
	else:
		game.show_tooltip("%s (%.1f%%)\n%s\n%s\n%s" % [language_data[language].name, language_data[language].progress * 100.0, tr("LINES") % language_data[language].lines, tr("WORDS") % language_data[language].words, tr("CHARACTERS") % language_data[language].chars])

func _on_lg_mouse_exited():
	game.hide_tooltip()
