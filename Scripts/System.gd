extends Node2D

onready var game = self.get_parent().get_parent()
onready var stars_info = game.system_data[game.c_s]["stars"]
onready var star_graphic = preload("res://Graphics/Stars/Star.png")
onready var planets_id = game.system_data[game.c_s]["planets"]

var stars

const DIST_MULT = 150.0
const PLANET_SCALE_DIV = 1600000.0
const STAR_SCALE_DIV = 5.0

func _ready():
	var combined_star_size = 0
	for i in range(0, stars_info.size()):
		var star_info = stars_info[i]
		var star = TextureButton.new()
		star.texture_normal = star_graphic
		self.add_child(star)
		star.rect_pivot_offset = Vector2(300, 300)
		combined_star_size += star_info["size"]
		star.rect_scale.x = star_info["size"] / STAR_SCALE_DIV
		star.rect_scale.y = star_info["size"] / STAR_SCALE_DIV
		star.rect_position = star_info["pos"] - Vector2(300, 300)
		star.connect("mouse_entered", self, "on_star_over", [i])
		star.connect("mouse_exited", self, "on_btn_out")
		star.modulate = game.get_star_modulate(star_info["class"])
	
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
		planet_btn.connect("mouse_exited", self, "on_btn_out")
		planet_glow.connect("mouse_exited", self, "on_btn_out")
		planet_btn.connect("pressed", self, "on_planet_click", [p_i["id"]])
		planet_glow.connect("pressed", self, "on_planet_click", [p_i["id"]])
		planet_btn.rect_position = Vector2(-320, -320)
		planet_btn.rect_pivot_offset = Vector2(320, 320)
		planet_btn.rect_scale.x = p_i["size"] / PLANET_SCALE_DIV
		planet_btn.rect_scale.y = p_i["size"] / PLANET_SCALE_DIV
		planet_glow.rect_pivot_offset = Vector2(100, 100)
		planet_glow.rect_position = Vector2(-100, -100)
		planet_glow.rect_scale *= (planet_btn.rect_scale.x * 3 + pow(1.3, p_i["ring"])) * pow(combined_star_size / 5.0, 0.5)
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

func on_planet_click (id:int):
	var view = self.get_parent()
	if not view.dragged:
		game.c_p = id
		game.switch_view("planet")

func on_star_over (id:int):
	var star = stars_info[id]
	game.show_tooltip("Class " + star["class"] + " " + star["type"] + " star\nTemperature: " + String(star["temperature"]) + " K\nRadius: " + String(star["size"]) + " solar radii\nMass: " + String(star["mass"]) + " solar masses\nLuminosity: " + String(star["luminosity"]) + " solar luminosity")

func on_btn_out ():
	game.hide_tooltip()
