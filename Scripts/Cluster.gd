extends Node2D

onready var game = self.get_parent().get_parent()

var dimensions:float

const DIST_MULT = 200.0
var obj_btns:Array = []
var overlays:Array = []
var rsrcs:Array = []

func _ready():
	rsrcs.resize(len(game.galaxy_data))
	for g_i in game.galaxy_data:
		if g_i.empty():
			continue
		var galaxy_btn = TextureButton.new()
		var galaxy = Sprite.new()
		galaxy_btn.texture_normal = game.galaxy_textures[g_i.type]
		self.add_child(galaxy)
		galaxy.add_child(galaxy_btn)
		obj_btns.append(galaxy_btn)
		galaxy_btn.connect("mouse_entered", self, "on_galaxy_over", [g_i.l_id])
		galaxy_btn.connect("mouse_exited", self, "on_galaxy_out")
		galaxy_btn.connect("pressed", self, "on_galaxy_click", [g_i.id, g_i.l_id])
		galaxy_btn.rect_position = Vector2(-358 / 2, -199 / 2)
		galaxy_btn.rect_pivot_offset = Vector2(358 / 2, 199 / 2)
		galaxy_btn.rect_rotation = rad2deg(g_i["rotation"])
		var radius = pow(g_i["system_num"] / game.GALAXY_SCALE_DIV, 0.5)
		galaxy_btn.rect_scale.x = radius
		galaxy_btn.rect_scale.y = radius
		if g_i.has("modulate"):
			galaxy_btn.modulate = g_i.modulate
		galaxy.position = g_i["pos"]
		dimensions = max(dimensions, g_i.pos.length())
		Helper.add_overlay(galaxy, self, "galaxy", g_i, overlays)
		if g_i.has("GS"):
			var rsrc
			var prod:float
			var rsrc_mult:float = 1.0
			match g_i.GS:
				"ME":
					rsrc_mult = pow(game.maths_bonus.IRM, game.infinite_research.MEE) * game.u_i.time_speed
					rsrc = add_rsrc(g_i.pos, Color(0, 0.5, 0.9, 1), Data.rsrc_icons.ME, g_i.l_id, radius * 10.0)
				"PP":
					rsrc_mult = pow(game.maths_bonus.IRM, game.infinite_research.EPE) * game.u_i.time_speed
					rsrc = add_rsrc(g_i.pos, Color(0, 0.8, 0, 1), Data.rsrc_icons.PP, g_i.l_id, radius * 10.0)
				"RL":
					rsrc_mult = pow(game.maths_bonus.IRM, game.infinite_research.RLE) * game.u_i.time_speed
					rsrc = add_rsrc(g_i.pos, Color(0, 0.8, 0, 1), Data.rsrc_icons.RL, g_i.l_id, radius * 10.0)
			if rsrc:
				rsrc.get_node("Control/Label").text = "%s/%s" % [Helper.format_num(g_i.prod_num * rsrc_mult), tr("S_SECOND")]
	if game.overlay_data.cluster.visible:
		Helper.toggle_overlay(obj_btns, overlays, true)

func add_rsrc(v:Vector2, mod:Color, icon, id:int, sc:float = 1):
	var rsrc = game.rsrc_stocked_scene.instance()
	add_child(rsrc)
	rsrc.get_node("TextureRect").texture = icon
	rsrc.rect_scale *= sc
	rsrc.rect_position = v + Vector2(0, 70 * sc)
	rsrc.get_node("Control").modulate = mod
	rsrcs[id] = rsrc
	return rsrc

func e(n, e):
	return n * pow(10, e)

func on_galaxy_over (id:int):
	var g_i = game.galaxy_data[id]
	var tooltip:String = g_i.name if g_i.has("name") else ("%s %s" % [tr("GALAXY"), id])
	if g_i.has("GS") and g_i.GS == "TP":
		tooltip += "(%s)" % tr("TPCC_SC")
	tooltip += "\n%s: %s\n%s: %s\n%s: %s nT\n%s: %s" % [tr("SYSTEMS"), g_i.system_num, tr("DIFFICULTY"), g_i.diff, tr("B_STRENGTH"), g_i.B_strength * e(1, 9), tr("DARK_MATTER"), g_i.dark_matter]
	game.show_tooltip(tooltip)

func on_galaxy_out ():
	game.hide_tooltip()

func on_galaxy_click (id:int, l_id:int):
	var g_i:Dictionary = game.galaxy_data[l_id]
	var view = self.get_parent()
	if not view.dragged:
		if g_i.has("GS"):
			if g_i.GS == "TP":
				game.PC_panel.probe_tier = 2
				game.toggle_panel(game.PC_panel)
				game.hide_tooltip()
			return
		if not g_i.has("discovered") and g_i.system_num > 9000:
			game.show_YN_panel("op_galaxy", tr("OP_GALAXY_DESC"), [l_id, id], tr("OP_GALAXY"))
		else:
			game.c_g_g = id
			game.c_g = l_id
			game.switch_view("galaxy", false, "set_g_id", [l_id, id])
	view.dragged = false

func change_overlay(overlay_id:int, gradient:Gradient):
	var c_vl = game.overlay_data.cluster.custom_values[overlay_id]
	match overlay_id:
		0:
			for overlay in overlays:
				var offset = inverse_lerp(c_vl.left, c_vl.right, game.galaxy_data[overlay.id].system_num)
				Helper.set_overlay_visibility(gradient, overlay, offset)
		1:
			for overlay in overlays:
				if game.galaxy_data[overlay.id].has("discovered"):
					overlay.circle.modulate = gradient.interpolate(0)
				else:
					overlay.circle.modulate = gradient.interpolate(1)
		2:
			for overlay in overlays:
				if game.galaxy_data[overlay.id].has("explored"):
					overlay.circle.modulate = gradient.interpolate(0)
				else:
					overlay.circle.modulate = gradient.interpolate(1)
		3:
			for overlay in overlays:
				if game.galaxy_data[overlay.id].has("conquered"):
					overlay.circle.modulate = gradient.interpolate(0)
				else:
					overlay.circle.modulate = gradient.interpolate(1)
		4:
			for overlay in overlays:
				var offset = inverse_lerp(c_vl.left, c_vl.right, game.galaxy_data[overlay.id].diff)
				Helper.set_overlay_visibility(gradient, overlay, offset)
		5:
			for overlay in overlays:
				var offset = inverse_lerp(c_vl.left, c_vl.right, game.galaxy_data[overlay.id].B_strength * e(1, 9))
				Helper.set_overlay_visibility(gradient, overlay, offset)
		6:
			for overlay in overlays:
				var offset = inverse_lerp(c_vl.left, c_vl.right, game.galaxy_data[overlay.id].dark_matter)
				Helper.set_overlay_visibility(gradient, overlay, offset)
		7:
			for overlay in overlays:
				if game.galaxy_data[overlay.id].has("GS"):
					overlay.circle.modulate = gradient.interpolate(0)
				else:
					overlay.circle.modulate = gradient.interpolate(1)


func _on_Galaxy_tree_exited():
	queue_free()

var items_collected:Dictionary = {}

func collect_all():
	items_collected.clear()
	var curr_time = OS.get_system_time_msecs()
	var galaxies = game.cluster_data[game.c_c].galaxies
	var progress:TextureProgress = game.HUD.get_node("Panel/CollectProgress")
	progress.max_value = len(galaxies)
	var cond = game.collect_speed_lag_ratio != 0
	for g_ids in galaxies:
		if game.c_v != "cluster":
			break
		if not game.galaxy_data[g_ids.local].has("discovered"):
			progress.value += 1
			continue
		game.system_data = game.open_obj("Galaxies", g_ids.global)
		if game.system_data.empty():
			continue
		for s_ids in game.galaxy_data[g_ids.local].systems:
			var system:Dictionary = game.system_data[s_ids.local]
			if not system.has("discovered"):
				continue
			game.planet_data = game.open_obj("Systems", s_ids.global)
			for p_ids in system.planets:
				var planet:Dictionary = game.planet_data[p_ids.local]
				if planet.empty() or p_ids.local >= len(game.planet_data) or not planet.has("discovered"):
					continue
				if planet.has("tile_num"):
					if planet.bldg.name in ["ME", "PP", "MM", "AE"]:
						Helper.call("collect_%s" % planet.bldg.name, planet, planet, items_collected, curr_time, planet.tile_num)
			Helper.save_obj("Systems", s_ids.global, game.planet_data)
		Helper.save_obj("Galaxies", g_ids.global, game.system_data)
		if cond:
			progress.value += 1
			yield(get_tree().create_timer(0.02 * game.collect_speed_lag_ratio), "timeout")
	game.show_collect_info(items_collected)
	game.HUD.refresh()
