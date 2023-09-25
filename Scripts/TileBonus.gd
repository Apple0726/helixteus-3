extends ColorRect
@onready var label = $TileBonus/Label
@onready var texture_rect = $TileBonus/TextureRect

func set_icon(texture):
	texture_rect.texture = texture

func set_multiplier(mult:float):
	label.text = "x %s" % Helper.clever_round(mult)
	var c:Color
	if mult < 5.0:
		c = lerp(Color.WHITE, Color.GREEN, (mult - 1.0) / 4.0)
	else:
		var hue:float = 0.4 + log(mult - 4.0) / 10.0
		var sat:float = 1.0 - floor(hue - 0.4) / 5.0
		c = Color.from_hsv(fmod(hue, 1.0), sat, 1.0) * max(log(mult - 5.0) / 10.0, 1.0)
	label["theme_override_colors/font_color"] = c.lightened(0.1)
	label["theme_override_colors/font_shadow_color"] = c.lightened(0.4)
	color = c
	color.a = 0.0
