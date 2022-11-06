class_name Debris
extends StaticBody2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var id:int
var sprite_frame:int


# Called when the node enters the scene tree for the first time.
func _ready():
	$Sprite.frame = sprite_frame


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
