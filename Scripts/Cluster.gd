extends Node2D

onready var game = self.get_parent().get_parent()
onready var galaxies_id = game.cluster_data[game.c_c]["galaxies"]

const DIST_MULT = 200.0
var obj_btns:Array = []
var overlays:Array = []

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
		obj_btns.append(galaxy_btn)
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
		Helper.add_overlay(galaxy, self, "galaxy", g_i, overlays)
	if game.overlay_data.cluster.visible:
		Helper.toggle_overlay(obj_btns, overlays)
	game.overlay.refresh_overlay()

func on_galaxy_over (id:int):
	var g_i = game.galaxy_data[id]
	game.show_tooltip("%s\n%s: %s\n%s: %s\n%s: %s\n%s: %s" % [g_i.name, tr("SYSTEMS"), g_i.system_num, tr("DIFFICULTY"), g_i.diff, tr("B_STRENGTH"), g_i.B_strength * game.pow10(1, 9), tr("DARK_MATTER"), g_i.dark_matter])

func on_galaxy_out ():
	game.hide_tooltip()

func on_galaxy_click (id:int):
	var view = self.get_parent()
	if not view.dragged:
		game.c_g = id
		game.switch_view("galaxy")
	view.dragged = false

func change_overlay(overlay_id:int, gradient:Gradient):
	var c_vl = game.overlay_data.cluster.custom_values[overlay_id]
	match overlay_id:
		0:
			for overlay in overlays:
				var offset = inverse_lerp(c_vl.left, c_vl.right, game.galaxy_data[overlay.id].system_num)
				overlay.circle.modulate = gradient.interpolate(offset)
		1:
			for overlay in overlays:
				if game.galaxy_data[overlay.id].discovered:
					overlay.circle.modulate = gradient.interpolate(0)
				else:
					overlay.circle.modulate = gradient.interpolate(1)
		2:
			for overlay in overlays:
				var offset = inverse_lerp(c_vl.left, c_vl.right, game.galaxy_data[overlay.id].diff)
				overlay.circle.modulate = gradient.interpolate(offset)
		3:
			for overlay in overlays:
				var offset = inverse_lerp(c_vl.left, c_vl.right, game.galaxy_data[overlay.id].B_strength * game.pow10(1, 9))
				overlay.circle.modulate = gradient.interpolate(offset)
		4:
			for overlay in overlays:
				var offset = inverse_lerp(c_vl.left, c_vl.right, game.galaxy_data[overlay.id].dark_matter)
				overlay.circle.modulate = gradient.interpolate(offset)


func _on_Galaxy_tree_exited():
	queue_free()
