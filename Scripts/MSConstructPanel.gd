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
		btn.mouse_entered.connect(on_MS_over.bind(MS))
		btn.mouse_exited.connect(on_MS_out)
		btn.pressed.connect(on_MS_click.bind(MS))

func _input(event):
	super(event)

func _unhandled_input(event):
	if Input.is_action_just_released("left_click") and visible:
		game.toggle_panel(panel_var_name)

func refresh():
	for MS in Megastructure.names:
		$Panel/ScrollContainer/VBoxContainer.get_node(MS).visible = (star_selected == -1 or MS in ["DS", "CBS", "MB", "PK"]) and (MS != "MB" or game.science_unlocked.has("MB"))

func on_MS_over(MS:String):
	game.show_tooltip("[font_size=20]{MS_name}[/font_size]\n\n{MS_desc}".format({"MS_name":tr("M_" + MS + "_NAME"), "MS_desc":tr("M_" + MS + "_DESC")}))
	if star_selected != -1:
		var star:Dictionary = game.system_data[game.c_s].stars[star_selected]
		if MS == "DS":
			game.view.obj.show_DS_costs(star, not build_all)
		elif MS == "CBS":
			game.view.obj.show_CBS_costs(star, not build_all)
		elif MS == "PK":
			game.view.obj.show_PK_costs(star, not build_all)
		var star_node = get_tree().get_nodes_in_group("stars_system")[star_selected]
		if build_all:
			game.view.obj.add_MS_sprite(star_node, {"MS":MS, "MS_lv": Data.MS_num_stages[MS]})
		else:
			game.view.obj.add_MS_sprite(star_node, {"MS":MS, "MS_lv": 0})

func on_MS_out():
	var star_node = get_tree().get_nodes_in_group("stars_system")[star_selected]
	if star_node.has_node("MS") and not game.system_data[game.c_s].stars[star_selected].has("MS"):
		star_node.get_node("MS").free()
	game.get_node("UI/Panel").hide()
	game.hide_tooltip()

func on_MS_click(MS:String):
	if MS == "" or game.c_v != "system":
		return
	game.view.obj.build_all_MS_stages = build_all
	if star_selected != -1 and MS in ["DS", "CBS", "MB", "PK"]:
		game.view.obj.star_over_id = star_selected
		game.view.obj.build_MS(game.system_data[game.c_s].stars[star_selected], MS)
		return
	if MS == "DS":
		if not build_all or build_all and game.science_unlocked.has("DS1") and game.science_unlocked.has("DS2") and game.science_unlocked.has("DS3") and game.science_unlocked.has("DS4"):
			game.put_bottom_info(tr("CLICK_STAR_TO_CONSTRUCT"), "building_DS", "cancel_building_MS")
			game.space_HUD.show_stars_panel("DS")
		else:
			game.popup(tr("NOT_ALL_STAGES_UNLOCKED"), 2.0)
			return
	elif MS == "CBS":
		if not build_all or build_all and game.science_unlocked.has("CBS1") and game.science_unlocked.has("CBS2") and game.science_unlocked.has("CBS3"):
			game.put_bottom_info(tr("CLICK_STAR_TO_CONSTRUCT"), "building_CBS", "cancel_building_MS")
			game.space_HUD.show_stars_panel("CBS")
		else:
			game.popup(tr("NOT_ALL_STAGES_UNLOCKED"), 2.0)
			return
	elif MS == "MB":
		game.put_bottom_info(tr("CLICK_STAR_TO_CONSTRUCT"), "building_MB", "cancel_building_MS")
		game.space_HUD.show_stars_panel("MB")
	elif MS == "PK":
		if not build_all or build_all and game.science_unlocked.has("PK1") and game.science_unlocked.has("PK2"):
			game.put_bottom_info(tr("CLICK_STAR_TO_CONSTRUCT"), "building_PK", "cancel_building_MS")
			game.space_HUD.show_stars_panel("PK")
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
	game.toggle_panel(panel_var_name)


func _on_build_all_toggled(toggled_on: bool) -> void:
	build_all = toggled_on
	for btn in $Panel/ScrollContainer/VBoxContainer.get_children():
		if toggled_on:
			btn.visible = game.science_unlocked.has("{name}{stage}".format({"name":btn.name, "stage":Data.MS_num_stages[btn.name] if toggled_on else 0}))
		else:
			btn.show()
		btn.icon = load("res://Graphics/Megastructures/{name}_{stage}.png".format({"name":btn.name, "stage":Data.MS_num_stages[btn.name] if toggled_on else 0}))
