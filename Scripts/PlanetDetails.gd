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
	crust_layer.rect_position = Vector2(664, 352)
	crust_layer.get_node("Background").connect("mouse_entered", self, "on_crust_enter")
	crust_layer.get_node("Background").connect("mouse_exited", self, "on_exit")
	mantle_layer = layer_scene.instance()
	add_child(mantle_layer)
	mantle_layer.rect_scale *= 0.6
	mantle_layer.get_node("Background").modulate = Color(1, 0.56, 0, 1)
	mantle_layer.rect_position = Vector2(664, 352)
	mantle_layer.get_node("Background").connect("mouse_entered", self, "on_mantle_enter")
	mantle_layer.get_node("Background").connect("mouse_exited", self, "on_exit")
	core_layer = layer_scene.instance()
	add_child(core_layer)
	core_layer.get_node("Shadow").visible = false
	core_layer.rect_scale *= 0.3
	core_layer.get_node("Background").modulate = Color(1, 0.93, 0.63, 1)
	core_layer.rect_position = Vector2(664, 352)
	core_layer.get_node("Background").connect("mouse_entered", self, "on_core_enter")
	core_layer.get_node("Background").connect("mouse_exited", self, "on_exit")

func on_crust_enter():
	game.show_tooltip("Crust\nDepths: " + String(p_i.crust_start_depth + 1) + " m - " + String(p_i.mantle_start_depth) + " m\nComposition: " + get_surface_string(p_i.crust))

func on_mantle_enter():
	game.show_tooltip("Mantle\nDepths: " + String(floor(p_i.mantle_start_depth / 1000.0)) + " km - " + String(floor(p_i.core_start_depth / 1000.0)) + " km\nComposition: " + get_surface_string(p_i.mantle))
	
func on_core_enter():
	game.show_tooltip("Core\nDepths: " + String(floor(p_i.core_start_depth / 1000.0)) + " km - " + String(floor(p_i.size / 2.0)) + " km\nComposition: " + get_surface_string(p_i.core))

func on_exit():
	game.hide_tooltip()
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
	game.show_tooltip("Surface\nDepths: 0 m - " + String(p_i.crust_start_depth) + " m\nMaterials:\n" + get_surface_string(p_i.surface))

func get_surface_string(mats:Dictionary):
	var string = ""
	for mat in mats.keys():
		string += mat + ": " + String(mats[mat]) + "\n"
	string = string.substr(0,len(string) - 1)
	return string


func _on_Planet_mouse_exited():
	game.hide_tooltip()
