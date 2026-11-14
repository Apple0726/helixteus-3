extends "Panel.gd"

var build_all:bool = false
var star_selected = -1

func _ready():
	set_polygon($Panel.size, $Panel.position)
	for MS in Megastructure.names:
		var btn = Button.new()
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.expand_icon = true
		btn.icon = load("res://Graphics/Megastructures/%s_0.png" % MS)
		btn.custom_minimum_size.y = 138.0
		$Panel/ScrollContainer/VBoxContainer.add_child(btn)
		btn.name = MS
		btn.mouse_entered.connect(on_MS_over.bind(MS, btn))
		btn.mouse_exited.connect(on_MS_out)
		btn.pressed.connect(on_MS_click.bind(MS))

func _input(event):
	super(event)

func _unhandled_input(event):
	if Input.is_action_just_released("left_click") and visible:
		game.toggle_panel(panel_var_name)

func refresh():
	game.view.obj.build_all_MS_stages = build_all
	for MS in Megastructure.names:
		$Panel/ScrollContainer/VBoxContainer.get_node(MS).visible = (star_selected == -1 or MS in ["DS", "CBS", "MB", "PK"]) and (MS != "MB" or game.science_level[Science.MATRIOSHKA_BRAIN])

func on_MS_over(MS:String, MS_btn):
	if star_selected != -1:
		var star:Dictionary = game.system_data[game.c_s].stars[star_selected]
		if MS == "DS":
			game.view.obj.show_DS_costs(star, build_all)
		elif MS == "CBS":
			game.view.obj.show_CBS_costs(star, build_all)
		elif MS == "PK":
			game.view.obj.show_PK_costs(star, build_all)
		var star_node = get_tree().get_nodes_in_group("stars_system")[star_selected]
		if build_all:
			game.view.obj.add_MS_sprite(star_node, {"MS":MS, "MS_lv": Data.MS_num_stages[MS]})
		else:
			game.view.obj.add_MS_sprite(star_node, {"MS":MS, "MS_lv": 0})
	if MS_btn.disabled:
		var sc = Helper.get_science_from_MS(MS)
		var sc_name = Science.names[sc]
		game.show_tooltip("[color=#999999][font_size=20]({locked})[/font_size]\n{desc}".format({
			"locked":tr("LOCKED"),
			"desc":tr("UNLOCK_BY_RESEARCHING_X").format({"science": tr(sc_name.to_upper() + "_SC") + " " + str(len(Data.science_unlocks[sc].cost))})
		}))
	else:
		game.show_tooltip("[font_size=20]{MS_name}[/font_size]\n\n{MS_desc}".format({"MS_name":tr("M_" + MS + "_NAME"), "MS_desc":tr("M_" + MS + "_DESC")}))

func on_MS_out():
	var star_node = get_tree().get_nodes_in_group("stars_system")[star_selected]
	if star_node.has_node("MS") and not game.system_data[game.c_s].stars[star_selected].has("MS"):
		star_node.get_node("MS").free()
	game.get_node("UI/Panel").hide()
	game.hide_tooltip()

func on_MS_click(MS:String):
	if MS == "" or game.c_v != "system":
		return
	if star_selected != -1 and MS in ["DS", "CBS", "MB", "PK"]:
		game.view.obj.star_over_id = star_selected
		game.view.obj.build_MS(game.system_data[game.c_s].stars[star_selected], MS)
		return
	if MS == "DS":
		if not build_all or build_all and game.science_level[Science.DYSON_SPHERE] >= 4:
			game.put_bottom_info(tr("CLICK_STAR_TO_CONSTRUCT"), "building_DS", game.view.obj.finish_construct)
			game.space_HUD.show_stars_panel("DS")
		else:
			game.popup(tr("NOT_ALL_STAGES_UNLOCKED"), 2.0)
			return
	elif MS == "CBS":
		if not build_all or build_all and game.science_level[Science.CENTRAL_BUSINESS_SYSTEM] >= 3:
			game.put_bottom_info(tr("CLICK_STAR_TO_CONSTRUCT"), "building_CBS", game.view.obj.finish_construct)
			game.space_HUD.show_stars_panel("CBS")
		else:
			game.popup(tr("NOT_ALL_STAGES_UNLOCKED"), 2.0)
			return
	elif MS == "MB":
		game.put_bottom_info(tr("CLICK_STAR_TO_CONSTRUCT"), "building_MB", game.view.obj.finish_construct)
		game.space_HUD.show_stars_panel("MB")
	elif MS == "PK":
		if not build_all or build_all and game.science_level[Science.PLANETKILLER] >= 2:
			game.put_bottom_info(tr("CLICK_STAR_TO_CONSTRUCT"), "building_PK", game.view.obj.finish_construct)
			game.space_HUD.show_stars_panel("PK")
		else:
			game.popup(tr("NOT_ALL_STAGES_UNLOCKED"), 2.0)
			return
	elif MS == "SE":
		if not build_all or build_all and game.science_level[Science.SPACE_ELEVATOR] >= 1:
			game.put_bottom_info(tr("CLICK_PLANET_TO_CONSTRUCT"), "building-SE", game.view.obj.finish_construct)
		else:
			game.popup(tr("NOT_ALL_STAGES_UNLOCKED"), 2.0)
			return
	elif MS == "MME":
		if not build_all or build_all and game.science_level[Science.MEGA_MINERAL_EXTRACTOR] >= 3:
			game.put_bottom_info(tr("CLICK_PLANET_TO_CONSTRUCT"), "building-MME", game.view.obj.finish_construct)
		else:
			game.popup(tr("NOT_ALL_STAGES_UNLOCKED"), 2.0)
			return
	game.toggle_panel(panel_var_name)


func _on_build_all_toggled(toggled_on: bool) -> void:
	build_all = toggled_on
	game.view.obj.build_all_MS_stages = build_all
	for btn in $Panel/ScrollContainer/VBoxContainer.get_children():
		if toggled_on:
			btn.disabled = game.science_level[Helper.get_science_from_MS(btn.name)] < (Data.MS_num_stages[btn.name] if toggled_on else 0)
		else:
			btn.disabled = false
		if btn.disabled:
			btn.modulate = Color.GRAY
		else:
			btn.modulate = Color.WHITE
		btn.icon = load("res://Graphics/Megastructures/{name}_{stage}.png".format({"name":btn.name, "stage":Data.MS_num_stages[btn.name] if toggled_on else 0}))
