extends Node2D

onready var game = self.get_parent().get_parent()
onready var stars_info = game.system_data[game.c_s]["stars"]
onready var star_graphic = preload("res://Graphics/Stars/M.png")
onready var planets_id = game.system_data[game.c_s]["planets"]

var stars

const DIST_MULT = 200.0
const PLANET_SCALE_DIV = 400000.0
const STAR_SCALE_DIV = 5.0

func _ready():
	for star_info in stars_info:
		var star = Sprite.new()
		star.texture = star_graphic
		self.add_child(star)
		star.position = star_info["pos"]
		star.scale.x = star_info["size"] / STAR_SCALE_DIV
		star.scale.y = star_info["size"] / STAR_SCALE_DIV
	
	var orbit_scene = preload("res://Scenes/Orbit.tscn")
	var planets_info = []
	for i in planets_id:
		planets_info.append(game.planet_data[i])
	for p_i in planets_info:
		var orbit = orbit_scene.instance()
		orbit.radius = p_i["distance"] * DIST_MULT
		self.add_child(orbit)
		var planet_btn = TextureButton.new()
		var planet_glow = TextureButton.new()
		var planet = Sprite.new()
		var planet_texture = load("res://Graphics/Planets/" + String(p_i["type"]) + ".png")
		var planet_glow_texture = preload("res://Graphics/Misc/Glow.png")
		planet_btn.texture_normal = planet_texture
		planet_glow.texture_normal = planet_glow_texture
		self.add_child(planet)
		planet.add_child(planet_glow)
		planet.add_child(planet_btn)
		planet_btn.connect("mouse_entered", self, "on_planet_over", [p_i["id"]])
		planet_glow.connect("mouse_entered", self, "on_planet_over", [p_i["id"]])
		planet_btn.connect("mouse_exited", self, "on_planet_out")
		planet_glow.connect("mouse_exited", self, "on_planet_out")
		planet_btn.connect("pressed", self, "on_planet_click", [p_i["id"]])
		planet_glow.connect("pressed", self, "on_planet_click", [p_i["id"]])
		planet_btn.rect_position = Vector2(-320, -320)
		planet_btn.rect_pivot_offset = Vector2(320, 320)
		planet_btn.rect_scale.x = p_i["size"] / PLANET_SCALE_DIV
		planet_btn.rect_scale.y = p_i["size"] / PLANET_SCALE_DIV
		planet_glow.rect_pivot_offset = Vector2(100, 100)
		planet_glow.rect_position = Vector2(-100, -100)
		planet_glow.rect_scale *= planet_btn.rect_scale.x * 7 + p_i["ring"] / 2.5
		match p_i["status"]:
			"conquered":
				planet_glow.modulate = Color(0, 1, 0, 1)
			"unconquered":
				planet_glow.modulate = Color(1, 0, 0, 1)
		planet.position.x = cos(p_i["angle"]) * p_i["distance"] * DIST_MULT
		planet.position.y = sin(p_i["angle"]) * p_i["distance"] * DIST_MULT

func on_planet_over (id:int):
	var p_i = game.planet_data[id]
	game.show_tooltip(p_i["name"] + "\nDiameter: " + String(round(p_i["size"])) + " km")

func on_planet_out ():
	game.hide_tooltip()

func on_planet_click (id:int):
	game.c_p = id
	game.switch_view("planet")
