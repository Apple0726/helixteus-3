@tool
extends Button

@export var texture:Texture2D

func _ready():
	$Icon.texture = texture

func set_mod(filtered:bool):
	if filtered:
		$Icon.modulate = Color(0.2, 0.2, 0.2, 0.6)
	else:
		$Icon.modulate = Color.WHITE
