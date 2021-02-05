extends Node2D

onready var game = self.get_parent().get_parent()

var stars

const DIST_MULT = 200.0
var obj_btns = []
var overlays = []

func _ready():
	for s_i in game.system_data:
		var star = s_i["stars"][0]
		var star_btn = TextureButton.new()
		var system = Sprite.new()
		var star_texture = preload("res://Graphics/Stars/Star.png")
		star_btn.texture_normal = star_texture
		star_btn.modulate = game.get_star_modulate(star["class"])
		add_child(system)
		system.add_child(star_btn)
		obj_btns.append(star_btn)
		star_btn.connect("mouse_entered", self, "on_system_over", [s_i.l_id])
		star_btn.connect("mouse_exited", self, "on_system_out")
		star_btn.connect("pressed", self, "on_system_click", [s_i.id, s_i.l_id])
		star_btn.rect_position = Vector2(-600 / 2, -600 / 2)
		star_btn.rect_pivot_offset = Vector2(600 / 2, 600 / 2)
		var radius = pow(star["size"] / game.SYSTEM_SCALE_DIV, 0.35)
		star_btn.rect_scale *= radius
		system.position = s_i["pos"]
		Helper.add_overlay(system, self, "system", s_i, overlays)
	if game.galaxy_data[game.c_g].has("wormholes"):
		for wh_data in game.galaxy_data[game.c_g].wormholes:
			var blue_line = Line2D.new()
			add_child(blue_line)
			blue_line.add_point(game.system_data[wh_data.from].pos)
			blue_line.add_point(game.system_data[wh_data.to].pos)
			blue_line.width = 1
			blue_line.default_color = Color(0.4, 0.2, 1.0, 1.0)
			blue_line.antialiased = true
	if game.overlay_data.galaxy.visible:
		Helper.toggle_overlay(obj_btns, overlays)
	if game.overlay:
		game.overlay.refresh_overlay()

func on_system_over (l_id:int):
	var s_i = game.system_data[l_id]
	game.show_tooltip("%s\n%s: %s\n%s: %s" % [s_i.name, tr("PLANETS"), s_i.planet_num, tr("DIFFICULTY"), s_i.diff])

func on_system_out ():
	game.hide_tooltip()

func on_system_click (id:int, l_id:int):
	var view = self.get_parent()
	if not view.dragged:
		game.c_s = l_id
		game.c_s_g = id
		game.switch_view("system")
	view.dragged = false

func change_overlay(overlay_id:int, gradient:Gradient):
	var c_vl = game.overlay_data.galaxy.custom_values[overlay_id]
	match overlay_id:
		0:
			for overlay in overlays:
				var offset = inverse_lerp(c_vl.left, c_vl.right, game.system_data[overlay.id].planet_num)
				overlay.circle.modulate = gradient.interpolate(offset)
		1:
			for overlay in overlays:
				if game.system_data[overlay.id].discovered:
					overlay.circle.modulate = gradient.interpolate(0)
				else:
					overlay.circle.modulate = gradient.interpolate(1)
		2:
			for overlay in overlays:
				if game.system_data[overlay.id].conquered:
					overlay.circle.modulate = gradient.interpolate(0)
				else:
					overlay.circle.modulate = gradient.interpolate(1)
		3:
			for overlay in overlays:
				var offset = inverse_lerp(c_vl.left, c_vl.right, game.system_data[overlay.id].diff)
				overlay.circle.modulate = gradient.interpolate(offset)
		4:
			for overlay in overlays:
				var temp = game.get_coldest_star_temp(overlay.id)
				var offset = inverse_lerp(c_vl.left, c_vl.right, temp)
				overlay.circle.modulate = gradient.interpolate(offset)
		5:
			for overlay in overlays:
				var temp = game.get_biggest_star_size(overlay.id)
				var offset = inverse_lerp(c_vl.left, c_vl.right, temp)
				overlay.circle.modulate = gradient.interpolate(offset)
		6:
			for overlay in overlays:
				var temp = game.get_brightest_star_luminosity(overlay.id)
				var offset = inverse_lerp(c_vl.left, c_vl.right, temp)
				overlay.circle.modulate = gradient.interpolate(offset)


func _on_Galaxy_tree_exited():
	queue_free()
