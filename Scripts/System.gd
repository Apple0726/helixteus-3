extends Node2D

onready var game = get_node("/root/Game")
onready var stars_info = game.system_data[game.c_s]["stars"]
onready var star_graphic = preload("res://Graphics/Stars/Star.png")
onready var planets_id = game.system_data[game.c_s]["planets"]
onready var view = get_parent()

var stars

const PLANET_SCALE_DIV = 6400000.0
const STAR_SCALE_DIV = 300.0/2.63
var glows = []

func _ready():
	#var combined_star_size = 0
	for i in range(0, stars_info.size()):
		var star_info = stars_info[i]
		var star = TextureButton.new()
		star.texture_normal = star_graphic
		self.add_child(star)
		star.rect_pivot_offset = Vector2(300, 300)
		#combined_star_size += star_info["size"]
		star.rect_scale.x = max(0.02, star_info["size"] / STAR_SCALE_DIV)
		star.rect_scale.y = max(0.02, star_info["size"] / STAR_SCALE_DIV)
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
		orbit.radius = p_i["distance"]
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
		planet_glow.rect_scale *= p_i["distance"] / 1200.0
		match p_i["status"]:
			"conquered":
				planet_glow.modulate = Color(0, 1, 0, 1)
			"unconquered":
				planet_glow.modulate = Color(1, 0, 0, 1)
		planet.position.x = cos(p_i["angle"]) * p_i["distance"]
		planet.position.y = sin(p_i["angle"]) * p_i["distance"]
		glows.append(planet_glow)

func on_planet_over (id:int):
	var p_i = game.planet_data[id]
	game.show_tooltip(tr("PLANET_INFO") % [p_i["name"], round(p_i["size"]), game.clever_round(p_i.distance / 569.25, 3), game.clever_round(p_i.temperature - 273)])

func on_planet_click (id:int):
	if not view.dragged:
		game.c_p = id
		if Input.is_action_pressed("shift"):
			game.switch_view("planet_details")
		else:
			game.switch_view("planet")

func on_star_over (id:int):
	var star = stars_info[id]
	var tooltip = tr("STAR_TITLE").format({"type":tr(star.type.to_upper()).to_lower(), "class":star.class})
	tooltip += "\n%s\n%s\n%s\n%s" % [	tr("STAR_TEMPERATURE") % [star.temperature], 
										tr("STAR_SIZE") % [star.size],
										tr("STAR_MASS") % [star.mass],
										tr("STAR_LUMINOSITY") % [star.luminosity]]
	game.show_tooltip(tooltip)

func on_btn_out ():
	game.hide_tooltip()

func _process(_delta):
	for glow in glows:
		glow.modulate.a = clamp(0.6 / (view.scale.x * glow.rect_scale.x) - 0.1, 0, 1)
		if glow.modulate.a == 0:
			glow.visible = false
		else:
			glow.visible = true
