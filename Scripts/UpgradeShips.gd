extends Panel

onready var op = $OptionButton
onready var game = get_node("/root/Game")

var Ship0_texture = preload("res://Graphics/Ships/Ship0.png")
var Ship1_texture = preload("res://Graphics/Ships/Ship1.png")
var Ship2_texture = preload("res://Graphics/Ships/Ship2.png")
var Ship3_texture = preload("res://Graphics/Ships/Ship3.png")
var ship:Dictionary

onready var Ship_textures = [Ship0_texture, Ship1_texture, Ship2_texture, Ship3_texture]

func _ready():
	_refresh_op()
	_refresh()

func _refresh():
	if game.ship_data:
		ship = game.ship_data[op.get_selected_id()]
		_pointfix(ship)
		$Ship/Ship.texture = Ship_textures[op.get_selected_id()]
		$Ship/Label.text = ship.name
		$Ship/Points.text = tr("YOU_HAVE_%s_POINTS_REMAINING") % ship.points
		for i in $Upgrades.get_children():
			i._refresh()

func _upgrade(stat:String):
	var stat_mult:String = "%s_mult" % stat
	if ship.points > 0:
		ship.points -= 1
		ship[stat_mult] += 0.1
		_refresh()
	else:
		game.popup(tr("CANT_AFFORD"), 1.5)

func _downgrade(stat:String):
	var stat_mult:String = "%s_mult" % stat
	if ship[stat_mult] > 0.9:
		ship.points += 1
		ship[stat_mult] -= 0.1
		_refresh()

func _on_OptionButton_item_selected(i):
	_refresh()

func _pointfix(ship):
	if not ship.has("max_points"):
		ship.max_points = 0
	var change = (2 + int(game.science_unlocked.UP2) + int(game.science_unlocked.UP3) + int(game.science_unlocked.UP4)) - ship.max_points
	ship.max_points += change
	ship.points += change

func _refresh_op():
	op.clear()
	for i in game.ship_data.size():
		op.add_item(game.ship_data[i].name, (i))
