extends Panel

onready var op = $Control/OptionButton
onready var game = get_node("/root/Game")

var coal_texture = preload("res://Graphics/Materials/coal.png")
var cellulose_texture = preload("res://Graphics/Materials/cellulose.png")
var neon_texture = preload("res://Graphics/Atoms/Ne.png")
var xenon_texture = preload("res://Graphics/Atoms/Xe.png")
var he3mix_texture = preload("res://Graphics/Icons/he3mix.png")
var graviton_texture = preload("res://Graphics/Icons/graviton.png")

var cost = float(0)
var meta = ""
var speed = 0
var type:String = "mats"

func refresh_drive_modulate():
	for drive in $Panel/Drives.get_children():
		drive.modulate.a = 0.5
	
func refresh():
	for drive in $Panel/Drives.get_children():
		drive.visible = game.science_unlocked[drive.name]

	meta = op.get_selected_metadata()
	var unit:String = "kg"
	
	match meta:
		"cellulose":
			$Control/TextureRect.texture = cellulose_texture
			speed = 1000
		"coal":
			$Control/TextureRect.texture = coal_texture
			speed = 1000
		"neon":
			$Control/TextureRect.texture = neon_texture
			speed = 400000
			unit = "mol"
			type = "atoms"
		"xenon":
			$Control/TextureRect.texture = xenon_texture
			speed = 9000000
			unit = "mol"
			type = "atoms"
		"he3mix":
			$Control/TextureRect.texture = he3mix_texture
			speed = 8000000
			unit = "mol"
		"graviton":
			$Control/TextureRect.texture = graviton_texture
			speed = 100000000
			unit = "mol"
	cost = $Control/HSlider.value
	if meta:
		if game[type][meta] == 0:
			$Control/HSlider.visible = false
		else:
			$Control/HSlider.visible = true
			$Control/HSlider.max_value = game[type][meta]
		$Control/Label.text = "%s %s" % [game.clever_round(cost, 3), unit]
	
	$Control/Label2.text = Helper.time_to_str(cost * speed)

func use_drive():
	if game.ships_travel_view == "-":
		game.popup(tr("SHIPS_NEED_TO_BE_TRAVELLING"), 1.5)
	else:
		game.ships_travel_length -= cost * speed
		game[type][meta] -= cost
		game.popup(tr("DRIVE_SUCCESSFULLY_ACTIVATED"), 1.5)

func _on_ChemicalDrive_pressed():
	op.clear()
	op.add_item(tr("CELLULOSE"))
	op.add_item(tr("COAL"))
	op.set_item_metadata(0, "cellulose")
	op.set_item_metadata(1, "coal")
	$Control.visible = true
	refresh()
	refresh_drive_modulate()
	$Panel/Drives/CD.modulate.a = 1

func _on_IonDrive_pressed():
	op.clear()
	op.add_item(tr("NEON"))
	op.add_item(tr("XENON"))
	op.set_item_metadata(0, "neon")
	op.set_item_metadata(1, "xenon")
	$Control.visible = true
	refresh()
	refresh_drive_modulate()
	$Panel/Drives/ID.modulate.a = 1

func _on_FusionDrive_pressed():
	op.clear()
	op.add_icon_item(he3mix_texture, "Helium-3 Mix")
	op.set_item_metadata(0, "he3mix")
	$Control.visible = true
	refresh()
	refresh_drive_modulate()
	$Panel/Drives/FD.modulate.a = 1

func _on_ParticleDrive_pressed():
	op.clear()
	op.add_icon_item(graviton_texture, "Graviton")
	op.set_item_metadata(0, "graviton")
	$Control.visible = true
	refresh()
	refresh_drive_modulate()
	$Panel/Drives/PD.modulate.a = 1

func _on_OptionButton_item_selected(index):
	refresh()

func _on_HSlider_value_changed(value):
	refresh()
