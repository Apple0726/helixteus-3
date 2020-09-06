extends Node2D

onready var game = get_node("/root/Game")

var bldg_to_construct:String = ""
var constr_costs = {}
var id
var p_i
var tile_over = -1

func _ready():
	id = game.c_p
	p_i = game.planet_data[id]
	
	var tile_scene = preload("res://Scenes/Tile.tscn")
	var start_ind:int = p_i["tiles"][0]
	var wid:int = round(pow(p_i["tiles"].size(), 0.5))
	
	for i in range(0, p_i["tiles"].size()):
		var tile = tile_scene.instance()
		tile.id = i + start_ind
		tile.position = Vector2((i % wid - wid / 2.0) * 200, floor(i / wid - wid / 2.0) * 200) + Vector2(100, 100)
		add_child(tile)
		game.tiles.append(tile)

func _input(event):
	if tile_over != -1:
		if Input.is_action_just_released("duplicate"):
			var tile = game.tile_data[tile_over]
			if tile.bldg_str != "":
				game.put_bottom_info(tr("STOP_CONSTRUCTION"))
				bldg_to_construct = tile.bldg_str
				constr_costs = game.bldg_info[tile.bldg_str].costs
		if Input.is_action_just_released("upgrade"):
			game.add_upgrade_panel([tile_over])
