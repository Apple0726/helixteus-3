extends Node

onready var game = get_node("/root/Game")
#var game
#A place to put frequently used functions

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
			rsrc_available = Helper.get_sum_of_dict(rsrc_available)
		text = "%s/%s" % [format_num(rsrc_available, threshold / 2), format_num(rsrc_cost, threshold / 2)] + mass_str
		if rsrc_available >= rsrc_cost:
			color = Color(0.0, 1.0, 0.0, 1.0)
		else:
			color = Color(1.0, 0.0, 0.0, 1.0)
	else:
		var num_str:String = Helper.e_notation(rsrc_cost) if rsrc_cost < 0.0001 else format_num(game.clever_round(rsrc_cost, 3), threshold)
		text = num_str + mass_str
	text_node.text = text
	text_node["custom_colors/font_color"] = color

func put_rsrc(container, min_size, objs, remove:bool = true, show_available:bool = false):
	if remove:
		for child in container.get_children():
			container.remove_child(child)
	var data = []
	for obj in objs:
		var rsrc = game.rsrc_scene.instance()
		var texture = rsrc.get_node("Texture")
		if obj == "money":
			format_text(rsrc.get_node("Text"), texture, "Icons/money", show_available, objs[obj], game.money)
		elif obj == "stone":
			format_text(rsrc.get_node("Text"), texture, "Icons/stone", show_available, objs[obj], game.stone, " kg")
		elif obj == "minerals":
			format_text(rsrc.get_node("Text"), texture, "Icons/minerals", show_available, objs[obj], game.minerals)
		elif obj == "energy":
			format_text(rsrc.get_node("Text"), texture, "Icons/energy", show_available, objs[obj], game.energy)
		elif obj == "time":
			texture.texture_normal = load("res://Graphics/Icons/Time.png")
			rsrc.get_node("Text").text = time_to_str(objs[obj] * 1000.0)
		elif game.mats.has(obj):
			format_text(rsrc.get_node("Text"), texture, "Materials/" + obj, show_available, objs[obj], game.mats[obj], " kg")
		elif game.mets.has(obj):
			format_text(rsrc.get_node("Text"), texture, "Metals/" + obj, show_available, objs[obj], game.mets[obj], " kg")
		else:
			for item_group_info in game.item_groups:
				if item_group_info.dict.has(obj):
					format_text(rsrc.get_node("Text"), texture, item_group_info.path + "/" + obj, show_available, objs[obj], game.get_item_num(obj))
		rsrc.get_node("Texture").connect("mouse_entered", self, "on_rsrc_over", [tr(obj.to_upper())])
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

func get_item_name (name:String):
	if name.substr(0, 7) == "speedup":
		return tr("SPEED_UP") + " " + game.get_roman_num(int(name.substr(7, 1)))
	if name.substr(0, 9) == "overclock":
		return tr("OVERCLOCK") + " " + game.get_roman_num(int(name.substr(9, 1)))
	match name:
		"lead_seeds":
			return tr("LEAD_SEEDS")
		"copper_seeds":
			return tr("COPPER_SEEDS")
		"fertilizer":
			return tr("FERTILIZER")
		"stick":
			return tr("STICK")
		"wooden_pickaxe":
			return tr("WOODEN_PICKAXE")
		"stone_pickaxe":
			return tr("STONE_PICKAXE")
		"lead_pickaxe":
			return tr("LEAD_PICKAXE")
		"copper_pickaxe":
			return tr("COPPER_PICKAXE")
		"iron_pickaxe":
			return tr("IRON_PICKAXE")
		"hx_core":
			return tr("HX_CORE")

func get_plant_name(name:String):
	return tr("PLANT_TITLE").format({"metal":tr(name.split("_")[0].to_upper())})

func get_plant_produce(name:String):
	return name.split("_")[0]

func get_wid(size:float):
	return min(round(pow(size / 4000.0, 0.7) * 8.0) + 3, 300)

func e_notation(num:float):#e notation
	var e = floor(Helper.log10(num))
	var n = num * pow(10, -e)
	return "%se%s" %  [game.clever_round(n), e]

func get_dir_from_name(_name:String):
	if _name.substr(0, 7) == "speedup":
		return "Items/Speedups"
	if _name.substr(0, 9) == "overclock":
		return "Items/Overclocks"
	match _name:
		"lead_seeds", "copper_seeds", "fertilizer":
			return "Agriculture"
		"money":
			return "Icons"
		"minerals":
			return "Icons"
		"hx_core":
			return "Items/Others"

func get_type_from_name(name:String):
	if name.substr(0, 7) == "speedup":
		return "speedup_info"
	if name.substr(0, 9) == "overclock":
		return "overclock_info"
	match name:
		"lead_seeds", "copper_seeds", "fertilizer":
			return "craft_agric_info"
		_:
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
		if p >= 3 and p < 6:
			suff = "k"
		elif p < 9:
			suff = "M"
		elif p < 12:
			suff = "G"
		elif p < 15:
			suff = "T"
		elif p < 18:
			suff = "P"
		return "%s%s" % [game.clever_round(num / div, 3), suff]

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
			return Color(0.9, 0.9, 0.9, 1)
		"H", "Fe":
			return Color(1, 1, 1, 1)
		_:
			return Color(randf(), randf(), randf(), 1)

func mult_dict_by(dict:Dictionary, value:float):
	var dict2:Dictionary = dict.duplicate(true)
	for el in dict:
		dict2[el] = dict[el] * value
	return dict2

func get_crush_info(tile_obj):
	var time = OS.get_system_time_msecs()
	var crush_spd = tile_obj.path_1_value
	var constr_delay = 0
	if tile_obj.is_constructing:
		constr_delay = tile_obj.construction_date + tile_obj.construction_length - time
	var progress = (time - tile_obj.start_date + constr_delay) / 1000.0 * crush_spd / tile_obj.stone_qty
	var qty_left = max(0, round(tile_obj.stone_qty - (time - tile_obj.start_date + constr_delay) / 1000.0 * tile_obj.path_1_value))
	return {"crush_spd":crush_spd, "progress":progress, "qty_left":qty_left}

func get_prod_info(tile_obj):
	var time = OS.get_system_time_msecs()
	var spd = tile_obj.path_1_value#qty1: resource being used. qty2: resource being produced
	var qty_left = game.clever_round(max(0, tile_obj.qty1 - (time - tile_obj.start_date) / 1000.0 * spd / tile_obj.ratio), 3)
	var qty_made = game.clever_round(min(tile_obj.qty2, (time - tile_obj.start_date) / 1000.0 * spd), 3)
	var progress = qty_made / tile_obj.qty2
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
	overlay.rect_scale *= 2

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

func get_rover_weapon_text(name:String):
	var laser = name.split("_")
	return "%s\n%s\n%s" % [tr(laser[0].to_upper() + "_LASER").format({"laser":tr(laser[1])}), "%s: %s" % [tr("DAMAGE"), Data.rover_weapons[name].damage], "%s: %s%s" % [tr("COOLDOWN"), Data.rover_weapons[name].cooldown, tr("S_SECOND")]]

func get_rover_mining_text(name:String):
	var laser = name.split("_", true, 1)
	return "%s\n%s\n%s" % [tr(laser[0].to_upper() + "_LASER").format({"laser":tr(laser[1].to_upper())}), "%s: %s" % [tr("MINING_SPEED"), Data.rover_mining[name].speed], "%s: %s" % [tr("RANGE"), Data.rover_mining[name].rnge]]

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
	parent.add_child(lb)
	yield(tween, "tween_all_completed")
	parent.remove_child(lb)
	remove_child(tween)

func add_minerals(amount:float):
	var mineral_space_available = game.mineral_capacity - game.minerals
	if mineral_space_available >= amount:
		game.minerals += amount
		return 0
	else:
		game.minerals = game.mineral_capacity
		return amount - mineral_space_available

func get_AIE(next_lv:int = 0):
	return 0.24 + (game.MUs.AIE + next_lv) / 100.0

func get_layer(tile:Dictionary, p_i:Dictionary):
	var layer:String = ""
	if tile.has("init_depth"):
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
			var layer2 = "crust" if layer == "surface" or layer == "crater" else layer
			game.add_resources({"stone":amount}, p_i[layer2])
		else:
			game[content] += amount
		if game.show.has(content):
			game.show[content] = true
	if tile.has("current_deposit") and tile.current_deposit.progress > tile.current_deposit.size - 1:
		tile.erase("current_deposit")
	tile.depth += 1
	if tile.has("init_depth") and tile.depth > 3 * tile.init_depth:
		tile.erase("init_depth")

func generate_rock(tile:Dictionary, p_i:Dictionary):
	var aurora_mult = game.clever_round(pow(1 + tile.au_int, Helper.get_AIE())) if tile.has("au_int") else 1.0
	var contents = {}
	var other_volume = 0#in m^3
	#We assume all materials have a density of 1.5g/cm^3 to simplify things
	var rho = 1.5
	for mat in p_i.surface.keys():
		#Material quantity penalty the further you go from surface
		var depth_limit_mult = max(1, 1 + (tile.depth / 2.0 - p_i.crust_start_depth) / float(p_i.crust_start_depth))
		if randf() < p_i.surface[mat].chance / depth_limit_mult * aurora_mult:
			var amount = game.clever_round(p_i.surface[mat].amount * rand_range(0.8, 1.2) / depth_limit_mult * aurora_mult, 3)
			if amount < 1:
				continue
			contents[mat] = amount
			other_volume += amount / rho / 1000
	if get_layer(tile, p_i) != "surface":
		if not tile.has("current_deposit"):
			for met in game.met_info:
				var crater_metal = tile.has("init_depth") and met == tile.crater_metal
				if game.met_info[met].min_depth < tile.depth - p_i.crust_start_depth and tile.depth - p_i.crust_start_depth < game.met_info[met].max_depth or crater_metal:
					if randf() < 0.25 / game.met_info[met].rarity * (6 if crater_metal else 1) * aurora_mult:
						tile.current_deposit = {"met":met, "size":Helper.rand_int(4, 10), "progress":1}
		if tile.has("current_deposit"):
			var met = tile.current_deposit.met
			var size = tile.current_deposit.size
			var progress2 = tile.current_deposit.progress
			var amount_multiplier = -abs(2.0/size * progress2 - 1) + 1
			var amount = game.clever_round(game.met_info[met].amount * rand_range(0.4, 0.45) * amount_multiplier * aurora_mult, 3)
			contents[met] = amount
			other_volume += amount / game.met_info[met].density / 1000
			tile.current_deposit.progress += 1
		#   									                          	    V Every km, rock density goes up by 0.01
	var stone_amount = game.clever_round((1 - other_volume) * 1000 * (2.85 + tile.depth / 100000.0), 3)
	contents.stone = stone_amount
	return contents
