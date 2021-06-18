extends Node

export var type:String = ""
onready var game = get_node("/root/Game")
onready var upgrade_panel = get_parent().get_parent()
onready var ship = upgrade_panel.ship

var lv = 0
var boost = 0

func _refresh():
	boost = "+ %s %%" % (ship.upgrades["%s_mult" % type] * 100)
	$Boost.text = "+" + String(boost) + "%"

func _on_Up_pressed():
	get_parent().get_parent()._upgrade(type)

func _on_Down_pressed():
	get_parent().get_parent()._downgrade(type)
