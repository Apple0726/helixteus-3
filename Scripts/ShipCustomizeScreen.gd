extends Control

enum {
	STANDARD,
	OFFENSIVE,
	DEFENSIVE,
	ACCURATE,
	AGILE,
	ENERGETIC,
	SUPPORT,
	RECKLESS,
	TANK,
	UBER
}
var ship_data = {
	"HP": 10,
	"attack": 10,
	"defense": 10,
	"accuracy": 10,
	"agility": 10,
	"ship_class": STANDARD,
}

var ship_class_modifiers = {
	STANDARD: {
		"HP": 1,
		"attack": 1,
		"defense": 1,
		"accuracy": 1,
		"agility": 1,
	},
	OFFENSIVE: {
		"HP": 0,
		"attack": 3,
		"defense": 0,
		"accuracy": 1,
		"agility": 1,
	},
	DEFENSIVE: {
		"HP": 1,
		"attack": 0,
		"defense": 3,
		"accuracy": 0,
		"agility": 1,
	},
	ACCURATE: {
		"HP": 0,
		"attack": 1,
		"defense": 0,
		"accuracy": 4,
		"agility": 0,
	},
	AGILE: {
		"HP": 0,
		"attack": 0,
		"defense": 0,
		"accuracy": 1,
		"agility": 4,
	},
	ENERGETIC: {
		"HP": -1,
		"attack": 1,
		"defense": -1,
		"accuracy": 3,
		"agility": 3,
	},
	SUPPORT: {
		"HP": 2,
		"attack": -2,
		"defense": 0,
		"accuracy": 0,
		"agility": 0,
	},
	RECKLESS: {
		"HP": -1,
		"attack": 8,
		"defense": -1,
		"accuracy": -4,
		"agility": 3,
	},
	TANK: {
		"HP": 5,
		"attack": -1,
		"defense": 5,
		"accuracy": 0,
		"agility": -4,
	},
	UBER: {
		"HP": -6,
		"attack": 3,
		"defense": 3,
		"accuracy": 3,
		"agility": 3,
	},
}

func update_ship_stats(ship_class: int):
	ship_data.ship_class = ship_class
	ship_data.HP = 10 + ship_class_modifiers[ship_class].HP
	ship_data.attack = 10 + ship_class_modifiers[ship_class].attack
	ship_data.defense = 10 + ship_class_modifiers[ship_class].defense
	ship_data.accuracy = 10 + ship_class_modifiers[ship_class].accuracy
	ship_data.agility = 10 + ship_class_modifiers[ship_class].agility
	$ShipStats/HPLabel.text = str(ship_data.HP)
	$ShipStats/AttackLabel.text = str(ship_data.attack)
	$ShipStats/DefenseLabel.text = str(ship_data.defense)
	$ShipStats/AccuracyLabel.text = str(ship_data.accuracy)
	$ShipStats/AgilityLabel.text = str(ship_data.agility)
	if ship_class == STANDARD:
		$PassiveAbility/Label2.text = tr("STANDARD_PASSIVE_ABILITY")
	elif ship_class == OFFENSIVE:
		$PassiveAbility/Label2.text = tr("OFFENSIVE_PASSIVE_ABILITY")
	elif ship_class == DEFENSIVE:
		$PassiveAbility/Label2.text = tr("DEFENSIVE_PASSIVE_ABILITY")
	elif ship_class == ACCURATE:
		$PassiveAbility/Label2.text = tr("ACCURATE_PASSIVE_ABILITY")
	elif ship_class == AGILE:
		$PassiveAbility/Label2.text = tr("AGILE_PASSIVE_ABILITY")
	elif ship_class == ENERGETIC:
		$PassiveAbility/Label2.text = tr("ENERGETIC_PASSIVE_ABILITY")
	elif ship_class == SUPPORT:
		$PassiveAbility/Label2.text = tr("SUPPORT_PASSIVE_ABILITY")
	elif ship_class == RECKLESS:
		$PassiveAbility/Label2.text = tr("RECKLESS_PASSIVE_ABILITY")
	elif ship_class == TANK:
		$PassiveAbility/Label2.text = tr("TANK_PASSIVE_ABILITY")
	elif ship_class == UBER:
		$PassiveAbility/Label2.text = tr("UBER_PASSIVE_ABILITY")
