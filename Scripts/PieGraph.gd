extends VBoxContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

#Array of objects containing values, text, pie texture, modulate
#Values must be arranged in an increasing order (i.e. smallest number at index 0, largest at last index)
var objects:Array

var txts = []

func _ready():
	var last_value = 100.0
	for obj in objects:
		var pie = TextureProgress.new()
		#Angle where the text is placed
		var angle = (last_value / 100.0 - obj.value / 2.0) * 2 * PI - PI / 2.0
		pie.value = last_value
		last_value -= obj.value * 100.0
		pie.texture_progress = obj.texture
		pie.modulate = obj.modulate
		pie.set_fill_mode(pie.FILL_CLOCKWISE)
		$Pies.add_child(pie)
		var text = Label.new()
		$Pies.add_child(text)
		text.align = text.ALIGN_CENTER
		text.rect_position = polar2cartesian(85, angle) + Vector2(120, 120)
		text.text = obj.text
		text["custom_colors/font_color_shadow"] = Color(0, 0, 0, 1)
		text["custom_constants/shadow_as_outline"] = 1
		txts.append(text)
	for txt in txts:
		$Pies.move_child(txt, $Pies.get_child_count())
