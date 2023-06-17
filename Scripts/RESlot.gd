@tool
extends Panel
@export var texture:Texture2D

func _ready():
	$TextureRect.texture = texture
