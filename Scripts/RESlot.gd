tool
extends Panel
export var texture:Texture

func _ready():
	$TextureRect.texture = texture
