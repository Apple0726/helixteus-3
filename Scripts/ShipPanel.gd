extends "Panel.gd"

var ship_nodes = []
var selected_ship_id:int = -1

func _ready():
	$ShipStats/ShipDetails.hide()
	for i in len(game.ship_data):
		add_ship_node(i)
	set_polygon($GUI.size, $GUI.position)
	for weapon in ["Bullet", "Laser", "Bomb", "Light"]:
		for path in 3:
			for lv in 3:
				$ShipStats/ShipDetails.get_node("%s/WeaponLevels/Path%s/Level%s" % [weapon, path+1, lv+1]).mouse_entered.connect(show_weapon_tooltip.bind(weapon.to_lower(), path, lv))
				$ShipStats/ShipDetails.get_node("%s/WeaponLevels/Path%s/Level%s" % [weapon, path+1, lv+1]).mouse_exited.connect(game.hide_tooltip)
	$Drives.panel_closed.connect(hide_drive_panel)

func show_weapon_tooltip(weapon: String, path: int, lv: int):
	var tooltip = tr("%s_%s_%s_DESC" % [weapon.to_upper(), path+1, lv+1])
	if game.ship_data[selected_ship_id][weapon][path] <= lv+1:
		tooltip = "[color=#888888]" + tooltip
	game.show_tooltip(tooltip)

func add_ship_node(id: int):
	var ship = TextureButton.new()
	ship.material = ShaderMaterial.new()
	ship.material.shader = preload("res://Shaders/Highlight.gdshader")
	ship.material.resource_local_to_scene = true
	ship.mouse_entered.connect(_on_ship_mouse_entered.bind(id))
	ship.mouse_entered.connect(game.show_tooltip.bind("", {
		"additional_text": "{KBS_label}: {KBS}".format({"KBS_label":tr("KEYBOARD_SHORTCUT"), "KBS": str(id + 1)}),
		"additional_text_delay": 1.0}))
	ship.mouse_exited.connect(_on_ship_mouse_exited.bind(id))
	ship.mouse_exited.connect(game.hide_tooltip)
	ship.shortcut = Shortcut.new()
	ship.shortcut.events.append(InputEventKey.new())
	ship.shortcut.events[0].physical_keycode = KEY_1 + id
	ship.shortcut_in_tooltip = false
	ship.button_down.connect(_on_ship_button_down.bind(id))
	ship.pressed.connect(_on_ship_button_up.bind(id))
	ship.texture_normal = load("res://Graphics/Ships/Ship%s top down.png" % id)
	ship.texture_click_mask = load("res://Graphics/Ships/Ship%s top down CM.png" % id)
	ship.ignore_texture_size = true
	ship.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	ship.size = Vector2.ONE * 88.0
	ship.position = game.ship_data[id].initial_position / 2.2
	$Ships/Battlefield.add_child(ship)
	ship_nodes.append(ship)

func refresh():
	for ship in ship_nodes:
		ship.queue_free()
	ship_nodes.clear()
	for i in len(game.ship_data):
		add_ship_node(i)
	set_process(true)
	$ShipStats/ShipDetails/XP/XPGained.text = ""
	if selected_ship_id != -1:
		show_ship_stats(selected_ship_id)
		$Label.hide()
	else:
		$Label.show()
	if game.ships_travel_data.travel_view == "-":
		if game.autocollect.has("passive_xp_tier"):
			$Label.text = tr("SHIPS_BENEFITING_FROM_SPACEPORT")
		else:
			$Label.text = tr("CLICK_SHIP_TO_VIEW_DETAILS")

func _process(delta):
	if selected_ship_id != -1:
		$Ships/Battlefield/Selected.position = ship_nodes[selected_ship_id].position + Vector2(30.0, -40.0)
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
			for ship in ship_nodes:
				ship.material.set_shader_parameter("alpha", 1.0)
				fade_out_tween.tween_property(ship.material, "shader_parameter/alpha", 0.5, 0.2)
			$Drives.visible = true
			$ShipStats.visible = true
			$Ships/DriveButton.visible = false
	else:
		game.popup(tr("DRIVE_TECHNOLOGY_REQUIRED"), 1.5)

func hide_drive_panel():
	var fade_out_tween = create_tween().set_parallel()
	fade_out_tween.tween_property($Ships, "modulate:a", 1.0, 0.2)
	fade_out_tween.tween_property($ShipStats, "modulate:a", 1.0, 0.2)
	for ship in ship_nodes:
		ship.material.set_shader_parameter("alpha", 0.5)
		fade_out_tween.tween_property(ship.material, "shader_parameter/alpha", 1.0, 0.2)
	$Ships.visible = true
	$Drives.visible = false
	$ShipStats.visible = true
	$Drives.visible = false
	$Ships/DriveButton.visible = true

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

func update_xp_bars():
	if selected_ship_id != -1:
		show_ship_stats(selected_ship_id)
		$ShipStats/ShipDetails/XP/TextureProgressBar.modulate = Color.WHITE
		var tween = create_tween()
		tween.tween_property($ShipStats/ShipDetails/XP/TextureProgressBar, "modulate", Color(0.92, 0.63, 0.2), 1.0)

var dragging_ship_id:int = -1
var ship_mouse_offset:Vector2
var mouse_position:Vector2

func _input(event: InputEvent) -> void:
	super(event)
	if event is InputEventMouseMotion:
		mouse_position = event.position
		if dragging_ship_id != -1:
			var target_position = mouse_position - $Ships/Battlefield.global_position - ship_mouse_offset
			target_position.x = clamp(target_position.x, 0.0, 360.0)
			target_position.y = clamp(target_position.y, 0.0, 264.0)
			ship_nodes[dragging_ship_id].position = target_position
			game.ship_data[dragging_ship_id].initial_position = target_position * 2.2


func _on_ship_mouse_entered(ship_id: int):
	ship_nodes[ship_id].material.set_shader_parameter("highlight_strength", 0.15)
	if game.item_to_use.id != -1 and Item.data[game.item_to_use.id].type == Item.Type.HELIX_CORE:
		show_ship_stats(ship_id)
		$ShipStats.show()
		$ShipStats/ShipDetails/XP/TextureProgressGained.value = $ShipStats/ShipDetails/XP/TextureProgressBar.value + Item.data[game.item_to_use.id].XP * game.item_to_use.num
		$ShipStats/ShipDetails/XP/XPGained.text = "+ " + str(Item.data[game.item_to_use.id].XP * game.item_to_use.num)
		$ShipStats/ShipDetails/Respec.hide()

func _on_ship_mouse_exited(ship_id: int):
	ship_nodes[ship_id].material.set_shader_parameter("highlight_strength", 0.0)
	if game.item_to_use.id != -1 and Item.data[game.item_to_use.id].type == Item.Type.HELIX_CORE:
		$ShipStats/ShipDetails/XP/XPGained.text = ""
		$ShipStats/ShipDetails.hide()
	

func _on_ship_button_down(ship_id: int) -> void:
	game.view.move_view = false
	dragging_ship_id = ship_id
	ship_mouse_offset = mouse_position - ship_nodes[ship_id].global_position


func _on_ship_button_up(ship_id: int) -> void:
	game.view.move_view = true
	dragging_ship_id = -1
	selected_ship_id = ship_id
	$ShipStats.show()
	if game.item_to_use.id == -1 or Item.data[game.item_to_use.id].type != Item.Type.HELIX_CORE:
		$Ships/Battlefield/Selected.show()
		show_ship_stats(ship_id)
	else:
		Helper.add_ship_XP(ship_id, Item.data[game.item_to_use.id].XP * game.item_to_use.num)
		game.item_to_use.num = min(1, game.remove_items(game.item_to_use.id, game.item_to_use.num))
		game.update_item_cursor()
		show_ship_stats(ship_id)
		if game.item_to_use.id != -1 and Item.data[game.item_to_use.id].type == Item.Type.HELIX_CORE:
			$ShipStats/ShipDetails/XP/TextureProgressGained.value = $ShipStats/ShipDetails/XP/TextureProgressBar.value + Item.data[game.item_to_use.id].XP * game.item_to_use.num
		else:
			$ShipStats/ShipDetails/XP/XPGained.text = ""

func show_ship_stats(ship_id: int):
	$ShipStats/ShipDetails.show()
	var ship_info = game.ship_data[ship_id]
	$ShipStats/ShipDetails/LevelUp.visible = ship_info.has("leveled_up")
	$ShipStats/ShipDetails/Label.text = "%s %s %s" % [tr("LEVEL"), ship_info.lv, tr("%s_SHIP" % ShipClass.names[ship_info.ship_class].to_upper())]
	if game.item_to_use.id == -1:
		$ShipStats/ShipDetails/Respec.show()
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
		if ship_info.lv == 1:
			$ShipStats/ShipDetails.get_node(weapon).hide()
		else:
			$ShipStats/ShipDetails.get_node(weapon).show()
			var weapon_data = ship_info[weapon.to_lower()]
			$ShipStats/ShipDetails.get_node("%s/Icon" % [weapon]).texture = load("res://Graphics/Weapons/%s%s.png" % [weapon.to_lower(), 1])
			for path in 3:
				for lv in 3:
					$ShipStats/ShipDetails.get_node("%s/WeaponLevels/Path%s/Level%s" % [weapon, path+1, lv+1]).modulate = Color.WHITE if ship_info[weapon.to_lower()][path] > lv+1 else Color(0.3, 0.3, 0.3)
	$ShipStats/ShipDetails/XP/Label2.text = "%s / %s" % [Helper.format_num(round(ship_info.XP)), Helper.format_num(ship_info.XP_to_lv)]
	$ShipStats/ShipDetails/XP/TextureProgressBar.max_value = ship_info.XP_to_lv
	$ShipStats/ShipDetails/XP/TextureProgressGained.max_value = ship_info.XP_to_lv
	$ShipStats/ShipDetails/XP/TextureProgressBar.value = ship_info.XP
	$ShipStats/ShipDetails/XP/TextureProgressGained.value = ship_info.XP


func _on_weaponIcon_mouse_entered(weapon: String) -> void:
	if selected_ship_id != -1:
		game.show_tooltip(tr(weapon.to_upper() + "_DESC"))


func _on_respec_pressed() -> void:
	_on_close_button_pressed()
	if selected_ship_id != -1:
		game.switch_view("ship_customize_screen", {"ship_id":selected_ship_id, "respeccing":true})


func _on_level_up_mouse_entered() -> void:
	game.show_tooltip(tr("SHIP_LEVELED_UP"))


func _on_level_up_pressed() -> void:
	_on_close_button_pressed()
	if selected_ship_id != -1:
		game.switch_view("ship_customize_screen", {"ship_id":selected_ship_id})
