extends Control
onready var game = self.get_parent()
onready var click_sound = get_node("../click")
var on_button = false

func _ready():
	$VBoxContainer/PlaceSoil.visible = game.show.plant_button

func _on_StarSystem_pressed():
	click_sound.play()
	game.switch_view("system")


func _on_Construct_pressed():
	click_sound.play()
	game.toggle_construct_panel()

func _on_Mine_pressed():
	click_sound.play()
	if game.pickaxe != null:
		game.view.obj.about_to_mine = true
		game.cancel_building()
		game.put_bottom_info(tr("START_MINE"))
	else:
		game.long_popup(tr("NO_PICKAXE"), tr("NO_PICKAXE_TITLE"), [tr("BUY_ONE")], ["open_shop_pickaxe"], tr("LATER"))

func _on_PlaceSoil_pressed():
	click_sound.play()
	game.HUD.get_node("Resources/Soil").visible = true
	game.put_bottom_info(tr("PLACE_SOIL_INFO"))

func _on_Construct_mouse_entered():
	on_button = true
	game.show_tooltip(tr("CONSTRUCT") + " (C)")

func _on_StarSystem_mouse_entered():
	on_button = true
	game.show_tooltip(tr("VIEW_STAR_SYSTEM") + " (V)")

func _on_Mine_mouse_entered():
	on_button = true
	game.show_tooltip(tr("MINE") + " (N)")

func _on_PlaceSoil_mouse_entered():
	on_button = true
	game.show_tooltip(tr("PLACE_SOIL") + " (P)")

func _on_mouse_exited():
	on_button = false
	game.hide_tooltip()
