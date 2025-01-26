extends Control

@onready var game = get_node("/root/Game")

var ship_id:int
var ship_data:Dictionary
var allocatable_points:int = 2
var allocated_HP:int = 0
var allocated_attack:int = 0
var allocated_defense:int = 0
var allocated_accuracy:int = 0
var allocated_agility:int = 0

func _ready() -> void:
	if game.subject_levels.dimensional_power < 5:
		$ShipClass/VBox/VBox/Reckless.adv_button_disabled = true
		$ShipClass/VBox/VBox/Reckless.button_text = tr("LOCKED")
		$ShipClass/VBox/VBox/Reckless.mouse_entered.connect(game.show_tooltip.bind("SHIP_CLASS_UNLOCK_INFO"))
		$ShipClass/VBox/VBox/Reckless.mouse_exited.connect(game.hide_tooltip)
		$ShipClass/VBox/VBox/Impenetrable.adv_button_disabled = true
		$ShipClass/VBox/VBox/Impenetrable.button_text = tr("LOCKED")
		$ShipClass/VBox/VBox/Impenetrable.mouse_entered.connect(game.show_tooltip.bind("SHIP_CLASS_UNLOCK_INFO"))
		$ShipClass/VBox/VBox/Impenetrable.mouse_exited.connect(game.hide_tooltip)
		$ShipClass/VBox/VBox/Uber.adv_button_disabled = true
		$ShipClass/VBox/VBox/Uber.button_text = tr("LOCKED")
		$ShipClass/VBox/VBox/Uber.mouse_entered.connect(game.show_tooltip.bind("SHIP_CLASS_UNLOCK_INFO"))
		$ShipClass/VBox/VBox/Uber.mouse_exited.connect(game.hide_tooltip)
	ship_data = game.ship_data[ship_id].duplicate()
	if ship_data.ship_class == ShipClass.STANDARD:
		$ShipClass/VBox/VBox/Standard._on_Button_pressed()
	elif ship_data.ship_class == ShipClass.OFFENSIVE:
		$ShipClass/VBox/VBox/Offensive._on_Button_pressed()
	elif ship_data.ship_class == ShipClass.DEFENSIVE:
		$ShipClass/VBox/VBox/Defensive._on_Button_pressed()
	elif ship_data.ship_class == ShipClass.ACCURATE:
		$ShipClass/VBox/VBox/Accurate._on_Button_pressed()
	elif ship_data.ship_class == ShipClass.AGILE:
		$ShipClass/VBox/VBox/Agile._on_Button_pressed()
	elif ship_data.ship_class == ShipClass.ENERGETIC:
		$ShipClass/VBox/VBox/Energetic._on_Button_pressed()
	elif ship_data.ship_class == ShipClass.SUPPORT:
		$ShipClass/VBox/VBox/Support._on_Button_pressed()
	elif ship_data.ship_class == ShipClass.RECKLESS:
		$ShipClass/VBox/VBox/Reckless._on_Button_pressed()
	elif ship_data.ship_class == ShipClass.IMPENETRABLE:
		$ShipClass/VBox/VBox/Impenetrable._on_Button_pressed()
	elif ship_data.ship_class == ShipClass.UBER:
		$ShipClass/VBox/VBox/Uber._on_Button_pressed()
	update_ship_stats_display()

func update_ship_stats(ship_class: int):
	ship_data.ship_class = ship_class
	allocated_HP = 0
	allocated_attack = 0
	allocated_defense = 0
	allocated_accuracy = 0
	allocated_agility = 0
	update_ship_stats_display()
	
func update_ship_stats_display():
	var ship_class:int = ship_data.ship_class
	ship_data.HP = 10 + ShipClass.class_modifiers[ship_class].HP + ShipClass.class_modifiers[ship_class].HP_increase_on_levelup * allocated_HP
	ship_data.attack = 10 + ShipClass.class_modifiers[ship_class].attack + allocated_attack
	ship_data.defense = 10 + ShipClass.class_modifiers[ship_class].defense + allocated_defense
	ship_data.accuracy = 10 + ShipClass.class_modifiers[ship_class].accuracy + allocated_accuracy
	ship_data.agility = 10 + ShipClass.class_modifiers[ship_class].agility + allocated_agility
	$ShipStats/HPLabel.text = str(ship_data.HP)
	$ShipStats/AttackLabel.text = str(ship_data.attack)
	$ShipStats/DefenseLabel.text = str(ship_data.defense)
	$ShipStats/AccuracyLabel.text = str(ship_data.accuracy)
	$ShipStats/AgilityLabel.text = str(ship_data.agility)
	if ship_class == ShipClass.STANDARD:
		$PassiveAbility/Label2.text = tr("STANDARD_PASSIVE_ABILITY")
	elif ship_class == ShipClass.OFFENSIVE:
		$PassiveAbility/Label2.text = tr("OFFENSIVE_PASSIVE_ABILITY") % [25]
	elif ship_class == ShipClass.DEFENSIVE:
		$PassiveAbility/Label2.text = tr("DEFENSIVE_PASSIVE_ABILITY") % [15]
	elif ship_class == ShipClass.ACCURATE:
		$PassiveAbility/Label2.text = tr("ACCURATE_PASSIVE_ABILITY") % [15]
	elif ship_class == ShipClass.AGILE:
		$PassiveAbility/Label2.text = tr("AGILE_PASSIVE_ABILITY") % [15]
	elif ship_class == ShipClass.ENERGETIC:
		$PassiveAbility/Label2.text = tr("ENERGETIC_PASSIVE_ABILITY") % [15]
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


func _on_done_pressed() -> void:
	game.ship_data[ship_id] = ship_data.duplicate()
	game.ship_data[ship_id].respec_count += 1
	game.switch_view(game.l_v)


func _on_cancel_pressed() -> void:
	game.switch_view(game.l_v)


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
