extends Node
#A place to put frequently used functions

onready var game = get_node("/root/Game")
#var game
var notation:int = 1#0: standard, 1: SI, 2: scientific

func set_btn_color(btn):
	if not btn.get_parent_control():
		return
	for other_btn in btn.get_parent_control().get_children():
		other_btn["custom_colors/font_color"] = Color(1, 1, 1, 1)
		other_btn["custom_colors/font_color_hover"] = Color(1, 1, 1, 1)
		other_btn["custom_colors/font_color_pressed"] = Color(1, 1, 1, 1)
	btn["custom_colors/font_color"] = Color(0, 1, 1, 1)
	btn["custom_colors/font_color_hover"] = Color(0, 1, 1, 1)
	btn["custom_colors/font_color_pressed"] = Color(0, 1, 1, 1)

#put_rsrc helper function
func format_text(text_node, texture, path:String, show_available:bool, rsrc_cost, rsrc_available, mass_str:String = "", threshold:int = 6):
	texture.texture_normal = load("res://Graphics/" + path + ".png")
	var text:String
	var color:Color = Color(1.0, 1.0, 1.0, 1.0)
	if show_available:
		if path == "Icons/stone" and rsrc_available is Dictionary:
			rsrc_available = get_sum_of_dict(rsrc_available)
		text = "%s/%s" % [format_num(clever_round(rsrc_available), threshold / 2), format_num(clever_round(rsrc_cost), threshold / 2)] + mass_str
		if rsrc_available >= rsrc_cost:
			color = Color(0.0, 1.0, 0.0, 1.0)
		else:
			color = Color(1.0, 0.0, 0.0, 1.0)
	else:
		if path == "Icons/stone" and rsrc_cost is Dictionary:
			rsrc_cost = get_sum_of_dict(rsrc_cost)
		var minus:String = "-" if rsrc_cost < 0 else ""
		rsrc_cost = abs(rsrc_cost)
		var num_str:String = e_notation(rsrc_cost) if rsrc_cost < 0.0001 else format_num(clever_round(rsrc_cost), threshold)
		if rsrc_cost == 0:
			num_str = "0"
		text = "%s%s%s" % [minus, num_str, mass_str]
	text_node.text = text
	text_node["custom_colors/font_color"] = color

func put_rsrc(container, min_size, objs, remove:bool = true, show_available:bool = false):
	if remove:
		for child in container.get_children():
			container.remove_child(child)
			child.free()
	var data = []
	for obj in objs:
		var rsrc = game.rsrc_scene.instance()
		var texture = rsrc.get_node("Texture")
		var atom:bool = false
		var tooltip:String = tr(obj.to_upper())
		if obj == "money":
			format_text(rsrc.get_node("Text"), texture, "Icons/money", show_available, objs[obj], game.money)
		elif obj == "stone":
			format_text(rsrc.get_node("Text"), texture, "Icons/stone", show_available, objs[obj], game.stone, " kg")
		elif obj == "minerals":
			format_text(rsrc.get_node("Text"), texture, "Icons/minerals", show_available, objs[obj], game.minerals)
		elif obj == "energy":
			format_text(rsrc.get_node("Text"), texture, "Icons/energy", show_available, objs[obj], game.energy)
		elif obj == "SP":
			format_text(rsrc.get_node("Text"), texture, "Icons/SP", show_available, objs[obj], game.SP)
		elif obj == "time":
			texture.texture_normal = Data.time_icon
			rsrc.get_node("Text").text = time_to_str(objs[obj] * 1000.0)
		elif game.mats.has(obj):
			if obj == "silicon" and not game.show.silicon:
				tooltip += "\n%s" % [tr("HOW2SILICON")]
			format_text(rsrc.get_node("Text"), texture, "Materials/" + obj, show_available, objs[obj], game.mats[obj], " kg")
		elif game.mets.has(obj):
			format_text(rsrc.get_node("Text"), texture, "Metals/" + obj, show_available, objs[obj], game.mets[obj], " kg")
		elif game.atoms.has(obj):
			atom = true
			tooltip = tr(("%s_NAME" % obj).to_upper())
			format_text(rsrc.get_node("Text"), texture, "Atoms/" + obj, show_available, objs[obj], game.atoms[obj], " mol")
		elif game.particles.has(obj):
			format_text(rsrc.get_node("Text"), texture, "Particles/" + obj, show_available, objs[obj], game.particles[obj], " mol")
		else:
			for item_group_info in game.item_groups:
				if item_group_info.dict.has(obj):
					format_text(rsrc.get_node("Text"), texture, item_group_info.path + "/" + obj, show_available, objs[obj], game.get_item_num(obj))
		rsrc.get_node("Texture").connect("mouse_entered", self, "on_rsrc_over", [tooltip])
		rsrc.get_node("Texture").connect("mouse_exited", self, "on_rsrc_out")
		texture.rect_min_size = Vector2(1, 1) * min_size
		container.add_child(rsrc)
		data.append({"rsrc":rsrc, "name":obj})
	return data

func on_rsrc_over(st:String):
	game.show_tooltip(st)

func on_rsrc_out():
	game.hide_tooltip()

#Converts time in milliseconds to string format
func time_to_str (time:float):
	if time < 0:
		time = 0
	var seconds = int(floor(time / 1000)) % 60
	var second_zero = "0" if seconds < 10 else ""
	var minutes = int(floor(time / 60000)) % 60
	var minute_zero = "0" if minutes < 10 else ""
	var hours = int(floor(time / 3600000)) % 24
	var days = int(floor (time / 86400000)) % 365
	var years = int(floor (time / 31536000000))
	var year_str = "" if years == 0 else ("%s%s " % [years, tr("YEARS")])
	var day_str = "" if days == 0 else ("%s%s " % [days, tr("DAYS")])
	var hour_str = "" if hours == 0 else ("%s:" % hours)
	return "%s%s%s%s%s:%s%s" % [year_str, day_str, hour_str, minute_zero, minutes, second_zero, seconds]

#Returns a random integer between low and high inclusive
func rand_int(low:int, high:int):
	return randi() % (high - low + 1) + low

func log10(n):
	return log(n) / log(10)

func get_state(T:float, P:float, node):
	var v = Vector2(T / 1000.0 * 1109, -(log(P) / log(10)) * 576 / 12.0 + 290)
	if Geometry.is_point_in_polygon(v, node.get_node("Superfluid").polygon):
		return "SC"
	elif Geometry.is_point_in_polygon(v, node.get_node("Liquid").polygon):
		return "L"
	elif Geometry.is_point_in_polygon(v, node.get_node("Gas").polygon):
		return "G"
	else:
		return "S"

func set_visibility(node):
	for other_node in node.get_parent_control().get_children():
		other_node.visible = false
	node.visible = true

func get_item_name (_name:String):
	if _name.substr(0, 7) == "speedup":
		return tr("SPEEDUP") + " " + game.get_roman_num(int(_name.substr(7, 1)))
	if _name.substr(0, 9) == "overclock":
		return tr("OVERCLOCK") + " " + game.get_roman_num(int(_name.substr(9, 1)))
	if len(_name.split("_")) > 1 and _name.split("_")[1] == "seeds":
		return tr("X_SEEDS") % tr(_name.split("_")[0].to_upper())
	return tr(_name.to_upper())

func get_plant_name(name:String):
	return tr("PLANT_TITLE").format({"metal":tr(name.split("_")[0].to_upper())})

func get_wid(size:float):
	return min(round(pow(size / 6000.0, 0.7) * 8.0) + 3, 100)

func e_notation(num:float, sd:int = 4):#e notation
	if num == 0:
		return "0"
	var e = floor(log10(num))
	var n = num * pow(10, -e)
	var n2 = clever_round(n, sd)
	if n2 == 10:
		n2 = 1
		e += 1
	return "%se%s" %  [n2, e]

func get_dir_from_name(_name:String):
	if get_type_from_name(_name) == "speedups_info":
		return "Items/Speedups"
	if get_type_from_name(_name) == "overclocks_info":
		return "Items/Overclocks"
	if get_type_from_name(_name) == "other_items_info":
		return "Items/Others"
	if get_type_from_name(_name) == "craft_agriculture_info":
		return "Agriculture"
	if get_type_from_name(_name) == "craft_mining_info":
		return "Mining"
	if get_type_from_name(_name) == "craft_cave_info":
		return "Cave"
	match _name:
		"money":
			return "Icons"
		"minerals":
			return "Icons"
	return ""

func get_type_from_name(_name:String):
	if game.speedups_info.keys().has(_name):
		return "speedups_info"
	if game.overclocks_info.keys().has(_name):
		return "overclocks_info"
	if game.other_items_info.keys().has(_name):
		return "other_items_info"
	if game.craft_agriculture_info.keys().has(_name):
		return "craft_agriculture_info"
	if game.craft_mining_info.keys().has(_name):
		return "craft_mining_info"
	if game.craft_cave_info.keys().has(_name):
		return "craft_cave_info"
	return ""

func format_num(num:float, clever_round:bool = false, threshold:int = 6):
	if clever_round:
		num = clever_round(num)
	if num < pow(10, threshold):
		var string = str(num)
		var arr = string.split(".")
		if len(arr) == 1:
			arr.append("")
		else:
			arr[1] = "." + arr[1]
		var mod = arr[0].length() % 3
		var res = ""
		for i in range(0, arr[0].length()):
			if i != 0 and i % 3 == mod:
				res += ","
			res += string[i]
		return res + arr[1]
	else:
		var suff:String = ""
		var p:float = log(num) / log(10)
		if is_equal_approx(p, ceil(p)):
			p = ceil(p)
		else:
			p = int(p)
		var div = max(pow(10, stepify(p - 1, 3)), 1)
		if notation == 2 and p >= 3 or p >= 27:
			return e_notation(num, 3)
		if p >= 3 and p < 6:
			suff = "k"
		elif p < 9:
			suff = "M"
		elif p < 12:
			suff = "G" if notation == 1 else "B"
		elif p < 15:
			suff = "T"
		elif p < 18:
			suff = "P" if notation == 1 else "q"
		elif p < 21:
			suff = "E" if notation == 1 else "Q"
		elif p < 24:
			suff = "Z" if notation == 1 else "s"
		elif p < 27:
			suff = "Y" if notation == 1 else "S"
		return "%s%s" % [clever_round(num / div, 3), suff]

#Assumes that all values of dict are floats/integers
func get_sum_of_dict(dict:Dictionary):
	var sum = 0
	for el in dict.values():
		sum += el
	return sum

func get_el_color(element:String):
	match element:
		"O":
			return Color(1, 0.2, 0.2, 1)
		"Si":
			return Color(0.7, 0.7, 0.7, 1)
		"Ca":
			return Color(0.8, 1, 0.8, 1)
		"Al":
			return Color(0.6, 0.6, 0.6, 1)
		"Mg":
			return Color(0.69, 0.69, 0.53, 1)
		"Na":
			return Color(0.92, 0.98, 1, 1)
		"Ni":
			return Color(0.8, 0.8, 0.8, 1)
		"H", "Fe":
			return Color(0.9, 0.9, 0.9, 1)
		"He":
			return Color(0.8, 0.5, 1.0, 1)
		"H2O":
			return Color(0.2, 0.7, 1.0, 1)
		"C":
			return Color(0.15, 0.15, 0.15, 1)
		_:
			return Color(randf() * 0.5, randf() * 0.5, randf() * 0.5, 1)

func mult_dict_by(dict:Dictionary, value:float):
	var dict2:Dictionary = dict.duplicate(true)
	for el in dict:
		dict2[el] = dict[el] * value
	return dict2

func get_crush_info(tile_obj):
	var time = OS.get_system_time_msecs()
	var crush_spd = tile_obj.bldg.path_1_value * game.u_i.time_speed
	var constr_delay = 0
	if tile_obj.bldg.is_constructing:
		constr_delay = tile_obj.bldg.construction_date + tile_obj.bldg.construction_length - time
	var progress = (time - tile_obj.bldg.start_date + constr_delay) / 1000.0 * crush_spd / tile_obj.bldg.stone_qty
	var qty_left = max(0, round(tile_obj.bldg.stone_qty - (time - tile_obj.bldg.start_date + constr_delay) / 1000.0 * crush_spd))
	return {"crush_spd":crush_spd, "progress":progress, "qty_left":qty_left}

func get_prod_info(tile_obj):
	var time = OS.get_system_time_msecs()
	var spd = tile_obj.bldg.path_1_value * game.u_i.time_speed#qty1: resource being used. qty2: resource being produced
	var qty_left = clever_round(max(0, tile_obj.bldg.qty1 - (time - tile_obj.bldg.start_date) / 1000.0 * spd / tile_obj.bldg.ratio))
	var qty_made = clever_round(min(tile_obj.bldg.qty2, (time - tile_obj.bldg.start_date) / 1000.0 * spd))
	var progress = qty_made / tile_obj.bldg.qty2#1 = complete
	return {"spd":spd, "progress":progress, "qty_made":qty_made, "qty_left":qty_left}

var overlay_rsrc = preload("res://Graphics/Elements/Default.png")
func add_overlay(parent, self_node, c_v:String, obj_info:Dictionary, overlays:Array):
	var overlay_texture = overlay_rsrc
	var overlay = TextureButton.new()
	overlay.texture_normal = overlay_texture
	overlay.visible = false
	parent.add_child(overlay)
	overlays.append({"circle":overlay, "id":obj_info.l_id})
	overlay.connect("mouse_entered", self_node, "on_%s_over" % [c_v], [obj_info.l_id])
	overlay.connect("mouse_exited", self_node, "on_%s_out" % [c_v])
	overlay.connect("pressed", self_node, "on_%s_click" % [c_v], [obj_info.id, obj_info.l_id])
	overlay.rect_position = Vector2(-300 / 2, -300 / 2)
	overlay.rect_pivot_offset = Vector2(300 / 2, 300 / 2)

func toggle_overlay(obj_btns, overlays, overlay_visible):
	for obj_btn in obj_btns:
		obj_btn.visible = not overlay_visible
	for overlay in overlays:
		overlay.circle.visible = overlay_visible and overlay.circle.modulate.a == 1.0

func change_circle_size(value, overlays):
	for overlay in overlays:
		overlay.circle.rect_scale.x = 2 * value
		overlay.circle.rect_scale.y = 2 * value

func save_obj(type:String, id:int, arr:Array):
	var save:File = File.new()
	var file_path:String = "user://%s/Univ%s/%s/%s.hx3" % [game.c_sv, game.c_u, type, id]
	save.open(file_path, File.WRITE)
	save.store_var(arr)
	save.close()

func get_rover_weapon_text(_name:String):
	return "%s\n%s\n%s" % [get_rover_weapon_name(_name), "%s: %s" % [tr("DAMAGE"), Data.rover_weapons[_name].damage], "%s: %s%s" % [tr("COOLDOWN"), Data.rover_weapons[_name].cooldown, tr("S_SECOND")]]

func get_rover_weapon_name(_name:String):
	var laser = _name.split("_")
	return tr(laser[0].to_upper() + "_LASER").format({"laser":tr(laser[1])})

func get_rover_mining_text(_name:String):
	return "%s\n%s\n%s" % [get_rover_mining_name(_name), "%s: %s" % [tr("MINING_SPEED"), Data.rover_mining[_name].speed], "%s: %s" % [tr("RANGE"), Data.rover_mining[_name].rnge]]

func get_rover_mining_name(_name:String):
	var laser = _name.split("_", true, 1)
	return tr(laser[0].to_upper() + "_LASER").format({"laser":tr(laser[1].to_upper())})

func set_back_btn(back_btn, set_text:bool = true):
	if OS.get_latin_keyboard_variant() == "QWERTZ":
		back_btn.shortcut.shortcut.action = "Y"
	elif OS.get_latin_keyboard_variant() == "AZERTY":
		back_btn.shortcut.shortcut.action = "W"
	else:
		back_btn.shortcut.shortcut.action = "Z"
	if set_text:
		back_btn.text = "<- %s (%s)" % [tr("BACK"), back_btn.shortcut.shortcut.action]

var dmg_txt_rsrc = preload("res://Resources/DamageText.tres")
func show_dmg(dmg:float, pos:Vector2, parent, sc:float = 1.0, missed:bool = false, crit:bool = false):
	var lb:Label = Label.new()
	lb["custom_fonts/font"] = dmg_txt_rsrc
	if missed:
		lb["custom_colors/font_color"] = Color(1, 1, 0, 1)
		lb.text = tr("MISSED")
	else:
		lb["custom_colors/font_color"] = Color(1, 0.2, 0.2, 1)
		lb.text = "- %s" % format_num(dmg)
		if crit:
			lb.text = "%s\n- %s" % [tr("CRITICAL"), format_num(dmg)]
		else:
			lb.text = "- %s" % format_num(dmg)
	lb.rect_position = pos - Vector2(0, 40)
	lb.rect_scale *= sc
	var dur = 1.5 if crit else 1.0
	if game:
		dur /= game.u_i.time_speed
	var tween:Tween = Tween.new()
	tween.interpolate_property(lb, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), dur)
	tween.interpolate_property(lb, "rect_position", null, pos - Vector2(0, 55), dur, Tween.TRANS_BACK, Tween.EASE_OUT)
	add_child(tween)
	tween.start()
	#lb.light_mask = 2
	parent.add_child(lb)
	yield(tween, "tween_all_completed")
	if is_instance_valid(parent):
		parent.remove_child(lb)
		lb.queue_free()
		remove_child(tween)
		tween.queue_free()

func add_minerals(amount:float, add:bool = true):
	var min_cap = 200 + (game.mineral_capacity - 200) * get_IR_mult("MS")
	var mineral_space_available:float = round(min_cap) - round(game.minerals)
	if mineral_space_available >= amount:
		if add:
			game.minerals += amount
		return {"added":amount, "remainder":0}
	else:
		if game.autosell:
			if add:
				var diff:float = round(amount) - round(mineral_space_available)
				game.minerals = fmod(diff, round(min_cap))
				game.add_resources({"money":ceil(diff / min_cap) * round(min_cap) * (game.MUs.MV + 4)})
			return {"added":amount, "remainder":0}
		else:
			if add:
				game.minerals = min_cap
			return {"added":mineral_space_available, "remainder":amount - mineral_space_available}

func get_AIE(next_lv:int = 0):
	return 0.98 + (game.MUs.AIE + next_lv) / 50.0

func get_au_mult(tile:Dictionary):
	if tile.has("aurora"):
		return pow(1 + tile.aurora.au_int, get_AIE())
	else:
		return 1.0

func get_layer(tile:Dictionary, p_i:Dictionary):
	var layer:String = ""
	if tile.has("crater") and tile.crater.has("init_depth"):
		layer = "crater"
	elif tile.depth <= p_i.crust_start_depth:
		layer = "surface"
	elif tile.depth <= p_i.mantle_start_depth:
		layer = "crust"
	elif tile.depth <= p_i.core_start_depth:
		layer = "mantle"
	else:
		layer = "core"
	return layer

func get_rock_layer(tile:Dictionary, p_i:Dictionary):
	var layer:String = ""
	if tile.depth <= p_i.mantle_start_depth:
		layer = "crust"
	elif tile.depth <= p_i.core_start_depth:
		layer = "mantle"
	else:
		layer = "core"
	return layer

func get_rsrc_from_rock(contents:Dictionary, tile:Dictionary, p_i:Dictionary, is_MM:bool = false):
	var layer:String = get_layer(tile, p_i)
	for content in contents:
		var amount = contents[content]
		if game.mats.has(content):
			game.mats[content] += amount
			if not game.show.plant_button and content == "soil":
				game.show.plant_button = true
			if not game.show.materials:
				if not is_MM and is_instance_valid(game.tutorial):
					game.long_popup(tr("YOU_MINED_MATERIALS"), tr("MATERIALS"))
				game.inventory.get_node("Tabs/Materials").visible = true
				game.show.materials = true
		elif game.mets.has(content):
			if not game.show.metals:
				if not is_MM and is_instance_valid(game.tutorial):
					game.long_popup(tr("YOU_MINED_METALS"), tr("METALS"))
				game.inventory.get_node("Tabs/Metals").visible = true
				game.show.metals = true
			game.mets[content] += amount
		elif content == "stone":
			game.add_resources({"stone":contents.stone})
		elif content == "ship_locator":
			if not game.objective.empty() and game.objective.type == game.ObjectiveType.SIGNAL and game.objective.id == 11:
				game.objective.current += 1
			game.second_ship_hints.ship_locator = true
			tile.erase("ship_locator_depth")
		else:
			game[content] += amount
		if tile.has("artifact") and tile.depth >= 5000:
			game.fourth_ship_hints.artifact_found = true
			tile.erase("artifact")
			if game.fourth_ship_hints.boss_rekt:
				game.long_popup("%s\n%s" % [tr("ARTIFACT_FOUND_DESC"), tr("ARTIFACT_FOUND_DESC2")], tr("ARTIFACT_FOUND"))
			else:
				game.long_popup(tr("ARTIFACT_FOUND_DESC"), tr("ARTIFACT_FOUND"))
		if game.show.has(content):
			game.show[content] = true
	if tile.has("current_deposit") and tile.current_deposit.progress > tile.current_deposit.size - 1:
		tile.erase("current_deposit")
	if tile.has("crater") and tile.crater.has("init_depth") and tile.depth > 3 * tile.crater.init_depth:
		tile.erase("crater")

func mass_generate_rock(tile:Dictionary, p_i:Dictionary, depth:int):
	var aurora_mult = clever_round(get_au_mult(tile))
	var h_mult = game.u_i.planck
	var contents = {}
	var other_volume = 0#in m^3
	#We assume all materials have a density of 1.5g/cm^3 to simplify things
	var rho = 1.5
	#Material quantity penalty the further you go from surface
	var depth_limit_mult = max(1, 1 + (((2 * tile.depth + depth) / 2.0) - p_i.crust_start_depth) / float(p_i.crust_start_depth))
	for mat in p_i.surface.keys():
		var chance_mult:float = min(p_i.surface[mat].chance / depth_limit_mult * aurora_mult, 1)
		var amount = p_i.surface[mat].amount * rand_range(0.8, 1.2) / depth_limit_mult * aurora_mult * chance_mult * depth * h_mult
		if amount < 1:
			continue
		contents[mat] = amount
		other_volume += amount / rho / 1000
	for met in game.met_info:
		var met_info = game.met_info[met]
		var chance_mult:float = 0.25 * aurora_mult
		var amount:float
		if tile.has("crater") and met == tile.crater.metal:
			chance_mult = min(7.0 / (7.0 + 1 / (chance_mult * 6.0)), 1)
			amount = rand_range(0.2, 0.225) * min(depth, 2 * tile.crater.init_depth)
		else:
			chance_mult = min(7.0 / (7.0 + 1 / chance_mult), 1)
			var end_depth:int = tile.depth + depth
			var met_start_depth:int = met_info.min_depth + p_i.crust_start_depth
			var met_end_depth:int = met_info.max_depth + p_i.crust_start_depth
			var num_tiles:int = end_depth - met_start_depth
			var num_tiles2:int = met_end_depth - tile.depth
			var num_tiles3:int = clamp(min(num_tiles, num_tiles2), 0, min(depth, met_end_depth - met_start_depth))
			amount = rand_range(0.4, 0.45) * num_tiles3
		amount *= 20 * chance_mult * aurora_mult * h_mult / pow(met_info.rarity, 0.5)
		if amount < 1:
			continue
		contents[met] = amount
		other_volume += amount / met_info.density / 1000 / h_mult
		#   									                          	    V Every km, rock density goes up by 0.01
	var stone_amount = max(0, clever_round((depth - other_volume) * 1000 * (2.85 + (2 * tile.depth + depth) / 200000.0) * h_mult))
	contents.stone = get_stone_comp_from_amount(p_i[get_rock_layer(tile, p_i)], stone_amount)
	if tile.has("ship_locator_depth"):
		contents.ship_locator = 1
	return contents

func get_stone_comp_from_amount(p_i_layer:Dictionary, amount:float):
	var stone = {}
	for comp in p_i_layer:
		stone[comp] = p_i_layer[comp] * amount
	return stone

func generate_rock(tile:Dictionary, p_i:Dictionary):
	var aurora_mult = clever_round(get_au_mult(tile))
	var h_mult = game.u_i.planck
	var contents = {}
	var other_volume = 0#in m^3
	#We assume all materials have a density of 1.5g/cm^3 to simplify things
	var rho = 1.5
	#Material quantity penalty the further you go from surface
	var depth_limit_mult = max(1, 1 + (tile.depth - p_i.crust_start_depth) / float(p_i.crust_start_depth))
	if depth_limit_mult > 0.01:
		for mat in p_i.surface.keys():
			if p_i.has("tile_num"):
				var amount = p_i.surface[mat].amount * p_i.surface[mat].chance / depth_limit_mult * h_mult
				contents[mat] = amount
				other_volume += amount / rho / 1000 / h_mult
			elif randf() < p_i.surface[mat].chance / depth_limit_mult * aurora_mult:
				var amount = clever_round(p_i.surface[mat].amount * rand_range(0.8, 1.2) / depth_limit_mult * aurora_mult * h_mult)
				if amount < 1:
					continue
				contents[mat] = amount
				other_volume += amount / rho / 1000 / h_mult
	if get_layer(tile, p_i) != "surface" and not tile.has("current_deposit"):
		for met in game.met_info:
			var crater_metal = tile.has("crater") and tile.crater.has("init_depth") and met == tile.crater.metal
			if game.met_info[met].min_depth < tile.depth - p_i.crust_start_depth and tile.depth - p_i.crust_start_depth < game.met_info[met].max_depth or crater_metal:
				if randf() < 0.25 * (6 if crater_metal else 1) * aurora_mult / pow(game.met_info[met].rarity, 0.2):
					tile.current_deposit = {"met":met, "size":rand_int(4, 10), "progress":1}
	if tile.has("current_deposit"):
		var met = tile.current_deposit.met
		var size = tile.current_deposit.size
		var progress2 = tile.current_deposit.progress
		var amount_multiplier = -abs(2.0/size * progress2 - 1) + 1
		var amount = clever_round(20 * rand_range(0.4, 0.45) * amount_multiplier * aurora_mult * h_mult / pow(game.met_info[met].rarity, 0.3))
		contents[met] = amount
		other_volume += amount / game.met_info[met].density / 1000 / h_mult
		tile.current_deposit.progress += 1
		#   									                          	    V Every km, rock density goes up by 0.01
	var stone_amount = max(0, clever_round((1 - other_volume) * 1000 * (2.85 + tile.depth / 100000.0) * h_mult))
	if stone_amount != 0:
		contents.stone = get_stone_comp_from_amount(p_i[get_rock_layer(tile, p_i)], stone_amount)
	if tile.has("ship_locator_depth") and tile.depth >= tile.ship_locator_depth:
		contents.ship_locator = 1
	return contents

func get_IR_mult(bldg_name:String):
	var mult = 1.0
	var sc:String
	if bldg_name in ["PP", "SP"]:
		sc = "EPE"
	elif bldg_name in ["AMN", "SPR"]:
		sc = "PME"
	else:
		sc = "%sE" % bldg_name
	if game.infinite_research.has(sc):
		mult = pow(game.maths_bonus.IRM, game.infinite_research[sc])
	return mult

func add_ship_XP(id:int, XP:float):
	var ship_data = game.ship_data
	ship_data[id].XP += XP
	while ship_data[id].XP >= ship_data[id].XP_to_lv:
		ship_data[id].XP -= ship_data[id].XP_to_lv
		ship_data[id].XP_to_lv = round(ship_data[id].XP_to_lv * game.maths_bonus.SLUGF_XP)
		ship_data[id].lv += 1
		ship_data[id].total_HP = round(ship_data[id].total_HP * game.maths_bonus.SLUGF_Stats)
		ship_data[id].HP = ship_data[id].total_HP
		ship_data[id].atk = round(ship_data[id].atk * game.maths_bonus.SLUGF_Stats)
		ship_data[id].acc = round(ship_data[id].acc * game.maths_bonus.SLUGF_Stats)
		ship_data[id].eva = round(ship_data[id].eva * game.maths_bonus.SLUGF_Stats)

func add_weapon_XP(id:int, weapon:String, XP:float):
	var ship_data = game.ship_data
	ship_data[id][weapon].XP += XP
	while ship_data[id][weapon].XP >= ship_data[id][weapon].XP_to_lv and ship_data[id][weapon].lv < 7:
		ship_data[id][weapon].XP -= ship_data[id][weapon].XP_to_lv
		ship_data[id][weapon].XP_to_lv = [100, 800, 4000, 20000, 75000, 0][ship_data[id][weapon].lv - 1]
		ship_data[id][weapon].lv += 1

func add_label(txt:String, idx:int = -1, center:bool = true, autowrap:bool = false):
	var vbox = game.get_node("UI/Panel/VBox")
	var label = Label.new()
	label.autowrap = autowrap
	if autowrap:
		label.rect_size.x = 250
		label.rect_min_size.x = 250
	if center:
		label.align = Label.ALIGN_CENTER
	label.text = txt
	vbox.add_child(label)
	if idx != -1:
		vbox.move_child(label, idx)

#solar panels
func get_SP_production(temp:float, value:float, au_mult:float = 1.0):
	return clever_round(value * temp * au_mult / 273.0)

#atm extractor
func get_AE_production(pressure:float, value:float):
	return clever_round(value * pressure)

func get_PCNC_production(pressure:float, value:float):
	return clever_round(value / pressure)

func update_rsrc(p_i, tile, rsrc = null, active:bool = false):
	var curr_time = OS.get_system_time_msecs()
	var current_bar
	var capacity_bar
	var rsrc_text
	if is_instance_valid(rsrc):
		current_bar = rsrc.get_node("Control/CurrentBar")
		capacity_bar = rsrc.get_node("Control/CapacityBar")
		rsrc_text = rsrc.get_node("Control/Label")
	else:
		if tile.bldg.name in ["SC", "GF", "SE", "SPR"]:
			return
	update_bldg_constr(tile)
	if tile.bldg.is_constructing:
		return
	match tile.bldg.name:
		"ME", "PP", "MM", "SP", "AE":
			#Number of seconds needed per mineral
			var prod:float
			if tile.bldg.name == "SP":
				prod = 1000 / get_SP_production(p_i.temperature, tile.bldg.path_1_value, 1 + tile.aurora.au_int if tile.has("aurora") else 1.0)
			else:
				prod = 1000 / tile.bldg.path_1_value
			prod /= get_prod_mult(tile)
			var cap = round(tile.bldg.path_2_value * tile.bldg.IR_mult)
			var stored = tile.bldg.stored
			var c_d = tile.bldg.collect_date
			var c_t = curr_time
			if c_t < c_d and not tile.bldg.is_constructing:
				tile.bldg.collect_date = curr_time
			if c_t - c_d > prod:
				var rsrc_num:float = floor((c_t - c_d) / prod)
				var auto_rsrc:float = 0
				if tile.has("auto_collect") and tile.bldg.name in ["ME", "PP", "SP"]:
					auto_rsrc = floor(tile.auto_collect / 100.0 * rsrc_num)
					if auto_rsrc < 5 and randf() < fmod(tile.auto_collect / 100.0 * rsrc_num, 1.0):
						auto_rsrc += 1
					if game.auto_c_p_g != -1:
						if tile.bldg.name == "ME":
							auto_rsrc -= add_minerals(auto_rsrc).remainder
						elif tile.bldg.name in ["PP", "SP"]:
							game.energy += auto_rsrc
				tile.bldg.stored += rsrc_num - auto_rsrc
				tile.bldg.collect_date += prod * rsrc_num
				if tile.bldg.stored >= cap:
					tile.bldg.stored = cap
			if rsrc:
				current_bar.value = min((c_t - c_d) / prod, 1)
				capacity_bar.value = min(stored / float(cap), 1)
				if tile.bldg.name == "MM":
					rsrc_text.text = "%s / %s m" % [tile.depth + tile.bldg.stored, tile.depth + cap]
				else:
					rsrc_text.text = String(stored)
		"RL":
			var prod = 1000 / tile.bldg.path_1_value
			prod /= get_prod_mult(tile)
			var c_d = tile.bldg.collect_date
			var c_t = curr_time
			if c_t < c_d:
				tile.bldg.collect_date = curr_time
			if c_t - c_d > prod:
				var rsrc_num = floor((c_t - c_d) / prod)
				if game.auto_c_p_g != -1:
					game.SP += rsrc_num
				tile.bldg.collect_date += prod * rsrc_num
			if rsrc:
				current_bar.value = min((c_t - c_d) / prod, 1)
				rsrc_text.text = "%s/%s" % [format_num(1000.0 / prod, true), tr("S_SECOND")]
		"PC", "NC":
			var prod = 1000 / (tile.bldg.path_1_value / p_i.pressure)
			prod /= get_prod_mult(tile)
			if rsrc:
				rsrc_text.text = "%s/%s" % [format_num(1000.0 / prod, true), tr("S_SECOND")]
		"EC":
			var prod = 1000 / (tile.bldg.path_1_value * tile.aurora.au_int)
			prod /= get_prod_mult(tile)
			if rsrc:
				rsrc_text.text = "%s/%s" % [format_num(1000.0 / prod, true), tr("S_SECOND")]
		"SC":
			if tile.bldg.has("stone"):
				var c_i = get_crush_info(tile)
				rsrc_text.text = String(c_i.qty_left)
				capacity_bar.value = 1 - c_i.progress
			else:
				rsrc_text.text = ""
				capacity_bar.value = 0
		"GF":
			if tile.bldg.has("qty1"):
				var prod_i = get_prod_info(tile)
				rsrc_text.text = "%s kg" % [prod_i.qty_made]
				capacity_bar.value = prod_i.progress
			else:
				rsrc_text.text = ""
				capacity_bar.value = 0
		"SE":
			if tile.bldg.has("qty1"):
				var prod_i = get_prod_info(tile)
				rsrc_text.text = "%s" % [round(prod_i.qty_made)]
				capacity_bar.value = prod_i.progress
			else:
				rsrc_text.text = ""
				capacity_bar.value = 0
#		"SPR":
#			if tile.bldg.has("qty"):
#				var reaction_info = get_reaction_info(tile)
#				var MM_value = reaction_info.MM_value
#				capacity_bar.value = reaction_info.progress
#				rsrc_text.text = "%s mol" % [clever_round(MM_value, 2)]
#			else:
#				rsrc_text.text = ""
#				capacity_bar.value = 0

func get_prod_mult(tile):
	var mult = tile.bldg.IR_mult * (game.u_i.time_speed if Data.path_1.has(tile.bldg.name) and Data.path_1[tile.bldg.name].has("time_based") else 1.0)
	if tile.bldg.has("overclock_mult"):
		mult *= tile.bldg.overclock_mult
	return mult

func has_IR(bldg_name:String):
	return bldg_name in ["ME", "PP", "RL", "MS", "SP", "AMN", "SPR"]

func collect_rsrc(rsrc_collected:Dictionary, p_i:Dictionary, tile:Dictionary, tile_id:int):
	if not tile.has("bldg"):
		return
	var bldg:String = tile.bldg.name
	var curr_time = OS.get_system_time_msecs()
	update_rsrc(p_i, tile)
	match bldg:
		"ME":
			collect_ME(p_i, tile, rsrc_collected, curr_time)
		"PP":
			collect_PP(p_i, tile, rsrc_collected, curr_time)
		"SP":
			var stored = tile.bldg.stored
			if stored == round(tile.bldg.path_2_value * tile.bldg.IR_mult):
				tile.bldg.collect_date = curr_time
			add_item_to_coll(rsrc_collected, "energy", stored)
			tile.bldg.stored = 0
		"AE":
			collect_AE(p_i, tile, rsrc_collected, curr_time)
		"MM":
			collect_MM(p_i, tile, rsrc_collected, curr_time)

func collect_MM(p_i:Dictionary, dict:Dictionary, rsrc_collected:Dictionary, curr_time, n:float = 1):
	update_MS_rsrc(p_i)
	if dict.bldg.stored >= 1 and not dict.has("depth"):
		dict.depth = 0
	if dict.bldg.stored >= 3:
		var contents:Dictionary = mass_generate_rock(dict, p_i, dict.bldg.stored)
		get_rsrc_from_rock(contents, dict, p_i, true)
		dict.depth += dict.bldg.stored
		dict.erase("contents")
		for content in contents:
			if n > 1:
				if contents[content] is Dictionary:
					for el in contents[content]:
						contents[content][el] *= n
				else:
					contents[content] *= n
			add_item_to_coll(rsrc_collected, content, contents[content])
	else:
		for i in dict.bldg.stored:
			var contents:Dictionary = generate_rock(dict, p_i)
			get_rsrc_from_rock(contents, dict, p_i, true)
			dict.depth += 1
			for content in contents:
				if n > 1:
					if contents[content] is Dictionary:
						for el in contents[content]:
							contents[content][el] *= n
					else:
						contents[content] *= n
				add_item_to_coll(rsrc_collected, content, contents[content])
	if dict.bldg.stored == round(dict.bldg.path_2_value):
		dict.bldg.collect_date = curr_time
	dict.bldg.stored = 0

func collect_ME(p_i:Dictionary, dict:Dictionary, rsrc_collected:Dictionary, curr_time, n:float = 1):
	update_MS_rsrc(p_i)
	var stored = dict.bldg.stored
	if stored >= round(dict.bldg.path_2_value * dict.bldg.IR_mult * n):
		dict.bldg.collect_date = curr_time
	var min_info:Dictionary = add_minerals(stored)
	dict.bldg.stored = min_info.remainder
	add_item_to_coll(rsrc_collected, "minerals", min_info.added)

func collect_PP(p_i:Dictionary, dict:Dictionary, rsrc_collected:Dictionary, curr_time, n:float = 1):
	update_MS_rsrc(p_i)
	var stored = dict.bldg.stored
	if stored >= round(dict.bldg.path_2_value * dict.bldg.IR_mult * n):
		dict.bldg.collect_date = curr_time
	add_item_to_coll(rsrc_collected, "energy", stored)
	dict.bldg.stored = 0

func collect_RL(p_i:Dictionary, dict:Dictionary, rsrc_collected:Dictionary, curr_time, n:float = 1):
	update_MS_rsrc(p_i)
	add_item_to_coll(rsrc_collected, "SP", dict.bldg.stored)
	dict.bldg.stored = 0

func collect_AE(p_i:Dictionary, dict:Dictionary, rsrc_collected:Dictionary, curr_time, n:float = 1):
	update_MS_rsrc(p_i)
	var stored = dict.bldg.stored
	if stored == round(dict.bldg.path_2_value):
		dict.bldg.collect_date = curr_time
	for el in p_i.atmosphere:
		if el == "NH3":
			add_item_to_coll(rsrc_collected, "H", 3 * stored * p_i.atmosphere[el])
			add_item_to_coll(rsrc_collected, "N", 1 * stored * p_i.atmosphere[el])
		elif el == "CO2":
			add_item_to_coll(rsrc_collected, "C", 1 * stored * p_i.atmosphere[el])
			add_item_to_coll(rsrc_collected, "O", 2 * stored * p_i.atmosphere[el])
		elif el == "CH4":
			add_item_to_coll(rsrc_collected, "C", 1 * stored * p_i.atmosphere[el])
			add_item_to_coll(rsrc_collected, "H", 4 * stored * p_i.atmosphere[el])
		elif el == "H2O":
			add_item_to_coll(rsrc_collected, "H", 2 * stored * p_i.atmosphere[el])
			add_item_to_coll(rsrc_collected, "O", 1 * stored * p_i.atmosphere[el])
		else:
			add_item_to_coll(rsrc_collected, el, 1 * stored * p_i.atmosphere[el])
	dict.bldg.stored = 0

func add_item_to_coll(dict:Dictionary, item:String, num):
	if num is Dictionary:
		if not dict.has("stone"):
			dict.stone = {}
		for el in num:
			if dict.stone.has(el):
				dict.stone[el] += num[el]
			else:
				dict.stone[el] = num[el]
	else:
		if num == 0:
			return
		if dict.has(item):
			dict[item] += num
		else:
			dict[item] = num

func ships_on_planet(p_id:int):#local planet id
	return game.c_sc == game.ships_c_coords.sc and game.c_c == game.ships_c_coords.c and game.c_g == game.ships_c_coords.g and game.c_s == game.ships_c_coords.s and p_id == game.ships_c_coords.p

func update_ship_travel():
	if game.ships_travel_view == "-":
		return 1
	var progress:float = (OS.get_system_time_msecs() - game.ships_travel_start_date) / float(game.ships_travel_length)
	if progress >= 1:
		game.get_node("Ship").mouse_filter = TextureButton.MOUSE_FILTER_IGNORE
		game.ships_travel_view = "-"
		game.ships_c_coords = game.ships_dest_coords.duplicate(true)
		game.ships_c_g_coords = game.ships_dest_g_coords.duplicate(true)
	return progress

func update_bldg_constr(tile):
	var curr_time = OS.get_system_time_msecs()
	var start_date = tile.bldg.construction_date
	var length = tile.bldg.construction_length
	var progress = (curr_time - start_date) / float(length)
	var update_boxes:bool = false
	if progress >= 1:
		if tile.bldg.is_constructing:
			tile.bldg.is_constructing = false
			game.universe_data[game.c_u].xp += tile.bldg.XP
			if not game.objective.empty() and game.objective.type == game.ObjectiveType.BUILD and game.objective.data == tile.bldg.name:
				game.objective.current += 1
			if tile.bldg.has("rover_id"):
				game.rover_data[tile.bldg.rover_id].ready = true
				tile.bldg.erase("rover_id")
			if tile.has("auto_GH"):
				var produce_info:Dictionary = game.craft_agriculture_info[tile.auto_GH.seed].duplicate(true)
				tile.auto_GH.cellulose_drain = produce_info.costs.cellulose * game.u_i.time_speed / float(produce_info.grow_time) * 1000.0 * tile.bldg.path_1_value * Helper.get_au_mult(tile)
				for p in produce_info.produce:
					tile.auto_GH.produce[p] = produce_info.produce[p] * game.u_i.time_speed / produce_info.grow_time * 1000.0 * tile.bldg.path_1_value * tile.bldg.path_2_value * pow(Helper.get_au_mult(tile), 2)
					if tile.adj_lake_state == "l":
						tile.auto_GH.produce[p] *= 2
					elif tile.adj_lake_state == "sc":
						tile.auto_GH.produce[p] *= 4
					game.autocollect.mets[p] += tile.auto_GH.produce[p]
				if tile.adj_lake_state == "l":
					tile.auto_GH.cellulose_drain *= 2
				elif tile.adj_lake_state == "sc":
					tile.auto_GH.cellulose_drain *= 4
				game.autocollect.mats.cellulose -= tile.auto_GH.cellulose_drain
			if game.c_v == "planet":
				update_boxes = true
			var mult:float = tile.bldg.overclock_mult if tile.bldg.has("overclock_mult") else 1.0
			if tile.has("auto_collect"):
				if tile.bldg.name == "ME":
					game.autocollect.rsrc_list[String(tile.bldg.c_p_g)].minerals += tile.bldg.path_1_value * tile.auto_collect / 100.0 * mult
					game.autocollect.rsrc.minerals += tile.bldg.path_1_value * tile.auto_collect / 100.0 * mult
				elif tile.bldg.name in ["PP", "SP"]:
					game.autocollect.rsrc_list[String(tile.bldg.c_p_g)].energy += tile.bldg.path_1_value * tile.auto_collect / 100.0 * mult
					game.autocollect.rsrc.energy += tile.bldg.path_1_value * tile.auto_collect / 100.0 * mult
			if tile.bldg.name == "MS":
				game.mineral_capacity += tile.bldg.mineral_cap_upgrade
			elif tile.bldg.name == "NSF":
				game.neutron_cap += tile.bldg.cap_upgrade
			elif tile.bldg.name == "ESF":
				game.electron_cap += tile.bldg.cap_upgrade
			elif tile.bldg.name == "RL":
				if not game.autocollect.rsrc_list.has(String(tile.bldg.c_p_g)):
					game.autocollect.rsrc_list[String(tile.bldg.c_p_g)] = {"minerals":0, "energy":0, "SP":tile.bldg.path_1_value * mult}
				else:
					game.autocollect.rsrc_list[String(tile.bldg.c_p_g)].SP += tile.bldg.path_1_value * mult
				game.autocollect.rsrc.SP += tile.bldg.path_1_value * mult
			elif tile.bldg.name == "PC":
				game.autocollect.particles.proton += tile.bldg.path_1_value * mult / tile.bldg.planet_pressure
			elif tile.bldg.name == "NC":
				game.autocollect.particles.neutron += tile.bldg.path_1_value * mult / tile.bldg.planet_pressure
			elif tile.bldg.name == "EC":
				game.autocollect.particles.electron += tile.bldg.path_1_value * mult * tile.aurora.au_int
			elif tile.bldg.name == "CBD":
				var tile_data:Array
				var same_p:bool = game.c_p_g == tile.bldg.c_p_g
				if same_p:
					tile_data = game.tile_data
				else:
					tile_data = game.open_obj("Planets", tile.bldg.c_p_g)
				var n:int = tile.bldg.path_3_value
				var wid:int = tile.bldg.wid
				for i in n:
					var x:int = tile.bldg.x_pos + i - n / 2
					if x < 0 or x >= wid:
						continue
					for j in n:
						var y:int = tile.bldg.y_pos + j - n / 2
						if y < 0 or y >= tile.bldg.wid or x == tile.bldg.x_pos and y == tile.bldg.y_pos:
							continue
						var id:int = x % wid + y * wid
						if not tile_data[id]:
							tile_data[id] = {}
						var _tile = tile_data[id]
						var id_str:String = String(tile_data.find(tile))
						if not _tile.has("cost_div_dict"):
							_tile.cost_div = tile.bldg.path_1_value
							_tile.cost_div_dict = {}
						else:
							_tile.cost_div = max(_tile.cost_div, tile.bldg.path_1_value)
						_tile.cost_div_dict[id_str] = tile.bldg.path_1_value
						var diff:float = tile.bldg.path_2_value
						if not _tile.has("auto_collect_dict"):
							_tile.auto_collect = tile.bldg.path_2_value
							_tile.auto_collect_dict = {}
						else:
							diff = max(0, tile.bldg.path_2_value - _tile.auto_collect)
							_tile.auto_collect = max(_tile.auto_collect, tile.bldg.path_2_value)
						if not game.autocollect.rsrc_list.has(String(tile.bldg.c_p_g)):
							game.autocollect.rsrc_list[String(tile.bldg.c_p_g)] = {"minerals":0, "energy":0, "SP":0}
						if _tile.has("bldg"):
							var _mult:float = _tile.bldg.overclock_mult if _tile.bldg.has("overclock_mult") else 1.0
							if _tile.bldg.name == "ME":
								game.autocollect.rsrc_list[String(tile.bldg.c_p_g)].minerals += _tile.bldg.path_1_value * diff / 100.0 * _mult
								game.autocollect.rsrc.minerals += _tile.bldg.path_1_value * diff / 100.0 * _mult
							elif _tile.bldg.name in ["PP", "SP"]:
								game.autocollect.rsrc_list[String(tile.bldg.c_p_g)].energy += _tile.bldg.path_1_value * diff / 100.0 * _mult
								game.autocollect.rsrc.energy += _tile.bldg.path_1_value * diff / 100.0 * _mult
						_tile.auto_collect_dict[id_str] = tile.bldg.path_2_value
				if not same_p:
					save_obj("Planets", tile.bldg.c_p_g, tile_data)
			if game.tutorial:
				game.HUD.refresh()
	return update_boxes

func get_reaction_info(tile):
	var MM_value:float = clamp((OS.get_system_time_msecs() - tile.bldg.start_date) / (1000 * tile.bldg.difficulty) * tile.bldg.path_1_value * get_IR_mult(tile.bldg.name) * game.u_i.time_speed, 0, tile.bldg.qty)
	return {"MM_value":MM_value, "progress":MM_value / tile.bldg.qty}

func update_MS_rsrc(dict:Dictionary):
	var curr_time = OS.get_system_time_msecs()
	var prod:float
	if dict.has("tile_num"):
		if dict.bldg.name == "AE":
			prod = 1000 / get_AE_production(dict.pressure, dict.bldg.path_1_value) / dict.tile_num / game.u_i.time_speed
		else:
			prod = 1000 / dict.bldg.path_1_value
			if dict.bldg.name != "MM":
				prod /= dict.tile_num
			prod /= get_prod_mult(dict)
		var stored = dict.bldg.stored
		var c_d = dict.bldg.collect_date
		var c_t = curr_time
		if dict.bldg.has("path_2_value"):
			var cap = dict.bldg.path_2_value * dict.bldg.IR_mult
			if dict.bldg.name != "MM":
				cap = round(cap * dict.tile_num)
			else:
				cap = round(cap)
			if stored < cap:
				if c_t - c_d > prod:
					var rsrc_num = floor((c_t - c_d) / prod)
					dict.bldg.stored += rsrc_num
					dict.bldg.collect_date += prod * rsrc_num
					if dict.bldg.stored >= cap:
						dict.bldg.stored = cap
		else:
			if c_t - c_d > prod:
				var rsrc_num = floor((c_t - c_d) / prod)
				dict.bldg.stored += rsrc_num
				dict.bldg.collect_date += prod * rsrc_num
		return min((c_t - c_d) / prod, 1)
	else:
		return 0

func get_DS_output(star:Dictionary, next_lv:int = 0):
	return Data.MS_output["M_DS_%s" % ((star.MS_lv + next_lv) if star.has("MS") else 0)] * star.luminosity * game.u_i.planck * game.u_i.time_speed

func get_MB_output(star:Dictionary):
	return Data.MS_output.M_MB * star.luminosity * game.u_i.planck * game.u_i.time_speed

func get_MME_output(p_i:Dictionary, next_lv:int = 0):
	return Data.MS_output["M_MME_%s" % ((p_i.MS_lv + next_lv) if p_i.has("MS") else 0)] * pow(p_i.size / 12000.0, 2) * max(1, pow(p_i.pressure, 0.5)) * game.u_i.time_speed

func get_conquer_all_data():
	var max_ship_lv:int = 0
	var HX_data:Array = []
	for ship in game.ship_data:
		max_ship_lv = max(ship.lv, max_ship_lv)
	for planet in game.planet_data:
		if not planet.has("HX_data"):
			continue
		for HX in planet.HX_data:
			if HX.lv > max_ship_lv - 5:
				HX_data.append(HX)
	var energy_cost = round(14000 * game.planet_data[-1].distance)
	return {"HX_data":HX_data, "energy_cost":energy_cost}

var hbox_theme = preload("res://Resources/default_theme.tres")
var text_border_theme = preload("res://Resources/TextBorder.tres")
func add_lv_boxes(obj:Dictionary, v:Vector2, sc:float = 1.0):
	var hbox = HBoxContainer.new()
	hbox.alignment = hbox.ALIGN_CENTER
	hbox.theme = hbox_theme
	hbox["custom_constants/separation"] = -1
	if obj.bldg.has("path_1"):
		var path_1 = Label.new()
		path_1.name = "Path1"
		path_1.text = String(obj.bldg.path_1)
		path_1.connect("mouse_entered", self, "on_path_enter", ["1", obj])
		path_1.connect("mouse_exited", self, "on_path_exit")
		path_1["custom_styles/normal"] = text_border_theme
		hbox.add_child(path_1)
		hbox.mouse_filter = hbox.MOUSE_FILTER_IGNORE
		path_1.mouse_filter = path_1.MOUSE_FILTER_PASS
	if obj.bldg.has("path_2"):
		var path_2 = Label.new()
		path_2.name = "Path2"
		path_2.text = String(obj.bldg.path_2)
		path_2.connect("mouse_entered", self, "on_path_enter", ["2", obj])
		path_2.connect("mouse_exited", self, "on_path_exit")
		path_2["custom_styles/normal"] = text_border_theme
		path_2.mouse_filter = path_2.MOUSE_FILTER_PASS
		hbox.add_child(path_2)
	if obj.bldg.has("path_3"):
		var path_3 = Label.new()
		path_3.name = "Path3"
		path_3.text = String(obj.bldg.path_3)
		path_3.connect("mouse_entered", self, "on_path_enter", ["3", obj])
		path_3.connect("mouse_exited", self, "on_path_exit")
		path_3["custom_styles/normal"] = text_border_theme
		path_3.mouse_filter = path_3.MOUSE_FILTER_PASS
		hbox.add_child(path_3)
	hbox.rect_size.x = 200
	hbox.rect_scale *= sc
	hbox.rect_position = v - Vector2(100, 90) * sc
	#hbox.visible = get_parent().scale.x >= 0.25
	return hbox

func on_path_enter(path:String, obj:Dictionary):
	game.hide_adv_tooltip()
	if not obj.empty():
		game.show_tooltip("%s %s %s %s" % [tr("PATH"), path, tr("LEVEL"), obj.bldg["path_" + path]])

func on_path_exit():
	game.hide_tooltip()

func clever_round (num:float, sd:int = 3, st:bool = false):#sd: significant digits
	var e = floor(log10(abs(num)))
	if e < -4 and st:
		return e_notation(num, sd)
	if sd < e + 1:
		return round(num)
	return stepify(num, pow(10, e - sd + 1))

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

func get_final_value(p_i:Dictionary, dict:Dictionary, path:int, n:int = 1):
	var bldg:String = dict.bldg.name
	var mult:float = get_prod_mult(dict)
	var IR_mult:float = dict.bldg.IR_mult
	if bldg in ["MM", "GH", "AMN", "SPR"]:
		n = 1
	if path == 1:
		if bldg == "SP":
			return get_SP_production(p_i.temperature, dict.bldg.path_1_value * mult, 1 + dict.aurora.au_int if dict.has("aurora") else 1.0) * n
		elif bldg == "SPR":
			return dict.bldg.path_1_value * mult * n * game.u_i.charge
		elif bldg in ["PC", "NC"]:
			return dict.bldg.path_1_value * mult * n / p_i.pressure
		elif bldg == "EC":
			return dict.bldg.path_1_value * mult * n * (dict.aurora.au_int if dict.has("aurora") else 1.0)
		else:
			return dict.bldg.path_1_value * mult * n
	elif path == 2:
		if Data.path_2[bldg].is_value_integer:
			return round(dict.bldg.path_2_value * IR_mult * n)
		else:
			if bldg == "SPR":
				return dict.bldg.path_2_value * mult * n * game.u_i.charge
			else:
				return dict.bldg.path_2_value * IR_mult * n
	elif path == 3:
		return dict.bldg.path_3_value

func get_bldg_tooltip(p_i:Dictionary, dict:Dictionary, n:float = 1):
	var tooltip:String = ""
	var bldg:String = dict.bldg.name
	var path_1_value = get_final_value(p_i, dict, 1, n) if dict.bldg.has("path_1_value") else 0.0
	var path_2_value = get_final_value(p_i, dict, 2, n) if dict.bldg.has("path_2_value") else 0.0
	var path_3_value = get_final_value(p_i, dict, 3, n) if dict.bldg.has("path_3_value") else 0.0
	return get_bldg_tooltip2(bldg, path_1_value, path_2_value, path_3_value)

func get_bldg_tooltip2(bldg:String, path_1_value, path_2_value, path_3_value):
	match bldg:
		"ME", "PP", "SP", "AE":
			return (Data.path_1[bldg].desc + "\n" + Data.path_2[bldg].desc) % [format_num(path_1_value, true), format_num(round(path_2_value))]
		"AMN", "SPR":
			return (Data.path_1[bldg].desc + "\n" + Data.path_2[bldg].desc) % [format_num(path_1_value, true), format_num(path_2_value, true)]
		"MM":
			return (Data.path_1[bldg].desc + "\n" + Data.path_2[bldg].desc) % [format_num(path_1_value, true), format_num(path_2_value, true)]
		"SC", "GF", "SE":
			return "%s\n%s\n%s\n%s" % [Data.path_1[bldg].desc % format_num(path_1_value, true), Data.path_2[bldg].desc % format_num(path_2_value, true), Data.path_3[bldg].desc % path_3_value, tr("CLICK_TO_CONFIGURE")]
		"RL", "PC", "NC", "EC":
			return (Data.path_1[bldg].desc) % [format_num(path_1_value, true)]
		"MS", "NSF", "ESF":
			return (Data.path_1[bldg].desc) % [format_num(round(path_1_value))]
		"RCC", "SY":
			return (Data.path_1[bldg].desc) % [format_num(path_1_value, true)]
		"GH":
			return (Data.path_1[bldg].desc + "\n" + Data.path_2[bldg].desc) % [format_num(path_1_value, true), format_num(path_2_value, true)]
		"CBD":
			return "%s\n%s\n%s" % [
				Data.path_1[bldg].desc % clever_round(path_1_value),
				Data.path_2[bldg].desc % path_2_value,
				Data.path_3[bldg].desc.format({"n":path_3_value})]
		_:
			return ""

func set_overlay_visibility(gradient:Gradient, overlay, offset:float):
	overlay.circle.modulate = gradient.interpolate(offset)
	overlay.circle.visible = game.overlay.toggle_btn.pressed and (not game.overlay.hide_obj_btn.pressed or offset >= 0 and offset <= 1)
	overlay.circle.modulate.a = 1.0 if overlay.circle.visible else 0.0

func check_lake_presence(pos:Vector2, wid:int):
	var state:String
	var has_lake = false
	for i in range(max(0, pos.x - 1), min(pos.x + 2, wid)):
		if not has_lake:
			for j in range(max(0, pos.y - 1), min(pos.y + 2, wid)):
				if Vector2(i, j) != pos:
					var id2 = i % wid + j * wid
					if game.tile_data[id2] and game.tile_data[id2].has("lake"):
						has_lake = true
						state = game.tile_data[id2].lake.state
						break
	return {"has_lake":has_lake, "lake_state":state}

func check_lake(pos:Vector2, wid:int, seed_name:String):
	var state
	var has_lake = false
	for i in range(max(0, pos.x - 1), min(pos.x + 2, wid)):
		for j in range(max(0, pos.y - 1), min(pos.y + 2, wid)):
			if Vector2(i, j) != pos:
				var id2 = i % wid + j * wid
				if game.tile_data[id2] and game.tile_data[id2].has("lake"):
					var okay = game.tile_data[id2].lake.element == game.craft_agriculture_info[seed_name].lake
					has_lake = has_lake or okay
					if okay:
						state = game.tile_data[id2].lake.state
	return [has_lake, state]

func remove_recursive(path):
	var directory = Directory.new()
	
	# Open directory
	var error = directory.open(path)
	if error == OK:
		# List directory content
		directory.list_dir_begin(true)
		var file_name = directory.get_next()
		while file_name != "":
			if directory.current_is_dir():
				remove_recursive(path + "/" + file_name)
			else:
				directory.remove(file_name)
			file_name = directory.get_next()
		
		# Remove current path
		directory.remove(path)
	else:
		print("Error removing " + path)

func get_SC_output(expected_rsrc:Dictionary, amount:float, path_3_value:float, total_stone:float):
	for el in game.stone:
		var item:String
		var el_num = 0
		if el == "Si":
			item = "silicon"
			el_num = game.stone[el] * amount / total_stone / 30.0
		elif el == "Fe" and game.science_unlocked.has("ISC"):
			item = "iron"
			el_num = game.stone[el] * amount / total_stone / 30.0
		elif el == "Al" and game.science_unlocked.has("ISC"):
			item = "aluminium"
			el_num = game.stone[el] * amount / total_stone / 50.0
		elif el == "O":
			item = "sand"
			el_num = game.stone[el] * amount / total_stone / 2.0
		elif el == "Ti" and game.science_unlocked.has("ISC"):
			item = "titanium"
			el_num = game.stone[el] * amount / total_stone / 500.0
		el_num = stepify(el_num * path_3_value, 0.001)
		if el_num != 0:
			expected_rsrc[item] = el_num
