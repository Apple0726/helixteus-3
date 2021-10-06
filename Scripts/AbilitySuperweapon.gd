extends Panel

onready var game = get_node("/root/Game")
onready var upgrade_panel = get_parent()
var ship:Dictionary

var ability = ""
var superweapon = ""
var costs = {"none":0, "buff":1, "debuff":1, "repair":1, "lol":1, "orb":1, "charge":1}

func _ready():
	_refresh()

func _refresh():
	ship = upgrade_panel.ship
	if ship:
		ability = ship.get("ability", "none")
		$Abilities/Ability.text = ability
		superweapon = ship.get("superweapon", "none")
		$Superweapons/Superweapon.text = superweapon

func _upgrade(thing:String,type:String):
	var prev_thing = ship[type]
	var diff = costs[thing] - costs[prev_thing]
	if ship.points > diff:
		ship.points -= diff
		ship[type] = thing
		_refresh()
		upgrade_panel._refresh()

func _on_None_pressed():
	_upgrade("none","ability")

func _on_Buff_pressed():
	_upgrade("buff","ability")

func _on_Debuff_pressed():
	_upgrade("debuff","ability")

func _on_Repair_pressed():
	_upgrade("repair","ability")

func _on_LOL_pressed():
	_upgrade("lol","superweapon")

func _on_Orb_pressed():
	_upgrade("orb","superweapon")

func _on_Charge_pressed():
	_upgrade("charge","superweapon")

func _on_None2_pressed():
	_upgrade("none","superweapon")
