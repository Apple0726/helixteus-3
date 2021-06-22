extends "Panel.gd"

onready var vbox = $ScrollContainer/VBoxContainer
func _ready():
	set_polygon($Background.rect_size)

func _on_KeyboardShortcuts_pressed():
	var battle_text:String
	if OS.get_latin_keyboard_variant() == "AZERTY":
		battle_text = tr("BATTLE_HELP2") % ["Z", "M", "S", "ù", "Shift"]
	else:
		battle_text = tr("BATTLE_HELP2") % ["W", ";", "S", "'", "Shift"]
	$Text.text = tr("%s\n\n%s\n%s") % [tr("KEYBOARD_DESC1"), tr("KEYBOARD_DESC2"), battle_text]
	for child in vbox.get_children():
		if child != $ScrollContainer/VBoxContainer/KeyboardShortcuts:
			child.pressed = false

func _on_DarkMatter_pressed():
	$Text.text = tr("DARK_MATTER_DESC")
	for child in vbox.get_children():
		if child != $ScrollContainer/VBoxContainer/DarkMatter:
			child.pressed = false

func _on_B_strength_pressed():
	$Text.text = tr("B_STRENGTH_DESC")
	for child in vbox.get_children():
		if child != $ScrollContainer/VBoxContainer/B_strength:
			child.pressed = false

func _on_DarkEnergy_pressed():
	$Text.text = tr("DARK_ENERGY_DESC")
	for child in vbox.get_children():
		if child != $ScrollContainer/VBoxContainer/DarkEnergy:
			child.pressed = false


func _on_Aurora_pressed():
	$Text.text = tr("AURORA_LIST")
	for child in vbox.get_children():
		if child != $ScrollContainer/VBoxContainer/DarkEnergy:
			child.pressed = false

func _on_FM_pressed():
	$Text.text = tr("FM_DESC")
	for child in vbox.get_children():
		if child != $ScrollContainer/VBoxContainer/FM:
			child.pressed = false


func _on_LevelUnlocks_pressed():
	$Text.text = tr("LEVEL_UNLOCKS_DESC")
	for child in vbox.get_children():
		if child != $ScrollContainer/VBoxContainer/LevelUnlocks:
			child.pressed = false
