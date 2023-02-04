extends "Panel.gd"

var spaceport_tier:int
onready var travel_ETA = $Panel/TravelETA
onready var grid = $Grid

func _ready():
	set_polygon(rect_size)
	for panel in $Grid.get_children():
		panel.show_weapon_XPs = false
	refresh()

func _on_close_button_pressed():
	game.toggle_panel(self)

func refresh():
	for panel in $Grid.get_children():
		panel.refresh()
	$Grid/Panel1.visible = len(game.ship_data) >= 1
	$Grid/Panel2.visible = len(game.ship_data) >= 2
	$Grid/Panel3.visible = len(game.ship_data) >= 3
	$Grid/Panel4.visible = len(game.ship_data) >= 4
	$Panel/UpgradeButton.visible = game.science_unlocked.has("UP1")
	$Drives.refresh()
	$Upgrade._refresh()
	$Upgrade._refresh_op()
	if game.ships_travel_view != "-":
		$SpaceportTimer.stop()
		spaceport_tier = -1
		$Panel/TravelETA["custom_colors/font_color"] = Color.white
	else:
		if game.autocollect.has("ship_XP"):
			$Panel/TravelETA["custom_colors/font_color"] = Color.greenyellow
			$Panel/TravelETA.text = tr("SHIPS_BENEFITING_FROM_SPACEPORT")
			spaceport_tier = game.autocollect.ship_XP
			if $SpaceportTimer.is_stopped():
				$SpaceportTimer.start(4.0 / spaceport_tier)
		else:
			$SpaceportTimer.stop()
			spaceport_tier = -1
			$Panel/TravelETA["custom_colors/font_color"] = Color.white
			$Panel/TravelETA.text = ""
	set_process(true)

func _process(delta):
	if spaceport_tier != -1:
		for i in len(game.ship_data):
			for weapon in ["Bullet", "Laser", "Bomb", "Light"]:
				var node = grid.get_node("Panel%s/%s/TextureProgress" % [i + 1, weapon])
				var text_node = grid.get_node("Panel%s/%s/Label2" % [i + 1, weapon])
				var curr_weapon_XP = game.ship_data[i][weapon.to_lower()].XP
				node.value = move_toward(node.value, curr_weapon_XP, abs(curr_weapon_XP - node.value) * delta * 0.5)
				text_node.text = "%s / %s" % [round(node.value), game.ship_data[i][weapon.to_lower()].XP_to_lv]
			var XP_node = grid.get_node("Panel%s/XP/TextureProgress" % (i + 1))
			var XP_text_node = grid.get_node("Panel%s/XP/Label2" % (i + 1))
			var curr_XP = game.ship_data[i].XP
			XP_node.value = move_toward(XP_node.value, curr_XP, abs(curr_XP - XP_node.value) * delta * 2)
			XP_text_node.text = "%s / %s" % [Helper.format_num(round(XP_node.value)), Helper.format_num(game.ship_data[i].XP_to_lv)]
	elif game.ships_travel_view != "-":
		travel_ETA.text = "%s: %s" % [tr("TRAVEL_ETA"), Helper.time_to_str(game.ships_travel_length - OS.get_system_time_msecs() + game.ships_travel_start_date)]
	if not visible:
		set_process(false)

func _on_CheckBox_toggled(button_pressed):
	for panel in $Grid.get_children():
		panel.show_weapon_XPs = button_pressed
		panel.set_visibility()

func _on_DriveButton_pressed():
	if game.science_unlocked.has("CD"):
		$Grid.visible = false
		$Drives.visible = true
		$Panel/CheckBox.visible = false
		$Panel/DriveButton.visible = false
		$Panel/BackButton.visible = true
		$Panel/UpgradeButton.visible = false
	else:
		game.popup(tr("DRIVE_TECHNOLOGY_REQUIRED"), 1.5)

func _on_BackButton_pressed():
	$Grid.visible = true
	$Drives.visible = false
	$Upgrade.visible = false
	$Panel/CheckBox.visible = true
	$Panel/DriveButton.visible = true
	$Panel/BackButton.visible = false
	$Panel/UpgradeButton.visible = true
	refresh()

func _on_UpgradeButton_pressed():
	$Grid.visible = false
	$Drives.visible = false
	$Upgrade.visible = true
	$Panel/CheckBox.visible = false
	$Panel/DriveButton.visible = false
	$Panel/BackButton.visible = true
	$Panel/UpgradeButton.visible = false
	$Upgrade._refresh()
	$Upgrade._refresh_op()

func _on_GoToShips_mouse_entered():
	game.show_tooltip(tr("GO_TO_SHIPS"))

func _on_mouse_exited():
	game.hide_tooltip()

func _on_GoToShips_pressed():
	game.switch_view("system", {"fn":"set_to_ship_coords"})
	_on_close_button_pressed()

func _on_DriveButton_mouse_entered():
	game.show_tooltip(tr("OPEN_DRIVE_MENU"))

func _on_BackButton_mouse_entered():
	game.show_tooltip(tr("BACK"))

func _on_UpgradeButton_mouse_entered():
	game.show_tooltip("UP1_SC")

var bar_colors = {
	"bullet":Color(0, 0.46, 0.81),
	"laser":Color(1, 0.28, 0.28),
	"bomb":Color(0.28, 0.28, 0.28),
	"light":Color(0.81, 0.81, 0.36),
}

func _on_SpaceportTimer_timeout():
	var xp_mult = Helper.get_spaceport_xp_mult(spaceport_tier)
	for i in len(game.ship_data):
		var weapon = ["Bullet", "Laser", "Bomb", "Light"][randi() % 4]
		Helper.add_ship_XP(i, xp_mult * pow(1.15, game.u_i.lv))
		Helper.add_weapon_XP(i, weapon.to_lower(), xp_mult / 16.0 * pow(1.07, game.u_i.lv))
		if visible:
			grid.get_node("Panel%s/XP/TextureProgress2" % (i+1)).value = 0
			grid.get_node("Panel%s/%s/TextureProgress2" % [i+1, weapon]).value = 0
			grid.get_node("Panel%s/Lv" % (i+1)).text = "%s %s" % [tr("LV"), game.ship_data[i].lv]
			grid.get_node("Panel%s/XP/TextureProgress" % (i+1)).max_value = game.ship_data[i].XP_to_lv
			grid.get_node("Panel%s/XP/TextureProgress" % (i+1)).modulate = Color.white
			grid.get_node("Panel%s/%s/TextureProgress" % [i+1, weapon]).modulate = Color.white
			var weapon_data = game.ship_data[i][weapon.to_lower()]
			var tween = get_tree().create_tween()
			tween.tween_property(grid.get_node("Panel%s/XP/TextureProgress" % (i+1)), "modulate", Color(0.92, 0.63, 0.2), 1.0)
			var tween2 = get_tree().create_tween()
			tween2.tween_property(grid.get_node("Panel%s/%s/TextureProgress" % [i+1, weapon]), "modulate", bar_colors[weapon.to_lower()], 1.0)
			grid.get_node("Panel%s/%s/TextureRect" % [i+1, weapon]).texture = load("res://Graphics/Weapons/%s%s.png" % [weapon.to_lower(), weapon_data.lv])
			grid.get_node("Panel%s/%s/TextureProgress" % [i+1, weapon]).max_value = INF if weapon_data.lv == 5 else weapon_data.XP_to_lv
			grid.get_node("Panel%s/Stats/HP" % (i+1)).text = Helper.format_num(game.ship_data[i].total_HP * game.ship_data[i].HP_mult)
			grid.get_node("Panel%s/Stats/Atk" % (i+1)).text = Helper.format_num(game.ship_data[i].atk * game.ship_data[i].atk_mult)
			grid.get_node("Panel%s/Stats/Def" % (i+1)).text = Helper.format_num(game.ship_data[i].def * game.ship_data[i].def_mult)
			grid.get_node("Panel%s/Stats/Acc" % (i+1)).text = Helper.format_num(game.ship_data[i].acc * game.ship_data[i].acc_mult)
			grid.get_node("Panel%s/Stats/Eva" % (i+1)).text = Helper.format_num(game.ship_data[i].eva * game.ship_data[i].eva_mult)
