extends Node2D

onready var game = self.get_parent().get_parent()
onready var systems_id = game.galaxy_data[game.c_g]["systems"]

var stars

const DIST_MULT = 200.0

func _ready():
	var systems_info = []
	for i in systems_id:
		systems_info.append(game.system_data[i])
	for s_i in systems_info:
		var star = s_i["stars"][0]
		var star_btn = TextureButton.new()
		var system = Sprite.new()
		var star_texture = preload("res://Graphics/Stars/Star.png")
		star_btn.texture_normal = star_texture
		star_btn.modulate = game.get_star_modulate(star["class"])
		self.add_child(system)
		system.add_child(star_btn)
		star_btn.connect("mouse_entered", self, "on_system_over", [s_i["id"]])
		star_btn.connect("mouse_exited", self, "on_system_out")
		star_btn.connect("pressed", self, "on_system_click", [s_i["id"]])
		star_btn.rect_position = Vector2(-600 / 2, -600 / 2)
		star_btn.rect_pivot_offset = Vector2(600 / 2, 600 / 2)
		var radius = pow(star["size"] / game.SYSTEM_SCALE_DIV, 0.35)
		star_btn.rect_scale.x = radius
		star_btn.rect_scale.y = radius
		system.position = s_i["pos"]

func on_system_over (id:int):
	var s_i = game.system_data[id]
	game.show_tooltip(tr("SYSTEM_INFO") % [s_i.name, s_i.planet_num])

func on_system_out ():
	game.hide_tooltip()

func on_system_click (id:int):
	var view = self.get_parent()
	if not view.dragged:
		game.c_s = id
		game.switch_view("system")
	view.dragged = false
