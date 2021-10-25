tool
extends Panel

export var achievement_icon:Texture
export var number:float = 0.0

func _ready():
	$TextureRect.texture = achievement_icon
	if number != 0.0 and not Engine.editor_hint:
		$Label.text = Helper.format_num(number, 3)
