extends Control

onready var click_sound = get_node("../click")
onready var game = get_parent()
onready var money_text = $Resources/Money/Text
onready var minerals_text = $Resources/Minerals/Text
onready var stone_text = $Resources/Stone/Text
onready var soil_text = $Resources/Soil/Text
onready var energy_text = $Resources/Energy/Text
onready var minerals = $Resources/Minerals
onready var stone = $Resources/Stone
onready var craft = $Buttons/Craft
var on_button = false

func _on_Button_pressed():
	click_sound.play()
	if AudioServer.is_bus_mute(1) == false:
		AudioServer.set_bus_mute(1,true)
	else:
		AudioServer.set_bus_mute(1,false)

func _process(_delta):
	money_text.text = String(game.money)
	minerals_text.text = String(game.minerals) + " / " + String(game.mineral_capacity)
	stone_text.text = String(game.stone) + " kg"
	soil_text.text = String(game.mats.soil) + " kg"
	energy_text.text = String(game.energy)
	minerals.visible = game.show.minerals
	stone.visible = game.show.stone
	craft.visible = game.show.materials

func _on_Shop_pressed():
	click_sound.play()
	game.toggle_shop_panel()

func _on_Button_mouse_entered():
	on_button = true
	game.show_tooltip(tr("MUTE") + " (M)")

func _on_Shop_mouse_entered():
	on_button = true
	game.show_tooltip(tr("SHOP") + " (R)")

func _on_Inventory_mouse_entered():
	on_button = true
	game.show_tooltip(tr("INVENTORY") + " (E)")

func _on_Craft_mouse_entered():
	on_button = true
	game.show_tooltip(tr("CRAFT") + " (T)")

func _on_Inventory_pressed():
	click_sound.play()
	game.toggle_inventory()

func _on_Craft_pressed():
	click_sound.play()
	game.toggle_craft_panel()

func _on_Money_mouse_entered():
	game.show_tooltip(tr("MONEY"))

func _on_Minerals_mouse_entered():
	game.show_tooltip(tr("MINERALS"))

func _on_Stone_mouse_entered():
	game.show_tooltip(tr("STONE"))

func _on_mouse_exited():
	on_button = false
	game.hide_tooltip()

func _on_Energy_mouse_entered():
	game.show_tooltip(tr("ENERGY"))


