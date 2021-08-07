extends Node

export var type:String = ""
onready var game = get_node("/root/Game")
onready var upgrade_panel = get_parent().get_parent()
var ship:Dictionary

var boost = 0

func _refresh():
	var ship = upgrade_panel.ship
	boost = (ship["%s_mult" % type] * 100) - 100
	$Boost.text = "Boost: +" + String(boost) + "%"

func _on_Up_pressed():
	upgrade_panel._upgrade(type)

func _on_Down_pressed():
	upgrade_panel._downgrade(type)
