extends Panel
@onready var label = $Label
@onready var texture_rect = $TextureRect

func set_icon(texture):
	texture_rect.texture = texture

func set_multiplier(mult:float):
	label.text = "x %s" % Helper.clever_round(mult)
