extends Node

enum {
	STANDARD,
	OFFENSIVE,
	DEFENSIVE,
	ACCURATE,
	AGILE,
	ENERGETIC,
	SUPPORT,
	RECKLESS,
	IMPENETRABLE,
	UBER
}

var names = [
	"standard",
	"offensive",
	"defensive",
	"accurate",
	"agile",
	"energetic",
	"support",
	"reckless",
	"impenetrable",
	"uber",
]


var class_modifiers = {
	STANDARD: {
		"HP": 1,
		"HP_increase_on_levelup": 5,
		"attack": 1,
		"defense": 1,
		"accuracy": 1,
		"agility": 1,
	},
	OFFENSIVE: {
		"HP": 0,
		"HP_increase_on_levelup": 4,
		"attack": 3,
		"defense": 0,
		"accuracy": 1,
		"agility": 1,
	},
	DEFENSIVE: {
		"HP": 1,
		"HP_increase_on_levelup": 5,
		"attack": 0,
		"defense": 3,
		"accuracy": 0,
		"agility": 1,
	},
	ACCURATE: {
		"HP": 0,
		"HP_increase_on_levelup": 4,
		"attack": 1,
		"defense": 0,
		"accuracy": 4,
		"agility": 0,
	},
	AGILE: {
		"HP": 0,
		"HP_increase_on_levelup": 4,
		"attack": 0,
		"defense": 0,
		"accuracy": 1,
		"agility": 4,
	},
	ENERGETIC: {
		"HP": -1,
		"HP_increase_on_levelup": 3,
		"attack": 1,
		"defense": -1,
		"accuracy": 3,
		"agility": 3,
	},
	SUPPORT: {
		"HP": 2,
		"HP_increase_on_levelup": 6,
		"attack": -2,
		"defense": 0,
		"accuracy": 0,
		"agility": 0,
	},
	RECKLESS: {
		"HP": -1,
		"HP_increase_on_levelup": 3,
		"attack": 8,
		"defense": -1,
		"accuracy": -4,
		"agility": 3,
	},
	IMPENETRABLE: {
		"HP": 5,
		"HP_increase_on_levelup": 10,
		"attack": -1,
		"defense": 5,
		"accuracy": 0,
		"agility": -4,
	},
	UBER: {
		"HP": -6,
		"HP_increase_on_levelup": 1,
		"attack": 3,
		"defense": 3,
		"accuracy": 3,
		"agility": 3,
	},
}