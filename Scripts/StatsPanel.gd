extends "Panel.gd"

var stats_for:String = "global"
var curr_stat_tab:String = ""
var star_class_bar_width:float = 20.0
var ach_num:int = 0

func _ready():
	set_polygon(rect_size)
	var show_stats_for:Array = tr("SHOW_STATS_FOR").split("%s")
	$Statistics/HBox/Prefix.text = show_stats_for[0]
	$Statistics/HBox/Suffix.text = show_stats_for[1]
	$Tabs/Achievements._on_Button_pressed()
	for grid in $Achievements/ScrollContainer/HBox/Slots.get_children():
		for ach in grid.get_children():
			ach_num += 1
			ach.connect("mouse_entered", self, "on_ach_entered", [grid.name, ach.name])
			ach.connect("mouse_exited", self, "on_ach_exited")
	refresh()

func refresh():
	var ach_get:int = 0
	for grid in $Achievements/ScrollContainer/HBox/Slots.get_children():
		for ach in grid.get_children():
			if game.achievement_data[grid.name][int(ach.name)]:
				ach.modulate = Color.white
				ach_get += 1
			else:
				ach.modulate = Color(0.2, 0.2, 0.2, 1.0)
	$Achievements/Progress.text = "%s: %s / %s" % [tr("ACHIEVEMENTS_EARNED"), ach_get, ach_num]
	$Statistics/HBox.visible = game.dim_num > 1 or len(game.universe_data) > 1
	$Statistics/HBox/OptionButton.clear()
	$Statistics/HBox/OptionButton.add_item(tr("THIS_SAVE"), 0)
	if game.dim_num > 1:
		$Statistics/HBox/OptionButton.add_item(tr("THIS_DIMENSION"), 1)
	if len(game.universe_data) > 1:
		$Statistics/HBox/OptionButton.add_item(tr("THIS_UNIVERSE"), 2)

func on_ach_entered(ach_type:String, ach_id:String):
	game.show_tooltip(game.achievements[ach_type.to_lower()][int(ach_id)])

func on_ach_exited():
	game.hide_tooltip()

func _on_Achievements_pressed():
	$Achievements.visible = true
	$Statistics.visible = false

func _on_Statistics_pressed():
	$Achievements.visible = false
	$Statistics.visible = true

func _on_General_pressed():
	curr_stat_tab = "_on_General_pressed"
	$Statistics/Panel.visible = true
	$Statistics/ScrollContainer2.visible = false
	$Statistics/Panel/Label.text = "%s: %s\n%s: %s\n%s: %s\n%s: %s\n%s: %s\n%s: %s\n%s: %s\n%s: %s\n%s: %s" % [
		tr("TOTAL_MONEY_EARNED"), Helper.format_num(game["stats_%s" % stats_for].total_money_earned),
		tr("PLANETS_CONQUERED"), Helper.format_num(game["stats_%s" % stats_for].planets_conquered),
		tr("SYSTEMS_CONQUERED"), Helper.format_num(game["stats_%s" % stats_for].systems_conquered),
		tr("GALAXIES_CONQUERED"), game["stats_%s" % stats_for].galaxies_conquered,
		tr("ENEMIES_REKT_IN_BATTLE"), Helper.format_num(game["stats_%s" % stats_for].enemies_rekt_in_battle),
		tr("ENEMIES_REKT_IN_CAVES"), Helper.format_num(game["stats_%s" % stats_for].enemies_rekt_in_caves),
		tr("CHESTS_LOOTED"), Helper.format_num(game["stats_%s" % stats_for].chests_looted),
		tr("TILES_MINED_MINING"), Helper.format_num(game["stats_%s" % stats_for].tiles_mined_mining),
		tr("TILES_MINED_CAVES"), Helper.format_num(game["stats_%s" % stats_for].tiles_mined_caves),
	]

func _on_Records_pressed():
	curr_stat_tab = "_on_Records_pressed"
	$Statistics/Panel.visible = true
	$Statistics/ScrollContainer2.visible = false
	$Statistics/Panel/Label.text = "%s: %s km\n%s: %s %s\n%s: %s K\n%s: %s" % [
		tr("BIGGEST_PLANET_DIAMETER"), Helper.format_num(game["stats_%s" % stats_for].biggest_planet),
		tr("BIGGEST_STAR_SIZE"), Helper.format_num(Helper.clever_round(game["stats_%s" % stats_for].biggest_star)), tr("SOLAR_RADII"),
		tr("HOTTEST_STAR_TEMPERATURE"), Helper.format_num(round(game["stats_%s" % stats_for].hottest_star)),
		tr("HIGHEST_AURORA_INTENSITY"), Helper.format_num(game["stats_%s" % stats_for].highest_au_int),
	]

func _on_StarClasses_pressed():
	$Statistics/ScrollContainer2/Control/Zoom.visible = true
	$Statistics/ScrollContainer2/Control/ZoomLabel.visible = true
	curr_stat_tab = "_on_StarClasses_pressed"
	var graph:HBoxContainer = $Statistics/ScrollContainer2/Control/HBox
	var max_label:Label = $Statistics/ScrollContainer2/Control/MaxNum
	$Statistics/Panel.visible = false
	$Statistics/ScrollContainer2.visible = true
	for vbox in graph.get_children():
		graph.remove_child(vbox)
		vbox.queue_free()
	var max_num:int = 0
	for star_class in game["stats_%s" % stats_for].star_classes:
		for j in 10:
			var i:int = 9 - j
			var star_num:int = game["stats_%s" % stats_for].star_classes[star_class][i]
			if star_num == 0:
				continue
			max_num = max(max_num, star_num)
			var vbox = VBoxContainer.new()
			var bar = ColorRect.new()
			vbox["custom_constants/separation"] = 0
			vbox.rect_min_size.x = star_class_bar_width
			bar.rect_min_size.y = star_num
			bar.name = "ColorRect"
			bar.connect("mouse_entered", self, "on_star_class_bar_entered", [star_class, i])
			bar.connect("mouse_exited", self, "on_bar_exited")
			bar.color = Helper.get_star_modulate("%s%s" % [star_class, i])
			bar.size_flags_vertical = 10
			vbox.add_child(bar)
			var label = Label.new()
			label.align = Label.ALIGN_CENTER
			label.mouse_filter = Control.MOUSE_FILTER_PASS
			label.connect("mouse_entered", self, "on_star_class_bar_entered", [star_class, i])
			label.connect("mouse_exited", self, "on_bar_exited")
			label["custom_fonts/font"] = max_label["custom_fonts/font"]
			if star_class_bar_width > 15:
				label.text = "%s%s" % [star_class, i]
			vbox.add_child(label)
			graph.add_child(vbox)
	max_label.text = String(max_num)
	yield(get_tree(), "idle_frame")
	$Statistics/ScrollContainer2/Control.rect_min_size.x = graph.rect_size.x + 100
	for vbox in graph.get_children():
		vbox.get_node("ColorRect").rect_min_size.y *= 288.0 / max_num

func on_star_class_bar_entered(star_class:String, i:int):
	game.show_tooltip("%s%s: %s" % [star_class, i, game["stats_%s" % stats_for].star_classes[star_class][i]])

func on_star_type_bar_entered(star_type:String, _str:String):
	game.show_tooltip("%s: %s" % [_str, game["stats_%s" % stats_for].star_types[star_type]])

func on_bar_exited():
	game.hide_tooltip()


func _on_StarTypes_pressed():
	$Statistics/ScrollContainer2/Control/Zoom.visible = false
	$Statistics/ScrollContainer2/Control/ZoomLabel.visible = false
	curr_stat_tab = "_on_StarTypes_pressed"
	var graph:HBoxContainer = $Statistics/ScrollContainer2/Control/HBox
	var max_label:Label = $Statistics/ScrollContainer2/Control/MaxNum
	$Statistics/Panel.visible = false
	$Statistics/ScrollContainer2.visible = true
	for vbox in graph.get_children():
		graph.remove_child(vbox)
		vbox.queue_free()
	var max_num:int = 0
	for star_type in game["stats_%s" % stats_for].star_types:
		var star_num:int = game["stats_%s" % stats_for].star_types[star_type]
		if star_num == 0:
			continue
		max_num = max(max_num, star_num)
		var vbox = VBoxContainer.new()
		var bar = ColorRect.new()
		var label = Label.new()
		label.align = Label.ALIGN_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_PASS
		vbox["custom_constants/separation"] = 0
		vbox.rect_min_size.x = 100
		bar.rect_min_size.y = star_num
		bar.name = "ColorRect"
		bar.size_flags_vertical = 10
		label["custom_fonts/font"] = max_label["custom_fonts/font"]
		if star_type.substr(0, 11) == "hypergiant ":
			var arr:Array = star_type.split(" ")
			var star_tier:String = arr[1]
			label.text = "%s %s" % [tr(arr[0].to_upper()), star_tier]
		else:
			label.text = tr(star_type.to_upper())
		bar.connect("mouse_entered", self, "on_star_type_bar_entered", [star_type, label.text])
		label.connect("mouse_entered", self, "on_star_type_bar_entered", [star_type, label.text])
		bar.connect("mouse_exited", self, "on_bar_exited")
		label.connect("mouse_exited", self, "on_bar_exited")
		vbox.add_child(bar)
		vbox.add_child(label)
		graph.add_child(vbox)
	max_label.text = String(max_num)
	yield(get_tree(), "idle_frame")
	$Statistics/ScrollContainer2/Control.rect_min_size.x = graph.rect_size.x + 100
	for vbox in graph.get_children():
		vbox.get_node("ColorRect").rect_min_size.y *= 288.0 / max_num

func _on_OptionButton_item_selected(index):
	if index == 0:
		stats_for = "global"
	elif index == 1:
		stats_for = "dim"
	elif index == 2:
		stats_for = "univ"
	if curr_stat_tab != "":
		call(curr_stat_tab)

func _on_Zoom_value_changed(value):
	star_class_bar_width = value
	_on_StarClasses_pressed()
