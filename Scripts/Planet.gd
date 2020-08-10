extends Node2D

onready var game = self.get_parent().get_parent()

var bldg_to_construct:String = ""
var id
var p_i

func _ready():
	id = game.c_p
	p_i = game.planet_data[id]
	
	var tile_scene = preload("res://Scenes/Tile.tscn")
	var start_ind:int = p_i["tiles"][0]
	var wid:int = pow(p_i["tiles"].size(), 0.5)
	
	for i in range(0, p_i["tiles"].size()):
		var tile = tile_scene.instance()
		tile.id = i + start_ind
		tile.position = Vector2((i % wid - wid / 2.0) * 200, floor(i / wid - wid / 2.0) * 200) + Vector2(100, 100)
		self.add_child(tile)
