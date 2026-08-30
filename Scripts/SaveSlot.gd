extends Panel

@onready var game = get_node("/root/Game")

func _ready() -> void:
	$Export.mouse_entered.connect(game.show_tooltip.bind(tr("EXPORT")))
	$Export.mouse_exited.connect(game.hide_tooltip)
	$Delete.mouse_entered.connect(game.show_tooltip.bind(tr("DELETE")))
	$Delete.mouse_exited.connect(game.hide_tooltip)
	$ViewBackups.mouse_entered.connect(game.show_tooltip.bind(tr("VIEW_BACKUPS")))
	$ViewBackups.mouse_exited.connect(game.hide_tooltip)

func initialize(save_info_dict, save_name:String, on_load: Callable, on_delete: Callable, on_export: Callable):
	$SaveName.text = save_name
	$Delete.pressed.connect(on_delete.bind(save_name))
	if save_info_dict is not Dictionary:
		$LoadSave.disabled = true
		$Export.disabled = true
	else:
		var save_created = save_info_dict.save_created
		var save_modified = save_info_dict.save_modified
		$Version.text = save_info_dict.version
		$LoadSave.pressed.connect(on_load.bind(save_name))
		$Export.pressed.connect(on_export.bind(save_name))
		if save_info_dict.version == game.VERSION:
			$Version.mouse_entered.connect(game.show_tooltip.bind(tr("SAME_VERSION")))
			$Version.label_settings.font_color = Color.GREEN
		elif save_info_dict.version in game.COMPATIBLE_VERSIONS:
			$Version.mouse_entered.connect(game.show_tooltip.bind(tr("VERSION_COMPATIBLE")))
			$Version.label_settings.font_color = Color.GREEN_YELLOW
		else:
			$Version.mouse_entered.connect(game.show_tooltip.bind(tr("VERSION_INCOMPATIBLE")))
			$Version.label_settings.font_color = Color.ORANGE
		$Version.mouse_exited.connect(game.hide_tooltip)
		var univ_num = len(save_info_dict.universe_data)
		var univ_txt = tr("1_UNIVERSE")
		if univ_num > 1:
			univ_txt = tr("X_UNIVERSES") % univ_num
		$Info.text = "{dim_txt} #{dim}\n{univ}".format({"dim_txt":tr("DIMENSION"), "dim":save_info_dict.dim_num, "univ":univ_txt})
		for i in univ_num:
			var universe_icon = preload("res://Scenes/UniverseIcon.tscn").instantiate()
			universe_icon.custom_minimum_size = Vector2.ONE * 100.0
			for node in universe_icon.get_children():
				if node.name != "Level":
					node.hide()
			var univ_info:Dictionary = save_info_dict.universe_data[i]
			universe_icon.get_node("Level")["theme_override_font_sizes/font_size"] = 12
			universe_icon.get_node("Level").text = "{lv_txt} {lv}".format({"lv_txt":tr("LEVEL"), "lv":univ_info.lv})
			if Settings.enable_shaders:
				Helper.set_universe_btn_shader(universe_icon, univ_info)
			$ScrollContainer/Universes.add_child(universe_icon)
		var now = Time.get_unix_time_from_system()
		var created_text = ""
		var saved_text = ""
		if now - save_created < 86400 * 2:
			created_text = "%s %s" % [tr("SAVE_CREATED"), tr("X_HOURS_AGO") % int((now - save_created) / 3600)]
		else:
			created_text = "%s %s" % [tr("SAVE_CREATED"), tr("X_DAYS_AGO") % int((now - save_created) / 86400)]
		if now - save_modified < 86400 * 2:
			saved_text = "%s %s" % [tr("SAVE_MODIFIED"), tr("X_HOURS_AGO") % int((now - save_modified) / 3600)]
		else:
			saved_text = "%s %s" % [tr("SAVE_MODIFIED"), tr("X_DAYS_AGO") % int((now - save_modified) / 86400)]
		$CreatedSaved.text = "{created}\n{saved}".format({"created":created_text, "saved":saved_text})
		$TotalMoneyEarned.text = "[center][font size=13]" + tr("TOTAL_MONEY_EARNED") + ": [img height=1em]res://Graphics/Icons/money.png[/img] " + Helper.format_num(save_info_dict.stats_global.total_money_earned, true, 9) + "[/font][/center]"
