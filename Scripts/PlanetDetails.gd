extends Control

onready var game = get_node("/root/Game")
var id
var p_i
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
