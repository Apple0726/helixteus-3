extends Node2D

var dir:String
var rsrc_name:String
var amount:int

func _ready():
	var rsrc_texture = load("res://Graphics/%s/%s.png" % [dir, rsrc_name])
	for i in amount:
		var rsrc = Sprite.new()
		add_child(rsrc)
		rsrc.scale *= rand_range(0.1, 0.15)
		rsrc.rotation = rand_range(0, 2 * PI)
		rsrc.texture = rsrc_texture
		rsrc.position.x = rand_range(20, 180)
		rsrc.position.y = rand_range(20, 180)
