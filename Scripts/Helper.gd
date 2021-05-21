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
		if path == "Icons/stone":
			rsrc_available = get_sum_of_dict(rsrc_available)
		text = "%s/%s" % [format_num(clever_round(rsrc_available, 3), threshold / 2), format_num(clever_round(rsrc_cost, 3), threshold / 2)] + mass_str
		if rsrc_available >= rsrc_cost:
			color = Color(0.0, 1.0, 0.0, 1.0)
		else:
			color = Color(1.0, 0.0, 0.0, 1.0)
	else:
		if path == "Icons/stone":
			rsrc_cost = get_sum_of_dict(rsrc_cost)
		var num_str:String = e_notation(rsrc_cost) if rsrc_cost < 0.0001 else format_num(clever_round(rsrc_cost, 3), threshold)
		if rsrc_cost == 0:
			num_str = "0"
		text = num_str + mass_str
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
			texture.texture_normal = load("res://Graphics/Icons/Time.png")
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
	var seconds = int(floor(time / 1000)) % 60
	var second_zero = "0" if seconds < 10 else ""
	var minutes = int(floor(time / 60000)) % 60
	var minute_zero = "0" if minutes < 10 else ""
	var hours = int(floor(time / 3600000)) % 24
	var days = int(floor (time / 86400000)) % 365
	var years = int(floor (time / 31536000000))
	var year_str = "" if years == 0 else String(years) + "y "
	var day_str = "" if days == 0 else String(days) + "d "
	var hour_str = "" if hours == 0 else String(hours) + ":"
	return year_str + day_str + hour_str + minute_zero + String(minutes) + ":" + second_zero + String(seconds)

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

func get_item_name (_name:String, s:String = ""):
	if _name.substr(0, 7) == "speedup":
		return tr("SPEEDUP") + " " + game.get_roman_num(int(_name.substr(7, 1)))
	if _name.substr(0, 9) == "overclock":
		return tr("OVERCLOCK") + " " + game.get_roman_num(int(_name.substr(9, 1)))
	if len(_name.split("_")) > 1 and _name.split("_")[1] == "seeds":
		return tr("X_SEEDS") % tr(_name.split("_")[0].to_upper())
	match _name:
		"ME":
			return tr("MINERAL_EXTRACTOR%s" % s)
		"PP":
			return tr("POWER_PLANT%s" % s)
		"RL":
			return tr("RESEARCH_LAB%s" % s)
		"MM":
			return tr("MINING_MACHINE%s" % s)
		"MS":
			return tr("MINERAL_SILO%s" % s)
		"RCC":
			return tr("ROVER_CONSTR_CENTER%s" % s)
		"SC":
			return tr("STONE_CRUSHER%s" % s)
		"GF":
			return tr("GLASS_FACTORY%s" % s)
		"SE":
			return tr("STEAM_ENGINE%s" % s)
		"GH":
			return tr("GREENHOUSE%s" % s)
		"SP":
			return tr("SOLAR_PANELS")
		"AE":
			return tr("ATMOSPHERE_EXTRACTOR%s" % s)
		"AMN", "SPR", "SY", "PCC":
			return tr("%s_NAME" % _name)
	return tr(_name.to_upper())

func get_plant_name(name:String):
	return tr("PLANT_TITLE").format({"metal":tr(name.split("_")[0].to_upper())})

func get_plant_produce(name:String):
	return name.split("_")[0]

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
	if _name.substr(0, 7) == "speedup":
		return "Items/Speedups"
	if _name.substr(0, 9) == "overclock":
		return "Items/Overclocks"
	if _name.substr(0, 7) == "hx_core":
		return "Items/Others"
	match _name:
		"fertilizer":
			return "Agriculture"
		"money":
			return "Icons"
		"minerals":
			return "Icons"
	if _name.split("_")[1] == "seeds":
		return "Agriculture"
	return ""

func get_type_from_name(_name:String):
	if _name.substr(0, 7) == "speedup":
		return "speedups_info"
	if _name.substr(0, 9) == "overclock":
		return "overclocks_info"
	if _name.substr(0, 7) == "hx_core":
		return "other_items_info"
	match _name:
		"fertilizer":
			return "craft_agriculture_info"
	if _name.split("_")[1] == "seeds":
		return "craft_agriculture_info"
	return ""

func format_num(num:float, threshold:int = 6):
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
	var crush_spd = tile_obj.bldg.path_1_value
	var constr_delay = 0
	if tile_obj.bldg.is_constructing:
		constr_delay = tile_obj.bldg.construction_date + tile_obj.bldg.construction_length - time
	var progress = (time - tile_obj.bldg.start_date + constr_delay) / 1000.0 * crush_spd / tile_obj.bldg.stone_qty
	var qty_left = max(0, round(tile_obj.bldg.stone_qty - (time - tile_obj.bldg.start_date + constr_delay) / 1000.0 * tile_obj.bldg.path_1_value))
	return {"crush_spd":crush_spd, "progress":progress, "qty_left":qty_left}

func get_prod_info(tile_obj):
	var time = OS.get_system_time_msecs()
	var spd = tile_obj.bldg.path_1_value#qty1: resource being used. qty2: resource being produced
	var qty_left = clever_round(max(0, tile_obj.bldg.qty1 - (time - tile_obj.bldg.start_date) / 1000.0 * spd / tile_obj.bldg.ratio), 3)
	var qty_made = clever_round(min(tile_obj.bldg.qty2, (time - tile_obj.bldg.start_date) / 1000.0 * spd), 3)
	var progress = qty_made / tile_obj.bldg.qty2#1 = complete
	return {"spd":spd, "progress":progress, "qty_made":qty_made, "qty_left":qty_left}

func add_overlay(parent, self_node, c_v:String, obj_info:Dictionary, overlays:Array):
	var overlay_texture = preload("res://Graphics/Elements/Default.png")
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
	#overlay.rect_scale *= 2

func toggle_overlay(obj_btns, overlays):
	for obj_btn in obj_btns:
		obj_btn.visible = not obj_btn.visible
	for overlay in overlays:
		overlay.circle.visible = not overlay.circle.visible

func change_circle_size(value, overlays):
	for overlay in overlays:
		overlay.circle.rect_scale.x = 2 * value
		overlay.circle.rect_scale.y = 2 * value

func save_obj(type:String, id:int, arr:Array):
	var save:File = File.new()
	var file_path:String = "user://Save1/%s/%s.hx3" % [type, id]
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

func show_dmg(dmg:int, pos:Vector2, parent, sc:float = 1.0, missed:bool = false, crit:bool = false):
	var lb:Label = Label.new()
	lb["custom_fonts/font"] = load("res://Resources/DamageText.tres")
	if missed:
		lb["custom_colors/font_color"] = Color(1, 1, 0, 1)
		lb.text = tr("MISSED")
	else:
		lb["custom_colors/font_color"] = Color(1, 0.2, 0.2, 1)
		lb.text = "- %s" % [dmg]
		if crit:
			lb.text = "%s\n- %s" % [tr("CRITICAL"), dmg]
		else:
			lb.text = "- %s" % [dmg]
	lb.rect_position = pos - Vector2(0, 40)
	lb.rect_scale *= sc
	var dur = 1.5 if crit else 1.0
	var tween:Tween = Tween.new()
	tween.interpolate_property(lb, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), dur)
	tween.interpolate_property(lb, "rect_position", null, pos - Vector2(0, 55), dur, Tween.TRANS_BACK, Tween.EASE_OUT)
	add_child(tween)
	tween.start()
	#lb.light_mask = 2
	parent.add_child(lb)
	yield(tween, "tween_all_completed")
	if parent:
		parent.remove_child(lb)
		lb.queue_free()
		remove_child(tween)
		tween.queue_free()

func add_minerals(amount:float, add:bool = true):
	var min_cap = game.mineral_capacity * get_IR_mult("MS")
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
				game.money += ceil(diff / min_cap) * round(min_cap) * (game.MUs.MV + 4)
			return {"added":amount, "remainder":0}
		else:
			if add:
				game.minerals = min_cap
			return {"added":mineral_space_available, "remainder":amount - mineral_space_available}

func get_AIE(next_lv:int = 0):
	return 0.48 + (game.MUs.AIE + next_lv) / 50.0

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
				if not is_MM:
					game.long_popup(tr("YOU_MINED_MATERIALS"), tr("MATERIALS"))
				game.inventory.get_node("Tabs/Materials").visible = true
				game.show.materials = true
		elif game.mets.has(content):
			if not game.show.metals:
				if not is_MM:
					game.long_popup(tr("YOU_MINED_METALS"), tr("METALS"))
				game.inventory.get_node("Tabs/Metals").visible = true
				game.show.metals = true
			game.mets[content] += amount
		elif content == "stone":
			game.add_resources({"stone":contents.stone})
		elif content == "ship_locator":
			if not game.objective.empty() and game.objective.type == game.ObjectiveType.SIGNAL:
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
	var contents = {}
	var other_volume = 0#in m^3
	#We assume all materials have a density of 1.5g/cm^3 to simplify things
	var rho = 1.5
	#Material quantity penalty the further you go from surface
	var depth_limit_mult = max(1, 1 + (((2 * tile.depth + depth) / 2.0) - p_i.crust_start_depth) / float(p_i.crust_start_depth))
	for mat in p_i.surface.keys():
		var chance_mult:float = min(p_i.surface[mat].chance / depth_limit_mult * aurora_mult, 1)
		var amount = p_i.surface[mat].amount * rand_range(0.8, 1.2) / depth_limit_mult * aurora_mult * chance_mult * depth
		if amount < 1:
			continue
		contents[mat] = amount
		other_volume += amount / rho / 1000
	for met in game.met_info:
		var met_info = game.met_info[met]
		var chance_mult:float = 0.25 / met_info.rarity * aurora_mult
		if tile.has("crater") and met == tile.crater.metal:
			chance_mult = min(7.0 / (7.0 + 1 / (chance_mult * 6.0)), 1)
			contents[met] = met_info.amount * rand_range(0.2, 0.225) * aurora_mult * chance_mult * min(depth, 2 * tile.crater.init_depth)
		else:
			chance_mult = min(7.0 / (7.0 + 1 / chance_mult), 1)
			var end_depth:int = tile.depth + depth
			var met_start_depth:int = met_info.min_depth + p_i.crust_start_depth
			var met_end_depth:int = met_info.max_depth + p_i.crust_start_depth
			var num_tiles:int = end_depth - met_start_depth
			var num_tiles2:int = met_end_depth - tile.depth
			var num_tiles3:int = clamp(min(num_tiles, num_tiles2), 0, min(depth, met_end_depth - met_start_depth))
			var amount:float = met_info.amount * rand_range(0.4, 0.45) * aurora_mult * chance_mult * num_tiles3
			contents[met] = amount
			other_volume += amount / met_info.density / 1000
		#   									                          	    V Every km, rock density goes up by 0.01
	var stone_amount = (depth - other_volume) * 1000 * (2.85 + (2 * tile.depth + depth) / 200000.0)
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
	var contents = {}
	var other_volume = 0#in m^3
	#We assume all materials have a density of 1.5g/cm^3 to simplify things
	var rho = 1.5
	#Material quantity penalty the further you go from surface
	var depth_limit_mult = max(1, 1 + (tile.depth - p_i.crust_start_depth) / float(p_i.crust_start_depth))
	if depth_limit_mult > 0.01:
		for mat in p_i.surface.keys():
			if randf() < p_i.surface[mat].chance / depth_limit_mult * aurora_mult:
				var amount = clever_round(p_i.surface[mat].amount * rand_range(0.8, 1.2) / depth_limit_mult * aurora_mult, 3)
				if amount < 1:
					continue
				contents[mat] = amount
				other_volume += amount / rho / 1000
	if get_layer(tile, p_i) != "surface":
		if not tile.has("current_deposit"):
			for met in game.met_info:
				var crater_metal = tile.has("crater") and tile.crater.has("init_depth") and met == tile.crater.metal
				if game.met_info[met].min_depth < tile.depth - p_i.crust_start_depth and tile.depth - p_i.crust_start_depth < game.met_info[met].max_depth or crater_metal:
					if randf() < 0.25 / game.met_info[met].rarity * (6 if crater_metal else 1) * aurora_mult:
						tile.current_deposit = {"met":met, "size":rand_int(4, 10), "progress":1}
		if tile.has("current_deposit"):
			var met = tile.current_deposit.met
			var size = tile.current_deposit.size
			var progress2 = tile.current_deposit.progress
			var amount_multiplier = -abs(2.0/size * progress2 - 1) + 1
			var amount = clever_round(game.met_info[met].amount * rand_range(0.4, 0.45) * amount_multiplier * aurora_mult, 3)
			contents[met] = amount
			other_volume += amount / game.met_info[met].density / 1000
			tile.current_deposit.progress += 1
		#   									                          	    V Every km, rock density goes up by 0.01
	var stone_amount = clever_round((1 - other_volume) * 1000 * (2.85 + tile.depth / 100000.0), 3)
	contents.stone = get_stone_comp_from_amount(p_i[get_rock_layer(tile, p_i)], stone_amount)
	if tile.has("ship_locator_depth") and tile.depth >= tile.ship_locator_depth:
		contents.ship_locator = 1
	return contents

func get_IR_mult(bldg_name:String):
	var mult = 1.0
	var sc:String
	if bldg_name in ["PP", "SP"]:
		sc = "EPE"
	else:
		sc = "%sE" % bldg_name
	if game.infinite_research.has(sc):
		mult = pow(Data.infinite_research_sciences[sc].value, game.infinite_research[sc])
	return mult

func add_ship_XP(id:int, XP:float):
	var ship_data = game.ship_data
	ship_data[id].XP += XP
	while ship_data[id].XP >= ship_data[id].XP_to_lv:
		ship_data[id].XP -= ship_data[id].XP_to_lv
		ship_data[id].XP_to_lv = round(ship_data[id].XP_to_lv * 1.3)
		ship_data[id].lv += 1
		ship_data[id].total_HP = round(ship_data[id].total_HP * 1.15)
		ship_data[id].HP = ship_data[id].total_HP
		ship_data[id].atk = round(ship_data[id].atk * 1.15)
		ship_data[id].acc = round(ship_data[id].acc * 1.15)
		ship_data[id].eva = round(ship_data[id].eva * 1.15)

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
	return clever_round(value * temp * au_mult / 273.0, 3)

#atm extractor
func get_AE_production(pressure:float, value:float):
	return clever_round(value * pressure, 3)

func update_rsrc(p_i, tile, rsrc = null):
	var curr_time = OS.get_system_time_msecs()
	var current_bar
	var capacity_bar
	var rsrc_text
	if rsrc:
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
			var prod
			if tile.bldg.name == "SP":
				prod = 1000 / get_SP_production(p_i.temperature, tile.bldg.path_1_value, get_au_mult(tile))
			elif tile.bldg.name == "AE":
				prod = 1000 / get_AE_production(p_i.pressure, tile.bldg.path_1_value)
			else:
				prod = 1000 / tile.bldg.path_1_value
			prod /= get_prod_mult(tile)
			var cap = round(tile.bldg.path_2_value * tile.bldg.IR_mult)
			var stored = tile.bldg.stored
			var c_d = tile.bldg.collect_date
			var c_t = curr_time
			if c_t < c_d and not tile.bldg.is_constructing:
				tile.bldg.collect_date = curr_time
			if stored < cap:
				if c_t - c_d > prod:
					var rsrc_num = floor((c_t - c_d) / prod)
					tile.bldg.stored += rsrc_num
					tile.bldg.collect_date += prod * rsrc_num
					if tile.bldg.stored >= cap:
						tile.bldg.stored = cap
			if rsrc:
				if tile.bldg.stored >= cap:
					current_bar.value = 0
					capacity_bar.value = 1
				else:
					current_bar.value = min((c_t - c_d) / prod, 1)
					capacity_bar.value = min(stored / float(cap), 1)
				if tile.bldg.name == "MM":
					rsrc_text.text = "%s / %s m" % [tile.depth + tile.bldg.stored, tile.depth + cap]
				else:
					rsrc_text.text = String(stored)
		"RL":
			var prod = 1000 / tile.bldg.path_1_value
			prod /= get_prod_mult(tile)
			var stored = tile.bldg.stored
			var c_d = tile.bldg.collect_date
			var c_t = curr_time
			if c_t < c_d:
				tile.bldg.collect_date = curr_time
			if c_t - c_d > prod:
				var rsrc_num = floor((c_t - c_d) / prod)
				tile.bldg.stored += rsrc_num
				tile.bldg.collect_date += prod * rsrc_num
			if rsrc:
				current_bar.value = min((c_t - c_d) / prod, 1)
				rsrc_text.text = String(stored)
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
		"SPR":
			if tile.bldg.has("qty"):
				var reaction_info = get_reaction_info(tile)
				var MM_value = reaction_info.MM_value
				capacity_bar.value = reaction_info.progress
				rsrc_text.text = "%s mol" % [clever_round(MM_value, 2)]
			else:
				rsrc_text.text = ""
				capacity_bar.value = 0

func get_prod_mult(tile):
	var mult = tile.bldg.IR_mult
	if tile.bldg.has("overclock_mult"):
		mult *= tile.bldg.overclock_mult
	return mult

func has_IR(bldg_name:String):
	return bldg_name in ["ME", "PP", "RL", "MS", "SP"]

func collect_rsrc(rsrc_collected:Dictionary, p_i:Dictionary, tile:Dictionary, tile_id:int):
	if not tile.has("bldg"):
		return
	var bldg:String = tile.bldg.name
	var curr_time = OS.get_system_time_msecs()
	update_rsrc(p_i, tile)
	match bldg:
		"ME":
			var stored = tile.bldg.stored
			var min_info:Dictionary = add_minerals(stored)
			tile.bldg.stored = min_info.remainder
			add_item_to_coll(rsrc_collected, "minerals", min_info.added)
			if stored == round(tile.bldg.path_2_value * tile.bldg.IR_mult):
				tile.bldg.collect_date = curr_time
		"PP":
			var stored = tile.bldg.stored
			if stored == round(tile.bldg.path_2_value * tile.bldg.IR_mult):
				tile.bldg.collect_date = curr_time
			#game.energy += stored
			add_item_to_coll(rsrc_collected, "energy", stored)
			tile.bldg.stored = 0
		"SP":
			var stored = tile.bldg.stored
			if stored == round(tile.bldg.path_2_value * tile.bldg.IR_mult):
				tile.bldg.collect_date = curr_time
			#game.energy += stored
			add_item_to_coll(rsrc_collected, "energy", stored)
			tile.bldg.stored = 0
		"AE":
			collect_AE(p_i, tile, rsrc_collected, curr_time)
		"RL":
			#game.SP += tile.bldg.stored
			add_item_to_coll(rsrc_collected, "SP", tile.bldg.stored)
			tile.bldg.stored = 0
		"MM":
			collect_MM(p_i, tile, rsrc_collected, curr_time)

func collect_MM(p_i:Dictionary, dict:Dictionary, rsrc_collected:Dictionary, curr_time, n:int = 1):
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
	
func collect_AE(p_i:Dictionary, dict:Dictionary, rsrc_collected:Dictionary, curr_time, n:int = 1):
	update_MS_rsrc(p_i)
	var stored = dict.bldg.stored
	if stored == round(dict.bldg.path_2_value):
		dict.bldg.collect_date = curr_time
	stored *= n
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
	if num is float:
		if num == 0:
			return
		if dict.has(item):
			dict[item] += num
		else:
			dict[item] = num
	else:
		if not dict.has("stone"):
			dict.stone = {}
		for el in num:
			if dict.stone.has(el):
				dict.stone[el] += num[el]
			else:
				dict.stone[el] = num[el]

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
	if progress > 1:
		if tile.bldg.is_constructing:
			tile.bldg.is_constructing = false
			game.xp += tile.bldg.XP
			if not game.objective.empty() and game.objective.type == game.ObjectiveType.BUILD and game.objective.data == tile.bldg.name:
				game.objective.current += 1
			if tile.bldg.has("rover_id"):
				game.rover_data[tile.bldg.rover_id].ready = true
				tile.bldg.erase("rover_id")
			if game.c_v == "planet":
				update_boxes = true
			if tile.bldg.name == "MS":
				game.mineral_capacity += tile.bldg.mineral_cap_upgrade
			game.HUD.refresh()
	return update_boxes

func get_reaction_info(tile):
	var MM_value:float = clamp((OS.get_system_time_msecs() - tile.bldg.start_date) / (1000 * tile.bldg.difficulty) * tile.bldg.path_1_value, 0, tile.bldg.qty)
	return {"MM_value":MM_value, "progress":MM_value / tile.bldg.qty}

func update_MS_rsrc(dict:Dictionary):
	var curr_time = OS.get_system_time_msecs()
	var prod
	if dict.has("MS"):
		if dict.MS == "M_DS":
			prod = 1000.0 / Helper.get_DS_output(dict)
		elif dict.MS == "M_MME":
			prod = 1000.0 / Helper.get_MME_output(dict)
		if prod:
			var stored = dict.bldg.stored
			var c_d = dict.bldg.collect_date
			var c_t = curr_time
			if c_t - c_d > prod:
				var rsrc_num = floor((c_t - c_d) / prod)
				dict.bldg.stored += rsrc_num
				dict.bldg.collect_date += prod * rsrc_num
			return min((c_t - c_d) / prod, 1)
	elif dict.has("bldg"):
		if dict.bldg.name == "AE":
			prod = 1000 / get_AE_production(dict.pressure, dict.bldg.path_1_value)
		else:
			prod = 1000 / dict.bldg.path_1_value
		if dict.bldg.name != "MM":
			prod /= dict.tile_num
		var stored = dict.bldg.stored
		var c_d = dict.bldg.collect_date
		var c_t = curr_time
		if dict.bldg.has("path_2_value"):
			var cap = round(dict.bldg.path_2_value * dict.bldg.IR_mult)
			if stored < cap:
				if c_t - c_d > prod:
					var rsrc_num = floor((c_t - c_d) / prod)
					dict.bldg.stored += rsrc_num
					dict.bldg.collect_date += prod * rsrc_num
					if dict.bldg.stored >= cap:
						dict.bldg.stored = cap
		return min((c_t - c_d) / prod, 1)

func get_DS_output(star:Dictionary, next_lv:int = 0):
	return Data.MS_output["M_DS_%s" % ((star.MS_lv + next_lv) if star.has("MS") else 0)] * star.luminosity

func get_MB_output(star:Dictionary):
	return Data.MS_output.M_MB * star.luminosity

func get_MME_output(p_i:Dictionary, next_lv:int = 0):
	return Data.MS_output["M_MME_%s" % ((p_i.MS_lv + next_lv) if p_i.has("MS") else 0)] * pow(p_i.size / 12000.0, 2) * max(1, pow(p_i.pressure, 0.5))

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

func add_lv_boxes(obj:Dictionary, v:Vector2):
	var hbox = HBoxContainer.new()
	hbox.alignment = hbox.ALIGN_CENTER
	hbox.theme = load("res://Resources/panel_theme.tres")
	hbox["custom_constants/separation"] = -1
	if obj.bldg.has("path_1"):
		var path_1 = Label.new()
		path_1.name = "Path1"
		path_1.text = String(obj.bldg.path_1)
		path_1.connect("mouse_entered", self, "on_path_enter", ["1", obj])
		path_1.connect("mouse_exited", self, "on_path_exit")
		path_1["custom_styles/normal"] = load("res://Resources/TextBorder.tres")
		hbox.add_child(path_1)
		hbox.mouse_filter = hbox.MOUSE_FILTER_IGNORE
		path_1.mouse_filter = path_1.MOUSE_FILTER_PASS
	if obj.bldg.has("path_2"):
		var path_2 = Label.new()
		path_2.name = "Path2"
		path_2.text = String(obj.bldg.path_2)
		path_2.connect("mouse_entered", self, "on_path_enter", ["2", obj])
		path_2.connect("mouse_exited", self, "on_path_exit")
		path_2["custom_styles/normal"] = load("res://Resources/TextBorder.tres")
		path_2.mouse_filter = path_2.MOUSE_FILTER_PASS
		hbox.add_child(path_2)
	if obj.bldg.has("path_3"):
		var path_3 = Label.new()
		path_3.name = "Path3"
		path_3.text = String(obj.bldg.path_3)
		path_3.connect("mouse_entered", self, "on_path_enter", ["3", obj])
		path_3.connect("mouse_exited", self, "on_path_exit")
		path_3["custom_styles/normal"] = load("res://Resources/TextBorder.tres")
		path_3.mouse_filter = path_3.MOUSE_FILTER_PASS
		hbox.add_child(path_3)
	hbox.rect_size.x = 200
	hbox.rect_position = v - Vector2(100, 90)
	#hbox.visible = get_parent().scale.x >= 0.25
	return hbox

func on_path_enter(path:String, obj):
	game.hide_adv_tooltip()
	game.show_tooltip("%s %s %s %s" % [tr("PATH"), path, tr("LEVEL"), obj.bldg["path_" + path]])

func on_path_exit():
	game.hide_tooltip()

func clever_round (num:float, sd:int = 4):#sd: significant digits
	var e = floor(log10(abs(num)))
	if sd < e + 1:
		return round(num)
	return stepify(num, pow(10, e - sd + 1))
