extends Node

onready var rsrc_scene = preload("res://Scenes/Resource.tscn")
onready var game = get_node("/root/Game")
#var game
#A place to put frequently used functions

func set_btn_color(btn):
	if not btn.get_parent_control():
		return
	for other_btn in btn.get_parent_control().get_children():
		other_btn["custom_colors/font_color"] = Color(1, 1, 1, 1)
		other_btn["custom_colors/font_color_hover"] = Color(1, 1, 1, 1)
		other_btn["custom_colors/font_color_pressed"] = Color(1, 1, 1, 1)
	btn["custom_colors/font_color"] = Color(0, 1, 1, 1)
	btn["custom_colors/font_color_hover"] = Color(0, 1, 1, 1)
	btn["custom_colors/font_color_pressed"] = Color(0, 1, 1, 1)

#put_rsrc helper function
func format_text(text_node, texture, path:String, show_available:bool, rsrc_cost, rsrc_available, mass_str:String = "", threshold:int = 6):
	texture.texture_normal = load("res://Graphics/" + path + ".png")
	var text:String
	var color:Color = Color(1.0, 1.0, 1.0, 1.0)
	if show_available:
		text = "%s/%s" % [format_num(rsrc_available, threshold / 2), format_num(rsrc_cost, threshold / 2)] + mass_str
		if rsrc_available >= rsrc_cost:
			color = Color(0.0, 1.0, 0.0, 1.0)
		else:
			color = Color(1.0, 0.0, 0.0, 1.0)
	else:
		text = format_num(rsrc_cost, threshold) + mass_str
	text_node.text = text
	text_node["custom_colors/font_color"] = color

func put_rsrc(container, min_size, objs, remove:bool = true, show_available:bool = false):
	if remove:
		for child in container.get_children():
			container.remove_child(child)
	var data = []
	for obj in objs:
		var rsrc = rsrc_scene.instance()
		var texture = rsrc.get_node("Texture")
		if obj == "money":
			format_text(rsrc.get_node("Text"), texture, "Icons/money", show_available, objs[obj], game.money)
		elif obj == "stone":
			format_text(rsrc.get_node("Text"), texture, "Icons/stone", show_available, objs[obj], game.stone, " kg")
		elif obj == "minerals":
			format_text(rsrc.get_node("Text"), texture, "Icons/minerals", show_available, objs[obj], game.minerals)
		elif obj == "energy":
			format_text(rsrc.get_node("Text"), texture, "Icons/Energy", show_available, objs[obj], game.energy)
		elif obj == "time":
			texture.texture_normal = load("res://Graphics/Icons/Time.png")
			rsrc.get_node("Text").text = time_to_str(objs[obj] * 1000.0)
		elif game.mats.has(obj):
			format_text(rsrc.get_node("Text"), texture, "Materials/" + obj, show_available, objs[obj], game.mats[obj], " kg")
		elif game.mets.has(obj):
			format_text(rsrc.get_node("Text"), texture, "Metals/" + obj, show_available, objs[obj], game.mets[obj], " kg")
		else:
			for item_group_info in game.item_groups:
				if item_group_info.dict.has(obj):
					format_text(rsrc.get_node("Text"), texture, item_group_info.path + "/" + obj, show_available, objs[obj], game.get_item_num(obj))
		rsrc.get_node("Texture").connect("mouse_entered", self, "on_rsrc_over", [tr(obj.to_upper())])
		rsrc.get_node("Texture").connect("mouse_exited", self, "on_rsrc_out")
		texture.rect_min_size = Vector2(1, 1) * min_size
		container.add_child(rsrc)
		data.append({"rsrc":rsrc, "name":obj})
	return data

func on_rsrc_over(st:String):
	game.show_tooltip(st)

func on_rsrc_out():
	game.hide_tooltip()

#Converts time in milliseconds to string format
func time_to_str (time:float):
	var seconds = int(floor(time / 1000)) % 60
	var second_zero = "0" if seconds < 10 else ""
	var minutes = int(floor(time / 60000)) % 60
	var minute_zero = "0" if minutes < 10 else ""
	var hours = int(floor(time / 3600000)) % 24
	var days = int(floor (time / 86400000)) % 365
	var years = int(floor (time / 31536000000))
	var year_str = "" if years == 0 else String(years) + "y "
	var day_str = "" if days == 0 else String(days) + "d "
	var hour_str = "" if hours == 0 else String(hours) + ":"
	return year_str + day_str + hour_str + minute_zero + String(minutes) + ":" + second_zero + String(seconds)

#Returns a random integer between low and high inclusive
func rand_int(low:int, high:int):
	return randi() % (high - low + 1) + low

func log10(n):
	return log(n) / log(10)

func get_state(T:float, P:float, node):
	var v = Vector2(T / 750.0 * 832, -floor(log(P) / log(10)) * 576 / 12.0 + 290)
	if Geometry.is_point_in_polygon(v, node.get_node("Superfluid").polygon):
		return "SF"
	elif Geometry.is_point_in_polygon(v, node.get_node("Liquid").polygon):
		return "L"
	elif Geometry.is_point_in_polygon(v, node.get_node("Gas").polygon):
		return "G"
	else:
		return "S"

func set_visibility(node):
	for other_node in node.get_parent_control().get_children():
		other_node.visible = false
	node.visible = true

func get_item_name (name:String):
	if name.substr(0, 7) == "speedup":
		return tr("SPEED_UP") + " " + game.get_roman_num(int(name.substr(7, 1)))
	if name.substr(0, 9) == "overclock":
		return tr("OVERCLOCK") + " " + game.get_roman_num(int(name.substr(9, 1)))
	match name:
		"lead_seeds":
			return tr("LEAD_SEEDS")
		"fertilizer":
			return tr("FERTILIZER")
		"stick":
			return tr("STICK")
		"wooden_pickaxe":
			return tr("WOODEN_PICKAXE")
		"stone_pickaxe":
			return tr("STONE_PICKAXE")
		"lead_pickaxe":
			return tr("LEAD_PICKAXE")
		"copper_pickaxe":
			return tr("COPPER_PICKAXE")
		"iron_pickaxe":
			return tr("IRON_PICKAXE")
		"hx_core":
			return tr("HX_CORE")

func get_plant_name(name:String):
	match name:
		"lead_seeds":
			return tr("PLANT_TITLE").format({"metal":tr("LEAD")})

func get_plant_produce(name:String):
	match name:
		"lead_seeds":
			return "lead"

func get_wid(size:float):
	return min(round(pow(size / 4000.0, 0.7) * 8.0) + 3, 250)

func get_dir_from_name(name:String):
	if name.substr(0, 7) == "speedup":
		return "Items/Speedups"
	if name.substr(0, 9) == "overclock":
		return "Items/Overclocks"
	match name:
		"lead_seeds", "fertilizer":
			return "Agriculture"
		"money":
			return "Icons"
		"minerals":
			return "Icons"
		"hx_core":
			return "Items/Others"

func get_type_from_name(name:String):
	if name.substr(0, 7) == "speedup":
		return "speedup_info"
	if name.substr(0, 9) == "overclock":
		return "overclock_info"
	match name:
		"lead_seeds", "fertilizer":
			return "craft_agric_info"

func format_num(num:float, threshold:int):
	if num < pow(10, threshold):
		var string = str(num)
		var arr = string.split(".")
		if len(arr) == 1:
			arr.append("")
		else:
			arr[1] = "." + arr[1]
		var mod = arr[0].length() % 3
		var res = ""
		for i in range(0, arr[0].length()):
			if i != 0 and i % 3 == mod:
				res += ","
			res += string[i]
		return res + arr[1]
	else:
		var suff:String = ""
		var p = floor(log10(num))
		var div = max(pow(10, stepify(p - 1, 3)), 1)
		if p >= 3 and p < 6:
			suff = "k"
		elif p < 9:
			suff = "M"
		elif p < 12:
			suff = "G"
		return "%s%s" % [game.clever_round(num / div, 3), suff]

#Assumes that all values of dict are floats/integers
func get_sum_of_dict(dict:Dictionary):
	var sum = 0
	for el in dict.values():
		sum += el
	return sum

func get_el_color(element:String):
	match element:
		"O":
			return Color(1, 0.2, 0.2, 1)
		"Si":
			return Color(0.7, 0.7, 0.7, 1)
		"Ca":
			return Color(0.8, 1, 0.8, 1)
		"Al":
			return Color(0.6, 0.6, 0.6, 1)
		"Mg":
			return Color(0.69, 0.69, 0.53, 1)
		"Na":
			return Color(0.92, 0.98, 1, 1)
		"Ni":
			return Color(0.9, 0.9, 0.9, 1)
		"H", "Fe":
			return Color(1, 1, 1, 1)
		_:
			return Color(randf(), randf(), randf(), 1)

func mult_dict_by(dict:Dictionary, value:float):
	var dict2:Dictionary = dict.duplicate(true)
	for el in dict:
		dict2[el] = dict[el] * value
	return dict2

func get_crush_info(tile_obj):
	var time = OS.get_system_time_msecs()
	var crush_spd = tile_obj.path_1_value
	var progress = (time - tile_obj.start_date) / 1000.0 * crush_spd / tile_obj.stone_qty
	var qty_left = max(0, round(tile_obj.stone_qty - (time - tile_obj.start_date) / 1000.0 * tile_obj.path_1_value))
	return {"crush_spd":crush_spd, "progress":progress, "qty_left":qty_left}
