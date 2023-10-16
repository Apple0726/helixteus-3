extends Panel

@onready var op = $Control/OptionButton
@onready var game = get_node("/root/Game")

var coal_texture = preload("res://Graphics/Materials/coal.png")
var cellulose_texture = Data.cellulose_icon
var helium_texture = preload("res://Graphics/Atoms/He.png")
var neon_texture = preload("res://Graphics/Atoms/Ne.png")
var xenon_texture = preload("res://Graphics/Atoms/Xe.png")
var hydrogen_texture = preload("res://Graphics/Atoms/H.png")

var ships_time_remaining:float = 0
var ships_time_reduction:float = 0
var cost = float(0)
var meta = ""
var energy = 0
var unit:String = "kg"
var type:String = "mats"

func _ready():
	$Control.visible = false

func refresh_drive_modulate():
	for drive in $Panel/Drives.get_children():
		drive.modulate.a = 0.5
	
func refresh():
	for drive in $Panel/Drives.get_children():
		drive.visible = game.science_unlocked.has(drive.name)
	
	meta = op.get_selected_metadata()
	if meta != null:
		match meta:
			"cellulose":
				$Control/TextureRect.texture = cellulose_texture
				$Control/TextureRect3.texture = cellulose_texture
				energy = 2500
				unit = "kg"
				type = "mats"
			"coal":
				$Control/TextureRect.texture = coal_texture
				$Control/TextureRect3.texture = coal_texture
				energy = 400
				unit = "kg"
				type = "mats"
			"Ne":
				$Control/TextureRect.texture = neon_texture
				$Control/TextureRect3.texture = neon_texture
				energy = 60000
				unit = "mol"
				type = "atoms"
			"Xe":
				$Control/TextureRect.texture = xenon_texture
				$Control/TextureRect3.texture = xenon_texture
				energy = 10000000
				unit = "mol"
				type = "atoms"
		$Control/HSlider.max_value = game[type][meta]
		$Control/HSlider.value = 0
		_on_h_slider_value_changed($Control/HSlider.value)

func use_drive():
	if game.ships_travel_data.travel_view == "-":
		game.popup(tr("SHIPS_NEED_TO_BE_TRAVELLING"), 1.5)
	else:
		game.ships_travel_data.travel_length -= ships_time_reduction
		game.ships_travel_data.travel_cost += cost * energy
		game[type][meta] -= cost
		set_process(true)
		game.ships_travel_data.drive_available_time = Time.get_unix_time_from_system() + 60 * pow(2, game.ships_travel_data.drives_used)
		game.ships_travel_data.drives_used += 1
		game.popup(tr("DRIVE_SUCCESSFULLY_ACTIVATED"), 1.5)
	#refresh_h_slider()
	_on_h_slider_value_changed($Control/HSlider.value)
	$Control/HSlider.max_value = game[type][meta]
	#$Control/HSlider.set_value_no_signal(0)

func _on_ChemicalDrive_pressed():
	op.clear()
	op.add_item(tr("COAL"))
	op.add_item(tr("CELLULOSE"))
	op.set_item_metadata(0, "coal")
	op.set_item_metadata(1, "cellulose")
	op.selected = 0
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
	op.selected = 0
	$Control.visible = true
	refresh()
	refresh_drive_modulate()
	$Panel/Drives/ID.modulate.a = 1

func _on_OptionButton_item_selected(index):
	refresh()

func _on_h_slider_value_changed(value):
	refresh_h_slider()
	ships_time_remaining = game.ships_travel_data.travel_length - (Time.get_unix_time_from_system() - game.ships_travel_data.travel_start_date)
	if ships_time_remaining < 0:
		ships_time_remaining = 0
	$Control/UseDrive.disabled = game.ships_travel_data.drive_available_time > Time.get_unix_time_from_system() or is_zero_approx(value)
	if not is_processing():
		$Control/Cooldown.text = Helper.time_to_str(60 * pow(2, game.ships_travel_data.drives_used))
	cost = $Control/HSlider.value
	ships_time_reduction = ships_time_remaining - ships_time_remaining * (game.ships_travel_data.travel_cost / (game.ships_travel_data.travel_cost + cost * energy))
	$Control/Label.text = "%s %s" % [Helper.format_num(cost, true), unit]
	$Control/RsrcOwned.text = "%s %s" % [Helper.format_num(game[type][meta], true), unit]
	$Control/Label2.text = Helper.time_to_str(ships_time_reduction)

func _process(delta):
	$Control/Cooldown.text = Helper.time_to_str(game.ships_travel_data.drive_available_time - Time.get_unix_time_from_system())
	if Time.get_unix_time_from_system() > game.ships_travel_data.drive_available_time:
		set_process(false)
		$Control/UseDrive.disabled = false
		$Control/Cooldown.text = Helper.time_to_str(60 * pow(2, game.ships_travel_data.drives_used))

func refresh_h_slider():
	if meta:
		if is_zero_approx(game[type][meta]):
			$Control/HSlider.visible = false
			$Control/HSlider.set_value_no_signal(0)
		else:
			$Control/HSlider.visible = true
