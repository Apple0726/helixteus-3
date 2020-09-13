extends Node2D

onready var time_scene = load("res://Scenes/TimeLeft.tscn")
onready var rsrc_scene = load("res://Scenes/ResourceStocked.tscn")
onready var game = get_node("/root/Game")
onready var view = game.view
onready var id = game.c_p
onready var p_i = game.planet_data[id]
onready var id_offset = p_i.tile_id_start
var bldg_to_construct:String = ""
var constr_costs:Dictionary = {}
var shadow:Sprite
var tile_over:int = -1
onready var wid:int = round(pow(p_i.tile_num, 0.5))
onready var planet_bounds:PoolVector2Array = [Vector2.ZERO, Vector2(0, wid * 200), Vector2(wid * 200, wid * 200), Vector2(wid * 200, 0)]

func _ready():
	if p_i.has("lake_1"):
		var phase_1_scene = load("res://Scenes/PhaseDiagrams/" + p_i.lake_1 + ".tscn")
		var phase_1 = phase_1_scene.instance()
		$Lakes1.modulate = phase_1.colors[Helper.get_state(p_i.temperature, p_i.pressure, phase_1)]
	if p_i.has("lake_2"):
		var phase_2_scene = load("res://Scenes/PhaseDiagrams/" + p_i.lake_2 + ".tscn")
		var phase_2 = phase_2_scene.instance()
		$Lakes2.modulate = phase_2.colors[Helper.get_state(p_i.temperature, p_i.pressure, phase_2)]
	for i in wid:
		for j in wid:
			if p_i.temperature > 1000:
				$TileMap.set_cell(i, j, 8)
			else:
				$TileMap.set_cell(i, j, p_i.type - 3)
			var id = i % wid + j * wid + id_offset
			var tile = game.tile_data[id]
			if tile.bldg_str == "rock":
				$Rocks.set_cell(i, j, 0)
			match tile.bldg_str:
				"ME", "PP":
					add_bldg(id, tile.bldg_str)
	if p_i.has("lake_1"):
		for i in wid:
			for j in wid:
				var tile = game.tile_data[i % wid + j * wid + id_offset]
				var lake = tile.bldg_str.split("_")
				if len(lake) == 3 and lake[2] != "1":
					continue
				if lake[0] == "liquid":
					$Lakes1.set_cell(i, j, 0)
				elif lake[0] == "solid":
					$Lakes1.set_cell(i, j, 1)
				elif lake[0] == "superfluid":
					$Lakes1.set_cell(i, j, 2)
	if p_i.has("lake_2"):
		for i in wid:
			for j in wid:
				var tile = game.tile_data[i % wid + j * wid + id_offset]
				var lake = tile.bldg_str.split("_")
				if len(lake) == 3 and lake[2] != "2":
					continue
				if lake[0] == "liquid":
					$Lakes2.set_cell(i, j, 0)
				elif lake[0] == "solid":
					$Lakes2.set_cell(i, j, 1)
				elif lake[0] == "superfluid":
					$Lakes2.set_cell(i, j, 2)
	$Lakes1.update_bitmask_region()
	$Lakes2.update_bitmask_region()

func show_tooltip(tile):
	var strs = tile.bldg_str.split("_")
	var tooltip:String = ""
	var icons = []
	var adv = false
	match strs[0]:
		"ME":
			tooltip = "Extracts " + (Data.path_1[tile.bldg_str].desc + "\n" + Data.path_2[tile.bldg_str].desc) % [tile.path_1_value, tile.path_2_value]
			#tooltip = "Produces @i%s per second\nStores @i%s" % [tile.bldg_info.production, tile.bldg_info.capacity]
			icons = [load("res://Graphics/Icons/Minerals.png"), load("res://Graphics/Icons/Minerals.png")]
			tooltip += "\n" + tr("PRESS_F_TO_UPGRADE") + "\n" + tr("PRESS_Q_TO_DUPLICATE")
			adv = true
		"PP":
			tooltip = "Generates " + (Data.path_1[tile.bldg_str].desc + "\n" + Data.path_2[tile.bldg_str].desc) % [tile.path_1_value, tile.path_2_value]
			#tooltip = "Produces @i%s per second\nStores @i%s" % [tile.bldg_info.production, tile.bldg_info.capacity]
			icons = [load("res://Graphics/Icons/Energy.png"), load("res://Graphics/Icons/Energy.png")]
			tooltip += "\n" + tr("PRESS_F_TO_UPGRADE") + "\n" + tr("PRESS_Q_TO_DUPLICATE")
			adv = true
		"liquid":
			tooltip = tr("LIQUID") + " " + tr(strs[1].to_upper())
		"solid":
			tooltip = tr("SOLID") + " " + tr(strs[1].to_upper())
		"superfluid":
			tooltip = tr("SUPERFLUID") + " " + tr(strs[1].to_upper())
		"rock":
			tooltip = tr("BOULDER_DESC")
	if adv:
		if tile.bldg_str == "":
			game.hide_adv_tooltip()
		else:
			if not game.get_node("Tooltip").visible:
				game.show_adv_tooltip(tooltip, icons)
	else:
		if tile.bldg_str == "":
			game.hide_tooltip()
			game.hide_adv_tooltip()
		else:
			game.show_tooltip(tooltip)

var prev_tile_over = -1
func _input(event):
	if tile_over != -1:
		var tile = game.tile_data[tile_over]
		if tile.bldg_str != "":
			if Input.is_action_just_released("duplicate"):
				game.put_bottom_info(tr("STOP_CONSTRUCTION"))
				construct(tile.bldg_str, Data.costs[tile.bldg_str])
			if Input.is_action_just_released("upgrade"):
				game.add_upgrade_panel([tile_over])
	if event is InputEventMouseMotion:
		var mouse_pos = to_local(event.position)
		var mouse_on_tiles = Geometry.is_point_in_polygon(mouse_pos, planet_bounds)
		$WhiteRect.visible = mouse_on_tiles
		$WhiteRect.position.x = floor(mouse_pos.x / 200) * 200
		$WhiteRect.position.y = floor(mouse_pos.y / 200) * 200
		if mouse_on_tiles:
			tile_over = int(mouse_pos.x / 200) % wid + floor(mouse_pos.y / 200) * wid
			if tile_over != prev_tile_over:
				game.hide_tooltip()
				show_tooltip(game.tile_data[tile_over + id_offset])
			prev_tile_over = tile_over
		else:
			if tile_over != -1:
				game.hide_tooltip()
				tile_over = -1
			game.hide_adv_tooltip()
		if shadow:
			shadow.visible = mouse_on_tiles
			shadow.position.x = floor(mouse_pos.x / 200) * 200
			shadow.position.y = floor(mouse_pos.y / 200) * 200
			shadow.position += Vector2(100, 100)
	if Input.is_action_just_released("left_click") and not view.dragged:
		var mouse_pos = to_local(event.position)
		if not Geometry.is_point_in_polygon(mouse_pos, planet_bounds):
			return
		var tile_id = int(mouse_pos.x / 200) % wid + floor(mouse_pos.y / 200) * wid
		var tile = game.tile_data[tile_id + id_offset]
		if tile.bldg_str == "":
			if bldg_to_construct != "":
				if game.check_enough(constr_costs):
					game.deduct_resources(constr_costs)
					tile.bldg_str = bldg_to_construct
					if not game.show.minerals and tile.bldg_str == "ME":
						game.show.minerals = true
					tile.is_constructing = true
					tile.construction_date = OS.get_system_time_msecs()
					tile.construction_length = constr_costs.time * 1000
					match bldg_to_construct:
						"ME", "PP":
							tile.collect_date = tile.construction_date + tile.construction_length
							tile.collect_date = tile.construction_date + tile.construction_length
							tile.stored = 0
							tile.path_1 = 1
							tile.path_1_value = Data.path_1[tile.bldg_str].value
							tile.path_2 = 1
							tile.path_2_value = Data.path_2[tile.bldg_str].value
					add_bldg(tile_id + id_offset, bldg_to_construct)
					add_time_bar(tile_id + id_offset)
				else:
					game.popup("Not enough resources", 1.2)
			elif game.about_to_mine:
				game.get_node("Control/BottomInfo").visible = false
				game.c_t = tile_id + id_offset
				game.switch_view("mining")
		else:
			match tile.bldg_str:
				"ME":
					var mineral_space_available = game.mineral_capacity - game.minerals
					var stored = tile.stored
					if mineral_space_available >= stored:
						tile.stored = 0
						game.minerals += stored
					else:
						game.minerals = game.mineral_capacity
						tile.stored -= mineral_space_available
					if stored == tile.path_2_value:
						tile.collect_date = OS.get_system_time_msecs()
				"PP":
					var stored = tile.stored
					if stored == tile.path_2_value:
						tile.collect_date = OS.get_system_time_msecs()
					game.energy += stored
					tile.stored = 0
	if Input.is_action_just_released("right_click"):
		game.get_node("Control/BottomInfo").visible = false
		finish_construct()

var time_bars = []
var rsrcs = []
var bldgs = []#Tiles with a bldg

func add_time_bar(id:int):
	var local_id = id - id_offset
	var v = Vector2.ZERO
	v.x = (local_id % wid) * 200
	v.y = floor(local_id / wid) * 200
	v += Vector2(100, 15)
	var time_bar = time_scene.instance()
	time_bar.rect_position = v
	add_child(time_bar)
	time_bar.modulate = Color(0, 0.74, 0, 1)
	time_bars.append({"node":time_bar, "id":id})

func add_bldg(id:int, st:String):
	var bldg = Sprite.new()
	bldg.texture = load("res://Graphics/Buildings/" + st + ".png")
	bldg.scale *= 0.4
	var local_id = id - id_offset
	var v = Vector2.ZERO
	v.x = (local_id % wid) * 200
	v.y = floor(local_id / wid) * 200
	v += Vector2(100, 100)
	bldg.position = v
	add_child(bldg)
	var tile = game.tile_data[id]
	bldgs.append(tile)
	match st:
		"ME":
			add_rsrc(v, Color(0, 0.5, 0.9, 1), Data.icons.ME, id)
		"PP":
			add_rsrc(v, Color(0, 0.8, 0, 1), Data.icons.PP, id)
	var hbox = HBoxContainer.new()
	hbox.alignment = hbox.ALIGN_CENTER
	hbox.theme = load("res://Resources/panel_theme.tres")
	hbox["custom_constants/separation"] = -1
	var path_1 = Label.new()
	path_1.text = String(tile.path_1)
	path_1.connect("mouse_entered", self, "on_path_enter", ["1", String(tile.path_1)])
	path_1.connect("mouse_exited", self, "on_path_exit")
	path_1["custom_styles/normal"] = load("res://Resources/TextBorder.tres")
	hbox.add_child(path_1)
	hbox.mouse_filter = hbox.MOUSE_FILTER_IGNORE
	path_1.mouse_filter = path_1.MOUSE_FILTER_PASS
	if tile.has("path_2"):
		var path_2 = Label.new()
		path_2.text = String(tile.path_2)
		path_2.connect("mouse_entered", self, "on_path_enter", ["2", String(tile.path_2)])
		path_2.connect("mouse_exited", self, "on_path_exit")
		path_2["custom_styles/normal"] = load("res://Resources/TextBorder.tres")
		path_2.mouse_filter = path_2.MOUSE_FILTER_PASS
		hbox.add_child(path_2)
	if tile.has("path_3"):
		var path_3 = Label.new()
		path_3.text = String(tile.path_3)
		path_3.connect("mouse_entered", self, "on_path_enter", ["3", String(tile.path_3)])
		path_3.connect("mouse_exited", self, "on_path_exit")
		path_3["custom_styles/normal"] = load("res://Resources/TextBorder.tres")
		path_3.mouse_filter = path_3.MOUSE_FILTER_PASS
		hbox.add_child(path_3)
	hbox.rect_size.x = 200
	hbox.rect_position = v - Vector2(100, 90)
	add_child(hbox)
	if tile.is_constructing:
		add_time_bar(id)

func on_path_enter(path:String, lv:String):
	game.hide_adv_tooltip()
	game.show_tooltip(tr("PATH") + " " + path + " " + tr("LEVEL") + " " + lv)

func on_path_exit():
	game.hide_tooltip()

func add_rsrc(v:Vector2, mod:Color, icon, id:int):
	var rsrc = rsrc_scene.instance()
	add_child(rsrc)
	rsrc.get_node("TextureRect").texture = icon
	rsrc.rect_position = v + Vector2(0, 70)
	rsrc.get_node("Control").modulate = mod
	rsrcs.append({"node":rsrc, "id":id})
	update_rsrc(rsrc, game.tile_data[id])

func _process(delta):
	for time_bar_obj in time_bars:
		var time_bar = time_bar_obj.node
		var tile = game.tile_data[time_bar_obj.id]
		var progress = (OS.get_system_time_msecs() - tile.construction_date) / float(tile.construction_length)
		time_bar.get_node("Bar").value = progress
		time_bar.get_node("TimeString").text = Helper.time_to_str(tile.construction_length - OS.get_system_time_msecs() + tile.construction_date)
		if progress > 1:
			if tile.is_constructing:
				tile.is_constructing = false
			remove_child(time_bar)
			time_bars.erase(time_bar_obj)
	for rsrc_obj in rsrcs:
		var tile = game.tile_data[rsrc_obj.id]
		if tile.is_constructing:
			continue
		var rsrc = rsrc_obj.node
		update_rsrc(rsrc, tile)

func update_rsrc(rsrc, tile):
	match tile.bldg_str:
		"ME", "PP":
			#Number of seconds needed per mineral
			var prod = 1 / tile.path_1_value
			var cap = tile.path_2_value
			var stored = tile.stored
			var c_d = tile.collect_date
			var c_t = OS.get_system_time_msecs()
			var current_bar = rsrc.get_node("Control/CurrentBar")
			var capacity_bar = rsrc.get_node("Control/CapacityBar")
			if stored < cap:
				current_bar.value = min((c_t - c_d) / (prod * 1000), 1)
				capacity_bar.value = min(stored / float(cap), 1)
				if c_t - c_d > prod * 1000:
					tile.stored += 1
					tile.collect_date += prod * 1000
			else:
				current_bar.value = 0
				capacity_bar.value = 1
			rsrc.get_node("Control/Label").text = String(stored)

func construct(st:String, costs:Dictionary):
	bldg_to_construct = st
	constr_costs = costs
	shadow = Sprite.new()
	shadow.texture = load("res://Graphics/Buildings/" + st + ".png")
	shadow.scale *= 0.4
	shadow.modulate.a = 0.5
	add_child(shadow)

func finish_construct():
	if shadow:
		bldg_to_construct = ""
		remove_child(shadow)
		shadow = null
