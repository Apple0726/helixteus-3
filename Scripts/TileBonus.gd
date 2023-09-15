extends Panel

func set_icon(texture):
	$TextureRect.texture = texture

func set_multiplier(mult:float):
	$Label.text = "x %s" % Helper.clever_round(mult)
