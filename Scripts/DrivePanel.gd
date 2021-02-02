extends Panel

onready var op = $OptionButton
onready var game = get_node("/root/Game")

var coal_texture = preload("res://Graphics/Icons/coal.png")
var cellulose_texture = preload("res://Graphics/Icons/cellulose.png")
var xenon_texture = preload("res://Graphics/Icons/xenon.png")
var he3mix_texture = preload("res://Graphics/Icons/he3mix.png")
var graviton_texture = preload("res://Graphics/Icons/graviton.png")

var cost = float(0)
var meta = ""
var speed = 0

func refresh(value):
	for drive in $Drives.get_children():
		drive.visible = game.science_unlocked[drive.name]

	meta = op.get_selected_metadata()
	$HSlider.value = value
	
	match meta:
		"cellulose":
			$TextureRect.texture = cellulose_texture
			speed = 1000
		"coal":
			$TextureRect.texture = coal_texture
			speed = 8000
		"xenon":
			$TextureRect.texture = xenon_texture
			speed = 40000
		"he3mix":
			$TextureRect.texture = he3mix_texture
			speed = 200000
		"graviton":
			$TextureRect.texture = graviton_texture
			speed = 4000000
	
	if meta:
		cost = game.mats[meta] * (value / 100)
		if game.mats[meta] > 100 and cost < 100:
			cost = 100
		$Label.text = "%s kg" % cost
	
	var slider_factor = (-100 * pow(0.95, $HSlider.value)) + 101
	var time_reduction = (cost * speed) / slider_factor
	if game.ships_travel_length - time_reduction < 0:
		$Label2.text = Helper.time_to_str(0)
	else:
		$Label2.text = Helper.time_to_str(time_reduction)

func use_drive():
	if game.ships_travel_view == "-":
		game.popup(tr("SHIPS_NEED_TO_BE_TRAVELLING"), 1.5)
	else:
		var slider_factor = (-100 * pow(0.95, $HSlider.value)) + 101
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
	refresh(50)

func _on_IonDrive_pressed():
	op.clear()
	op.add_icon_item(xenon_texture, "Xenon")
	op.set_item_metadata(0, "xenon")
	refresh(50)

func _on_FusionDrive_pressed():
	op.clear()
	op.add_icon_item(he3mix_texture, "Helium-3 Mix")
	op.set_item_metadata(0, "he3mix")
	refresh(50)

func _on_ParticleDrive_pressed():
	op.clear()
	op.add_icon_item(graviton_texture, "Graviton")
	op.set_item_metadata(0, "graviton")
	refresh(50)

func _on_OptionButton_item_selected(index):
	refresh(50)

func _on_HSlider_value_changed(value):
	refresh(value)
