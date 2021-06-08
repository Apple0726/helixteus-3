extends Node

onready var game = get_node("/root/Game")

var lv = 0
var boost = 0

func get_type(name):
	match name:
		"Hp":
			return 0
		"Atk":
			return 1
		"Def":
			return 2
		"Acc":
			return 3
		"Eva":
			return 4

func _refresh(i):
	boost = int((game.ship_data[i].upgrades[get_type(self.name)]-1)*100)
	lv = boost / 10
	$Level.text = "Lv " + String(lv)
	$Boost.text = "+" + String(boost) + "%"

func _on_Up_pressed():
	get_parent().get_parent()._upgrade(get_type(self.name))

func _on_Down_pressed():
	get_parent().get_parent()._downgrade(get_type(self.name))

func _on_OptionButton_item_selected(i):
	_refresh(i)
