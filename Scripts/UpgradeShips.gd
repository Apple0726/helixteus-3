extends Panel

onready var op = $OptionButton
onready var game = get_node("/root/Game")

var Ship0_texture = preload("res://Graphics/Ships/Ship0.png")
var Ship1_texture = preload("res://Graphics/Ships/Ship1.png")
var Ship2_texture = preload("res://Graphics/Ships/Ship2.png")
var Ship3_texture = preload("res://Graphics/Ships/Ship3.png")

onready var Ship_textures = [Ship0_texture, Ship1_texture, Ship2_texture, Ship3_texture]

func _ready():
	for i in game.ship_data.size():
		op.add_item(game.ship_data[i].name, (i))
		#op.set_item_metadata(i, i)
	op.selected = -1

func _on_OptionButton_item_selected(id):
	$Ship/Ship.texture = Ship_textures[(id)]
	$Ship/Label.text = game.ship_data[(id)].name
