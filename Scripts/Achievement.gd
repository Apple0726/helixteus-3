@tool
extends Panel

@export var achievement_icon:Texture2D
@export var number:float = 0.0

func _ready():
	$TextureRect.texture = achievement_icon
	if number != 0.0 and not Engine.is_editor_hint():
		$Label.text = Helper.format_num(number, false, 3)
