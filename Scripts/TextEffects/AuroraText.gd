tool
extends RichTextEffect
class_name AuroraText

var bbcode = "aurora"

func _process_custom_fx(char_fx):
	var au_int:float = char_fx.env.get("au_int", 15.0)
	var hue:float = 0.4 + log(au_int * range_lerp(sin(char_fx.elapsed_time * 4.0 + char_fx.relative_index * 0.15), -1, 1, 1.0, 2.0) + 1.0) / 10.0
	char_fx.color = Color.from_hsv(fmod(hue, 1.0), 0.7, 1.0)
	return true
