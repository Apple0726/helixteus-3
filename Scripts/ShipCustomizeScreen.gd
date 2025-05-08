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
var unallocated_weapon_levels:int

func _ready() -> void:
	$Ship.texture = load("res://Graphics/Ships/Ship%s.png" % ship_id)
	if game.subject_levels.dimensional_power < 5:
		$ShipClass/VBox/VBox/Reckless.adv_button_disabled = true
		$ShipClass/VBox/VBox/Reckless.button_text = tr("LOCKED")
		$ShipClass/VBox/VBox/Reckless.mouse_entered.connect(game.show_tooltip.bind(tr("SHIP_CLASS_UNLOCK_INFO")))
		$ShipClass/VBox/VBox/Reckless.mouse_exited.connect(game.hide_tooltip)
		$ShipClass/VBox/VBox/Impenetrable.adv_button_disabled = true
		$ShipClass/VBox/VBox/Impenetrable.button_text = tr("LOCKED")
		$ShipClass/VBox/VBox/Impenetrable.mouse_entered.connect(game.show_tooltip.bind(tr("SHIP_CLASS_UNLOCK_INFO")))
		$ShipClass/VBox/VBox/Impenetrable.mouse_exited.connect(game.hide_tooltip)
		$ShipClass/VBox/VBox/Uber.adv_button_disabled = true
		$ShipClass/VBox/VBox/Uber.button_text = tr("LOCKED")
		$ShipClass/VBox/VBox/Uber.mouse_entered.connect(game.show_tooltip.bind(tr("SHIP_CLASS_UNLOCK_INFO")))
		$ShipClass/VBox/VBox/Uber.mouse_exited.connect(game.hide_tooltip)
	ship_data = game.ship_data[ship_id].duplicate(true)
	if respeccing:
		unallocated_weapon_levels = ship_data.lv / 2
		ship_data.bullet = [1, 1, 1]
		ship_data.laser = [1, 1, 1]
		ship_data.bomb = [1, 1, 1]
		ship_data.light = [1, 1, 1]
	else:
		$Actions/Cancel.hide()
		allocated_HP = ship_data.allocated_HP
		allocated_attack = ship_data.allocated_attack
		allocated_defense = ship_data.allocated_defense
		allocated_accuracy = ship_data.allocated_accuracy
		allocated_agility = ship_data.allocated_agility
		for class_btn in $ShipClass/VBox/VBox.get_children():
			class_btn.adv_button_disabled = true
		unallocated_weapon_levels = ship_data.unallocated_weapon_levels
	if ship_data.lv == 1:
		$Weapons.hide()
	else:
		for i in 3:
			for j in 3:
				$Weapons/ScrollContainer/Control.get_node("%s%s/Button" % [i+1, j+1]).mouse_entered.connect(show_weapon_tooltip.bind(i+1, j+1))
				$Weapons/ScrollContainer/Control.get_node("%s%s/Button" % [i+1, j+1]).mouse_exited.connect(game.hide_tooltip)
				$Weapons/ScrollContainer/Control.get_node("%s%s/Button" % [i+1, j+1]).pressed.connect(game.show_YN_panel.bind("upgrade_ship_weapon", tr("ARE_YOU_SURE"), [i]))
		update_weapons_panel()
	$Ship/Level.text = "%s %s" % [tr("LEVEL"), ship_data.lv]
	allocatable_points = (ship_data.lv - 1) / 2 + 2
	$ShipClass/VBox/VBox.get_child(ship_data.ship_class)._on_Button_pressed()
	for i in ShipClass.N:
		$ShipClass/VBox/VBox.get_child(i).pressed.connect(update_ship_stats_after_class_change.bind(i))
	update_ship_stats_display()

func update_ship_stats_after_class_change(ship_class: int):
	ship_data.ship_class = ship_class
	allocated_HP = 0
	allocated_attack = 0
	allocated_defense = 0
	allocated_accuracy = 0
	allocated_agility = 0
	update_ship_stats_display()

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
	$ShipStats/HPLabel.text = str(ship_data.HP)
	$ShipStats/AttackLabel.text = str(ship_data.attack)
	$ShipStats/DefenseLabel.text = str(ship_data.defense)
	$ShipStats/AccuracyLabel.text = str(ship_data.accuracy)
	$ShipStats/AgilityLabel.text = str(ship_data.agility)
	if ship_class == ShipClass.STANDARD:
		$PassiveAbility/Label2.text = tr("STANDARD_PASSIVE_ABILITY")
	elif ship_class == ShipClass.OFFENSIVE:
		$PassiveAbility/Label2.text = tr("OFFENSIVE_PASSIVE_ABILITY") % [3]
	elif ship_class == ShipClass.DEFENSIVE:
		$PassiveAbility/Label2.text = tr("DEFENSIVE_PASSIVE_ABILITY") % [2]
	elif ship_class == ShipClass.ACCURATE:
		$PassiveAbility/Label2.text = tr("ACCURATE_PASSIVE_ABILITY") % [2]
	elif ship_class == ShipClass.AGILE:
		$PassiveAbility/Label2.text = tr("AGILE_PASSIVE_ABILITY") % [2]
	elif ship_class == ShipClass.ENERGETIC:
		$PassiveAbility/Label2.text = tr("ENERGETIC_PASSIVE_ABILITY") % [30, 25]
	elif ship_class == ShipClass.SUPPORT:
		$PassiveAbility/Label2.text = tr("SUPPORT_PASSIVE_ABILITY")
	elif ship_class == ShipClass.RECKLESS:
		$PassiveAbility/Label2.text = tr("RECKLESS_PASSIVE_ABILITY")
	elif ship_class == ShipClass.IMPENETRABLE:
		$PassiveAbility/Label2.text = tr("IMPENETRABLE_PASSIVE_ABILITY") % [15, 25, 50]
	elif ship_class == ShipClass.UBER:
		$PassiveAbility/Label2.text = tr("UBER_PASSIVE_ABILITY")
	var points_allocated = allocated_HP + allocated_attack + allocated_defense + allocated_accuracy + allocated_agility
	$ShipStats/PointsAllocated.text = "%s: %s / %s" % [tr("POINTS_ALLOCATED"), points_allocated, allocatable_points]
	var no_more_allocatable_points = points_allocated >= allocatable_points
	if no_more_allocatable_points:
		$ShipStats/PointsAllocated["theme_override_colors/font_color"] = Color.WHITE
		$Actions/Done.disabled = false
	else:
		$ShipStats/PointsAllocated["theme_override_colors/font_color"] = Color.YELLOW
		$Actions/Done.disabled = true
	$ShipStats/AddHP.disabled = no_more_allocatable_points
	$ShipStats/AddAttack.disabled = no_more_allocatable_points
	$ShipStats/AddDefense.disabled = no_more_allocatable_points
	$ShipStats/AddAccuracy.disabled = no_more_allocatable_points
	$ShipStats/AddAgility.disabled = no_more_allocatable_points

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
	$ShipStats/RemoveHP.disabled = false
	update_ship_stats_display()


func _on_remove_hp_pressed() -> void:
	allocated_HP -= 1
	if allocated_HP <= 0:
		$ShipStats/RemoveHP.disabled = true
	update_ship_stats_display()


func _on_remove_attack_pressed() -> void:
	allocated_attack -= 1
	if allocated_attack <= 0:
		$ShipStats/RemoveAttack.disabled = true
	update_ship_stats_display()


func _on_add_attack_pressed() -> void:
	allocated_attack += 1
	$ShipStats/RemoveAttack.disabled = false
	update_ship_stats_display()


func _on_remove_defense_pressed() -> void:
	allocated_defense -= 1
	if allocated_defense <= 0:
		$ShipStats/RemoveDefense.disabled = true
	update_ship_stats_display()


func _on_add_defense_pressed() -> void:
	allocated_defense += 1
	$ShipStats/RemoveDefense.disabled = false
	update_ship_stats_display()


func _on_remove_accuracy_pressed() -> void:
	allocated_accuracy -= 1
	if allocated_accuracy <= 0:
		$ShipStats/RemoveAccuracy.disabled = true
	update_ship_stats_display()


func _on_add_accuracy_pressed() -> void:
	allocated_accuracy += 1
	$ShipStats/RemoveAccuracy.disabled = false
	update_ship_stats_display()


func _on_remove_agility_pressed() -> void:
	allocated_agility -= 1
	if allocated_agility <= 0:
		$ShipStats/RemoveAgility.disabled = true
	update_ship_stats_display()


func _on_add_agility_pressed() -> void:
	allocated_agility += 1
	$ShipStats/RemoveAgility.disabled = false
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
	$Weapons/LvRemaining.text = tr("WEAPON_LV_UP_REMAINING") + " " + str(unallocated_weapon_levels)
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
			if ship_data[weapon_selected_str][i] > j+1:
				$Weapons/ScrollContainer/Control.get_node("%s%s/Button" % [i+1, j+1]).modulate = Color.GREEN_YELLOW
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
	if unallocated_weapon_levels > 0:
		ship_data[weapon_selected_str][path] += 1
		unallocated_weapon_levels -= 1
	update_weapons_panel()

func show_weapon_tooltip(path: int, lv: int):
	game.show_tooltip(tr("%s_%s_%s_DESC" % [weapon_selected_str.to_upper(), path, lv]))
