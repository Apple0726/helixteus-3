extends Node2D

onready var game = self.get_parent().get_parent()
var star_texture = preload("res://Graphics/Stars/Star.png")

var dimensions:float

var stars

const DIST_MULT = 200.0
var obj_btns = []
var overlays = []

func _ready():
	for s_i in game.system_data:
		var star = s_i["stars"][0]
		var star_btn = TextureButton.new()
		var system = Sprite.new()
		star_btn.texture_normal = star_texture
		star_btn.modulate = get_star_modulate(star["class"])
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
		dimensions = max(dimensions, s_i.pos.length())
		Helper.add_overlay(system, self, "system", s_i, overlays)
	if game.galaxy_data[game.c_g].has("wormholes"):
		for wh_data in game.galaxy_data[game.c_g].wormholes:
			var blue_line = Line2D.new()
			add_child(blue_line)
			blue_line.add_point(game.system_data[wh_data.from].pos)
			blue_line.add_point(game.system_data[wh_data.to].pos)
			blue_line.width = 2
			blue_line.default_color = Color(0.6, 0.4, 1.0, 1.0)
			blue_line.antialiased = true
	if game.overlay_data.galaxy.visible:
		Helper.toggle_overlay(obj_btns, overlays)

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
		7:
			for overlay in overlays:
				if game.system_data[overlay.id].has("has_MS"):
					overlay.circle.modulate = gradient.interpolate(0)
				else:
					overlay.circle.modulate = gradient.interpolate(1)

func _on_Galaxy_tree_exited():
	queue_free()

var items_collected = {}

func collect_all():
	items_collected.clear()
	var curr_time = OS.get_system_time_msecs()
	var systems = game.galaxy_data[game.c_g].systems
	var progress:TextureProgress = game.HUD.get_node("Panel/CollectProgress")
	progress.max_value = len(systems)
	var cond = game.collect_speed_lag_ratio != 0
	for s_ids in systems:
		if game.c_v != "galaxy":
			break
		if not game.system_data[s_ids.local].discovered:
			progress.value += 1
			continue
		game.planet_data = game.open_obj("Systems", s_ids.global)
		for star in game.system_data[s_ids.local].stars:
			if star.has("MS"):
				Helper.collect_from_star(star, items_collected)
		for p_ids in game.system_data[s_ids.local].planets:
			var planet:Dictionary = game.planet_data[p_ids.local]
			if planet.empty():
				continue
			if p_ids.local >= len(game.planet_data):
				continue
			if planet.has("MS"):
				if planet.MS == "M_MME":
					Helper.update_MS_rsrc(planet)
					var collect_data:Dictionary = Helper.add_minerals(planet.bldg.stored)
					Helper.add_item_to_coll(items_collected, "minerals", collect_data.added)
					planet.bldg.stored = collect_data.remainder
					continue
			elif planet.has("bldg"):
				if planet.bldg.name in ["ME", "PP", "RL", "MM", "AE"]:
					Helper.call("collect_%s" % planet.bldg.name, planet, planet, items_collected, OS.get_system_time_msecs(), planet.tile_num)
			if not planet.discovered:
				continue
			game.tile_data = game.open_obj("Planets", p_ids.global)
			var i:int
			for tile in game.tile_data:
				if tile:
					Helper.collect_rsrc(items_collected, planet, tile, i)
				i += 1
			Helper.save_obj("Planets", p_ids.global, game.tile_data)
		Helper.save_obj("Systems", s_ids.global, game.planet_data)
		if cond:
			progress.value += 1
			yield(get_tree().create_timer(0.02 * game.collect_speed_lag_ratio), "timeout")
	game.show_collect_info(items_collected)
	game.HUD.refresh()

const Y9 = Color(25, 0, 0, 255) / 255.0
const Y0 = Color(66, 0, 0, 255) / 255.0
const T0 = Color(117, 0, 0, 255) / 255.0
const L0 = Color(189, 32, 23, 255) / 255.0
const M0 = Color(255, 181, 108, 255) / 255.0
const K0 = Color(255, 218, 181, 255) / 255.0
const G0 = Color(255, 237, 227, 255) / 255.0
const F0 = Color(249, 245, 255, 255) / 255.0
const A0 = Color(213, 224, 255, 255) / 255.0
const B0 = Color(162, 192, 255, 255) / 255.0
const O0 = Color(140, 177, 255, 255) / 255.0
const Q0 = Color(134, 255, 117, 255) / 255.0
const R0 = Color(255, 151, 255, 255) / 255.0

func get_star_modulate (star_class:String):
	var w = int(star_class[1]) / 10.0#weight for lerps
	var m:Color
	match star_class[0]:
		"Y":
			m = lerp(Y0, Y9, w)
		"T":
			m = lerp(T0, Y0, w)
		"L":
			m = lerp(L0, T0, w)
		"M":
			m = lerp(M0, L0, w)
		"K":
			m = lerp(K0, M0, w)
		"G":
			m = lerp(G0, K0, w)
		"F":
			m = lerp(F0, G0, w)
		"A":
			m = lerp(A0, F0, w)
		"B":
			m = lerp(B0, A0, w)
		"O":
			m = lerp(O0, B0, w)
		"Q":
			m = lerp(Q0, O0, w)
		"R":
			m = lerp(R0, Q0, w)
		"Z":
			m = Color(0.05, 0.05, 0.05, 1)
	return m
