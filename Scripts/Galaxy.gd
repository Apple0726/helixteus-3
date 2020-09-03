extends Node2D

onready var game = self.get_parent().get_parent()
onready var systems_id = game.galaxy_data[game.c_g]["systems"]

var stars

const DIST_MULT = 200.0
var star_btns = []
var overlays = []

func _ready():
	var systems_info = []
	for i in systems_id:
		systems_info.append(game.system_data[i])
	for s_i in systems_info:
		var star = s_i["stars"][0]
		var star_btn = TextureButton.new()
		var overlay = TextureButton.new()
		var system = Sprite.new()
		var star_texture = preload("res://Graphics/Stars/Star.png")
		var overlay_texture = preload("res://Graphics/Elements/Default.png")
		star_btn.texture_normal = star_texture
		overlay.texture_normal = overlay_texture
		star_btn.modulate = game.get_star_modulate(star["class"])
		add_child(system)
		system.add_child(star_btn)
		overlay.visible = false
		system.add_child(overlay)
		star_btns.append(star_btn)
		overlays.append({"circle":overlay, "id":s_i.id})
		star_btn.connect("mouse_entered", self, "on_system_over", [s_i["id"]])
		star_btn.connect("mouse_exited", self, "on_system_out")
		star_btn.connect("pressed", self, "on_system_click", [s_i["id"]])
		overlay.connect("mouse_entered", self, "on_system_over", [s_i["id"]])
		overlay.connect("mouse_exited", self, "on_system_out")
		overlay.connect("pressed", self, "on_system_click", [s_i["id"]])
		star_btn.rect_position = Vector2(-600 / 2, -600 / 2)
		star_btn.rect_pivot_offset = Vector2(600 / 2, 600 / 2)
		overlay.rect_position = Vector2(-300 / 2, -300 / 2)
		overlay.rect_pivot_offset = Vector2(300 / 2, 300 / 2)
		var radius = pow(star["size"] / game.SYSTEM_SCALE_DIV, 0.35)
		star_btn.rect_scale *= radius
		overlay.rect_scale *= 2
		system.position = s_i["pos"]
	if game.overlay and game.overlay.get_node("Panel/CheckBox").pressed:
		toggle_overlay()

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

func toggle_overlay():
	for star_btn in star_btns:
		star_btn.visible = not star_btn.visible
	for overlay in overlays:
		overlay.circle.visible = not overlay.circle.visible

func change_overlay(overlay:String, gradient:Gradient):
	match overlay:
		"planet_num":
			for overlay in overlays:
				var offset = inverse_lerp(2, 30, game.system_data[overlay.id].planet_num)
				overlay.circle.modulate = gradient.interpolate(offset)

func change_circle_size(value):
	for overlay in overlays:
		overlay.circle.rect_scale.x = 2 * value
		overlay.circle.rect_scale.y = 2 * value
