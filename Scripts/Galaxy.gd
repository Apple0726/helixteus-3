extends Node2D

@onready var game = get_node("/root/Game")

var dimensions:float
var dimensions_temp:float

const DIST_MULT = 200.0
var obj_btns = []
var overlays = []
var star_texture = [	preload("res://Graphics/Effects/spotlight_4.png"),
						preload("res://Graphics/Effects/spotlight_5.png"),
						preload("res://Graphics/Effects/spotlight_6.png"),
]
var g_i:Dictionary

func _ready():
	queue_redraw()
	var await_counter:int = 0
	g_i = game.galaxy_data[game.c_g]
	for s_i in game.system_data:
		if not is_inside_tree():
			return
		var star:Dictionary = s_i.stars[0]
		for i in range(1, len(s_i.stars)):
			if s_i.stars[i].luminosity > star.luminosity:
				star = s_i.stars[i]
		if g_i.has("conquered") and not s_i.has("conquered"):
			s_i["conquered"] = true
			game.stats_univ.planets_conquered += s_i.planet_num
			game.stats_dim.planets_conquered += s_i.planet_num
			game.stats_global.planets_conquered += s_i.planet_num
		var star_btn = TextureButton.new()
		var system = Sprite2D.new()
		star_btn.texture_normal = star_texture[int(star.temperature) % 3]
		star_btn.texture_click_mask = preload("res://Graphics/Misc/StarCM.png")
		if Settings.enable_shaders:
			star_btn.material = ShaderMaterial.new()
			star_btn.material.shader = preload("res://Shaders/Star.gdshader")
			star_btn.material.set_shader_parameter("time_offset", 10.0 * randf())
			star_btn.material.set_shader_parameter("color", Helper.get_star_modulate(star["class"]))
			star_btn.material.set_shader_parameter("alpha", 0.0)
			var galaxy_tween = create_tween()
			galaxy_tween.tween_property(star_btn.material, "shader_parameter/alpha", 1.0, 0.3)
		else:
			star_btn.modulate = Helper.get_star_modulate(star["class"])
		add_child(system)
		system.add_child(star_btn)
		obj_btns.append(star_btn)
		star_btn.mouse_entered.connect(on_system_over.bind(s_i.l_id))
		star_btn.mouse_exited.connect(on_system_out)
		star_btn.pressed.connect(on_system_click.bind(s_i.id, s_i.l_id))
		star_btn.rotation = sin(star.temperature) * 180
		star_btn.position = Vector2(-1024 / 2, -1024 / 2)
		star_btn.pivot_offset = Vector2(1024 / 2, 1024 / 2)
		var radius = pow(star["size"] / game.SYSTEM_SCALE_DIV, 0.35)
		star_btn.scale *= radius
		system.position = s_i["pos"]
		dimensions_temp = max(dimensions_temp, s_i.pos.length())
		Helper.add_overlay(system, self, "system", s_i, overlays)
		await_counter += 1
		if is_instance_valid(game.overlay):
			change_overlay(game.overlay.option_btn.selected, game.overlay.get_node("TextureRect").texture.gradient, overlays[-1])
		star_btn.visible = not game.overlay_data.galaxy.visible
		overlays[-1].circle.visible = game.overlay_data.galaxy.visible
		if await_counter % int(6000.0 / Engine.get_frames_per_second()) == 0:
			await get_tree().process_frame
	game.add_space_HUD()
	if is_instance_valid(game.overlay):
		game.overlay.refresh_options(game.overlay_data[game.c_v].overlay)
	dimensions = dimensions_temp

func _draw():
	if g_i.has("wormholes"):
		for wh_data in g_i.wormholes:
			draw_line(game.system_data[wh_data.from].pos, game.system_data[wh_data.to].pos, Color(0.6, 0.4, 1.0, 1.0))

func on_system_over (l_id:int):
	if l_id >= len(game.system_data):
		return
	var s_i = game.system_data[l_id]
	var _name:String
	if s_i.has("name"):
		_name = s_i.name
	else:
		_name = "%s %s" % [tr("SYSTEM"), l_id]
		match len(game.system_data[l_id].stars):
			2:
				_name = "%s %s" % [tr("BINARY_SYSTEM"), l_id]
			3:
				_name = "%s %s" % [tr("TERNARY_SYSTEM"), l_id]
			4:
				_name = "%s %s" % [tr("QUADRUPLE_SYSTEM"), l_id]
			5:
				_name = "%s %s" % [tr("QUINTUPLE_SYSTEM"), l_id]
	for grid in get_tree().get_nodes_in_group("Grids"):
		if grid.name != "Grid_%s" % l_id:
			var tween = create_tween()
			tween.tween_property(grid, "modulate", Color(1, 1, 1, 0), 0.1)
	for grid in get_tree().get_nodes_in_group("MSGrids"):
		if grid.name != "MSGrid_%s" % l_id:
			var tween = create_tween()
			tween.tween_property(grid, "modulate", Color(1, 1, 1, 0), 0.1)
	game.show_tooltip("%s\n%s: %s\n%s: %s" % [_name, tr("PLANETS"), s_i.planet_num, tr("DIFFICULTY"), Helper.format_num(s_i.diff)])
	
	var planet_data:Array = game.open_obj("Systems", s_i.id)
	var bldgs:Dictionary = {}
	var ancient_bldgs:Dictionary = {}
	var MSs:Dictionary = {}
	for p_i in planet_data:
		if p_i.is_empty():
			continue
		if p_i.has("tile_num") and p_i.bldg.has("name"):
			Helper.add_to_dict(bldgs, p_i.bldg.name, p_i.tile_num)
		if p_i.has("MS"):
			Helper.add_to_dict(MSs, p_i.MS, 1)
		var tile_data:Array = game.open_obj("Planets", p_i.id)
		for tile in tile_data:
			if tile:
				if tile.has("bldg"):
					Helper.add_to_dict(bldgs, tile.bldg.name, 1)
				elif tile.has("ancient_bldg"):
					Helper.add_to_dict(bldgs, tile.ancient_bldg.name, 1)
	for _star in s_i.stars:
		if _star.has("MS"):
			Helper.add_to_dict(MSs, _star.MS, 1)
	if not is_instance_valid(game.space_HUD):
		return
	var bldg_info_node = game.space_HUD.get_node("HBoxContainer/BldgInfo")
	var ancient_bldg_info_node = game.space_HUD.get_node("HBoxContainer/AncientBldgInfo")
	var MS_info_node = game.space_HUD.get_node("HBoxContainer/MSInfo")
	if not bldgs.is_empty():
		for bldg in bldgs:
			var bldg_count = preload("res://Scenes/EntityCount.tscn").instantiate()
			bldg_info_node.add_child(bldg_count)
			bldg_count.get_node("Texture2D").texture = game.bldg_textures[bldg]
			bldg_count.get_node("Label").text = "x %s" % Helper.format_num(bldgs[bldg])
	if not ancient_bldgs.is_empty():
		for ancient_bldg in ancient_bldgs:
			var ancient_bldg_count = preload("res://Scenes/EntityCount.tscn").instantiate()
			ancient_bldg_info_node.add_child(ancient_bldg_count)
			ancient_bldg_count.get_node("Texture2D").texture = game.ancient_bldg_textures[ancient_bldg]
			ancient_bldg_count.get_node("Label").text = "x %s" % Helper.format_num(ancient_bldgs[ancient_bldg])
	if not MSs.is_empty():
		for MS in MSs:
			var MS_count = preload("res://Scenes/EntityCount.tscn").instantiate()
			MS_info_node.add_child(MS_count)
			MS_count.get_node("Texture2D").texture = load("res://Graphics/Megastructures/%s_0.png" % MS)
			MS_count.get_node("Label").text = "x %s" % Helper.format_num(MSs[MS])

func on_system_out ():
	for grid in get_tree().get_nodes_in_group("Grids"):
		var tween = create_tween()
		tween.tween_property(grid, "modulate", Color(1, 1, 1, 1), 0.1)
	for grid in get_tree().get_nodes_in_group("MSGrids"):
		var tween = create_tween()
		tween.tween_property(grid, "modulate", Color(1, 1, 1, 1), 0.1)
	game.hide_tooltip()
	if is_instance_valid(game.space_HUD):
		game.space_HUD.clear_bldg_info()

func on_system_click (id:int, l_id:int):
	var view = self.get_parent()
	if not view.dragged:
		game.switch_view("system", {"fn":"set_custom_coords", "fn_args":[["c_s", "c_s_g"], [l_id, id]]})
	view.dragged = false

func change_overlay(overlay_id:int, gradient:Gradient, object:Dictionary = {}):
	var _overlays = overlays
	if not object.is_empty():
		_overlays = [object]
	var c_vl = game.overlay_data.galaxy.custom_values[overlay_id]
	match overlay_id:
		0:
			for overlay in _overlays:
				var offset = inverse_lerp(c_vl.left, c_vl.right, game.system_data[overlay.id].planet_num)
				Helper.set_overlay_visibility(gradient, overlay, offset)
		1:
			for overlay in _overlays:
				var offset = inverse_lerp(c_vl.left, c_vl.right, len(game.system_data[overlay.id].stars))
				Helper.set_overlay_visibility(gradient, overlay, offset)
		2:
			for overlay in _overlays:
				if game.system_data[overlay.id].has("discovered"):
					overlay.circle.modulate = gradient.sample(0)
				else:
					overlay.circle.modulate = gradient.sample(1)
		3:
			for overlay in _overlays:
				if game.system_data[overlay.id].has("explored"):
					overlay.circle.modulate = gradient.sample(0)
				else:
					overlay.circle.modulate = gradient.sample(1)
		4:
			for overlay in _overlays:
				if game.system_data[overlay.id].has("conquered"):
					overlay.circle.modulate = gradient.sample(0)
				else:
					overlay.circle.modulate = gradient.sample(1)
		5:
			for overlay in _overlays:
				var offset = inverse_lerp(c_vl.left, c_vl.right, game.system_data[overlay.id].diff)
				Helper.set_overlay_visibility(gradient, overlay, offset)
		6:
			for overlay in _overlays:
				var temp = game.get_max_star_prop(overlay.id, "temperature")
				var offset = inverse_lerp(c_vl.left, c_vl.right, temp)
				Helper.set_overlay_visibility(gradient, overlay, offset)
		7:
			for overlay in _overlays:
				var size = game.get_max_star_prop(overlay.id, "size")
				var offset = inverse_lerp(c_vl.left, c_vl.right, size)
				Helper.set_overlay_visibility(gradient, overlay, offset)
		8:
			for overlay in _overlays:
				var luminosity = game.get_max_star_prop(overlay.id, "luminosity")
				var offset = inverse_lerp(c_vl.left, c_vl.right, luminosity)
				Helper.set_overlay_visibility(gradient, overlay, offset)
		9:
			for overlay in _overlays:
				if game.system_data[overlay.id].has("has_MS"):
					overlay.circle.modulate = gradient.sample(0)
				else:
					overlay.circle.modulate = gradient.sample(1)

func _on_Galaxy_tree_exited():
	queue_free()

var sorted_systems:Array = []
var system_conquer_start_index:int = 0

func sort_systems(ascending:bool):
	sorted_systems = game.system_data.duplicate(true)
	sorted_systems.sort_custom(diff_sort)
	if not ascending:
		sorted_systems.reverse()

func diff_sort(a:Dictionary, b:Dictionary):
	return a.diff < b.diff

func _process(delta: float) -> void:
	if g_i.has("conquer_start_date"):
		if sorted_systems.is_empty():
			system_conquer_start_index = 0
			sort_systems(g_i.conquer_order)
		var curr_time = Time.get_unix_time_from_system()
		var fighters_rekt = g_i.combined_strength <= 0
		var galaxy_conquered = true
		var breaker:int = 0
		var progress = (curr_time - g_i.conquer_start_date) / g_i.time_for_one_sys * 100.0
		while breaker < 100:
			if fighters_rekt:
				break
			breaker += 1
			if progress >= 100:
				for i in range(system_conquer_start_index, len(sorted_systems)):
					var system = sorted_systems[i]
					if system.has("conquered"):
						system_conquer_start_index = i
						continue
					galaxy_conquered = false
					if g_i.combined_strength < system.diff:
						g_i.combined_strength = 0
						fighters_rekt = true
						for j in len(game.fighter_data):
							if game.fighter_data[j] and game.fighter_data[j].c_g_g == game.c_g_g:
								game.fighter_data[j] = null
						g_i.erase("conquer_start_date")
						g_i.erase("time_for_one_sys")
						g_i.erase("sys_num")
						g_i.erase("sys_conquered")
						g_i.erase("combined_strength")
						g_i.erase("conquer_order")
						breaker = 100
						game.popup_window(tr("ALL_FIGHTERS_REKT"))
						break
					if not system.has("conquered"):
						g_i.combined_strength -= system.diff
						game.system_data[system.l_id].conquered = true
						system.conquered = true
						game.stats_univ.planets_conquered += system.planet_num
						game.stats_dim.planets_conquered += system.planet_num
						game.stats_global.planets_conquered += system.planet_num
						game.stats_univ.systems_conquered += 1
						game.stats_dim.systems_conquered += 1
						game.stats_global.systems_conquered += 1
						g_i.sys_conquered += 1
						g_i.conquer_start_date += g_i.time_for_one_sys
						progress = (curr_time - g_i.conquer_start_date) / g_i.time_for_one_sys * 100.0
						break
			else:
				galaxy_conquered = false
				break
		if galaxy_conquered:
			if not g_i.has("conquered"):
				game.stats_univ.galaxies_conquered += 1
				game.stats_dim.galaxies_conquered += 1
				game.stats_global.galaxies_conquered += 1
				g_i.conquered = true
				g_i.erase("conquer_start_date")
				g_i.erase("time_for_one_sys")
				g_i.erase("sys_num")
				g_i.erase("sys_conquered")
				g_i.erase("combined_strength")
				g_i.erase("conquer_order")
				if not game.new_bldgs.has(Building.SOLAR_PANEL):
					game.new_bldgs[Building.SOLAR_PANEL] = true
				for j in len(game.fighter_data):
					if game.fighter_data[j] and game.fighter_data[j].c_g_g == game.c_g_g:
						game.fighter_data[j].erase("exploring")
				game.popup_window(tr("CONQUERED_GALAXY"), "", [tr("DISBAND")], [disband_fighters], tr("KEEP"))
			set_process(false)
	else:
		set_process(false)

func disband_fighters():
	for i in len(game.fighter_data):
		if game.fighter_data[i] and game.fighter_data[i].c_g_g == game.c_g_g:
			game.fighter_data[i] = null
