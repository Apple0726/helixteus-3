extends Panel

@onready var op = $Control/OptionButton
@onready var game = get_node("/root/Game")

var coal_texture = preload("res://Graphics/Materials/coal.png")
var cellulose_texture = Data.cellulose_icon
var helium_texture = preload("res://Graphics/Atoms/He.png")
var neon_texture = preload("res://Graphics/Atoms/Ne.png")
var xenon_texture = preload("res://Graphics/Atoms/Xe.png")
var hydrogen_texture = preload("res://Graphics/Atoms/H.png")
var electron_texture = preload("res://Graphics/Particles/electron.png")
var proton_texture = preload("res://Graphics/Particles/proton.png")
var neutron_texture = preload("res://Graphics/Particles/neutron.png")

var cost = float(0)
var meta = ""
var speed = 0
var unit:String = "kg"
var type:String = "mats"

func refresh_drive_modulate():
	for drive in $Panel/Drives.get_children():
		drive.modulate.a = 0.5
	
func refresh():
	for drive in $Panel/Drives.get_children():
		drive.visible = game.science_unlocked.has(drive.name)

	meta = op.get_selected_metadata()
	
	match meta:
		"cellulose":
			$Control/TextureRect.texture = cellulose_texture
			speed = 4000
			unit = "kg"
			type = "mats"
		"coal":
			$Control/TextureRect.texture = coal_texture
			speed = 600
			unit = "kg"
			type = "mats"
		"Ne":
			$Control/TextureRect.texture = neon_texture
			speed = 48000
			unit = "mol"
			type = "atoms"
		"Xe":
			$Control/TextureRect.texture = xenon_texture
			speed = 8500000
			unit = "mol"
			type = "atoms"
	refresh_costs()
	$Control/HSlider.value = $Control/HSlider.max_value

func refresh_costs():
	if meta:
		if game[type][meta] == 0:
			$Control/HSlider.visible = false
			$Control/HSlider.value = 0
		else:
			$Control/HSlider.visible = true
			$Control/HSlider.max_value = min(game[type][meta], (game.ships_travel_length - Time.get_unix_time_from_system() + game.ships_travel_start_date) / float(speed))
		cost = $Control/HSlider.value
		$Control/Label.text = "%s %s" % [Helper.clever_round(cost), unit]
	$Control/Label2.text = Helper.time_to_str(cost * speed)
	
func use_drive():
	if game.ships_travel_view == "-":
		game.popup(tr("SHIPS_NEED_TO_BE_TRAVELLING"), 1.5)
	else:
		game.ships_travel_start_date -= cost * speed
		game[type][meta] -= cost
		game.popup(tr("DRIVE_SUCCESSFULLY_ACTIVATED"), 1.5)
	refresh_costs()

func _on_ChemicalDrive_pressed():
	op.clear()
	op.add_item(tr("COAL"))
	op.add_item(tr("CELLULOSE"))
	op.set_item_metadata(0, "coal")
	op.set_item_metadata(1, "cellulose")
	$Control.visible = true
	refresh()
	refresh_drive_modulate()
	$Panel/Drives/CD.modulate.a = 1

func _on_IonDrive_pressed():
	op.clear()
	op.add_item(tr("NE_NAME"))
	op.add_item(tr("XE_NAME"))
	op.set_item_metadata(0, "Ne")
	op.set_item_metadata(1, "Xe")
	$Control.visible = true
	refresh()
	refresh_drive_modulate()
	$Panel/Drives/ID.modulate.a = 1

func _on_OptionButton_item_selected(index):
	refresh()

func _on_HSlider_value_changed(value):
	refresh_costs()
