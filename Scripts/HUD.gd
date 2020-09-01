extends Control

onready var click_sound = get_node("../click")
onready var game = get_parent()
onready var money_text = $Resources/Money/Text
onready var minerals_text = $Resources/Minerals/Text
onready var stone_text = $Resources/Stone/Text
onready var energy_text = $Resources/Energy/Text
onready var minerals = $Resources/Minerals
onready var stone = $Resources/Stone

func _on_Button_pressed():
	click_sound.play()
	if AudioServer.is_bus_mute(1) == false:
		AudioServer.set_bus_mute(1,true)
	else:
		AudioServer.set_bus_mute(1,false)

func _on_Button_mouse_entered():
	game.show_tooltip(tr("MUTE") + " (M)")

func _on_Button_mouse_exited():
	game.hide_tooltip()

func _process(_delta):
	money_text.text = String(game.money)
	minerals_text.text = String(game.minerals) + " / " + String(game.mineral_capacity)
	stone_text.text = String(game.stone) + " kg"
	energy_text.text = String(game.energy)
	minerals.visible = game.show.minerals
	stone.visible = game.show.stone

func _on_Shop_pressed():
	click_sound.play()
	game.toggle_shop_panel()

func _on_Shop_mouse_entered():
	game.show_tooltip(tr("SHOP") + " (R)")

func _on_Shop_mouse_exited():
	game.hide_tooltip()

func _on_Inventory_pressed():
	click_sound.play()
	game.toggle_inventory()

func _on_Inventory_mouse_entered():
	game.show_tooltip(tr("INVENTORY") + " (E)")

func _on_Inventory_mouse_exited():
	game.hide_tooltip()

func _on_Money_mouse_entered():
	game.show_tooltip(tr("MONEY"))

func _on_Money_mouse_exited():
	game.hide_tooltip()

func _on_Minerals_mouse_entered():
	game.show_tooltip(tr("MINERALS"))

func _on_Minerals_mouse_exited():
	game.hide_tooltip()

func _on_Stone_mouse_entered():
	game.show_tooltip(tr("STONE"))

func _on_Stone_mouse_exited():
	game.hide_tooltip()

func _on_Energy_mouse_entered():
	game.show_tooltip(tr("ENERGY"))

func _on_Energy_mouse_exited():
	game.hide_tooltip()
