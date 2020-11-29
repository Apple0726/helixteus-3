extends Control
onready var game = self.get_parent()
onready var click_sound = get_node("../click")
var on_button = false

func _ready():
	if OS.get_latin_keyboard_variant() == "AZERTY":
		$VBoxContainer/StarSystem.shortcut.shortcut.action = "W"
	refresh()

func refresh():
	$VBoxContainer/PlaceSoil.visible = game.show.plant_button
	$VBoxContainer/Vehicles.visible = game.show.vehicles_button

func _on_StarSystem_pressed():
	click_sound.play()
	if game.lv < 5:
		return
	game.switch_view("system")

func _input(event):
	if OS.get_latin_keyboard_variant() == "QWERTY":
		$VBoxContainer/StarSystem.shortcut.shortcut.action = "Z"
	elif OS.get_latin_keyboard_variant() == "AZERTY":
		$VBoxContainer/StarSystem.shortcut.shortcut.action = "W"

func _on_Construct_pressed():
	if not Input.is_action_pressed("shift"):
		click_sound.play()
		game.toggle_panel(game.construct_panel)

func _on_Mine_pressed():
	click_sound.play()
	if not game.pickaxe.empty():
		game.cancel_building()
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
	game.show_tooltip("%s (%s)\n%s" % [tr("VIEW_STAR_SYSTEM"), $VBoxContainer/StarSystem.shortcut.shortcut.action, tr("REACH_X_TO_UNLOCK") % [tr("LV") + " 5"]])

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
