extends Node2D

@onready var game = get_node("/root/Game")

var dimensions:float
var dimensions_temp:float

const DIST_MULT = 200.0
var obj_btns:Array = []
var overlays:Array = []
var rsrcs:Array = []
@onready var bldg_overlay_timer = $BuildingOverlayTimer
var discovered_gal:Array = []
var curr_bldg_overlay:int = 0

func _ready():
	rsrcs.resize(len(game.galaxy_data))
	var conquered = true
	var await_counter:int = 0
	for g_i in game.galaxy_data:
		if g_i.is_empty():
			continue
		conquered = conquered and g_i.has("conquered")
		var galaxy_btn = TextureButton.new()
		var galaxy = Sprite2D.new()
		galaxy_btn.texture_normal = game.galaxy_textures[g_i.type]
		self.add_child(galaxy)
		galaxy.add_child(galaxy_btn)
		obj_btns.append(galaxy_btn)
		galaxy_btn.connect("mouse_entered",Callable(self,"on_galaxy_over").bind(g_i.l_id))
		galaxy_btn.connect("mouse_exited",Callable(self,"on_galaxy_out"))
		galaxy_btn.connect("pressed",Callable(self,"on_galaxy_click").bind(g_i.id, g_i.l_id))
		var radius = pow(g_i["system_num"] / game.GALAXY_SCALE_DIV, 0.5)
		galaxy_btn.position = Vector2(-galaxy_btn.texture_normal.get_width(), -galaxy_btn.texture_normal.get_height()) / 2.0 * radius
		galaxy_btn.scale = Vector2.ONE * radius
		galaxy.rotation = g_i.rotation
		galaxy_btn.modulate = g_i.get("modulate", Color.WHITE)
		galaxy_btn.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(galaxy_btn, "modulate:a", 1.0, 0.15)
		galaxy.position = g_i["pos"]
		dimensions_temp = max(dimensions_temp, g_i.pos.length())
		Helper.add_overlay(galaxy, self, "galaxy", g_i, overlays)
		if g_i.has("GS"):
			var GS_marker:Sprite2D = Sprite2D.new()
			GS_marker.scale *= 2.0
			GS_marker.texture = preload("res://Graphics/Effects/spotlight_8.png")
			galaxy.add_child(GS_marker)
			var rsrc
			var prod:float
			var rsrc_mult:float = 1.0
			match g_i.GS:
				Building.MINERAL_EXTRACTOR:
					rsrc_mult = Helper.get_IR_mult(Building.MINERAL_EXTRACTOR) * game.u_i.time_speed
					rsrc = add_rsrc(g_i.pos, Color(0, 0.5, 0.9, 1), Data.rsrc_icons[Building.MINERAL_EXTRACTOR], g_i.l_id, radius * 10.0)
				Building.POWER_PLANT:
					rsrc_mult = Helper.get_IR_mult(Building.POWER_PLANT) * game.u_i.time_speed
					rsrc = add_rsrc(g_i.pos, Color(0, 0.8, 0, 1), Data.rsrc_icons[Building.POWER_PLANT], g_i.l_id, radius * 10.0)
				Building.RESEARCH_LAB:
					rsrc_mult = Helper.get_IR_mult(Building.RESEARCH_LAB) * game.u_i.time_speed
					rsrc = add_rsrc(g_i.pos, Color(0, 0.8, 0, 1), Data.rsrc_icons[Building.RESEARCH_LAB], g_i.l_id, radius * 10.0)
				_:
					rsrc = null
			if is_instance_valid(rsrc):
				rsrc.set_text("%s/%s" % [Helper.format_num(g_i.prod_num * rsrc_mult), tr("S_SECOND")])
		if g_i.has("discovered") and not g_i.has("GS"):
			discovered_gal.append(g_i)
		await_counter += 1
		if is_instance_valid(game.overlay):
			change_overlay(game.overlay.option_btn.selected, game.overlay.get_node("TextureRect").texture.gradient, overlays[-1])
		galaxy_btn.visible = not game.overlay_data.cluster.visible
		overlays[-1].circle.visible = game.overlay_data.cluster.visible
		if await_counter % int(3000.0 / Engine.get_frames_per_second()) == 0:
			await get_tree().process_frame
	game.overlay.refresh_options(game.overlay_data[game.c_v].overlay)
	if conquered:
		game.u_i.cluster_data[game.c_c].conquered = true
	if len(discovered_gal) > 0:
		bldg_overlay_timer.start(0.05)
	dimensions = dimensions_temp

func on_bldg_overlay_timeout():
	var g_i = discovered_gal[curr_bldg_overlay]
	var bldgs:Dictionary = {}
	var MSs:Dictionary = {}
	var system_data2:Array = game.open_obj("Galaxies", g_i.id)
	for s_i in system_data2:
		if not s_i.has("discovered"):
			continue
		var planet_data2:Array = game.open_obj("Systems", s_i.id)
		for p_i in planet_data2:
			if p_i.is_empty():
				continue
			if p_i.has("tile_num") and p_i.bldg.has("name"):
				Helper.add_to_dict(bldgs, p_i.bldg.name, p_i.tile_num)
			if p_i.has("MS"):
				Helper.add_to_dict(MSs, p_i.MS, 1)
		for _star in s_i.stars:
			if _star.has("MS"):
				Helper.add_to_dict(MSs, _star.MS, 1)
		#await get_tree().process_frame
	var sc:float = pow(g_i["system_num"] / game.GALAXY_SCALE_DIV, 0.5)
	if not bldgs.is_empty():
		var grid_panel = preload("res://Scenes/BuildingInfo.tscn").instantiate()
		grid_panel.get_node("Top").visible = false
		var grid = grid_panel.get_node("PanelContainer/GridContainer")
		grid_panel.scale *= 7.0
		for bldg in bldgs:
			var bldg_count = preload("res://Scenes/EntityCount.tscn").instantiate()
			grid.add_child(bldg_count)
			bldg_count.get_node("Texture2D").texture = game.bldg_textures[bldg]
			bldg_count.get_node("Texture2D").mouse_filter = Control.MOUSE_FILTER_IGNORE
			bldg_count.get_node("Label").text = "x %s" % Helper.format_num(bldgs[bldg])
		add_child(grid_panel)
		grid_panel.add_to_group("Grids")
		grid_panel.name = "Grid_%s" % g_i.l_id
		grid_panel.position.x = g_i.pos.x - grid.size.x / 2.0 * grid_panel.scale.x
		grid_panel.position.y = g_i.pos.y - grid_panel.size.y * grid_panel.scale.y - 170 * sc
	if not MSs.is_empty():
		var MS_grid_panel = preload("res://Scenes/BuildingInfo.tscn").instantiate()
		MS_grid_panel.get_node("Bottom").visible = false
		var MS_grid = MS_grid_panel.get_node("PanelContainer/GridContainer")
		MS_grid_panel.scale *= 7.0
		for MS in MSs:
			var MS_count = preload("res://Scenes/EntityCount.tscn").instantiate()
			MS_grid.add_child(MS_count)
			MS_count.get_node("Texture2D").texture = load("res://Graphics/Megastructures/%s_0.png" % MS)
			MS_count.get_node("Label").text = "x %s" % Helper.format_num(MSs[MS])
		add_child(MS_grid_panel)
		MS_grid_panel.add_to_group("MSGrids")
		MS_grid_panel.name = "MSGrid_%s" % g_i.l_id
		MS_grid_panel.position.x = g_i.pos.x - MS_grid.size.x / 2.0 * MS_grid_panel.scale.x
		MS_grid_panel.position.y = g_i.pos.y + 170 * sc
	curr_bldg_overlay += 1
	if curr_bldg_overlay >= len(discovered_gal):
		bldg_overlay_timer.stop()

func add_rsrc(v:Vector2, mod:Color, icon, id:int, sc:float = 1):
	var rsrc:ResourceStored = game.rsrc_stored_scene.instantiate()
	add_child(rsrc)
	rsrc.set_current_bar_visibility(false)
	rsrc.set_icon_texture(icon)
	rsrc.scale *= 5.0
	rsrc.position = v + Vector2(0, 70 * 5.0)
	rsrc.set_panel_modulate(mod)
	rsrcs[id] = rsrc
	return rsrc

func e(n, e):
	return n * pow(10, e)

func on_galaxy_over (id:int):
	var g_i = game.galaxy_data[id]
	var tooltip:String = g_i.name if g_i.has("name") else ("%s %s" % [tr("GALAXY"), id])
	var icons = []
	if g_i.has("GS"):
		tooltip += "\n"
		if g_i.GS == Building.MINERAL_SILO:
			icons = [Data.minerals_icon]
			tooltip += Data.path_1[Building.MINERAL_SILO].desc % Helper.format_num(g_i.prod_num * Helper.get_IR_mult(Building.MINERAL_SILO))
		elif g_i.GS == Building.BATTERY:
			icons = [Data.energy_icon]
			tooltip += Data.path_1[Building.BATTERY].desc % Helper.format_num(g_i.prod_num * Helper.get_IR_mult(Building.BATTERY))
		elif g_i.GS == Building.MINERAL_EXTRACTOR:
			icons = [Data.minerals_icon]
			tooltip += Data.path_1[Building.MINERAL_EXTRACTOR].desc % Helper.format_num(g_i.prod_num * Helper.get_IR_mult(Building.MINERAL_EXTRACTOR) * game.u_i.time_speed)
		elif g_i.GS == Building.POWER_PLANT:
			icons = [Data.energy_icon]
			tooltip += Data.path_1[Building.POWER_PLANT].desc % Helper.format_num(g_i.prod_num * Helper.get_IR_mult(Building.POWER_PLANT) * game.u_i.time_speed)
		elif g_i.GS == Building.RESEARCH_LAB:
			icons = [Data.SP_icon]
			tooltip += Data.path_1[Building.RESEARCH_LAB].desc % Helper.format_num(g_i.prod_num * Helper.get_IR_mult(Building.RESEARCH_LAB) * game.u_i.time_speed)
	else:
		tooltip += "\n%s: %s\n%s: %s\n%s: %s nT\n%s: %s" % [tr("SYSTEMS"), g_i.system_num, tr("DIFFICULTY"), g_i.diff, tr("B_STRENGTH"), Helper.clever_round(g_i.B_strength * 1e9), tr("DARK_MATTER"), g_i.dark_matter]
	for grid in get_tree().get_nodes_in_group("Grids"):
		if grid.name != "Grid_%s" % g_i.l_id:
			var tween = create_tween()
			tween.tween_property(grid, "modulate", Color(1, 1, 1, 0), 0.1)
			#grid.visible = false
	for grid in get_tree().get_nodes_in_group("MSGrids"):
		if grid.name != "MSGrid_%s" % g_i.l_id:
			var tween = create_tween()
			tween.tween_property(grid, "modulate", Color(1, 1, 1, 0), 0.1)
			#grid.visible = false
	game.show_adv_tooltip(tooltip, icons)

func on_galaxy_out ():
	for grid in get_tree().get_nodes_in_group("Grids"):
		#grid.visible = true
		var tween = create_tween()
		tween.tween_property(grid, "modulate", Color(1, 1, 1, 1), 0.1)
	for grid in get_tree().get_nodes_in_group("MSGrids"):
		#grid.visible = true
		var tween = create_tween()
		tween.tween_property(grid, "modulate", Color(1, 1, 1, 1), 0.1)
	game.hide_tooltip()

func on_galaxy_click (id:int, l_id:int):
	var g_i:Dictionary = game.galaxy_data[l_id]
	var view = self.get_parent()
	if not view.dragged:
		if g_i.has("GS"):
#			if g_i.GS == "TP":
#				game.PC_panel.probe_tier = 2
#				game.toggle_panel(game.PC_panel)
#				game.hide_tooltip()
			return
		if game.bottom_info_action == "convert_to_GS":
			if id == 0:
				game.popup(tr("GS_ERROR"), 1.5)
			elif not game.galaxy_data[l_id].has("conquered"):
				game.popup(tr("NO_GS"), 2.0)
			elif not game.galaxy_data[l_id].has("GS"):
				game._on_BottomInfo_close_button_pressed()
				game.gigastructures_panel.g_i = game.galaxy_data[l_id]
				game.gigastructures_panel.galaxy_id_g = id
				game.toggle_panel(game.gigastructures_panel)
		else:
			if not g_i.has("discovered") and g_i.system_num > 9000:
				game.show_YN_panel("op_galaxy", tr("OP_GALAXY_DESC"), [l_id, id], tr("OP_GALAXY"))
			else:
				game.switch_view("galaxy", {"fn":"set_custom_coords", "fn_args":[["c_g", "c_g_g"], [l_id, id]]})
	view.dragged = false

func change_overlay(overlay_id:int, gradient:Gradient, object:Dictionary = {}):
	var _overlays = overlays
	if not object.is_empty():
		_overlays = [object]
	var c_vl = game.overlay_data.cluster.custom_values[overlay_id]
	match overlay_id:
		0:
			for overlay in _overlays:
				var offset = inverse_lerp(c_vl.left, c_vl.right, game.galaxy_data[overlay.id].system_num)
				Helper.set_overlay_visibility(gradient, overlay, offset)
		1:
			for overlay in _overlays:
				if game.galaxy_data[overlay.id].has("discovered"):
					overlay.circle.modulate = gradient.sample(0)
				else:
					overlay.circle.modulate = gradient.sample(1)
		2:
			for overlay in _overlays:
				if game.galaxy_data[overlay.id].has("explored"):
					overlay.circle.modulate = gradient.sample(0)
				else:
					overlay.circle.modulate = gradient.sample(1)
		3:
			for overlay in _overlays:
				if game.galaxy_data[overlay.id].has("conquered"):
					overlay.circle.modulate = gradient.sample(0)
				else:
					overlay.circle.modulate = gradient.sample(1)
		4:
			for overlay in _overlays:
				var offset = inverse_lerp(c_vl.left, c_vl.right, game.galaxy_data[overlay.id].diff)
				Helper.set_overlay_visibility(gradient, overlay, offset)
		5:
			for overlay in _overlays:
				var offset = inverse_lerp(c_vl.left, c_vl.right, game.galaxy_data[overlay.id].B_strength * e(1, 9))
				Helper.set_overlay_visibility(gradient, overlay, offset)
		6:
			for overlay in _overlays:
				var offset = inverse_lerp(c_vl.left, c_vl.right, game.galaxy_data[overlay.id].dark_matter)
				Helper.set_overlay_visibility(gradient, overlay, offset)
		7:
			for overlay in _overlays:
				if game.galaxy_data[overlay.id].has("GS"):
					overlay.circle.modulate = gradient.sample(0)
				else:
					overlay.circle.modulate = gradient.sample(1)


func _on_Galaxy_tree_exited():
	queue_free()
