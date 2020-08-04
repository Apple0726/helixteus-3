extends Node2D

onready var game = self.get_parent().get_parent()
var tiles:Array = []

var bldg_to_construct:String = ""
var id
var p_i

func _ready():
	id = game.c_p
	p_i = game.planet_data[id]
	#wid is number of tiles horizontally/vertically
	#So total number of tiles is wid squared
	var wid:int = round(pow(p_i["size"], 0.6) / 28)
	
	var tile_scene = preload("res://Scenes/Tile.tscn")
	#Tile generation
	for i in range(0, pow(wid, 2)):
		var tile = tile_scene.instance()
		tile.position = Vector2((i % wid) * 200, floor(i / wid) * 200)
		self.add_child(tile)
		tile.id = i
		tiles.append(tile)
