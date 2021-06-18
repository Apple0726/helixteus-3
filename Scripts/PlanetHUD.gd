extends Control
onready var game = get_node("/root/Game")
onready var click_sound = game.get_node("click")
var on_button = false

func _ready():
	refresh()

func refresh():
	$VBoxContainer/Construct.visible = game.show.construct_button
	$VBoxContainer/PlaceSoil.visible = game.show.plant_button
	$VBoxContainer/Terraform.visible = game.science_unlocked.TF
	$VBoxContainer/Mine.visible = game.show.mining
	if OS.get_latin_keyboard_variant() == "AZERTY":
		$VBoxContainer/StarSystem.shortcut.shortcut.action = "W"
	elif OS.get_latin_keyboard_variant() == "QWERTZ":
		$VBoxContainer/StarSystem.shortcut.shortcut.action = "Y"
	else:
		$VBoxContainer/StarSystem.shortcut.shortcut.action = "Z"

func _on_StarSystem_pressed():
	click_sound.play()
	if game.lv < 8:
		return
	game.switch_view("system")

func _input(event):
	refresh()

func _on_Construct_pressed():
	if not Input.is_action_pressed("shift"):
		click_sound.play()
		if game.tutorial:
			if game.tutorial.visible and not game.construct_panel.visible and game.tutorial.tut_num in [2, 3, 4]:
				game.tutorial.fade(0.15)
				game.toggle_panel(game.construct_panel)
			if not game.tutorial.tut_num in [2, 3, 4, 5] or not game.tutorial.visible and game.tutorial.tut_num == 4 and game.bottom_info_action == "":
				game.toggle_panel(game.construct_panel)
		else:
			game.toggle_panel(game.construct_panel)

func _on_Mine_pressed():
	click_sound.play()
	game.mine_tile()

func _on_PlaceSoil_pressed():
	click_sound.play()
	game.HUD.get_node("Resources/Soil").visible = true
	game.put_bottom_info(tr("PLACE_SOIL_INFO"), "place_soil", "cancel_place_soil")

func _on_Construct_mouse_entered():
	on_button = true
	game.show_tooltip(tr("CONSTRUCT") + " (C)")

func _on_StarSystem_mouse_entered():
	on_button = true
	var view_str:String = "%s (%s)" % [tr("VIEW_STAR_SYSTEM"), $VBoxContainer/StarSystem.shortcut.shortcut.action]
	if game.lv < 8:
		view_str += "\n%s" % [tr("REACH_X_TO_UNLOCK") % [tr("LV") + " 8"]]
	game.show_tooltip(view_str)

func _on_Mine_mouse_entered():
	on_button = true
	game.show_tooltip(tr("MINE") + " (N)")

func _on_PlaceSoil_mouse_entered():
	on_button = true
	game.show_tooltip(tr("PLACE_SOIL") + " (L)")

func _on_mouse_exited():
	on_button = false
	game.hide_tooltip()


func _on_Terraform_pressed():
	if game.c_p_g in [2, game.second_ship_hints.spawned_at_p, game.third_ship_hints.ship_spawned_at_p, game.third_ship_hints.part_spawned_at_p]:
		game.popup(tr("NO_TF"), 1.5)
	else:
		game.terraform_panel.pressure = game.planet_data[game.c_p].pressure
		var surface = 4 * PI * pow(game.planet_data[game.c_p].size / 2.0, 2)
		game.terraform_panel.surface = surface
		var lake_num:int = 0
		for tile in game.tile_data:
			if tile and tile.has("lake"):
				lake_num += 1
		game.terraform_panel.lake_num = lake_num
		game.terraform_panel.tile_num = len(game.tile_data)
		game.toggle_panel(game.terraform_panel)

func _on_Terraform_mouse_entered():
	game.show_tooltip(tr("TERRAFORM"))
