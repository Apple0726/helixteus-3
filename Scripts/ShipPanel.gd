extends "Panel.gd"

var spaceport_tier:int

var target_ship_positions:Array
var ship_nodes = []
var selected_ship_id:int = -1

func _ready():
	$ShipStats/ShipDetails.hide()
	$ShipStats/Label.show()
	for i in len(game.ship_data):
		add_ship_node(i)
	set_polygon($GUI.size, $GUI.position)
	refresh()
	$Drives.panel_closed.connect(hide_drive_panel)

func add_ship_node(id: int):
	var ship = preload("res://Scenes/ShipsPanelShip.tscn").instantiate()
	ship.get_node("TextureButton").button_down.connect(_on_ship_button_down.bind(id))
	ship.get_node("TextureButton").button_up.connect(_on_ship_button_up.bind(id))
	ship.get_node("TextureButton").texture_normal = load("res://Graphics/Ships/Ship%s.png" % id)
	ship.get_node("TextureButton").texture_click_mask = load("res://Graphics/Ships/Ship%sCM.png" % id)
	ship.position = game.ship_data[id].initial_position / 1.8
	target_ship_positions.append(ship.position)
	$Ships/Battlefield.add_child(ship)
	ship_nodes.append(ship)

func refresh():
	set_process(true)
	if selected_ship_id != -1:
		_on_ship_button_up(selected_ship_id)
	#$Drives.refresh()
	#if game.ships_travel_data.travel_view != "-":
		#$SpaceportTimer.stop()
		#spaceport_tier = -1
		#$Panel/TravelETA["theme_override_colors/font_color"] = Color.WHITE
		#$Battlefield/HBoxContainer/DriveButton.modulate.a = 1.0
		#$Battlefield/HBoxContainer/DriveButton.disabled = false
	#else:
		#$Battlefield/HBoxContainer/DriveButton.disabled = true
		#$Battlefield/HBoxContainer/DriveButton.modulate.a = 0.3
		#if game.autocollect.has("ship_XP"):
			#$Panel/TravelETA["theme_override_colors/font_color"] = Color.GREEN_YELLOW
			#$Panel/TravelETA.text = tr("SHIPS_BENEFITING_FROM_SPACEPORT")
			#spaceport_tier = game.autocollect.ship_XP
			#if $SpaceportTimer.is_stopped():
				#$SpaceportTimer.start(4.0 / spaceport_tier)
		#else:
			#$SpaceportTimer.stop()
			#spaceport_tier = -1
			#$Panel/TravelETA["theme_override_colors/font_color"] = Color.WHITE
			#$Panel/TravelETA.text = ""

func _process(delta):
	if selected_ship_id != -1:
		$Ships/Battlefield/Selected.position = ship_nodes[selected_ship_id].position - Vector2(0, 40)
	if game.ships_travel_data.travel_view != "-":
		$Ships/TravelTimeRemaining.text = "%s: %s" % [tr("TRAVEL_TIME_REMAINING"), Helper.time_to_str(game.ships_travel_data.travel_length - Time.get_unix_time_from_system() + game.ships_travel_data.travel_start_date)]
	if not visible:
		set_process(false)

func _on_CheckBox_toggled(button_pressed):
	for panel in $Grid.get_children():
		panel.show_weapon_XPs = button_pressed
		panel.set_visibility()

func _on_DriveButton_pressed():
	if game.science_unlocked.has("CD"):
		if game.ships_travel_data.travel_view == "-":
			game.popup(tr("SHIPS_NEED_TO_BE_TRAVELLING"), 1.5)
		else:
			var fade_out_tween = create_tween().set_parallel()
			fade_out_tween.tween_property($Ships, "modulate:a", 0.5, 0.2)
			fade_out_tween.tween_property($ShipStats, "modulate:a", 0.5, 0.2)
			$Drives.visible = true
			$ShipStats.visible = true
			$Ships/DriveButton.visible = false
	else:
		game.popup(tr("DRIVE_TECHNOLOGY_REQUIRED"), 1.5)

func hide_drive_panel():
	var fade_out_tween = create_tween().set_parallel()
	fade_out_tween.tween_property($Ships, "modulate:a", 1.0, 0.2)
	fade_out_tween.tween_property($ShipStats, "modulate:a", 1.0, 0.2)
	$Ships.visible = true
	$Drives.visible = false
	$ShipStats.visible = true
	$Drives.visible = false
	$Ships/DriveButton.visible = true
	refresh()

func _on_GoToShips_mouse_entered():
	var st = tr("GO_TO_SHIPS")
	if game.u_i.lv < 9:
		st += "\n%s" % [tr("REACH_X_TO_UNLOCK") % [tr("LV") + " 8"]]
	game.show_tooltip(st)

func _on_mouse_exited():
	game.hide_tooltip()

func _on_GoToShips_pressed():
	if game.u_i.lv >= 8:
		game.switch_view("system", {"fn":"set_to_ship_coords"})
		_on_close_button_pressed()

func _on_DriveButton_mouse_entered():
	if not $Ships/DriveButton.disabled:
		game.show_tooltip(tr("ACCELERATE_SHIP_TRAVEL"))

func _on_BackButton_mouse_entered():
	game.show_tooltip(tr("BACK"))

var bar_colors = {
	"bullet":Color(0, 0.46, 0.81),
	"laser":Color(1, 0.28, 0.28),
	"bomb":Color(0.28, 0.28, 0.28),
	"light":Color(0.81, 0.81, 0.36),
}

func _on_SpaceportTimer_timeout():
	var xp_mult = Helper.get_spaceport_xp_mult(spaceport_tier)
	for i in len(game.ship_data):
		Helper.add_ship_XP(i, xp_mult * pow(1.15, game.u_i.lv) * game.u_i.time_speed)
		if visible:
			get_node("ShipDetails/XP/TextureProgress2" % (i+1)).value = 0
			get_node("ShipDetails/Lv" % (i+1)).text = "%s %s" % [tr("LV"), game.ship_data[i].lv]
			get_node("ShipDetails/XP/TextureProgressBar" % (i+1)).max_value = game.ship_data[i].XP_to_lv
			get_node("ShipDetails/XP/TextureProgressBar" % (i+1)).modulate = Color.WHITE
			var tween = create_tween()
			tween.tween_property(get_node("ShipDetails/XP/TextureProgressBar" % (i+1)), "modulate", Color(0.92, 0.63, 0.2), 1.0)
			get_node("ShipDetails/Stats/HP" % (i+1)).text = Helper.format_num(game.ship_data[i].HP * game.ship_data[i].HP_mult)
			get_node("ShipDetails/Stats/Atk" % (i+1)).text = Helper.format_num(game.ship_data[i].atk * game.ship_data[i].atk_mult)
			get_node("ShipDetails/Stats/Def" % (i+1)).text = Helper.format_num(game.ship_data[i].def * game.ship_data[i].def_mult)
			get_node("ShipDetails/Stats/Acc" % (i+1)).text = Helper.format_num(game.ship_data[i].acc * game.ship_data[i].acc_mult)
			get_node("ShipDetails/Stats/Eva" % (i+1)).text = Helper.format_num(game.ship_data[i].eva * game.ship_data[i].eva_mult)

var dragging_ship_id:int = -1
var ship_mouse_offset:Vector2
var mouse_position:Vector2

func _input(event: InputEvent) -> void:
	super(event)
	if event is InputEventMouseMotion:
		mouse_position = event.position
		if dragging_ship_id != -1:
			var target_position = mouse_position - $Ships/Battlefield.global_position
			target_ship_positions[dragging_ship_id] = target_position - ship_mouse_offset
			game.ship_data[dragging_ship_id].initial_position = target_ship_positions[dragging_ship_id] * 1.8

func _physics_process(delta: float) -> void:
	for i in len(target_ship_positions):
		var F:Vector2 = 1000 * (target_ship_positions[i] - ship_nodes[i].position)
		F = F.clamp(-50000 * Vector2.ONE, 50000 * Vector2.ONE)
		ship_nodes[i].apply_force(F)

func _on_ship_button_down(ship_id: int) -> void:
	game.view.move_view = false
	dragging_ship_id = ship_id
	ship_mouse_offset = mouse_position - ship_nodes[ship_id].global_position


func _on_ship_button_up(ship_id: int) -> void:
	game.view.move_view = true
	dragging_ship_id = -1
	selected_ship_id = ship_id
	$Ships/Battlefield/Selected.show()
	$Ships/Battlefield/Selected.position = ship_nodes[ship_id].position - Vector2(0, 40)
	$ShipStats/ShipDetails.show()
	$ShipStats/Label.hide()
	var ship_info = game.ship_data[ship_id]
	$ShipStats/ShipDetails/Label.text = "%s %s %s" % [tr("LEVEL"), ship_info.lv, tr("%s_SHIP" % ShipClass.names[ship_info.ship_class].to_upper())]
	if ship_info.respec_count == 0:
		$ShipStats/ShipDetails/Respec.text = "%s (%s)" % [tr("RESPEC"), tr("FREE")]
	else:
		$ShipStats/ShipDetails/Respec.text = "%s (%s)" % [tr("RESPEC"), "-0.5 %s" % tr("LEVEL")]
	$ShipStats/ShipDetails/Stats/HP.text = str(ship_info.HP)
	$ShipStats/ShipDetails/Stats/Attack.text = str(ship_info.attack)
	$ShipStats/ShipDetails/Stats/Defense.text = str(ship_info.defense)
	$ShipStats/ShipDetails/Stats/Accuracy.text = str(ship_info.accuracy)
	$ShipStats/ShipDetails/Stats/Agility.text = str(ship_info.agility)
	for weapon in ["Bullet", "Laser", "Bomb", "Light"]:
		var weapon_data = ship_info[weapon.to_lower()]
		get_node("ShipStats/ShipDetails/%s/Icon" % [weapon]).texture = load("res://Graphics/Weapons/%s%s.png" % [weapon.to_lower(), 1])
		get_node("ShipStats/ShipDetails/%s/Label" % [weapon]).text = "%d / %d / %d" % [weapon_data[0], weapon_data[1], weapon_data[2]]
	$ShipStats/ShipDetails/XP/Label2.text = "%s / %s" % [Helper.format_num(round(ship_info.XP)), Helper.format_num(ship_info.XP_to_lv)]
	$ShipStats/ShipDetails/XP/TextureProgressBar.max_value = ship_info.XP_to_lv
	$ShipStats/ShipDetails/XP/TextureProgressGained.max_value = ship_info.XP_to_lv
	$ShipStats/ShipDetails/XP/TextureProgressBar.value = ship_info.XP
	$ShipStats/ShipDetails/XP/TextureProgressGained.value = ship_info.XP


func _on_weaponIcon_mouse_entered(weapon: String) -> void:
	if selected_ship_id != -1:
		game.show_tooltip(tr(weapon.to_upper() + "_DESC"))


func _on_weaponIcon_mouse_exited() -> void:
	game.hide_tooltip()


func _on_respec_pressed() -> void:
	_on_close_button_pressed()
	if selected_ship_id != -1:
		game.switch_view("ship_customize_screen", {"ship_id":selected_ship_id, "respeccing":true})
