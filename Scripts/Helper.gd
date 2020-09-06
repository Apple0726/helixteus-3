extends Node

onready var rsrc_scene = preload("res://Scenes/Resource.tscn")
onready var game = get_node("/root/Game")
#A place to put frequently used functions

func set_btn_color(btn):
	for other_btn in btn.get_parent_control().get_children():
		other_btn["custom_colors/font_color"] = Color(1, 1, 1, 1)
		other_btn["custom_colors/font_color_hover"] = Color(1, 1, 1, 1)
		other_btn["custom_colors/font_color_pressed"] = Color(1, 1, 1, 1)
	btn["custom_colors/font_color"] = Color(0, 1, 1, 1)
	btn["custom_colors/font_color_hover"] = Color(0, 1, 1, 1)
	btn["custom_colors/font_color_pressed"] = Color(0, 1, 1, 1)

func put_rsrc(container, min_size, objs, remove:bool = true):
	if remove:
		for child in container.get_children():
			container.remove_child(child)
	var data = []
	for obj in objs:
		var rsrc = rsrc_scene.instance()
		var texture = rsrc.get_node("Texture")
		if obj == "money":
			texture.texture_normal = load("res://Graphics/Icons/Money.png")
			rsrc.get_node("Text").text = String(objs[obj])
		elif obj == "stone":
			texture.texture_normal = load("res://Graphics/Icons/stone.png")
			rsrc.get_node("Text").text = String(objs[obj]) + " kg"
		elif obj == "energy":
			texture.texture_normal = load("res://Graphics/Icons/Energy.png")
			rsrc.get_node("Text").text = String(objs[obj])
		elif obj == "time":
			texture.texture_normal = load("res://Graphics/Icons/Time.png")
			rsrc.get_node("Text").text = time_to_str(objs[obj] * 1000.0)
		elif game.mats.has(obj):
			texture.texture_normal = load("res://Graphics/Materials/" + obj + ".png")
			rsrc.get_node("Text").text = String(objs[obj]) + " kg"
		elif game.mets.has(obj):
			texture.texture_normal = load("res://Graphics/Metals/" + obj + ".png")
			rsrc.get_node("Text").text = String(objs[obj]) + " kg"
		texture.rect_min_size = Vector2(1, 1) * min_size
		container.add_child(rsrc)
		data.append({"rsrc":rsrc, "name":obj})
	return data

#Converts time in milliseconds to string format
func time_to_str (time):
	var seconds = floor(time / 1000)
	var second_zero = "0" if seconds < 10 else ""
	var minutes = floor(seconds / 60)
	var minute_zero = "0" if minutes < 10 else ""
	var hours = floor(minutes / 60)
	var days = floor (hours / 24)
	var years = floor (days / 365)
	var year_str = "" if years == 0 else String(years) + "y "
	var day_str = "" if days == 0 else String(days) + "d "
	var hour_str = "" if hours == 0 else String(hours) + ":"
	return year_str + day_str + hour_str + minute_zero + String(minutes) + ":" + second_zero + String(seconds)
