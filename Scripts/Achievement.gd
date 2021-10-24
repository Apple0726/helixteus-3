tool
extends Panel

export var achievement_icon:Texture

func _ready():
	$TextureRect.texture = achievement_icon
