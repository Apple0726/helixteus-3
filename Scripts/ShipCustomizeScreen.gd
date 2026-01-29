extends Control

@onready var game = get_node("/root/Game")

var respeccing = false
var ship_id:int
var ship_data:Dictionary
var allocatable_points:int
var allocated_HP:int = 0
var allocated_attack:int = 0
var allocated_defense:int = 0
var allocated_accuracy:int = 0
var allocated_agility:int = 0

func _ready() -> void:
	$Navigation/Ship.texture = load("res://Graphics/Ships/Ship%s.png" % ship_id)
	if game.subject_levels.dimensional_power < 5:
		$ClassAndStats/ShipClass/VBox/VBox/Reckless.adv_button_disabled = true
		$ClassAndStats/ShipClass/VBox/VBox/Reckless.button_text = tr("LOCKED")
		$ClassAndStats/ShipClass/VBox/VBox/Reckless.mouse_entered.connect(game.show_tooltip.bind(tr("SHIP_CLASS_UNLOCK_INFO")))
		$ClassAndStats/ShipClass/VBox/VBox/Reckless.mouse_exited.connect(game.hide_tooltip)
		$ClassAndStats/ShipClass/VBox/VBox/Impenetrable.adv_button_disabled = true
		$ClassAndStats/ShipClass/VBox/VBox/Impenetrable.button_text = tr("LOCKED")
		$ClassAndStats/ShipClass/VBox/VBox/Impenetrable.mouse_entered.connect(game.show_tooltip.bind(tr("SHIP_CLASS_UNLOCK_INFO")))
		$ClassAndStats/ShipClass/VBox/VBox/Impenetrable.mouse_exited.connect(game.hide_tooltip)
		$ClassAndStats/ShipClass/VBox/VBox/Uber.adv_button_disabled = true
		$ClassAndStats/ShipClass/VBox/VBox/Uber.button_text = tr("LOCKED")
		$ClassAndStats/ShipClass/VBox/VBox/Uber.mouse_entered.connect(game.show_tooltip.bind(tr("SHIP_CLASS_UNLOCK_INFO")))
		$ClassAndStats/ShipClass/VBox/VBox/Uber.mouse_exited.connect(game.hide_tooltip)
	ship_data = game.ship_data[ship_id].duplicate(true)
	if ship_data.lv == 1:
		$Navigation/VBoxContainer.visible = false
		$ClassAndStats/ShipStats.visible = false
		$Navigation/Ship.position.y += 30.0
	if respeccing:
		ship_data.unallocated_weapon_levels = ship_data.lv / 2
		ship_data.bullet = [1, 1, 1]
		ship_data.laser = [1, 1, 1]
		ship_data.bomb = [1, 1, 1]
		ship_data.light = [1, 1, 1]
	else:
		if ship_data.unallocated_weapon_levels > 0:
			$Navigation/Notification.show()
		$Actions/Cancel.hide()
		allocated_HP = ship_data.allocated_HP
		allocated_attack = ship_data.allocated_attack
		allocated_defense = ship_data.allocated_defense
		allocated_accuracy = ship_data.allocated_accuracy
		allocated_agility = ship_data.allocated_agility
		for class_btn in $ClassAndStats/ShipClass/VBox/VBox.get_children():
			class_btn.adv_button_disabled = true
	if ship_data.lv == 1:
		$Weapons.hide()
	else:
		for i in 3:
			for j in 3:
				$Weapons/ScrollContainer/Control.get_node("%s%s/Button" % [i+1, j+1]).mouse_entered.connect(show_weapon_tooltip.bind(i+1, j+1))
				$Weapons/ScrollContainer/Control.get_node("%s%s/Button" % [i+1, j+1]).mouse_exited.connect(game.hide_tooltip)
				$Weapons/ScrollContainer/Control.get_node("%s%s/Button" % [i+1, j+1]).pressed.connect(check_weapon_points.bind(i))
		update_weapons_panel()
	$Navigation/Level.text = "%s %s" % [tr("LEVEL"), ship_data.lv]
	allocatable_points = (ship_data.lv - 1) / 2 + 2
	$ClassAndStats/ShipClass/VBox/VBox.get_child(ship_data.ship_class)._on_Button_pressed()
	$Navigation/VBoxContainer/ClassAndStats._on_Button_pressed()
	for i in ShipClass.N:
		var passive_ability_text = ""
		if i == ShipClass.STANDARD:
			passive_ability_text = tr("STANDARD_PASSIVE_ABILITY")
		elif i == ShipClass.OFFENSIVE:
			passive_ability_text = tr("OFFENSIVE_PASSIVE_ABILITY") % [3]
		elif i == ShipClass.DEFENSIVE:
			passive_ability_text = tr("DEFENSIVE_PASSIVE_ABILITY") % [2]
		elif i == ShipClass.ACCURATE:
			passive_ability_text = tr("ACCURATE_PASSIVE_ABILITY") % [2]
		elif i == ShipClass.AGILE:
			passive_ability_text = tr("AGILE_PASSIVE_ABILITY") % [2]
		elif i == ShipClass.ENERGETIC:
			passive_ability_text = tr("ENERGETIC_PASSIVE_ABILITY") % [30, 25]
		elif i == ShipClass.SUPPORT:
			passive_ability_text = tr("SUPPORT_PASSIVE_ABILITY")
		elif i == ShipClass.RECKLESS:
			passive_ability_text = tr("RECKLESS_PASSIVE_ABILITY")
		elif i == ShipClass.IMPENETRABLE:
			passive_ability_text = tr("IMPENETRABLE_PASSIVE_ABILITY") % [15, 25, 50]
		elif i == ShipClass.UBER:
			passive_ability_text = tr("UBER_PASSIVE_ABILITY")
		if not $ClassAndStats/ShipClass/VBox/VBox.get_child(i).adv_button_disabled:
			$ClassAndStats/ShipClass/VBox/VBox.get_child(i).mouse_entered.connect(game.show_tooltip.bind(tr("PASSIVE_ABILITY") + ": " + passive_ability_text))
			$ClassAndStats/ShipClass/VBox/VBox.get_child(i).mouse_exited.connect(game.hide_tooltip)
			$ClassAndStats/ShipClass/VBox/VBox.get_child(i).pressed.connect(update_ship_stats_after_class_change.bind(i))
	update_ship_stats_display()

func check_weapon_points(path: int):
	if ship_data.unallocated_weapon_levels > 0:
		game.show_YN_panel("upgrade_ship_weapon", tr("ARE_YOU_SURE"), [path])

func update_ship_stats_after_class_change(ship_class: int):
	ship_data.ship_class = ship_class
	allocated_HP = 0
	allocated_attack = 0
	allocated_defense = 0
	allocated_accuracy = 0
	allocated_agility = 0
	$ClassAndStats/ShipStats/RemoveHP.disabled = true
	$ClassAndStats/ShipStats/RemoveAttack.disabled = true
	$ClassAndStats/ShipStats/RemoveDefense.disabled = true
	$ClassAndStats/ShipStats/RemoveAccuracy.disabled = true
	$ClassAndStats/ShipStats/RemoveAgility.disabled = true
	update_ship_stats_display()
	$ClassAndStats/ShipStats.show()

func update_ship_stats_display():
	var ship_class:int = ship_data.ship_class
	ship_data.HP = 15 + ShipClass.class_modifiers[ship_class].HP + ShipClass.class_modifiers[ship_class].HP_increase_on_levelup * (allocated_HP + ship_data.lv - 1)
	ship_data.attack = 10 + ShipClass.class_modifiers[ship_class].attack + allocated_attack
	ship_data.defense = 10 + ShipClass.class_modifiers[ship_class].defense + allocated_defense
	ship_data.accuracy = 10 + ShipClass.class_modifiers[ship_class].accuracy + allocated_accuracy
	ship_data.agility = 10 + ShipClass.class_modifiers[ship_class].agility + allocated_agility
	ship_data.allocated_HP = allocated_HP
	ship_data.allocated_attack = allocated_attack
	ship_data.allocated_defense = allocated_defense
	ship_data.allocated_accuracy = allocated_accuracy
	ship_data.allocated_agility = allocated_agility
	$ClassAndStats/ShipStats/HPLabel.text = str(ship_data.HP)
	$ClassAndStats/ShipStats/AttackLabel.text = str(ship_data.attack)
	$ClassAndStats/ShipStats/DefenseLabel.text = str(ship_data.defense)
	$ClassAndStats/ShipStats/AccuracyLabel.text = str(ship_data.accuracy)
	$ClassAndStats/ShipStats/AgilityLabel.text = str(ship_data.agility)
	var points_allocated = allocated_HP + allocated_attack + allocated_defense + allocated_accuracy + allocated_agility
	$ClassAndStats/ShipStats/PointsAllocated.text = "%s: %s / %s" % [tr("POINTS_ALLOCATED"), points_allocated, allocatable_points]
	var no_more_allocatable_points = points_allocated >= allocatable_points
	if no_more_allocatable_points:
		$ClassAndStats/ShipStats/PointsAllocated["theme_override_colors/font_color"] = Color.WHITE
		$Actions/Done.disabled = false
	else:
		$ClassAndStats/ShipStats/PointsAllocated["theme_override_colors/font_color"] = Color.YELLOW
		$Actions/Done.disabled = true
	$ClassAndStats/ShipStats/AddHP.disabled = no_more_allocatable_points
	$ClassAndStats/ShipStats/AddAttack.disabled = no_more_allocatable_points
	$ClassAndStats/ShipStats/AddDefense.disabled = no_more_allocatable_points
	$ClassAndStats/ShipStats/AddAccuracy.disabled = no_more_allocatable_points
	$ClassAndStats/ShipStats/AddAgility.disabled = no_more_allocatable_points

func customize_next_ship():
	for i in len(game.ship_data):
		if ship_id == i:
			continue
		if game.ship_data[i].has("leveled_up"):
			game.switch_view("ship_customize_screen", {"ship_id":i})
			return
	game.switch_view(game.l_v)

func _on_done_pressed() -> void:
	game.ship_data[ship_id] = ship_data.duplicate()
	if respeccing:
		game.ship_data[ship_id].respec_count += 1
	else:
		game.ship_data[ship_id].erase("leveled_up")
	customize_next_ship()


func _on_cancel_pressed() -> void:
	customize_next_ship()


func _on_add_hp_pressed() -> void:
	allocated_HP += 1
	$ClassAndStats/ShipStats/RemoveHP.disabled = false
	update_ship_stats_display()


func _on_remove_hp_pressed() -> void:
	allocated_HP -= 1
	if allocated_HP <= 0:
		$ClassAndStats/ShipStats/RemoveHP.disabled = true
	update_ship_stats_display()


func _on_remove_attack_pressed() -> void:
	allocated_attack -= 1
	if allocated_attack <= 0:
		$ClassAndStats/ShipStats/RemoveAttack.disabled = true
	update_ship_stats_display()


func _on_add_attack_pressed() -> void:
	allocated_attack += 1
	$ClassAndStats/ShipStats/RemoveAttack.disabled = false
	update_ship_stats_display()


func _on_remove_defense_pressed() -> void:
	allocated_defense -= 1
	if allocated_defense <= 0:
		$ClassAndStats/ShipStats/RemoveDefense.disabled = true
	update_ship_stats_display()


func _on_add_defense_pressed() -> void:
	allocated_defense += 1
	$ClassAndStats/ShipStats/RemoveDefense.disabled = false
	update_ship_stats_display()


func _on_remove_accuracy_pressed() -> void:
	allocated_accuracy -= 1
	if allocated_accuracy <= 0:
		$ClassAndStats/ShipStats/RemoveAccuracy.disabled = true
	update_ship_stats_display()


func _on_add_accuracy_pressed() -> void:
	allocated_accuracy += 1
	$ClassAndStats/ShipStats/RemoveAccuracy.disabled = false
	update_ship_stats_display()


func _on_remove_agility_pressed() -> void:
	allocated_agility -= 1
	if allocated_agility <= 0:
		$ClassAndStats/ShipStats/RemoveAgility.disabled = true
	update_ship_stats_display()


func _on_add_agility_pressed() -> void:
	allocated_agility += 1
	$ClassAndStats/ShipStats/RemoveAgility.disabled = false
	update_ship_stats_display()


func _on_hp_icon_mouse_entered() -> void:
	game.show_tooltip(tr("SHIP_HIT_POINTS"))


func _on_mouse_exited() -> void:
	game.hide_tooltip()


func _on_attack_icon_mouse_entered() -> void:
	game.show_tooltip(tr("SHIP_ATTACK"))


func _on_defense_icon_mouse_entered() -> void:
	game.show_tooltip(tr("SHIP_DEFENSE"))


func _on_accuracy_icon_mouse_entered() -> void:
	game.show_tooltip(tr("SHIP_ACCURACY"))


func _on_agility_icon_mouse_entered() -> void:
	game.show_tooltip(tr("SHIP_AGILITY"))

enum {
	BULLET,
	LASER,
	BOMB,
	LIGHT,
}
var weapon_selected = BULLET
var weapon_selected_str = "bullet"

func _on_weapons_next_pressed() -> void:
	weapon_selected += 1
	$Weapons/Previous.disabled = false
	if weapon_selected == LIGHT:
		$Weapons/Next.disabled = true
	update_weapons_panel()


func _on_weapons_previous_pressed() -> void:
	weapon_selected -= 1
	$Weapons/Next.disabled = false
	if weapon_selected == BULLET:
		$Weapons/Previous.disabled = true
	update_weapons_panel()

func update_weapons_panel():
	$Weapons/LvRemaining.text = tr("WEAPON_LV_UP_REMAINING") + " " + str(ship_data.unallocated_weapon_levels)
	if weapon_selected == BULLET:
		# Placeholder textures
		for node_name in ["11", "12", "13", "21", "22", "23", "31", "32", "33"]:
			$Weapons/ScrollContainer/Control.get_node(node_name + "/TextureRect").texture = preload("res://Graphics/Weapons/bullet1.png")
		$Weapons/CurrentWeapon.text = tr("BULLET")
		weapon_selected_str = "bullet"
	elif weapon_selected == LASER:
		# Placeholder textures
		for node_name in ["11", "12", "13", "21", "22", "23", "31", "32", "33"]:
			$Weapons/ScrollContainer/Control.get_node(node_name + "/TextureRect").texture = preload("res://Graphics/Weapons/laser1.png")
		$Weapons/CurrentWeapon.text = tr("LASER")
		weapon_selected_str = "laser"
	elif weapon_selected == BOMB:
		# Placeholder textures
		for node_name in ["11", "12", "13", "21", "22", "23", "31", "32", "33"]:
			$Weapons/ScrollContainer/Control.get_node(node_name + "/TextureRect").texture = preload("res://Graphics/Weapons/bomb1.png")
		$Weapons/CurrentWeapon.text = tr("BOMB")
		weapon_selected_str = "bomb"
	elif weapon_selected == LIGHT:
		# Placeholder textures
		for node_name in ["11", "12", "13", "21", "22", "23", "31", "32", "33"]:
			$Weapons/ScrollContainer/Control.get_node(node_name + "/TextureRect").texture = preload("res://Graphics/Weapons/light1.png")
		$Weapons/CurrentWeapon.text = tr("LIGHT")
		weapon_selected_str = "light"
	for i in 3:
		for j in 3:
			$Weapons/ScrollContainer/Control.get_node("%s%s/Flicker" % [i+1, j+1]).visible = ship_data[weapon_selected_str][i] == j+1 and ship_data.unallocated_weapon_levels > 0
			if ship_data[weapon_selected_str][i] > j+1:
				$Weapons/ScrollContainer/Control.get_node("%s%s/Button" % [i+1, j+1]).modulate = Color.GREEN_YELLOW
				$Weapons/ScrollContainer/Control.get_node("%s%s/Flicker" % [i+1, j+1]).hide()
			else:
				$Weapons/ScrollContainer/Control.get_node("%s%s/Button" % [i+1, j+1]).modulate = Color.WHITE
			if ship_data[weapon_selected_str][i] >= j+1:
				$Weapons/ScrollContainer/Control.get_node("%s%s" % [i+1, j+1]).modulate = Color.WHITE
			else:
				$Weapons/ScrollContainer/Control.get_node("%s%s" % [i+1, j+1]).modulate = Color(0.4, 0.4, 0.4)
			$Weapons/ScrollContainer/Control.get_node("%s%s/Button" % [i+1, j+1]).disabled = ship_data[weapon_selected_str][i] != j+1
		for j in 2:
			$Weapons/ScrollContainer/Control.get_node("Line2D%s%s" % [i+1, j+1]).default_color = Color(0.4, 0.886, 1.0) if ship_data[weapon_selected_str][i] > j+1 else Color(0.0, 0.433, 0.51)


func upgrade_ship_weapon(path: int):
	if ship_data.unallocated_weapon_levels > 0:
		ship_data[weapon_selected_str][path] += 1
		ship_data.unallocated_weapon_levels -= 1
	update_weapons_panel()

func show_weapon_tooltip(path: int, lv: int):
	game.show_tooltip(tr("%s_%s_%s_DESC" % [weapon_selected_str.to_upper(), path, lv]))


func _on_class_and_stats_pressed() -> void:
	$Weapons.hide()
	$ClassAndStats.show()


func _on_weapon_levels_pressed() -> void:
	$Navigation/Notification.hide()
	$ClassAndStats.hide()
	$Weapons.show()
