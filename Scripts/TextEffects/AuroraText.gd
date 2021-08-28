tool
extends RichTextEffect
class_name AuroraText

var bbcode = "aurora"

func _process_custom_fx(char_fx):
	var au_int:float = char_fx.env.get("au_int", 15.0)
	var a:float = pow(au_int * range_lerp(sin(char_fx.elapsed_time * 4.0 + char_fx.relative_index * 0.15), -1, 1, 1.0, 2.0), 0.35) - pow(4, 0.25)
	var hue:float = 0.4 + max(0, a) / 10.0
	char_fx.color = Color.from_hsv(fmod(hue, 1.0), 0.7, clamp(0.6 + range_lerp(a, -1.0, 0.0, 0.0, 0.4), 0.6, 1.0))
	return true
