extends Panel

signal panel_closed

@onready var game = get_node("/root/Game")

var coal_texture = Data.coal_icon
var cellulose_texture = Data.cellulose_icon
var helium_texture = preload("res://Graphics/Atoms/He.png")
var neon_texture = preload("res://Graphics/Atoms/Ne.png")
var xenon_texture = preload("res://Graphics/Atoms/Xe.png")
var hydrogen_texture = preload("res://Graphics/Atoms/H.png")

var ships_time_remaining:float = 0
var ships_time_reduction:float = 0
var fuel_selected = ""
var selected_fuel_type = "mats"
var cost = 0.0
var energy_per_quantity_of_fuel = 0.0
var unit:String = "kg"

func _ready():
	$Control.visible = false
	refresh()

func reset_selected_drive_fuel():
	for drive in $Panel/Drives.get_children():
		drive.modulate.a = 0.5
	for fuel in $Control/Fuels.get_children():
		fuel.queue_free()
	
func refresh():
	for drive in $Panel/Drives.get_children():
		drive.visible = game.science_unlocked.has(drive.name)
	if fuel_selected != "":
		if selected_fuel_type == "mats":
			unit = "kg"
		elif selected_fuel_type == "atoms":
			unit = "mol"
		$Control/HSlider.max_value = game[selected_fuel_type][fuel_selected]

func use_drive():
	if game.ships_travel_data.travel_view == "-":
		game.popup(tr("SHIPS_NEED_TO_BE_TRAVELLING"), 1.5)
	else:
		game.ships_travel_data.travel_length -= ships_time_reduction
		game.ships_travel_data.travel_cost += cost * energy_per_quantity_of_fuel
		game[selected_fuel_type][fuel_selected] -= cost
		set_process(true)
		game.ships_travel_data.drive_available_time = Time.get_unix_time_from_system() + 60 * pow(2, game.ships_travel_data.drives_used)
		game.ships_travel_data.drives_used += 1
		game.popup(tr("DRIVE_SUCCESSFULLY_ACTIVATED"), 1.5)
	#refresh_h_slider()
	_on_h_slider_value_changed($Control/HSlider.value)
	$Control/HSlider.max_value = game[selected_fuel_type][fuel_selected]
	#$Control/HSlider.set_value_no_signal(0)

func add_fuel(type: String, fuel: String, texture, also_select_this_fuel = false):
	var fuel_btn_node = preload("res://Scenes/ShopItem.tscn").instantiate()
	fuel_btn_node.custom_minimum_size = Vector2.ONE * 48.0
	fuel_btn_node.get_node("TextureRect").texture = texture
	fuel_btn_node.get_node("TextureButton").mouse_entered.connect(game.show_tooltip.bind(tr(fuel.to_upper())))
	fuel_btn_node.get_node("TextureButton").mouse_exited.connect(game.hide_tooltip)
	fuel_btn_node.get_node("TextureButton").pressed.connect(select_fuel.bind(type, fuel, texture, fuel_btn_node))
	$Control/Fuels.add_child(fuel_btn_node)
	if also_select_this_fuel:
		select_fuel(type, fuel, texture, fuel_btn_node)

func select_fuel(type: String, fuel: String, texture, fuel_btn_node):
	$Control/TextureRect.texture = texture
	for fuel_btn in $Control/Fuels.get_children():
		fuel_btn.get_node("Highlight").hide()
	fuel_btn_node.get_node("Highlight").show()
	selected_fuel_type = type
	fuel_selected = fuel
	if fuel == "coal":
		energy_per_quantity_of_fuel = 400
	elif fuel == "cellulose":
		energy_per_quantity_of_fuel = 2500
	elif fuel == "Ne":
		energy_per_quantity_of_fuel = 60000
	elif fuel == "Xe":
		energy_per_quantity_of_fuel = 10000000
	$Control/HSlider.max_value = game[selected_fuel_type][fuel_selected]
	$Control/HSlider.value = 0
	_on_h_slider_value_changed($Control/HSlider.value)


func _on_ChemicalDrive_pressed():
	reset_selected_drive_fuel()
	add_fuel("mats", "coal", preload("res://Graphics/Materials/coal.png"), true)
	add_fuel("mats", "cellulose", preload("res://Graphics/Materials/cellulose.png"))
	$Control.visible = true
	refresh()
	$Panel/Drives/CD.modulate.a = 1

func _on_IonDrive_pressed():
	reset_selected_drive_fuel()
	add_fuel("atoms", "Ne", preload("res://Graphics/Atoms/Ne.png"), true)
	add_fuel("atoms", "Xe", preload("res://Graphics/Atoms/Xe.png"))
	$Control.visible = true
	refresh()
	reset_selected_drive_fuel()
	$Panel/Drives/ID.modulate.a = 1


func _on_h_slider_value_changed(value):
	refresh_h_slider()
	ships_time_remaining = game.ships_travel_data.travel_length - (Time.get_unix_time_from_system() - game.ships_travel_data.travel_start_date)
	if ships_time_remaining < 0:
		ships_time_remaining = 0
	$Control/UseDrive.disabled = game.ships_travel_data.drive_available_time > Time.get_unix_time_from_system() or is_zero_approx(value)
	if not is_processing():
		$Control/Cooldown.text = Helper.time_to_str(60 * pow(2, game.ships_travel_data.drives_used))
	cost = $Control/HSlider.value
	ships_time_reduction = ships_time_remaining - ships_time_remaining * (game.ships_travel_data.travel_cost / (game.ships_travel_data.travel_cost + cost * energy_per_quantity_of_fuel))
	$Control/FuelAmount.text = "%s / %s %s" % [Helper.format_num(cost, true), Helper.format_num(game[selected_fuel_type][fuel_selected], true), unit]
	$Control/Label2.text = Helper.time_to_str(ships_time_reduction)

func _process(delta):
	$Control/Cooldown.text = Helper.time_to_str(game.ships_travel_data.drive_available_time - Time.get_unix_time_from_system())
	if Time.get_unix_time_from_system() > game.ships_travel_data.drive_available_time:
		set_process(false)
		$Control/UseDrive.disabled = false
		$Control/Cooldown.text = Helper.time_to_str(60 * pow(2, game.ships_travel_data.drives_used))

func refresh_h_slider():
	if fuel_selected != "":
		if is_zero_approx(game[selected_fuel_type][fuel_selected]):
			$Control/HSlider.visible = false
			$Control/HSlider.set_value_no_signal(0)
		else:
			$Control/HSlider.visible = true


func _on_back_button_pressed() -> void:
	emit_signal("panel_closed")


func _on_visibility_changed() -> void:
	if visible:
		refresh()
