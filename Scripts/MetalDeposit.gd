extends Node2D

var rsrc_name:String
var rsrc_texture
var amount:int

func _ready():
	for i in amount:
		var rsrc = Sprite2D.new()
		rsrc.texture = rsrc_texture
		add_child(rsrc)
		rsrc.scale *= randf_range(0.1, 0.15)
		rsrc.rotation = randf_range(0, 2 * PI)
		rsrc.position.x = randf_range(20, 180)
		rsrc.position.y = randf_range(20, 180)
