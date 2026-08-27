extends Panel

@onready var game = get_node("/root/Game")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Export.mouse_entered.connect(game.show_tooltip.bind(tr("EXPORT")))
	$Export.mouse_exited.connect(game.hide_tooltip)
	$Delete.mouse_entered.connect(game.show_tooltip.bind(tr("DELETE")))
	$Delete.mouse_exited.connect(game.hide_tooltip)

func initialize(save_info_dict: Dictionary, save_name:String, on_load: Callable, on_delete: Callable, on_export: Callable):
	var save_created = save_info_dict.save_created
	var save_modified = save_info_dict.save_modified
	$Version.text = save_info_dict.version
	$Button.pressed.connect(on_load.bind(save_name))
	$Delete.pressed.connect(on_delete.bind(save_name))
	$Export.pressed.connect(on_export.bind(save_name))
	$SaveName.text = save_name
	if save_info_dict.version == game.VERSION:
		$Version.mouse_entered.connect(game.show_tooltip.bind(tr("SAME_VERSION")))
		$Version["theme_override_colors/font_color"] = Color.GREEN
	elif save_info_dict.version in game.COMPATIBLE_VERSIONS:
		$Version.mouse_entered.connect(game.show_tooltip.bind(tr("VERSION_COMPATIBLE")))
		$Version["theme_override_colors/font_color"] = Color.YELLOW
	else:
		$Version.mouse_entered.connect(game.show_tooltip.bind(tr("VERSION_INCOMPATIBLE")))
		$Version["theme_override_colors/font_color"] = Color.RED
	$Version.mouse_exited.connect(game.hide_tooltip)
	var univ_num = len(save_info_dict.universe_data)
	if save_info_dict.dim_num > 1 or univ_num > 1:
		var univ_txt = tr("1_UNIVERSE") + " ({lv})".format({"lv":save_info_dict.universe_data[0].lv})
		if univ_num > 1:
			univ_txt = tr("X_UNIVERSES") % univ_num
		$Info.text = "{dim_txt} #{dim}\n{univ}".format({"dim_txt":tr("DIMENSION"), "dim":save_info_dict.dim_num, "univ":univ_txt})
	else:
		$Info.text = "{lv_txt} {lv}".format({"lv_txt":tr("LEVEL"), "lv":save_info_dict.universe_data[0].lv})
	var now = Time.get_unix_time_from_system()
	if now - save_created < 86400 * 2:
		$Created.text = "%s %s" % [tr("SAVE_CREATED"), tr("X_HOURS_AGO") % int((now - save_created) / 3600)]
	else:
		$Created.text = "%s %s" % [tr("SAVE_CREATED"), tr("X_DAYS_AGO") % int((now - save_created) / 86400)]
	if now - save_modified < 86400 * 2:
		$Saved.text = "%s %s" % [tr("SAVE_MODIFIED"), tr("X_HOURS_AGO") % int((now - save_modified) / 3600)]
	else:
		$Saved.text = "%s %s" % [tr("SAVE_MODIFIED"), tr("X_DAYS_AGO") % int((now - save_modified) / 86400)]
