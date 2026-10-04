extends Control

@onready var game = get_node("/root/Game")
var moused_over = false
var language_data = {}

func _ready() -> void:
	var locale_stats_file = FileAccess.open("res://Text/localeStats.json", FileAccess.READ)
	var locale_stats_json = JSON.new()
	locale_stats_json = locale_stats_json.parse_string(locale_stats_file.get_as_text())
	var languages = []
	for locale in locale_stats_json:
		if locale != "en":
			languages.append({"locale":locale, "lines":locale_stats_json[locale].lines})
	languages.sort_custom(sort_by_completeness)
	languages.insert(0, {"locale":"en", "lines":locale_stats_json["en"].lines})
	
	for lg_data in languages:
		var locale = lg_data.locale
		var btn = TextureButton.new()
		btn.texture_normal = load("res://Graphics/Icons/Flags/%s.png" % locale)
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.custom_minimum_size.x = 60.0
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.material = ShaderMaterial.new()
		btn.material.shader = load("res://Shaders/LanguageButton.gdshader")
		btn.mouse_entered.connect(_on_lg_mouse_entered.bind(locale))
		btn.mouse_exited.connect(game.hide_tooltip)
		btn.pressed.connect(_on_lg_pressed.bind(locale))
		var lines_translated:int = locale_stats_json[locale]["lines"]
		var words_translated:int = locale_stats_json[locale]["words"]
		var chars_translated:int = locale_stats_json[locale]["chars"]
		language_data[locale] = {"lines":lines_translated, "words":words_translated, "chars":chars_translated}
		language_data[locale].name = locale_stats_json[locale]["name"]
		language_data[locale].progress = float(lines_translated) / locale_stats_json["en"]["lines"]
		btn.set_instance_shader_parameter("progress", float(lines_translated) / locale_stats_json["en"]["lines"])
		$Control/PanelContainer/Languages.add_child(btn)
		

func sort_by_completeness(a:Dictionary, b:Dictionary):
	return a.lines > b.lines

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
