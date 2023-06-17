extends "Panel.gd"

@onready var vbox = $ScrollContainer/VBoxContainer
func _ready():
	set_polygon(size)

func _on_KeyboardShortcuts_pressed():
	var battle_text:String = tr("BATTLE_HELP2") % [OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(KEY_W)), OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(KEY_S)), "Shift"]
	$Panel/Text.text = tr("%s\n\n%s\n%s") % [tr("KEYBOARD_DESC1"), tr("KEYBOARD_DESC2"), battle_text]
	for child in vbox.get_children():
		if child != $ScrollContainer/VBoxContainer/KeyboardShortcuts:
			child.button_pressed = false

func _on_DarkMatter_pressed():
	$Panel/Text.text = tr("DARK_MATTER_DESC")
	for child in vbox.get_children():
		if child != $ScrollContainer/VBoxContainer/DarkMatter:
			child.button_pressed = false

func _on_B_strength_pressed():
	$Panel/Text.text = tr("B_STRENGTH_DESC")
	for child in vbox.get_children():
		if child != $ScrollContainer/VBoxContainer/B_strength:
			child.button_pressed = false

func _on_DarkEnergy_pressed():
	$Panel/Text.text = tr("DARK_ENERGY_DESC")
	for child in vbox.get_children():
		if child != $ScrollContainer/VBoxContainer/DarkEnergy:
			child.button_pressed = false


func _on_Aurora_pressed():
	$Panel/Text.text = tr("AURORA_LIST")
	for child in vbox.get_children():
		if child != $ScrollContainer/VBoxContainer/Aurora:
			child.button_pressed = false

func _on_FM_pressed():
	$Panel/Text.text = tr("FM_DESC")
	for child in vbox.get_children():
		if child != $ScrollContainer/VBoxContainer/FM:
			child.button_pressed = false


func _on_LevelUnlocks_pressed():
	$Panel/Text.text = tr("LEVEL_UNLOCKS_DESC")
	for child in vbox.get_children():
		if child != $ScrollContainer/VBoxContainer/LevelUnlocks:
			child.button_pressed = false
