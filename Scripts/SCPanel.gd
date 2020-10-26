extends "Panel.gd"

onready var pie = $PieGraph
func _ready():
	refresh()

func refresh():
	if not game.stone.empty():
		pie.get_node("Title").text = tr("STONE_COMPOSITION")
		pie.objects = []
		pie.other_str = tr("TRACE_ELEMENTS")
		pie.other_str_short = tr("TRACE")
		var total_stone = Helper.get_sum_of_dict(game.stone)
		var arr = obj_to_array(game.stone)
		for obj in arr:
			var directory = Directory.new()
			var dir_str = "res://Graphics/Elements/" + obj.element + ".png"
			var texture_exists = directory.file_exists(dir_str)
			var texture
			if texture_exists:
				texture = load(dir_str)
			else:
				texture = preload("res://Graphics/Elements/Default.png")
			var pie_text = obj.element + "\n" + String(game.clever_round(obj.fraction * 100.0, 2)) + "%"
			pie.objects.append({"value":obj.fraction, "text":pie_text, "modulate":Helper.get_el_color(obj.element), "texture":texture})
	pie.refresh()

func obj_to_array(elements:Dictionary):
	var arr = []
	for element in elements.keys():
		arr.append({"element":element, "fraction":elements[element] / Helper.get_sum_of_dict(game.stone)})
	arr.sort_custom(self, "sort_elements")
	return arr

func sort_elements (a, b):
	if a["fraction"] < b["fraction"]:
		return true
	return false
