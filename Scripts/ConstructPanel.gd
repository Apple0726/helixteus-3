extends Control

@onready var game = get_node("/root/Game")
var basic_bldgs:Array = [Building.MINERAL_EXTRACTOR, Building.POWER_PLANT, Building.RESEARCH_LAB, Building.BORING_MACHINE, Building.SOLAR_PANEL, Building.ATMOSPHERE_EXTRACTOR]
var storage_bldgs:Array = [Building.MINERAL_SILO, Building.BATTERY]
var production_bldgs:Array = [Building.STONE_CRUSHER, Building.GLASS_FACTORY, Building.STEAM_ENGINE, Building.ATOM_MANIPULATOR, Building.SUBATOMIC_PARTICLE_REACTOR]
var support_bldgs:Array = [Building.GREENHOUSE, Building.CENTRAL_BUSINESS_DISTRICT]
var vehicles_bldgs:Array = [Building.ROVER_CONSTRUCTION_CENTER, Building.SHIPYARD, Building.PROBE_CONSTRUCTION_CENTER]
var megastructures:Array = ["DS", "SE", "MME", "CBS", "MB", "PK"]
var build_all:bool = false

var tab = "basic"

func _ready():
	var added_buildings = Mods.added_buildings
	for key in added_buildings:
		match added_buildings[key].type:
			"basic":
				basic_bldgs.append(key)
			"storage":
				storage_bldgs.append(key)
			"production":
				production_bldgs.append(key)
			"support":
				support_bldgs.append(key)
			"vehicles":
				vehicles_bldgs.append(key)

func _input(event):
	if visible and (Input.is_action_just_released("cancel") or Input.is_action_just_released("right_click")):
		hide_panel()

func _unhandled_input(event):
	if event is InputEventMouseButton and visible:
		hide_panel()

func refresh():
	$Panel/VBoxContainer/Unique.visible = game.engineering_bonus.max_unique_building_tier > 0
	for btn in $Panel/ScrollContainer/VBoxContainer.get_children():
		if btn is Button and btn.name != "BuildAll":
			btn.queue_free()
	$Panel/ScrollContainer/VBoxContainer/HBoxContainer.visible = tab == "unique"
	$Panel/VBoxContainer.visible = tab != "megastructures"
	$Panel/ScrollContainer/VBoxContainer/BuildAll.visible = tab == "megastructures"
	if tab == "unique":
		var tier_arr:Array = tr("TIER_X").split(" ")
		if tier_arr[0] == "%s":
			$Panel/ScrollContainer/VBoxContainer/HBoxContainer/Label.move_to_front()
			$Panel/ScrollContainer/VBoxContainer/HBoxContainer/Label.text = tier_arr[1]
		else:
			$Panel/ScrollContainer/VBoxContainer/HBoxContainer/Tier.move_to_front()
			$Panel/ScrollContainer/VBoxContainer/HBoxContainer/Label.text = tier_arr[0]
		var selected_tier:int = $Panel/ScrollContainer/VBoxContainer/HBoxContainer/Tier.value
		for bldg in len(UniqueBuilding.names):
			if bldg in game.unique_bldgs_discovered.keys() and selected_tier in game.unique_bldgs_discovered[bldg].keys():
				var btn = Button.new()
				btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				btn.expand_icon = true
				btn.icon = load("res://Graphics/Buildings/Unique/%s.png" % UniqueBuilding.names[bldg])
				btn.custom_minimum_size.y = 100
				$Panel/ScrollContainer/VBoxContainer.add_child(btn)
				btn.connect("mouse_entered", Callable(self, "on_unique_bldg_over").bind(bldg))
				btn.connect("mouse_exited", Callable(game, "hide_tooltip"))
				btn.connect("pressed", Callable(self, "on_unique_bldg_click").bind(bldg))
	elif tab == "megastructures":
		for MS in megastructures:
			if MS != "MB" or game.science_unlocked.has("MB"):
				var btn = Button.new()
				btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				btn.expand_icon = true
				btn.icon = load("res://Graphics/Megastrcutures/%s.png" % MS)
				btn.custom_minimum_size.y = 100
				$Panel/ScrollContainer/VBoxContainer.add_child(btn)
				btn.connect("mouse_entered", Callable(self, "on_MS_over").bind(MS))
				btn.connect("mouse_exited", Callable(game, "hide_tooltip"))
				btn.connect("pressed", Callable(self, "on_MS_click").bind(MS))
	else:
		for bldg in self["%s_bldgs" % tab]:
			if game.new_bldgs.has(bldg):
				var btn = Button.new()
				btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				btn.expand_icon = true
				btn.icon = load("res://Graphics/Buildings/%s.png" % Building.names[bldg])
				btn.custom_minimum_size.y = 100
				$Panel/ScrollContainer/VBoxContainer.add_child(btn)
				btn.connect("mouse_entered", Callable(self, "on_bldg_over").bind(bldg))
				btn.connect("mouse_exited", Callable(game, "hide_tooltip"))
				btn.connect("pressed", Callable(self, "on_bldg_click").bind(bldg))

func on_MS_over(MS:String):
	game.show_tooltip(tr("M_" + MS + "_DESC"))

func on_MS_click(MS:String):
	if MS == "" or game.c_v != "system":
		return
	if MS == "DS":
		if not build_all or build_all and game.science_unlocked.has("DS1") and game.science_unlocked.has("DS2") and game.science_unlocked.has("DS3") and game.science_unlocked.has("DS4"):
			game.put_bottom_info(tr("CLICK_STAR_TO_CONSTRUCT"), "building_DS", "cancel_building_MS")
		else:
			game.popup(tr("NOT_ALL_STAGES_UNLOCKED"), 2.0)
			return
	elif MS == "CBS":
		if not build_all or build_all and game.science_unlocked.has("CBS1") and game.science_unlocked.has("CBS2") and game.science_unlocked.has("CBS3"):
			game.put_bottom_info(tr("CLICK_STAR_TO_CONSTRUCT"), "building_CBS", "cancel_building_MS")
		else:
			game.popup(tr("NOT_ALL_STAGES_UNLOCKED"), 2.0)
			return
	elif MS == "MB":
		game.put_bottom_info(tr("CLICK_STAR_TO_CONSTRUCT"), "building_MB", "cancel_building_MS")
	elif MS == "PK":
		if not build_all or build_all and game.science_unlocked.has("PK1") and game.science_unlocked.has("PK2"):
			game.put_bottom_info(tr("CLICK_STAR_TO_CONSTRUCT"), "building_PK", "cancel_building_MS")
		else:
			game.popup(tr("NOT_ALL_STAGES_UNLOCKED"), 2.0)
			return
	elif MS == "SE":
		if not build_all or build_all and game.science_unlocked.has("SE1"):
			game.put_bottom_info(tr("CLICK_PLANET_TO_CONSTRUCT"), "building-SE", "cancel_building_MS")
		else:
			game.popup(tr("NOT_ALL_STAGES_UNLOCKED"), 2.0)
			return
	elif MS == "MME":
		if not build_all or build_all and game.science_unlocked.has("MME1") and game.science_unlocked.has("MME2") and game.science_unlocked.has("MME3"):
			game.put_bottom_info(tr("CLICK_PLANET_TO_CONSTRUCT"), "building-MME", "cancel_building_MS")
		else:
			game.popup(tr("NOT_ALL_STAGES_UNLOCKED"), 2.0)
			return
	hide_panel()
	game.view.obj.build_all_MS_stages = build_all
	
func on_bldg_click(bldg:int):
	hide_panel()
	game.put_bottom_info(tr("CLICK_TILE_TO_CONSTRUCT"), "building", "cancel_building")
	var base_cost = Data.costs[bldg].duplicate(true)
	for cost in base_cost:
		base_cost[cost] *= game.engineering_bonus.BCM
	if bldg == Building.GREENHOUSE:
		base_cost.energy = round(base_cost.energy * (1 + abs(game.planet_data[game.c_p].temperature - 273) / 10.0))
	game.view.obj.construct(bldg, base_cost)

func on_bldg_over(bldg:int):
	var time_speed = game.u_i.time_speed
	var txt:String = "[font_size=20]%s[/font_size]\n%s\n\n%s\n" % [tr("%s_NAME" % Building.names[bldg].to_upper()), tr("%s_DESC" % Building.names[bldg].to_upper()), tr("COSTS")]
	var costs = Data.costs[bldg].duplicate(true)
	for cost in costs:
		costs[cost] *= game.engineering_bonus.BCM
	if bldg == Building.GREENHOUSE:
		costs.energy = round(costs.energy * (1 + abs(game.planet_data[game.c_p].temperature - 273) / 10.0))
	if costs.has("time"):
		if game.subject_levels.dimensional_power >= 1:
			costs.time = 0.2
		else:
			costs.time /= game.u_i.time_speed
	var icons = []
	for cost in costs.keys():
		txt += "@i  \t"
		if cost == "time":
			txt += Helper.time_to_str(costs[cost])
			icons.append(Data.time_icon)
		elif cost in game.mat_info.keys():
			txt += Helper.format_num(costs[cost]) + " kg"
			icons.append(load("res://Graphics/Materials/%s.png" % cost))
		elif cost in game.met_info.keys():
			txt += Helper.format_num(costs[cost]) + " kg"
			icons.append(load("res://Graphics/Metals/%s.png" % cost))
		else:
			txt += Helper.format_num(costs[cost])
			icons.append(Data["%s_icon" % cost])
		txt += "\n"
	txt += "\n"
	var IR_mult = Helper.get_IR_mult(bldg)
	if bldg == Building.SOLAR_PANEL:
		txt += (Data.path_1[bldg].desc + "\n") % [Helper.format_num(Helper.get_SP_production(game.planet_data[game.c_p].temperature, Data.path_1[bldg].value * IR_mult * time_speed), true)]
	elif bldg == Building.ATMOSPHERE_EXTRACTOR:
		txt += (Data.path_1[bldg].desc + "\n") % [Helper.format_num(Helper.get_AE_production(game.planet_data[game.c_p].pressure, Data.path_1[bldg].value * IR_mult * time_speed), true)]
	elif bldg == Building.BATTERY:
		txt += (Data.path_1[bldg].desc + "\n") % [Helper.format_num(round(Data.path_1[bldg].value * IR_mult * game.u_i.charge))]
	elif Data.path_1.has(bldg):
		txt += (Data.path_1[bldg].desc + "\n") % [Helper.format_num(Data.path_1[bldg].value * IR_mult * time_speed, true)]
	if Data.path_2.has(bldg):
		if Data.path_2[bldg].has("is_value_integer"):
			txt += (Data.path_2[bldg].desc + "\n") % [Helper.format_num(round(Data.path_2[bldg].value * IR_mult))]
		else:
			txt += (Data.path_2[bldg].desc + "\n") % [Helper.format_num(Data.path_2[bldg].value * IR_mult, true)]
	if Data.path_3.has(bldg):
		if bldg == Building.CENTRAL_BUSINESS_DISTRICT:
			txt += Data.path_3[bldg].desc.format({"n":Data.path_3[bldg].value}) + "\n"
		else:
			txt += (Data.path_3[bldg].desc + "\n") % [Data.path_3[bldg].value]
	if Data.desc_icons.has(bldg):
		icons.append_array(Helper.flatten(Data.desc_icons[bldg]))
	game.show_adv_tooltip(txt, icons)


func _on_basic_mouse_entered():
	tween_label($Panel/VBoxContainer/Basic/Label, 1.0)


func _on_basic_mouse_exited():
	if tab != "basic":
		tween_label($Panel/VBoxContainer/Basic/Label, 0.0)


func _on_storage_mouse_entered():
	tween_label($Panel/VBoxContainer/Storage/Label, 1.0)


func _on_storage_mouse_exited():
	if tab != "storage":
		tween_label($Panel/VBoxContainer/Storage/Label, 0.0)


func _on_production_mouse_entered():
	tween_label($Panel/VBoxContainer/Production/Label, 1.0)


func _on_production_mouse_exited():
	if tab != "production":
		tween_label($Panel/VBoxContainer/Production/Label, 0.0)


func _on_support_mouse_entered():
	tween_label($Panel/VBoxContainer/Support/Label, 1.0)


func _on_support_mouse_exited():
	if tab != "support":
		tween_label($Panel/VBoxContainer/Support/Label, 0.0)


func _on_vehicles_mouse_entered():
	tween_label($Panel/VBoxContainer/Vehicles/Label, 1.0)


func _on_vehicles_mouse_exited():
	if tab != "vehicles":
		tween_label($Panel/VBoxContainer/Vehicles/Label, 0.0)


func _on_tab_pressed(extra_arg_0:String):
	tab = extra_arg_0.to_lower()
	for btn in $Panel/VBoxContainer.get_children():
		if btn.name != extra_arg_0:
			tween_label(btn.get_node("Label"), 0.0)
	refresh()

func tween_label(label, final_val):
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", final_val, 0.1)


func _on_unique_mouse_entered():
	tween_label($Panel/VBoxContainer/Unique/Label, 1.0)


func _on_unique_mouse_exited():
	if tab != "unique":
		tween_label($Panel/VBoxContainer/Unique/Label, 0.0)

func on_unique_bldg_over(bldg:int):
	pass

func on_unique_bldg_click(bldg:int):
	pass


func _on_tier_value_changed(value):
	refresh()


func _on_build_all_toggled(button_pressed):
	build_all = button_pressed


func _on_construct_panel_animation_animation_finished(anim_name):
	if $Panel.modulate.a == 0.0:
		visible = false

func hide_panel():
	if not $AnimationPlayer.is_playing():
		$AnimationPlayer.play_backwards("Fade")
		game.block_scroll = false
