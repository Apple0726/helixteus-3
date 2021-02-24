extends Control
onready var game = self.get_parent()
onready var click_sound = get_node("../click")
var on_button = false

func _ready():
	refresh()

func refresh():
	$VBoxContainer/Construct.visible = game.show.construct_button
	$VBoxContainer/PlaceSoil.visible = game.show.plant_button
	$VBoxContainer/Vehicles.visible = game.show.vehicles_button
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
			if not game.tutorial.tut_num in [2, 3, 4, 5]:
				game.toggle_panel(game.construct_panel)
		else:
			game.toggle_panel(game.construct_panel)

func _on_Mine_pressed():
	click_sound.play()
	if not game.pickaxe.empty():
		if game.shop_panel.visible:
			game.toggle_panel(game.shop_panel)
		if game.tutorial and game.tutorial.visible and game.tutorial.tut_num == 14:
			game.tutorial.fade(0.4, false)
		game.put_bottom_info(tr("START_MINE"), "about_to_mine")
	else:
		game.long_popup(tr("NO_PICKAXE"), tr("NO_PICKAXE_TITLE"), [tr("BUY_ONE")], ["open_shop_pickaxe"], tr("LATER"))

func _on_PlaceSoil_pressed():
	click_sound.play()
	game.HUD.get_node("Resources/Soil").visible = true
	game.put_bottom_info(tr("PLACE_SOIL_INFO"), "place_soil", "cancel_place_soil")

func _on_Vehicles_pressed():
	if not Input.is_action_pressed("shift"):
		click_sound.play()
		game.toggle_panel(game.vehicle_panel)

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

func _on_Vehicles_mouse_entered():
	on_button = true
	game.show_tooltip(tr("VEHICLES_ON_PLANET") + " (V)")

func _on_mouse_exited():
	on_button = false
	game.hide_tooltip()
