extends Panel

onready var op = $Control/OptionButton
onready var game = get_node("/root/Game")

var coal_texture = preload("res://Graphics/Icons/coal.png")
var cellulose_texture = preload("res://Graphics/Icons/cellulose.png")
var xenon_texture = preload("res://Graphics/Atoms/xenon.png")
var he3mix_texture = preload("res://Graphics/Icons/he3mix.png")
var graviton_texture = preload("res://Graphics/Icons/graviton.png")

var cost = float(0)
var meta = ""
var speed = 0

func refresh_drive_modulate():
	for drive in $Panel/Drives.get_children():
		drive.modulate.a = 0.5
	
func refresh():
	for drive in $Panel/Drives.get_children():
		drive.visible = game.science_unlocked[drive.name]

	meta = op.get_selected_metadata()
	
	match meta:
		"cellulose":
			$Control/TextureRect.texture = cellulose_texture
			speed = 1000
		"coal":
			$Control/TextureRect.texture = coal_texture
			speed = 1000
		"xenon":
			$Control/TextureRect.texture = xenon_texture
			speed = 40000
		"he3mix":
			$Control/TextureRect.texture = he3mix_texture
			speed = 8000000
		"graviton":
			$Control/TextureRect.texture = graviton_texture
			speed = 100000000
	cost = $Control/HSlider.value
	if meta:
		$Control/HSlider.max_value = game.mats[meta]
		$Control/Label.text = "%s kg" % game.clever_round(cost, 3)
	
	$Control/Label2.text = Helper.time_to_str(cost * speed)

func use_drive():
	if game.ships_travel_view == "-":
		game.popup(tr("SHIPS_NEED_TO_BE_TRAVELLING"), 1.5)
	else:
		var slider_factor = (-100 * pow(0.95, $Control/HSlider.value)) + 101
		var time_reduction = (cost * speed) / slider_factor
		game.ships_travel_length -= time_reduction
		game.mats[meta] -= cost
		game.popup(tr("DRIVE_SUCCESSFULLY_ACTIVATED"), 1.5)

func _on_ChemicalDrive_pressed():
	op.clear()
	op.add_icon_item(cellulose_texture, "Cellulose")
	op.add_icon_item(coal_texture, "Coal")
	op.set_item_metadata(0, "cellulose")
	op.set_item_metadata(1, "coal")
	$Control.visible = true
	refresh()
	refresh_drive_modulate()
	$Panel/Drives/CD.modulate.a = 1

func _on_IonDrive_pressed():
	op.clear()
	op.add_icon_item(xenon_texture, "Xenon")
	op.set_item_metadata(0, "xenon")
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
