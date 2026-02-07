extends Control

@onready var game = get_node("/root/Game")
var megastructures:Array = ["DS", "SE", "MME", "CBS", "MB", "PK"]
var build_all:bool = false
var star_selected = -1

func _ready():
	set_process_input(false)

func _input(event):
	if event is InputEventMouseMotion:
		var rect:Rect2 = Rect2($Panel.position, $Panel.size)
		game.block_scroll = rect.has_point(event.position)
	if visible and (Input.is_action_just_released("cancel") or Input.is_action_just_released("right_click")):
		hide_panel()

func _unhandled_input(event):
	if Input.is_action_just_released("left_click") and visible:
		hide_panel()

func refresh():
	for btn in $Panel/ScrollContainer/VBoxContainer.get_children():
		if btn is Button and btn.name != "BuildAll":
			btn.queue_free()
	for MS in megastructures:
		if MS != "MB" or game.science_unlocked.has("MB"):
			var btn = Button.new()
			btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			btn.expand_icon = true
			btn.icon = load("res://Graphics/Megastructures/%s_0.png" % MS)
			btn.custom_minimum_size.y = 138.0
			$Panel/ScrollContainer/VBoxContainer.add_child(btn)
			btn.connect("mouse_entered", Callable(self, "on_MS_over").bind(MS))
			btn.connect("mouse_exited", Callable(game, "hide_tooltip"))
			btn.connect("pressed", Callable(self, "on_MS_click").bind(MS))

func on_MS_over(MS:String):
	game.show_tooltip(tr("M_" + MS + "_DESC"))

func on_MS_click(MS:String):
	if MS == "" or game.c_v != "system":
		return
	if star_selected != -1 and MS in ["DS", "CBS", "MB", "PK"]:
		var MS_constr_data = {
			"obj":game.system_data[game.c_s].stars[star_selected],
		}
		game.view.obj.build_MS(MS_constr_data, MS)
		return
	if MS == "DS":
		if not build_all or build_all and game.science_unlocked.has("DS1") and game.science_unlocked.has("DS2") and game.science_unlocked.has("DS3") and game.science_unlocked.has("DS4"):
			game.put_bottom_info(tr("CLICK_STAR_TO_CONSTRUCT"), "building_DS", "cancel_building_MS")
			game.space_HUD._on_stars_pressed()
		else:
			game.popup(tr("NOT_ALL_STAGES_UNLOCKED"), 2.0)
			return
	elif MS == "CBS":
		if not build_all or build_all and game.science_unlocked.has("CBS1") and game.science_unlocked.has("CBS2") and game.science_unlocked.has("CBS3"):
			game.put_bottom_info(tr("CLICK_STAR_TO_CONSTRUCT"), "building_CBS", "cancel_building_MS")
			game.space_HUD._on_stars_pressed()
		else:
			game.popup(tr("NOT_ALL_STAGES_UNLOCKED"), 2.0)
			return
	elif MS == "MB":
		game.put_bottom_info(tr("CLICK_STAR_TO_CONSTRUCT"), "building_MB", "cancel_building_MS")
		game.space_HUD._on_stars_pressed()
	elif MS == "PK":
		if not build_all or build_all and game.science_unlocked.has("PK1") and game.science_unlocked.has("PK2"):
			game.put_bottom_info(tr("CLICK_STAR_TO_CONSTRUCT"), "building_PK", "cancel_building_MS")
			game.space_HUD._on_stars_pressed()
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


func _on_construct_panel_animation_animation_finished(anim_name):
	if $Panel.modulate.a == 0.0:
		visible = false

func hide_panel():
	if not $AnimationPlayer.is_playing():
		$AnimationPlayer.play_backwards("Fade")
		set_process_input(false)
		await get_tree().process_frame
		game.block_scroll = false


func _on_tree_exited():
	game.block_scroll = false


func _on_build_all_mouse_entered():
	game.show_tooltip(tr("BUILD_ALL_AT_ONCE"))


func _on_build_all_mouse_exited():
	game.hide_tooltip()
