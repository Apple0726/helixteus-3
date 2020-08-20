extends Node2D

onready var game = self.get_parent().get_parent()
onready var galaxies_id = game.cluster_data[game.c_c]["galaxies"]

const DIST_MULT = 200.0

func _ready():
	var galaxies_info = []
	for i in galaxies_id:
		galaxies_info.append(game.galaxy_data[i])
	for g_i in galaxies_info:
		var galaxy_btn = TextureButton.new()
		var galaxy = Sprite.new()
		var galaxy_texture = load("res://Graphics/Galaxies/" + String(g_i["type"]) + ".png")
		galaxy_btn.texture_normal = galaxy_texture
		self.add_child(galaxy)
		galaxy.add_child(galaxy_btn)
		galaxy_btn.connect("mouse_entered", self, "on_galaxy_over", [g_i["id"]])
		galaxy_btn.connect("mouse_exited", self, "on_galaxy_out")
		galaxy_btn.connect("pressed", self, "on_galaxy_click", [g_i["id"]])
		galaxy_btn.rect_position = Vector2(-358 / 2, -199 / 2)
		galaxy_btn.rect_pivot_offset = Vector2(358 / 2, 199 / 2)
		galaxy_btn.rect_rotation = rad2deg(g_i["rotation"])
		var radius = pow(g_i["system_num"] / game.GALAXY_SCALE_DIV, 0.7)
		galaxy_btn.rect_scale.x = radius
		galaxy_btn.rect_scale.y = radius
		galaxy.position = g_i["pos"]

func on_galaxy_over (id:int):
	var g_i = game.galaxy_data[id]
	game.show_tooltip(g_i["name"] + "\nSystems: " + String(g_i["system_num"]))

func on_galaxy_out ():
	game.hide_tooltip()

func on_galaxy_click (id:int):
	var view = self.get_parent()
	if not view.dragged:
		game.c_g = id
		game.switch_view("galaxy")
	view.dragged = false
