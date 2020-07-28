extends Node2D

onready var planet_tiles_scene = preload("res://Scenes/Planet.tscn")

func _ready():
	pass # Replace with function body.


func _load_game():
	self.remove_child($Title)
	var planet_tiles = planet_tiles_scene.instance()
	self.add_child(planet_tiles)
