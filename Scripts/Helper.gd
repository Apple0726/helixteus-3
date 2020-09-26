extends Node

onready var rsrc_scene = preload("res://Scenes/Resource.tscn")
#onready var game = get_node("/root/Game")
var game
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

func put_rsrc(container, min_size, objs, remove:bool = true, show_available:bool = false):
	if remove:
		for child in container.get_children():
			container.remove_child(child)
	var data = []
	for obj in objs:
		var rsrc = rsrc_scene.instance()
		var texture = rsrc.get_node("Texture")
		var text = ""
		var color = Color(1.0, 1.0, 1.0, 1.0)
		if obj == "money":
			texture.texture_normal = load("res://Graphics/Icons/Money.png")
			if show_available:
				text = String(game.money) + "/" + String(objs[obj])
				if game.money >= objs[obj]:
					color = Color(0.0, 1.0, 0.0, 1.0)
				else:
					color = Color(1.0, 0.0, 0.0, 1.0)
			else:
				text = String(objs[obj])
		elif obj == "stone":
			texture.texture_normal = load("res://Graphics/Icons/stone.png")
			if show_available:
				text = String(game.stone) + "/" + String(objs[obj]) + " kg"
				if game.stone >= objs[obj]:
					color = Color(0.0, 1.0, 0.0, 1.0)
				else:
					color = Color(1.0, 0.0, 0.0, 1.0)
			else:
				text = String(objs[obj]) + " kg"
		elif obj == "energy":
			texture.texture_normal = load("res://Graphics/Icons/Energy.png")
			if show_available:
				text = String(game.energy) + "/" + String(objs[obj])
				if game.energy >= objs[obj]:
					color = Color(0.0, 1.0, 0.0, 1.0)
				else:
					color = Color(1.0, 0.0, 0.0, 1.0)
			else:
				text = String(objs[obj])
		elif obj == "time":
			texture.texture_normal = load("res://Graphics/Icons/Time.png")
			text = time_to_str(objs[obj] * 1000.0)
		elif game.mats.has(obj):
			texture.texture_normal = load("res://Graphics/Materials/" + obj + ".png")
			if show_available:
				text = String(game.mats[obj]) + "/" + String(objs[obj]) + " kg"
				if game.mats[obj] >= objs[obj]:
					color = Color(0.0, 1.0, 0.0, 1.0)
				else:
					color = Color(1.0, 0.0, 0.0, 1.0)
			else:
				text = String(objs[obj]) + " kg"
		elif game.mets.has(obj):
			texture.texture_normal = load("res://Graphics/Metals/" + obj + ".png")
			if show_available:
				text = String(game.mets[obj]) + "/" + String(objs[obj]) + " kg"
				if game.mets[obj] >= objs[obj]:
					color = Color(0.0, 1.0, 0.0, 1.0)
				else:
					color = Color(1.0, 0.0, 0.0, 1.0)
			else:
				text = String(objs[obj]) + " kg"
		rsrc.get_node("Text").text = text
		rsrc.get_node("Text")["custom_colors/font_color"] = color
		texture.rect_min_size = Vector2(1, 1) * min_size
		container.add_child(rsrc)
		data.append({"rsrc":rsrc, "name":obj})
	return data

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

func get_type_from_name(name:String):
	if name.substr(0, 7) == "speedup":
		return "speedup_info"
	if name.substr(0, 9) == "overclock":
		return "overclock_info"
	match name:
		"lead_seeds", "fertilizer":
			return "craft_agric_info"
