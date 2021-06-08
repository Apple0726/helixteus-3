extends Panel

onready var op = $OptionButton
onready var game = get_node("/root/Game")

var Ship0_texture = preload("res://Graphics/Ships/Ship0.png")
var Ship1_texture = preload("res://Graphics/Ships/Ship1.png")
var Ship2_texture = preload("res://Graphics/Ships/Ship2.png")
var Ship3_texture = preload("res://Graphics/Ships/Ship3.png")
var points = 0

var costs = [0,1,2,4,8]
var lvs = [0,0,0,0,0]

onready var Ship_textures = [Ship0_texture, Ship1_texture, Ship2_texture, Ship3_texture]

func _ready():
	for i in game.ship_data.size():
		op.add_item(game.ship_data[i].name, (i))

func _refresh():
	if game.ship_data:
		var upgrades = game.ship_data[op.get_selected_id()].upgrades
		for i in 5:
			lvs[i] = (int((upgrades[i]-1)*100)/10)

func _upgrade(id):
	if (costs[lvs[id]]+1) <= points:
		points = points - (costs[lvs[id]]+1)
		game.ship_data[op.get_selected_id()].upgrades[id] = game.ship_data[op.get_selected_id()].upgrades[id] + 0.1
		$Upgrades.get_children()[id]._refresh(op.get_selected_id())
		$Ship/Points.text = tr("YOU_HAVE_%s_POINTS_REMAINING" % points)
		$Stats._display_upgrades(id)
		_refresh()
	else:
		game.popup(tr("CANT_AFFORD"), 1.5)

func _downgrade(id):
	if lvs[id] != 0:
		points = points + (costs[lvs[id]])
		game.ship_data[op.get_selected_id()].upgrades[id] = game.ship_data[op.get_selected_id()].upgrades[id] - 0.1
		$Upgrades.get_children()[id]._refresh(op.get_selected_id())
		$Ship/Points.text = tr("YOU_HAVE_%s_POINTS_REMAINING" % points)
		$Stats._display_upgrades(id)
		_refresh()

func _on_OptionButton_item_selected(i):
	$Ship/Ship.texture = Ship_textures[(i)]
	$Ship/Label.text = game.ship_data[(i)].name
	var upgrades = game.ship_data[i].upgrades
	for i in 5:
		lvs[i] = (int((upgrades[i]-1)*100)/10)
	points = 2
	if game.science_unlocked.UP2:
		points = points + 1
	if game.science_unlocked.UP3:
		points = points + 1
	if game.science_unlocked.UP4:
		points = points + 1
	points = points - costs[lvs[0]] - costs[lvs[1]] - costs[lvs[2]] - costs[lvs[3]] - costs[lvs[4]]
	$Ship/Points.text = tr("YOU_HAVE_%s_POINTS_REMAINING" % points)
