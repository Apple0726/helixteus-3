extends Control

onready var game = get_node("/root/Game")
onready var layer_scene = preload("res://Scenes/Planet/PlanetComposition.tscn")
var id
var p_i
var crust_layer
var mantle_layer
var core_layer
var renaming = false

func _ready():
	id = game.c_p
	p_i = game.planet_data[id]
	var texture = load("res://Graphics/Planets/" + String(p_i.type) + ".png")
	$Planet.texture_normal = texture
	$Planet.texture_hover = texture
	$Planet.texture_focused = texture
	$Name.text = p_i.name
	$Diameter.text = String(round(p_i.size)) + " km"
	crust_layer = layer_scene.instance()
	add_child(crust_layer)
	crust_layer.get_node("Shadow").visible = false
	crust_layer.get_node("Background").modulate = Color(0.4, 0.22, 0, 1)
	crust_layer.rect_scale *= 0.65
	crust_layer.rect_position = Vector2(654, 357)
	crust_layer.get_node("Background").connect("mouse_entered", self, "on_crust_enter")
	crust_layer.get_node("Background").connect("mouse_exited", self, "on_crust_exit")
	crust_layer.get_node("Background").connect("pressed", self, "on_crust_press")
	mantle_layer = layer_scene.instance()
	add_child(mantle_layer)
	mantle_layer.rect_scale *= min(0.63, 0.65 - 0.65 * p_i.mantle_start_depth / (p_i.size * 500.0))
	mantle_layer.get_node("Background").modulate = Color(1, 0.56, 0, 1)
	mantle_layer.rect_position = Vector2(654, 357)
	mantle_layer.get_node("Background").connect("mouse_entered", self, "on_mantle_enter")
	mantle_layer.get_node("Background").connect("mouse_exited", self, "on_mantle_exit")
	mantle_layer.get_node("Background").connect("pressed", self, "on_mantle_press")
	core_layer = layer_scene.instance()
	add_child(core_layer)
	core_layer.get_node("Shadow").visible = false
	core_layer.rect_scale *= 0.65 - 0.65 * p_i.core_start_depth / (p_i.size * 500.0)
	core_layer.get_node("Background").modulate = Color(1, 0.93, 0.63, 1)
	core_layer.rect_position = Vector2(654, 357)
	core_layer.get_node("Background").connect("mouse_entered", self, "on_core_enter")
	core_layer.get_node("Background").connect("mouse_exited", self, "on_core_exit")
	core_layer.get_node("Background").connect("pressed", self, "on_core_press")
	$Back.text = "<- " + tr("BACK") + " (Z)"

var crust_always_visible = false
var mantle_always_visible = false
var core_always_visible = false

func on_crust_enter():
	var tooltip = (tr("CRUST") + "\n" + tr("DEPTHS") + ": %s m - %s m") % [p_i.crust_start_depth + 1, p_i.mantle_start_depth]
	if crust_always_visible:
		tooltip += "\nClick to hide crust composition\nwhen not hovered over"
	else:
		tooltip += "\nClick to show crust composition\neven when not hovered over"
	game.show_tooltip(tooltip)
	if not crust_always_visible:
		make_pie_chart(obj_to_array(p_i.crust), tr("CRUST_COMPOSITION"))

func on_mantle_enter():
	var tooltip = (tr("MANTLE") + "\n" + tr("DEPTHS") + ": %s km - %s km") % [floor(p_i.mantle_start_depth / 1000.0), floor(p_i.core_start_depth / 1000.0)]
	if mantle_always_visible:
		tooltip += "\nClick to hide mantle composition\nwhen not hovered over"
	else:
		tooltip += "\nClick to show mantle composition\neven when not hovered over"
	game.show_tooltip(tooltip)
	if not mantle_always_visible:
		make_pie_chart(obj_to_array(p_i.mantle), tr("MANTLE_COMPOSITION"))
	
func on_core_enter():
	var tooltip = (tr("CORE") + "\n" + tr("DEPTHS") + ": %s km - %s km") % [floor(p_i.core_start_depth / 1000.0), floor(p_i.size / 2.0)]
	if core_always_visible:
		tooltip += "\nClick to hide core composition\nwhen not hovered over"
	else:
		tooltip += "\nClick to show core composition\neven when not hovered over"
	game.show_tooltip(tooltip)
	if not core_always_visible:
		make_pie_chart(obj_to_array(p_i.core), tr("CORE_COMPOSITION"))

func on_crust_press():
	crust_always_visible = not crust_always_visible
	var popup = "Set crust composition pie chart: "
	if crust_always_visible:
		popup += "always visible"
	else:
		popup += "default"
	game.popup(popup, 1.5)

func on_mantle_press():
	mantle_always_visible = not mantle_always_visible
	var popup = "Set mantle composition pie chart: "
	if mantle_always_visible:
		popup += "always visible"
	else:
		popup += "default"
	game.popup(popup, 1.5)

func on_core_press():
	core_always_visible = not core_always_visible
	var popup = "Set core composition pie chart: "
	if core_always_visible:
		popup += "always visible"
	else:
		popup += "default"
	game.popup(popup, 1.5)

var pies:Array = []
var texts:Array = []
var pie_scene = preload("res://Scenes/PieGraph.tscn")
func make_pie_chart(arr:Array, name:String):
	var pie = pie_scene.instance()
	pie.name = name
	pie.get_node("Title").text = name
	pie.objects = []
	pie.other_str = tr("TRACE_ELEMENTS")
	pie.other_str_short = tr("TRACE")
	for obj in arr:
		var directory = Directory.new();
		var texture_exists = directory.file_exists("res://Graphics/Elements/" + obj.element + ".png")
		var texture
		if texture_exists:
			texture = load("res://Graphics/Elements/" + obj.element + ".png")
		else:
			texture = preload("res://Graphics/Elements/Default.png")
		var pie_text = obj.element + "\n" + String(game.clever_round(obj.fraction * 100.0, 2)) + "%"
		pie.objects.append({"value":obj.fraction, "text":pie_text, "modulate":get_el_color(obj.element), "texture":texture})
	$ScrollContainer/VBoxContainer.add_child(pie)

func remove_pie_chart(name:String):
	if $ScrollContainer/VBoxContainer.has_node(name):
		$ScrollContainer/VBoxContainer.remove_child($ScrollContainer/VBoxContainer.get_node(name))
		

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

func on_crust_exit():
	game.hide_tooltip()
	if not crust_always_visible:
		remove_pie_chart(tr("CRUST_COMPOSITION"))

func on_mantle_exit():
	game.hide_tooltip()
	if not mantle_always_visible:
		remove_pie_chart(tr("MANTLE_COMPOSITION"))

func on_core_exit():
	game.hide_tooltip()
	if not core_always_visible:
		remove_pie_chart(tr("CORE_COMPOSITION"))

func _on_Back_pressed():
	p_i.name = $Name.text
	game.switch_view("system")


func _on_Name_focus_exited():
	if $Name.text == "":
		$Name.text = p_i.name
	renaming = false

func _on_Name_focus_entered():
	renaming = true

func _on_Planet_mouse_entered():
	game.show_tooltip((tr("SURFACE") + "\n" + tr("DEPTHS") + ": 0 m - %s m\n" + tr("MATERIALS") + ":\n%s") % [p_i.crust_start_depth + 1, get_surface_string(p_i.surface)])

func get_surface_string(mats:Dictionary):
	var string = ""
	for mat in mats.keys():
		string += mat + ": " + String(mats[mat]) + "\n"
	string = string.substr(0,len(string) - 1)
	return string

func obj_to_array(elements:Dictionary):
	var arr = []
	for element in elements.keys():
		arr.append({"element":element, "fraction":elements[element]})
	arr.sort_custom(self, "sort_elements")
	return arr

func sort_elements (a, b):
	if a["fraction"] < b["fraction"]:
		return true
	return false

func _on_Planet_mouse_exited():
	game.hide_tooltip()
