extends "Panel.gd"

var init_PP:float
var PP:float
var PP_multiplier:float = 1.0

var units:Dictionary = {
	"speed_of_light":"c",
	"planck":"h",
	"boltzmann":"k",
	"s_b":"σ",
	"gravitational":"G",
	"charge":"e",
	"dark_energy":"",
	"difficulty":"",
	"time_speed":"",
	"age":"x " + tr("DEFAULT_UNIVERSE_AGE"),
	"antimatter":"",
	}

var point_distribution:Dictionary = {
	"speed_of_light":0,
	"planck":0,
	"boltzmann":0,
	"gravitational":0,
	"charge":0,
	"dark_energy":0,
	"difficulty":0,
	"time_speed":0,
	"age":0,
	"antimatter":0,
	}

func _ready() -> void:
	set_polygon($GUI.size, $GUI.position)
	for prop_hbox in $TP/VBox.get_children():
		if prop_hbox.name == "age":
			prop_hbox.get_node("Label").mouse_entered.connect(game.show_tooltip.bind(tr("AGE_OF_THE_UNIVERSE_DESC")))
		else:
			prop_hbox.get_node("Label").mouse_entered.connect(game.show_tooltip.bind(tr(prop_hbox.name.to_upper() + "_DESC")))
		prop_hbox.get_node("Label").mouse_exited.connect(game.hide_tooltip)
		if prop_hbox.name in ["s_b", "antimatter"]:
			continue
		prop_hbox.get_node("HSlider").value_changed.connect(_on_TP_value_changed.bind(prop_hbox.name))
		prop_hbox.get_node("Label2").text_changed.connect(_on_Label2_text_changed.bind(prop_hbox.name))


func refresh():
	for prop in point_distribution.keys():
		if prop == "age":
			$TP/VBox.get_node(prop + "/Label").text = "%s [img]Graphics/Icons/help.png[/img]" % tr("AGE_OF_THE_UNIVERSE")
		else:
			$TP/VBox.get_node(prop + "/Label").text = "%s [img]Graphics/Icons/help.png[/img]" % tr(prop.to_upper())
		_on_TP_value_changed(float(get_node("TP/VBox/%s/Label2" % prop).text), prop)
	$TP/VBox/s_b/Label.text = "%s [img]Graphics/Icons/help.png[/img]" % tr("S_B")
	init_PP = get_lv_sum()
	if game.subject_levels.dimensional_power >= 5:
		init_PP += 150
	var ok:bool = false
	if len(game.universe_data) == 0 and game.subject_levels.dimensional_power >= 5:
		ok = true
	PP_multiplier = 1.0
	for probe in game.probe_data:
		if probe and probe.tier == 2:
			ok = true
			PP_multiplier = probe.get("PP_multiplier", 1.0)
			break
	PP = init_PP * PP_multiplier + Helper.get_sum_of_dict(point_distribution)
	$Send.visible = ok
	$TP.visible = ok
	if ok:
		for prop in $TP/VBox.get_children():
			prop.get_node("Unit").text = units[prop.name]
			if prop.name == "time_speed":
				var cave_battle_time_speed:float = Helper.get_logarithmic_time_speed(game.subject_levels.dimensional_power, prop.get_node("HSlider").value)
				if cave_battle_time_speed != 1.0:
					prop.get_node("Unit").text = " (%s)" % [tr("TIME_SPEED_IN_BATTLES_CAVES") % cave_battle_time_speed]
			if prop.has_node("HSlider"):
				prop.get_node("HSlider").min_value = game.physics_bonus.MVOUP
				prop.get_node("HSlider").max_value = ceil(init_PP * PP_multiplier / Data.univ_prop_weights[prop.name] / 2.0)
				prop.get_node("HSlider").step = 0.1
				var value_range = prop.get_node("HSlider").max_value - prop.get_node("HSlider").min_value
				if value_range > 10:
					prop.get_node("HSlider").step = 0.2
					if value_range > 30:
						prop.get_node("HSlider").step = 0.5
		$TP/Points.text = "%s: %s [img]Graphics/Icons/help.png[/img]" % [tr("PROBE_POINTS"), Helper.format_num(PP, true)]
	else:
		$Label.text = tr("NO_TRI_PROBES")


func get_lv_sum():
	var lv:float = 0
	for univ in game.universe_data:
		lv += pow(univ.lv, 2.2)
	lv /= 200
	return lv

func _on_TP_value_changed(value:float, prop:String):
	var text_node:LineEdit = get_node("TP/VBox/%s/Label2" % prop)
	if get_viewport().gui_get_focus_owner() is HSlider:
		text_node["theme_override_colors/font_color"] = Color.WHITE
		text_node.text = str(value)
	else:
		value = float(text_node.text)
		get_node("TP/VBox/%s/HSlider" % prop).value = value
	if prop == "antimatter":
		point_distribution.antimatter = value * -game.physics_bonus[prop]
	else:
		if prop == "time_speed":
			var cave_battle_time_speed:float = Helper.get_logarithmic_time_speed(game.subject_levels.dimensional_power, $TP/VBox/time_speed/HSlider.value)
			if cave_battle_time_speed != 1.0:
				$TP/VBox/time_speed/Unit.text = " (%.2f in caves)" % [cave_battle_time_speed]
		if value >= 1:
			point_distribution[prop] = (value - 1) * -game.physics_bonus[prop]
		else:
			point_distribution[prop] = (1 / value - 1) * min(game.physics_bonus[prop], Data.univ_prop_weights[prop])
	PP = init_PP * PP_multiplier + Helper.get_sum_of_dict(point_distribution)
	if is_equal_approx(PP, 0):
		PP = 0
	var s_b:float = pow(float($TP/VBox/boltzmann/Label2.text), 4) / pow(float($TP/VBox/planck/Label2.text), 3) / pow(float($TP/VBox/speed_of_light/Label2.text), 2)
	if s_b >= 1000:
		$TP/VBox/s_b/Label2.text = Helper.format_num(round(s_b))
	else:
		$TP/VBox/s_b/Label2.text = str(Helper.clever_round(s_b))
	$TP/Points.text = "%s: %s [img]Graphics/Icons/help.png[/img]" % [tr("PROBE_POINTS"), Helper.format_num(PP, true)]

func _on_Label2_text_changed(new_text, prop:String):
	var new_value:float = float(new_text)
	if prop == "antimatter" and new_value >= 0 or new_value >= 0.5:
		_on_TP_value_changed(new_value, prop)
		get_node("TP/VBox/%s/Label2" % prop)["theme_override_colors/font_color"] = Color.WHITE
	else:
		get_node("TP/VBox/%s/Label2" % prop)["theme_override_colors/font_color"] = Color.RED


func discover_univ():
	if len(game.universe_data) > 0:
		for probe in game.probe_data:
			if probe and probe.tier == 2:
				game.probe_data.erase(probe)
				break
	var id:int = len(game.universe_data)
	var u_i:Dictionary = {"id":id, "lv":1, "xp":0, "xp_to_lv":10, "shapes":[], "name":"%s %s" % [tr("UNIVERSE"), id], "cluster_num":1000, "view":{"pos":Vector2(640, 360), "zoom":2, "sc_mult":0.1}}
	for prop in $TP/VBox.get_children():
		if prop.name == "s_b":
			continue
		u_i[prop.name] = float(prop.get_node("Label2").text)
	if not game.achievement_data.is_empty() and not game.achievement_data.progression.has("new_universe"):
		game.earn_achievement("progression", "new_universe")
	game.universe_data.append(u_i)
	if len(game.universe_data) == 1:
		game.dimension.set_bonuses()
		Data.MUs.MV.pw = game.maths_bonus.MUCGF_MV
		Data.MUs.MSMB.pw = game.maths_bonus.MUCGF_MSMB
		for el in game.PD_panel.bonuses.keys():
			game.chemistry_bonus[el] = game.PD_panel.bonuses[el]
	game.dimension.refresh_univs()
	if visible:
		game.toggle_panel(panel_var_name)


func _on_send_pressed() -> void:
	if PP >= 0:
		for prop in $TP/VBox.get_children():
			if prop.get_node("Label2")["theme_override_colors/font_color"] == Color.RED:
				game.popup(tr("INVALID_INPUT"), 1.5)
		if PP >= 5:
			game.show_YN_panel("discover_univ", tr("TP_CONFIRM2"))
		else:
			discover_univ()
	else:
		game.popup(tr("NOT_ENOUGH_PP"), 2.0)


func _on_tier_distribution_mouse_entered() -> void:
	var st = tr("ANCIENT_BLDG_TIER_DISTRIBUTION")
	for tier in range(1, 7):
		var age = float($TP/VBox/age/Label2.text)
		var prob:float
		if tier == 1:
			prob = max(1 - age * exp(-3 * tier), 0)
		else:
			prob = max(min(age * exp(-3 * (tier-1)), 1) - age * exp(-3 * tier), 0)
		st += "\n" + tr("TIER_X") % tier + ": " + str(Helper.clever_round(100 * prob)) + "%"
	game.show_tooltip(st)


func _on_tier_distribution_mouse_exited() -> void:
	game.hide_tooltip()
