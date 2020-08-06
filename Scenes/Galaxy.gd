extends Node2D

onready var game = self.get_parent().get_parent()
onready var stars_info = game.system_data[game.c_s]["stars"]
onready var star_graphic = preload("res://Graphics/Stars/M.png")
onready var systems_id = game.system_data[game.c_s]["systems"]

var stars

const DIST_MULT = 200.0
const SYSTEM_SCALE_DIV = 40.0
const STAR_SCALE_DIV = 5.0

func _ready():
	for star_info in stars_info:
		var star = Sprite.new()
		star.texture = star_graphic
		self.add_child(star)
		star.position = star_info["pos"]
		star.scale.x = star_info["size"] / STAR_SCALE_DIV
		star.scale.y = star_info["size"] / STAR_SCALE_DIV
	
	var systems_info = []
	for i in systems_id:
		systems_info.append(game.system_data[i])
	for s_i in systems_info:
		var star_btn = TextureButton.new()
		var system_glow = TextureButton.new()
		var system = Sprite.new()
		var star_texture = load("res://Graphics/Stars/M.png")
		var system_glow_texture = preload("res://Graphics/Misc/Glow.png")
		system_glow.texture_normal = system_glow_texture
		star_btn.texture_normal = star_texture
		self.add_child(system)
		system.add_child(system_glow)
		system.add_child(star_btn)
		star_btn.connect("mouse_entered", self, "on_system_over", [s_i["id"]])
		system_glow.connect("mouse_entered", self, "on_system_over", [s_i["id"]])
		star_btn.connect("mouse_exited", self, "on_system_out")
		system_glow.connect("mouse_exited", self, "on_system_out")
		star_btn.connect("pressed", self, "on_system_click", [s_i["id"]])
		system_glow.connect("pressed", self, "on_system_click", [s_i["id"]])
		star_btn.rect_position = Vector2(-768 / 2, -768 / 2)
		star_btn.rect_pivot_offset = Vector2(768 / 2, 768 / 2)
		star_btn.rect_scale.x = s_i["size"] / SYSTEM_SCALE_DIV
		star_btn.rect_scale.y = s_i["size"] / SYSTEM_SCALE_DIV
		system_glow.rect_pivot_offset = Vector2(100, 100)
		system_glow.rect_position = Vector2(-100, -100)
		#system_glow.rect_scale 
		match s_i["status"]:
			"conquered":
				system_glow.modulate = Color(0, 1, 0, 1)
			"unconquered":
				system_glow.modulate = Color(1, 0, 0, 1)
		system.position = s_i["pos"]

func on_system_over (id:int):
	var s_i = game.system_data[id]
	game.show_tooltip(s_i["name"] + "\nPlanets: " + String(s_i["planet_num"]))

func on_system_out ():
	game.hide_tooltip()

func on_system_click (id:int):
	game.c_p = id
	game.switch_view("system")
