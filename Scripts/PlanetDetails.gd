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
	$Atmosphere.visible = not p_i.atmosphere.empty()
	if not p_i.type in [11, 12]:#if not gas giant
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
	if p_i.type == 11:
		mantle_layer.get_node("Background").modulate = Color(0, 0.3, 0.6, 1)
	core_layer = layer_scene.instance()
	add_child(core_layer)
	core_layer.get_node("Shadow").visible = false
	core_layer.rect_scale *= 0.65 - 0.65 * p_i.core_start_depth / (p_i.size * 500.0)
	core_layer.get_node("Background").modulate = Color(1, 0.93, 0.63, 1)
	core_layer.rect_position = Vector2(654, 357)
	core_layer.get_node("Background").connect("mouse_entered", self, "on_core_enter")
	core_layer.get_node("Background").connect("mouse_exited", self, "on_core_exit")
	core_layer.get_node("Background").connect("pressed", self, "on_core_press")

var atm_always_visible = false
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
		var dir_str = "res://Graphics/Elements/" + obj.element + ".png"
		var texture
		if ResourceLoader.exists(dir_str):
			texture = load(dir_str)
		else:
			texture = preload("res://Graphics/Elements/Default.png")
		var pie_text = "%s\n%s%%" % [tr("%s_NAME" % obj.element.to_upper()), game.clever_round(obj.fraction * 100.0, 2)]
		pie.objects.append({"value":obj.fraction, "text":pie_text, "modulate":Helper.get_el_color(obj.element), "texture":texture})
	$ScrollContainer/VBoxContainer.add_child(pie)

func remove_pie_chart(_name:String):
	if $ScrollContainer/VBoxContainer.has_node(_name):
		var node = $ScrollContainer/VBoxContainer.get_node(_name)
		$ScrollContainer/VBoxContainer.remove_child(node)
		node.queue_free()

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
	Helper.save_obj("Systems", game.c_s_g, game.planet_data)
	game.switch_view("system")

func _on_Name_focus_exited():
	if $Name.text == "":
		$Name.text = p_i.name
	renaming = false

func _on_Name_focus_entered():
	renaming = true

func _on_Planet_mouse_entered():
	if game.planet_data[id].type == 11:
		game.show_tooltip(tr("SURFACE"))
	else:
		game.show_tooltip((tr("SURFACE") + "\n" + tr("DEPTHS") + ": 0 m - %s m\n" + tr("MATERIALS") + ":\n%s") % [p_i.crust_start_depth + 1, get_surface_string(p_i.surface)])

func get_surface_string(mats:Dictionary):
	var string = ""
	for mat in mats.keys():
		string += mat + ": " + String(mats[mat]) + "\n"
	string = string.substr(0,len(string) - 1)
	return string

func _on_Planet_mouse_exited():
	game.hide_tooltip()

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

func _input(event):
	Helper.set_back_btn($Back)


func _on_Atmosphere_mouse_entered():
	var tooltip = tr("ATMOSPHERE")
	if atm_always_visible:
		tooltip += "\nClick to hide atmospheric composition\nwhen not hovered over"
	else:
		tooltip += "\nClick to show atmospheric composition\neven when not hovered over"
		make_pie_chart(obj_to_array(p_i.atmosphere), tr("ATMOSPHERE_COMPOSITION"))
	game.show_tooltip(tooltip)

func _on_Atmosphere_mouse_exited():
	yield(get_tree().create_timer(0), "timeout")
	if not atm_always_visible:
		remove_pie_chart(tr("ATMOSPHERE_COMPOSITION"))
	game.hide_tooltip()


func _on_Atmosphere_pressed():
	atm_always_visible = not atm_always_visible
	var popup = "Set atmospheric composition pie chart: "
	if atm_always_visible:
		popup += "always visible"
	else:
		popup += "default"
	game.popup(popup, 1.5)


func _on_Control_tree_exited():
	queue_free()
