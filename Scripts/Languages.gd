extends Control

onready var game = get_node("/root/Game")
var moused_over = false

func _input(event):
	if event is InputEventMouseMotion:
		if moused_over:
			if not Geometry.is_point_in_polygon(event.position, $MouseOut.polygon):
				$AnimationPlayer.play_backwards("MoveLanguages")
				moused_over = false
		elif Geometry.is_point_in_polygon(event.position, $MouseOver.polygon):
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
		yield(get_tree(), "idle_frame")
		$Control/TranslatedBy.rect_size.x = 0.0
		$Control/TranslatedBy.visible = true
	game.hide_tooltip()
	Data.reload()

func _on_lg_pressed(extra_arg_0):
	TranslationServer.set_locale(extra_arg_0)
	change_language()

func _on_lg_mouse_entered(extra_arg_0):
	var lg:String = ""
	var lines_translated:int = 0
	var lines_total:int = 1483 - 2
	match extra_arg_0:
		"fr":
			lg = "Français"
			lines_translated = 523 - 2
		"it":
			lg = "Italiano"
			lines_translated = 378 - 2
		"zh":
			lg = "中文"
			lines_translated = 1404 - 2
		"de":
			lg = "Deutsch"
			lines_translated = 1514 - 2
		"es":
			lg = "Español"
			lines_translated = 1160 - 2
		"ko":
			lg = "한국어"
			lines_translated = 220 - 2
		"sv":
			lg = "Svenska"
			lines_translated = 192 - 1
		"hu":
			lg = "Magyar"
			lines_translated = 1256 - 1
		"ja":
			lg = "日本語"
			lines_translated = 1420 - 2
		"nl":
			lg = "Nederlands"
			lines_translated = 1211 - 2
		"ru":
			lg = "Русский"
			lines_translated = 659 - 1
	if extra_arg_0 == "en":
		game.show_tooltip("English")
	else:
		game.show_tooltip("%s (%s)" % [lg, tr("X_LINES") % [lines_translated, lines_total]])

func _on_lg_mouse_exited():
	game.hide_tooltip()

