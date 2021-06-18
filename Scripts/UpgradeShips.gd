extends Panel

onready var op = $OptionButton
onready var game = get_node("/root/Game")

var Ship0_texture = preload("res://Graphics/Ships/Ship0.png")
var Ship1_texture = preload("res://Graphics/Ships/Ship1.png")
var Ship2_texture = preload("res://Graphics/Ships/Ship2.png")
var Ship3_texture = preload("res://Graphics/Ships/Ship3.png")
var ship:Dictionary

var costs = [0,1,2,4,8]
var totals = [0,1,3,7,15]
var lvs = [0,0,0,0,0]

onready var Ship_textures = [Ship0_texture, Ship1_texture, Ship2_texture, Ship3_texture]

func _ready():
	for i in game.ship_data.size():
		op.add_item(game.ship_data[i].name, (i))

func _refresh():
	if game.ship_data:
		ship = game.ship_data[op.get_selected_id()]
		$Ship/Ship.texture = Ship_textures[op.get_selected_id()]
		$Ship/Label.text = ship.name
		$Ship/Points.text = tr("YOU_HAVE_%s_POINTS_REMAINING") % ship.points

func _upgrade(stat:String):
	var stat_mult:String = "%s_mult" % stat
	if ship.points > 0:
		ship.points -= 1
		ship.upgrades[stat_mult] += 0.1
		$Upgrades.get_node(stat_mult)._refresh(op.get_selected_id())
		$Stats._display_upgrades(stat_mult)
		_refresh()
	else:
		game.popup(tr("CANT_AFFORD"), 1.5)

func _downgrade(stat:String):
	var stat_mult:String = "%s_mult" % stat
	if ship.upgrades[stat_mult] != 0:
		ship.points += 1
		ship.upgrades[stat_mult] -= 0.1
		$Upgrades.get_node(stat_mult)._refresh(op.get_selected_id())
		$Stats._display_upgrades(stat_mult)
		_refresh()

func _on_OptionButton_item_selected(i):
	_refresh()
