extends Node2D

onready var view_scene = preload("res://Scenes/View.tscn")
onready var construct_panel_scene = preload("res://Scenes/ConstructPanel.tscn")
onready var shop_panel_scene = preload("res://Scenes/ShopPanel.tscn")
onready var inventory_scene = preload("res://Scenes/Inventory.tscn")
onready var HUD_scene = preload("res://Scenes/HUD.tscn")
onready var planet_HUD_scene = preload("res://Scenes/Planet/PlanetHUD.tscn")
onready var tooltip_scene = preload("res://Scenes/Tooltip.tscn")
onready var dimension_scene = preload("res://Scenes/Dimension.tscn")
onready var planet_details_scene = preload("res://Scenes/Planet/PlanetDetails.tscn")
onready var mining_HUD_scene = preload("res://Scenes/Mining.tscn")

var construct_panel:Control
var shop_panel:Control
var inventory:Control
onready var tooltip:Control = tooltip_scene.instance()
var dimension:Control
var planet_details:Control

#var tooltip_scene
#var planet_HUD_scene
#var mining_HUD_scene
#var planet_details_scene
#var construct_panel
#var shop_panel
#var inventory
#var tooltip
#var dimension
#var planet_details

const SYSTEM_SCALE_DIV = 100.0
const GALAXY_SCALE_DIV = 750.0
const CLUSTER_SCALE_DIV = 1600.0
const SC_SCALE_DIV = 400.0

#Current view
var c_v = "planet"

#id of the universe/supercluster/etc. you're viewing the object in
var c_u = 0
var c_sc = 0
var c_c = 0
var c_g = 0
var c_s = 0
var c_p = 2
var c_t = 0#For mining only

#HUD shows the player resources at the top
var HUD
#planet_HUD shows the buttons and other things that only shows while viewing a planet surface (e.g. construct)
var planet_HUD

#Stores individual tile nodes
var tiles = []
var bldg_blueprints = []#ids of tiles where things will be constructed
var panels = []#Mainly for removing panels in a specific order

#The base node containing things that can be moved/zoomed in/out
var view

#Player resources
var money = 800
var minerals = 0
var mineral_capacity = 50
var stone = 0
var energy = 200
#Dimension remnants
var DRs = 0
#Stores information of the current pickaxe the player is holding
var pickaxe = {"name":"stick", "speed":1.0, "durability":14}
var mats = {	"coal":0,
				"glass":0,
				"sand":0,
				"clay":0,
				"soil":0,
				"cellulose":0}

#Stores information of all objects discovered
var universe_data = [{"id":0, "type":0, "name":"Universe", "diff":1, "discovered":false, "supercluster_num":8000, "superclusters":[0], "view":{"pos":Vector2(640 * 0.5, 360 * 0.5), "zoom":2, "sc_mult":0.1}}]
var supercluster_data = [{"id":0, "type":0, "name":"Laniakea Supercluster", "pos":Vector2.ZERO, "diff":1, "discovered":false, "parent":0, "cluster_num":600, "clusters":[0], "view":{"pos":Vector2(640 * 0.5, 360 * 0.5), "zoom":2, "sc_mult":0.1}}]
var cluster_data = [{"id":0, "type":0, "class":"group", "name":"Local Group", "pos":Vector2.ZERO, "diff":1, "discovered":false, "parent":0, "galaxy_num":55, "galaxies":[], "view":{"pos":Vector2(640 * 3, 360 * 3), "zoom":0.333}}]
var galaxy_data = [{"id":0, "type":0, "name":"Milky Way", "pos":Vector2.ZERO, "rotation":0, "diff":1, "discovered":false, "parent":0, "system_num":2000, "systems":[], "view":{"pos":Vector2(15000 + 1280, 15000 + 720), "zoom":0.5}}]
var system_data = [{"id":0, "name":"Solar system", "pos":Vector2(-15000, -15000), "diff":1, "discovered":false, "parent":0, "planet_num":7, "planets":[], "view":{"pos":Vector2(640, -100), "zoom":1}, "stars":[{"type":"main_sequence", "class":"G2", "size":1, "temperature":5500, "mass":1, "luminosity":1, "pos":Vector2(0, 0)}]}]
var planet_data = []
var tile_data = []

#If true, clicking any tile initiates mining
var about_to_mine = false
var mining_HUD

#Stores information on the building(s) about to be constructed
var constr_cost = {"money":0, "energy":0, "time":0}

#Stores all building information
var bldg_info = {"ME":{"name":"Mineral extractor", "desc":"Extracts minerals from the planet surface, giving you a constant supply of minerals.", "money":100, "energy":50, "time":5, "production":0.12, "capacity":15},
				 "PP":{"name":"Power plant", "desc":"Generates energy from... something", "money":80, "energy":0, "time":5, "production":0.3, "capacity":40}}

var pickaxe_info = {"stick":{"speed":1.0, "durability":14, "money_cost":150}}

#Density is in g/cm^3
var element = {	"Si":{"density":2.329},
				"O":{"density":1.429}}

#Display help when players see/do things for the first time. true: show help
var help = {"mining":true}

#Measures to not overwhelm beginners
var show = {	"minerals":false,
				"stone":false,
				"mining_layer":false}

func _ready():
	view = view_scene.instance()
	add_child(view)
	
	tooltip.visible = false
	add_child(tooltip)
	
	$titlescreen.play()
	#noob
	#AudioServer.set_bus_mute(1,true)

func popup(txt, dur):
	$Popup.visible = true
	move_child($Popup, get_child_count())
	$Popup.init_popup(txt, dur)

var dialog:AcceptDialog

func long_popup(txt:String, title:String, other_buttons:Array = [], other_functions:Array = [], ok_txt:String = "OK"):
	if dialog:
		$Control.remove_child(dialog)
	dialog = AcceptDialog.new()
	$Control.add_child(dialog)
	dialog.window_title = title
	dialog.dialog_text = txt
	dialog.popup_centered()
	for i in range(0, len(other_buttons)):
		dialog.add_button(other_buttons[i], false, other_functions[i])
		dialog.connect("custom_action", self, "popup_action")
	dialog.get_ok().text = ok_txt

func popup_action(action:String):
	call(action)
	dialog.visible = false

func open_shop_pickaxe():
	if not shop_panel.visible:
		fade_in_panel(shop_panel)
	shop_panel._on_Pickaxes_pressed()

#Executed once a building has been double clicked in the construction panel
func construct_building(bldg_type):
	put_bottom_info(tr("STOP_CONSTRUCTION"))
	view.obj.bldg_to_construct = bldg_type

func put_bottom_info(txt:String):
	var more_info = $Control/BottomInfo
	more_info.text = txt
	more_info.rect_size.x = 0#This "trick" lets us resize the label to fit the text
	more_info.rect_position.x = -more_info.rect_size.x / 2.0
	more_info.visible = true
	move_child($Control, get_child_count())

func _load_game():
	$Languages.visible = false
	#Loads planet scene
	$click.play()
	#Music fading
	$AnimationPlayer.play("title song fade")
	$ambient.play()
	$AnimationPlayer.play("ambient fade in")
	
	dimension = dimension_scene.instance()
	inventory = inventory_scene.instance()
	shop_panel = shop_panel_scene.instance()
	construct_panel = construct_panel_scene.instance()
	HUD = HUD_scene.instance()

	construct_panel.rect_scale = Vector2(0.8, 0.8)
	shop_panel.rect_position = Vector2(106.5, 70)
	construct_panel.visible = false
	add_child(construct_panel)

	shop_panel.rect_position = Vector2(106.5, 70)
	shop_panel.visible = false
	add_child(shop_panel)

	inventory.rect_position = Vector2(106.5, 70)
	inventory.visible = false
	add_child(inventory)

	dimension.visible = false
	add_child(dimension)

	remove_child($Title)

	generate_planets(0)
	#Home planet information
	planet_data[2]["name"] = tr("HOME_PLANET")
	planet_data[2]["status"] = "conquered"
	planet_data[2]["size"] = rand_range(12000, 13000)
	planet_data[2]["angle"] = PI / 2
	planet_data[2]["tiles"] = []
	planet_data[2]["discovered"] = false
	planet_data[2].crust_start_depth = rand_int(140, 160)
	planet_data[2].mantle_start_depth = rand_int(25000, 30000)
	planet_data[2].core_start_depth = rand_int(4000000, 4200000)
	planet_data[2].surface.coal.chance = 0.5
	planet_data[2].surface.coal.amount = 100
	planet_data[2].surface.soil.chance = 0.6
	planet_data[2].surface.soil.amount = 60
	planet_data[2].surface.cellulose.chance = 0.4
	planet_data[2].surface.cellulose.amount = 10
	
	system_data[0].name = tr("SOLAR_SYSTEM")
	galaxy_data[0].name = tr("MILKY_WAY")
	cluster_data[0].name = tr("LOCAL_GROUP")
	supercluster_data[0].name = tr("LANIAKEA")
	
	generate_tiles(2)
	
	for u_i in universe_data:
		u_i["epsilon_zero"] = pow10(8.854, -12)#F/m
		u_i["mu_zero"] = pow10(1.257, -6)#H/m
		u_i["planck"] = pow10(6.626, -34)#J.s
		u_i["gravitational"] = pow10(6.674, -11)#m^3/kg/s^2
		u_i["charge"] = pow10(1.602, -19)#C
		u_i["strong_force"] = 1.0
		u_i["weak_force"] = 1.0
		u_i["dark_matter"] = 1.0
		u_i["difficulty"] = 1.0
		u_i["multistar_systems"] = 1.0
		u_i["rare_stars"] = 1.0
		u_i["rare_materials"] = 1.0
		u_i["time_speed"] = 1.0
		u_i["radiation"] = 1.0
		u_i["antimatter"] = 1.0
		u_i["value"] = 1.0

	add_planet()
	add_child(HUD)

	move_child($FPS, get_child_count())

func fade_in_panel(panel:Control):
	panel.visible = true
	move_child(panel, get_child_count())
	panel.tween.interpolate_property(panel, "modulate", null, Color(1, 1, 1, 1), 0.1)
	panel.tween.interpolate_property(panel, "rect_position", null, Vector2(106.5, 60), 0.1)
	if panel.tween.is_connected("tween_all_completed", self, "on_fade_complete"):
		panel.tween.disconnect("tween_all_completed", self, "on_fade_complete")
	panel.tween.start()

func fade_out_panel(panel:Control):
	panel.tween.interpolate_property(panel, "modulate", null, Color(1, 1, 1, 0), 0.1)
	panel.tween.interpolate_property(panel, "rect_position", null, Vector2(106.5, 70), 0.1)
	panel.tween.start()
	if not panel.tween.is_connected("tween_all_completed", self, "on_fade_complete"):
		panel.tween.connect("tween_all_completed", self, "on_fade_complete", [panel])

func on_fade_complete(panel:Control):
	panel.visible = false

func toggle_shop_panel():
	if not shop_panel.visible:
		panels.push_front("shop")
		fade_in_panel(shop_panel)
	else:
		fade_out_panel(shop_panel)
		panels.erase("shop")

func toggle_inventory():
	if not inventory.visible:
		panels.push_front("inventory")
		fade_in_panel(inventory)
		inventory.refresh_values()
	else:
		fade_out_panel(inventory)
		panels.erase("inventory")

func toggle_construct_panel():
	if not Input.is_action_pressed("shift"):
		if not construct_panel.visible:
			panels.push_front("construct")
			fade_in_panel(construct_panel)
		else:
			fade_out_panel(construct_panel)
			panels.erase("construct")

func switch_view(new_view:String):
	hide_tooltip()
	match c_v:
		"planet":
			remove_planet()
		"planet_details":
			remove_child(planet_details)
			planet_details = null
			add_child(HUD)
		"system":
			remove_system()
		"galaxy":
			remove_galaxy()
		"cluster":
			remove_cluster()
		"supercluster":
			remove_supercluster()
		"universe":
			remove_universe()
		"dimension":
			remove_dimension()
		"mining":
			remove_mining()
	match new_view:
		"planet":
			add_planet()
		"planet_details":
			planet_details = planet_details_scene.instance()
			add_child(planet_details)
			remove_child(HUD)
		"system":
			add_system()
		"galaxy":
			add_galaxy()
		"cluster":
			add_cluster()
		"supercluster":
			add_supercluster()
		"universe":
			add_universe()
		"dimension":
			add_dimension()
		"mining":
			add_mining()
	c_v = new_view

func add_mining():
	mining_HUD = mining_HUD_scene.instance()
	add_child(mining_HUD)

func remove_mining():
	remove_child(mining_HUD)
	mining_HUD = null

func add_loading():
	var loading_scene = preload("res://Scenes/Loading.tscn")
	var loading = loading_scene.instance()
	loading.position = Vector2(640, 360)
	add_child(loading)
	loading.name = "Loading"

func add_obj(view_str):
	match view_str:
		"planet":
			view.add_obj("Planet", planet_data[c_p]["view"]["pos"], planet_data[c_p]["view"]["zoom"])
		"system":
			view.add_obj("System", system_data[c_s]["view"]["pos"], system_data[c_s]["view"]["zoom"])
		"galaxy":
			view.add_obj("Galaxy", galaxy_data[c_g]["view"]["pos"], galaxy_data[c_g]["view"]["zoom"])
		"cluster":
			view.add_obj("Cluster", cluster_data[c_c]["view"]["pos"], cluster_data[c_c]["view"]["zoom"])
		"supercluster":
			view.add_obj("Supercluster", supercluster_data[c_sc]["view"]["pos"], supercluster_data[c_sc]["view"]["zoom"], supercluster_data[c_sc]["view"]["sc_mult"])
		"universe":
			view.add_obj("Universe", universe_data[c_u]["view"]["pos"], universe_data[c_u]["view"]["zoom"], universe_data[c_u]["view"]["sc_mult"])

func add_dimension():
	remove_child(HUD)
	dimension.visible = true

func add_universe():
	put_change_view_btn(tr("VIEW_DIMENSION") + " (Z)", "res://Graphics/Buttons/DimensionView.png")
	if not universe_data[c_u]["discovered"]:
		reset_collisions()
		generate_superclusters(c_u)
	add_obj("universe")

func add_supercluster():
	put_change_view_btn(tr("VIEW_UNIVERSE") + " (Z)", "res://Graphics/Buttons/UniverseView.png")
	if not supercluster_data[c_sc]["discovered"]:
		reset_collisions()
		generate_clusters(c_sc)
	add_obj("supercluster")

func add_cluster():
	if not cluster_data[c_c]["discovered"]:
		add_loading()
		reset_collisions()
		generate_galaxy_part()
	else:
		put_change_view_btn(tr("VIEW_SUPERCLUSTER") + " (Z)", "res://Graphics/Buttons/SuperclusterView.png")
		add_obj("cluster")

func add_galaxy():
	if not galaxy_data[c_g]["discovered"]:
		add_loading()
		reset_collisions()
		gc_remaining = floor(pow(galaxy_data[c_g]["system_num"], 0.8) / 250.0)
		generate_system_part()
	else:
		put_change_view_btn(tr("VIEW_CLUSTER") + " (Z)", "res://Graphics/Buttons/ClusterView.png")
		add_obj("galaxy")

func add_system():
	put_change_view_btn(tr("VIEW_GALAXY") + " (Z)", "res://Graphics/Buttons/GalaxyView.png")
	if not system_data[c_s]["discovered"]:
		generate_planets(c_s)
	add_obj("system")

func add_planet():
	if not planet_data[c_p]["discovered"]:
		generate_tiles(c_p)
	add_obj("planet")
	planet_HUD = planet_HUD_scene.instance()
	add_child(planet_HUD)
	planet_HUD.name = "planet_HUD"
	about_to_mine = false

func remove_dimension():
	add_child(HUD)
	move_child($FPS, get_child_count())
	dimension.visible = false
	view.dragged = true

func remove_universe():
	remove_child(change_view_btn)
	view.remove_obj("universe")

func remove_supercluster():
	remove_child(change_view_btn)
	view.remove_obj("supercluster")

func remove_cluster():
	remove_child(change_view_btn)
	view.remove_obj("cluster")

func remove_galaxy():
	remove_child(change_view_btn)
	view.remove_obj("galaxy")

func remove_system():
	remove_child(change_view_btn)
	view.remove_obj("system")

func remove_planet():
	view.remove_obj("planet")
	remove_child(planet_HUD)
	planet_HUD = null

#Collision detection of systems, galaxies etc.
var obj_shapes = []
var max_outer_radius = 0
var min_dist_from_center = 0
var max_dist_from_center = 0

#For globular cluster generation
var gc_remaining = 0
var gc_stars_remaining = 0
var gc_center = Vector2.ZERO
#To not put gc near galactic core
var gc_offset = 0
var gc_circles = []

func reset_collisions():
	obj_shapes = []
	max_outer_radius = 0
	min_dist_from_center = 0
	max_dist_from_center = 0
	gc_remaining = 0
	gc_stars_remaining = 0
	gc_center = Vector2.ZERO
	gc_offset = 0
	gc_circles = []

func sort_shapes (a, b):
	if a["outer_radius"] < b["outer_radius"]:
		return true
	return false

func generate_superclusters(id:int):
	randomize()
	var total_sc_num = universe_data[id]["supercluster_num"]
	max_dist_from_center = pow(total_sc_num, 0.5) * 300
	for _i in range(1, total_sc_num):
		var sc_i = {}
		sc_i["status"] = "unconquered"
		sc_i["type"] = rand_int(0, 0)
		sc_i["parent"] = id
		sc_i["clusters"] = []
		sc_i["cluster_num"] = rand_int(100, 1000)
		sc_i["discovered"] = false
		var pos
		var dist_from_center = pow(randf(), 0.5) * max_dist_from_center
		pos = polar2cartesian(dist_from_center, rand_range(0, 2 * PI))
		sc_i["pos"] = pos
		var sc_id = supercluster_data.size()
		sc_i["id"] = sc_id
		sc_i["name"] = tr("SUPERCLUSTER") + " %s" % sc_id
		sc_i["discovered"] = false
		universe_data[id]["superclusters"].append(sc_id)
		supercluster_data.append(sc_i)
	if id != 0:
		var view_zoom = 500.0 / max_dist_from_center
		universe_data[id]["view"] = {"pos":Vector2(640, 360) / view_zoom, "zoom":view_zoom, "sc_mult":1.0}
	universe_data[id]["discovered"] = true

func generate_clusters(id:int):
	randomize()
	var total_clust_num = supercluster_data[id]["cluster_num"]
	max_dist_from_center = pow(total_clust_num, 0.5) * 500
	for _i in range(1, total_clust_num):
		var c_i = {}
		c_i["status"] = "unconquered"
		c_i["type"] = rand_int(0, 0)
		c_i["class"] = "group" if randf() < 0.5 else "cluster"
		c_i["parent"] = id
		c_i["galaxies"] = []
		c_i["discovered"] = false
		var c_id = cluster_data.size()
		if c_i["class"] == "group":
			c_i["galaxy_num"] = rand_int(10, 100)
			c_i.name = tr("GALAXY_GROUP") + " %s" % c_id
		else:
			c_i["galaxy_num"] = rand_int(500, 5000)
			c_i.name = tr("GALAXY_CLUSTER") + " %s" % c_id
		var pos
		var dist_from_center = pow(randf(), 0.5) * max_dist_from_center
		pos = polar2cartesian(dist_from_center, rand_range(0, 2 * PI))
		c_i["pos"] = pos
		c_i["id"] = c_id
		c_i["discovered"] = false
		supercluster_data[id]["clusters"].append(c_id)
		cluster_data.append(c_i)
	if id != 0:
		var view_zoom = 500.0 / max_dist_from_center
		supercluster_data[id]["view"] = {"pos":Vector2(640, 360) / view_zoom, "zoom":view_zoom, "sc_mult":1.0}
	supercluster_data[id]["discovered"] = true

func generate_galaxy_part():
	var progress = 0.0
	while progress != 1:
		progress = generate_galaxies(c_c)
		$Loading.update_bar(progress, tr("GENERATING_CLUSTER") % [String(cluster_data[c_c]["galaxies"].size()), String(cluster_data[c_c]["galaxy_num"])])
		yield(get_tree().create_timer(0.0000000000001),"timeout")  #Progress Bar doesnt update without this
	add_obj("cluster")
	remove_child($Loading)
	put_change_view_btn(tr("VIEW_SUPERCLUSTER") + " (Z)", "res://Graphics/Buttons/SuperclusterView.png")

func generate_galaxies(id:int):
	randomize()
	var total_gal_num = cluster_data[id]["galaxy_num"]
	var galaxy_num = total_gal_num - cluster_data[id]["galaxies"].size()
	var gal_num_to_load = min(500, galaxy_num)
	var progress = 1 - (galaxy_num - gal_num_to_load) / float(total_gal_num)
	for i in range(0, gal_num_to_load):
		var g_i = {}
		g_i["status"] = "unconquered"
		g_i["parent"] = id
		g_i["systems"] = []
		g_i["discovered"] = false
		g_i["system_num"] = int(pow(randf(), 2) * 8000) + 2000
		g_i["type"] = rand_int(0, 5)
		g_i["rotation"] = rand_range(0, 2 * PI)
		if randf() < 0.6: #Dwarf galaxy
			g_i["system_num"] /= 10
		g_i["view"] = {"pos":Vector2(640, 360), "zoom":0.2}
		var pos
		var N = obj_shapes.size()
		if N >= total_gal_num / 6:
			obj_shapes.sort_custom(self, "sort_shapes")
			obj_shapes = obj_shapes.slice(int((N - 1) * 0.7), N - 1)
			min_dist_from_center = obj_shapes[0]["outer_radius"]
		
		var radius = 200 * pow(g_i["system_num"] / GALAXY_SCALE_DIV, 0.7)
		var circle
		var colliding = true
		if min_dist_from_center == 0:
			max_dist_from_center = 5000
		else:
			max_dist_from_center = min_dist_from_center * 1.5
		var outer_radius
		while colliding:
			colliding = false
			var dist_from_center = rand_range(min_dist_from_center + radius, max_dist_from_center)
			outer_radius = radius + dist_from_center
			pos = polar2cartesian(dist_from_center, rand_range(0, 2 * PI))
			circle = {"pos":pos, "radius":radius, "outer_radius":outer_radius}
			for star_shape in obj_shapes:
				if pos.distance_to(star_shape["pos"]) < radius + star_shape["radius"]:
					colliding = true
					max_dist_from_center *= 1.2
					break
		if outer_radius > max_outer_radius:
			max_outer_radius = outer_radius
		obj_shapes.append(circle)
		g_i["pos"] = pos
		var g_id = galaxy_data.size()
		g_i["id"] = g_id
		g_i["name"] = tr("GALAXY") + " %s" % g_id
		g_i["discovered"] = false
		var starting_galaxy = c_c == 0 and galaxy_num == total_gal_num and i == 0
		if starting_galaxy:
			g_i = galaxy_data[0]
			radius = 200 * pow(g_i["system_num"] / GALAXY_SCALE_DIV, 0.5)
			obj_shapes.append({"pos":g_i["pos"], "radius":radius, "outer_radius":g_i["pos"].length() + radius})
			cluster_data[id]["galaxies"].append(0)
		else:
			cluster_data[id]["galaxies"].append(g_id)
			galaxy_data.append(g_i)
	if progress == 1:
		cluster_data[id]["discovered"] = true
		if id != 0:
			var view_zoom = 500.0 / max_outer_radius
			cluster_data[id]["view"] = {"pos":Vector2(640, 360) / view_zoom, "zoom":view_zoom}
	else:
		cluster_data[id]["discovered"] = false
	return progress

func generate_system_part():
	var progress = 0.0
	while progress != 1:
		progress = generate_systems(c_g)
		$Loading.update_bar(progress, tr("GENERATING_GALAXY") % [String(galaxy_data[c_g]["systems"].size()), String(galaxy_data[c_g]["system_num"])])
		yield(get_tree().create_timer(0.0000000000001),"timeout")  #Progress Bar doesnt update without this
	add_obj("galaxy")
	remove_child($Loading)
	put_change_view_btn(tr("VIEW_CLUSTER") + " (Z)", "res://Graphics/Buttons/ClusterView.png")

func generate_systems(id:int):
	randomize()
	var total_sys_num = galaxy_data[id]["system_num"]
	#Systems remaining to load
	var system_num = total_sys_num - galaxy_data[id]["systems"].size()
	
	#For reference, globular clusters are tightly packed old stars (class G etc)
	#Most of the stars in them are around the same temperature, but put some outliers
	#They have low metallicity

	#Open clusters are
	
	var sys_num_to_load = min(500, system_num)
	var progress = 1 - (system_num - sys_num_to_load) / float(total_sys_num)
	
	for i in range(0, sys_num_to_load):
		var s_i = {}
		s_i["status"] = "unconquered"
		s_i["parent"] = id
		s_i["planets"] = []
		s_i["discovered"] = false
		
		#Checks whether the star is in globular cluster
		var N = obj_shapes.size()
		if N >= total_sys_num / 8:
			obj_shapes.sort_custom(self, "sort_shapes")
			obj_shapes = obj_shapes.slice(int((N - 1) * 0.9), N - 1)
			min_dist_from_center = obj_shapes[0]["outer_radius"]
			if gc_remaining > 0 and gc_offset > 1 + int(pow(total_sys_num, 0.1)):
				gc_remaining -= 1
				gc_stars_remaining = int(pow(total_sys_num, 0.5) * rand_range(1, 3))
				gc_center = polar2cartesian(rand_range(min_dist_from_center * 1.25, min_dist_from_center * 1.5), rand_range(0, 2 * PI))
				max_dist_from_center = 100
			gc_offset += 1
		
		var num_stars = 1
#		while randf() < 0.3 / float(num_stars):
#			num_stars += 1
		var stars = []
		for _j in range(0, num_stars):
			var star = {}
			var a = 1.65 if gc_stars_remaining == 0 else 4.0

			#Solar masses
			var mass = -log(1 - randf()) / a
			var star_size = 1
			var star_class = ""
			#Temperature in K
			var temp = 0
			if mass < 0.08:
				star_size = range_lerp(mass, 0, 0.08, 0.001, 0.1)
				temp = range_lerp(mass, 0, 0.08, 250, 2400)
			if mass >= 0.08 and mass < 0.45:
				star_size = range_lerp(mass, 0.08, 0.45, 0.1, 0.7)
				temp = range_lerp(mass, 0.08, 0.45, 2400, 3700)
			if mass >= 0.45 and mass < 0.8:
				star_size = range_lerp(mass, 0.45, 0.8, 0.7, 0.96)
				temp = range_lerp(mass, 0.45, 0.8, 3700, 5200)
			if mass >= 0.8 and mass < 1.04:
				star_size = range_lerp(mass, 0.8, 1.04, 0.96, 1.15)
				temp = range_lerp(mass, 0.8, 1.04, 5200, 6000)
			if mass >= 1.04 and mass < 1.4:
				star_size = range_lerp(mass, 1.04, 1.4, 1.15, 1.4)
				temp = range_lerp(mass, 1.04, 1.4, 6000, 7500)
			if mass >= 1.4 and mass < 2.1:
				star_size = range_lerp(mass, 1.4, 2.1, 1.4, 1.8)
				temp = range_lerp(mass, 1.4, 2.1, 7500, 10000)
			if mass >= 2.1 and mass < 16:
				star_size = range_lerp(mass, 2.1, 16, 1.8, 6.6)
				temp = range_lerp(mass, 2.1, 16, 10000, 30000)
			if mass >= 16 and mass < 100:
				star_size = range_lerp(mass, 16, 100, 6.6, 22)
				temp = range_lerp(mass, 16, 100, 30000, 70000)
			if mass >= 100 and mass < 1000:
				star_size = range_lerp(mass, 100, 1000, 22, 60)
				temp = range_lerp(mass, 100, 1000, 70000, 120000)
			if mass >= 1000 and mass < 10000:
				star_size = range_lerp(mass, 1000, 10000, 60, 200)
				temp = range_lerp(mass, 1000, 10000, 120000, 210000)
			if mass >= 10000:
				star_size = pow(mass, 1/3.0) * (200 / pow(10000, 1/3.0))
				temp = 210000 * pow(1.45, mass / 10000.0 - 1)
			
			var star_type = ""
			if mass >= 0.08:
				star_type = "main_sequence"
			else:
				star_type = "brown_dwarf"
			
			if mass > 0.2 and mass < 1.3 and randf() < 0.02:
				star_type = "white_dwarf"
				temp = rand_range(4000,10000)
				if randf() < 0.05:
					temp = rand_range(10000, 60000)
				star_size = rand_range(0.006, 0.03)
				mass = rand_range(0.4, 1.2)
			if mass > 0.25 and randf() < 0.08:
				star_type = "giant"
				star_size *= max(rand_range(240000, 280000) / temp, rand_range(1.2, 1.4))
			if star_type == "main-sequence":
				if randf() < 0.01:
					mass = rand_range(10, 50)
					star_type = "supergiant"
					star_size *= max(rand_range(360000, 440000) / temp, rand_range(1.7, 2.1))
				elif randf() < 0.0015:
					mass = rand_range(5, 30)
					star_type = "hypergiant"
					star_size *= max(rand_range(500000, 600000) / temp, rand_range(3.0, 4.0))
					var tier = 1
					while randf() < 0.2:
						tier += 1
						star_type = "hypergiant " + get_roman_num(tier)
						star_size *= 1.2
			
			star_class = get_star_class(temp)
			#star["luminosity"] = pow(mass, rand_range(3, 4))
			star["luminosity"] = clever_round(4 * PI * pow(star_size * pow10(6.957, 8), 2) * pow10(5.67, -8) * pow(temp, 4) / pow10(3.828, 26))
			star["mass"] = clever_round(mass)
			star["size"] = clever_round(star_size)
			star["type"] = star_type
			star["class"] = star_class
			star["temperature"] = clever_round(temp)
			star["pos"] = Vector2.ZERO
			stars.append(star)
		
		var biggest_star_size = 0
		var combined_star_size = 0
		for star in stars:
			if star["size"] > biggest_star_size:
				biggest_star_size = star["size"]
			combined_star_size += star["size"]
		var planet_num = max(round(pow(combined_star_size, 0.3) * rand_int(2, 9)), 2)
		if planet_num > 30:
			planet_num -= floor((planet_num - 30) / 2)
		s_i["planet_num"] = planet_num
		
		var s_id = system_data.size()
		s_i["id"] = s_id
		s_i["stars"] = stars
		s_i["name"] = tr("STAR_SYSTEM") + " %s" % s_id
		s_i["discovered"] = false
		
		var starting_system = c_g == 0 and system_num == total_sys_num and i == 0
		
		#Collision detection
		var radius = 320 * pow(biggest_star_size / SYSTEM_SCALE_DIV, 0.35)
		var circle
		var pos
		var colliding = true
		if gc_stars_remaining == 0:
			gc_center = Vector2.ZERO
			if min_dist_from_center == 0:
				max_dist_from_center = 6000
			else:
				max_dist_from_center = min_dist_from_center * pow(total_sys_num, 0.04) * 1.1
		var outer_radius
		var radius_increase_counter = 0
		while colliding:
			colliding = false
			var dist_from_center = rand_range(0, max_dist_from_center)
			if gc_stars_remaining == 0:
				dist_from_center = rand_range(min_dist_from_center + radius, max_dist_from_center)
			outer_radius = radius + dist_from_center
			pos = polar2cartesian(dist_from_center, rand_range(0, 2 * PI)) + gc_center
			circle = {"pos":pos, "radius":radius, "outer_radius":outer_radius}
			for star_shape in obj_shapes:
				#if Geometry.is_point_in_circle(pos, star_shape.pos, radius + star_shape.radius):
				if pos.distance_to(star_shape["pos"]) < radius + star_shape["radius"]:
					colliding = true
					radius_increase_counter += 1
					if radius_increase_counter > 5:
						max_dist_from_center *= 1.2
						radius_increase_counter = 0
					break
			if not colliding:
				for gc_circle in gc_circles:
					#if Geometry.is_point_in_circle(pos, gc_circle.pos, radius + gc_circle.radius):
					if pos.distance_to(gc_circle["pos"]) < radius + gc_circle["radius"]:
						colliding = true
						radius_increase_counter += 1
						if radius_increase_counter > 5:
							max_dist_from_center *= 1.2
							radius_increase_counter = 0
						break
		if outer_radius > max_outer_radius:
			max_outer_radius = outer_radius
		if gc_stars_remaining > 0:
			gc_stars_remaining -= 1
			gc_circles.append(circle)
			if gc_stars_remaining == 0:
				#Convert globular cluster to a single huge circle for collision detection purposes
				gc_circles.sort_custom(self, "sort_shapes")
				var big_radius = gc_circles[-1]["outer_radius"]
				obj_shapes = [{"pos":gc_center, "radius":big_radius, "outer_radius":gc_center.length() + big_radius}]
				gc_circles = []
		else:
			if not starting_system:
				obj_shapes.append(circle)
		s_i["pos"] = pos
		if starting_system:
			s_i = system_data[0]
			radius = 320 * pow(1 / SYSTEM_SCALE_DIV, 0.3)
			obj_shapes.append({"pos":s_i["pos"], "radius":radius, "outer_radius":s_i["pos"].length() + radius})
			galaxy_data[id]["systems"].append(0)
		else:
			galaxy_data[id]["systems"].append(s_id)
			system_data.append(s_i)
	if progress == 1:
		galaxy_data[id]["discovered"] = true
		if id != 0:
			var view_zoom = 500.0 / max_outer_radius
			galaxy_data[id]["view"] = {"pos":Vector2(640, 360) / view_zoom, "zoom":view_zoom}
	else:
		galaxy_data[id]["discovered"] = false
	return progress

func generate_planets(id:int):
	randomize()
	var combined_star_size = 0
	var max_star_temp = 0
	var max_star_size = 0
	for star in system_data[id]["stars"]:
		combined_star_size += star["size"]
		if star.temperature > max_star_temp:
			max_star_temp = star.temperature
		if star.size > max_star_size:
			max_star_size = star.size
	var planet_num = system_data[id]["planet_num"]
	var max_distance
	var j = 0
	while pow(1.3, j) * 240 < combined_star_size * 2.63:
		j += 1
	for i in range(1, planet_num + 1):
		#p_i = planet_info
		var p_i = {}
		p_i["status"] = "unconquered"
		p_i["ring"] = i
		p_i["type"] = rand_int(3, 10)
		p_i["size"] = 2000 + rand_range(0, 10000) * (i + 1)
		p_i["angle"] = rand_range(0, 2 * PI)
		#p_i["distance"] = pow(1.3,i+(max(1.0,log(combined_star_size*(0.75+0.25/max(1.0,log(combined_star_size)))))/log(1.3)))
		p_i["distance"] = pow(1.3,i + j) * rand_range(240, 270)
		#1 solar radius = 2.63 px = 0.0046 AU
		#569 px = 1 AU = 215.6 solar radii
		max_distance = p_i["distance"]
		p_i["parent"] = id
		p_i["view"] = {"pos":Vector2.ZERO, "zoom":1.0}
		p_i["tiles"] = []
		p_i["discovered"] = false
		var p_id = planet_data.size()
		p_i["id"] = p_id
		p_i["name"] = tr("PLANET") + " " + String(p_id)
		system_data[id]["planets"].append(p_id)
		#var temp = 1 / pow(p_i.distance - max_star_size * 2.63, 0.5) * max_star_temp * pow(max_star_size, 0.5)
		var dist_in_km = p_i.distance / 569.0 * pow10(1.5, 8)
		var star_size_in_km = max_star_size * pow10(6.957, 5)#                             V bond albedo
		var temp = max_star_temp * pow(star_size_in_km / (2 * dist_in_km), 0.5) * pow(1 - 0.1, 0.25)
		p_i.temperature = temp# in K
		p_i.crust = make_planet_composition(temp, "crust")
		p_i.mantle = make_planet_composition(temp, "mantle")
		p_i.core = make_planet_composition(temp, "core")
		p_i.crust_start_depth = rand_int(50, 450)
		p_i.mantle_start_depth = round(rand_range(0.005, 0.02) * p_i.size * 1000)
		p_i.core_start_depth = round(rand_range(0.4, 0.46) * p_i.size * 1000)
		p_i.surface = add_surface_materials(temp, p_i.crust)
		planet_data.append(p_i)
	
	if id != 0:
		var view_zoom = 400 / max_distance
		system_data[id]["view"] = {"pos":Vector2(640, 360) / view_zoom, "zoom":view_zoom}
	system_data[id]["discovered"] = true

func generate_tiles(id:int):
	#wid is number of tiles horizontally/vertically
	#So total number of tiles is wid squared
	var wid = min(round(pow(planet_data[id]["size"] / 10000.0, 0.4) * 8.0) + 1, 60)

	for _i in range(0, pow(wid, 2)):
		planet_data[id]["tiles"].append(tile_data.size())
		tile_data.append({	"is_constructing":false,
							"bldg_str":"",
							"construction_date":0,
							"construction_length":0,
							"bldg_info":{},
							"depth":0,
							"contents":[]})#To prevent "tile-scumming"
	var view_zoom = 3.0 / wid
	planet_data[id]["view"] = {"pos":Vector2(640, 385) / view_zoom, "zoom":view_zoom}
	planet_data[id]["discovered"] = true

func make_planet_composition(temp:float, depth:String):
	randomize()
	var common_elements = {}
	var uncommon_elements = {}
	if temp > -100:
		if depth == "crust":
			common_elements["O"] = rand_range(0.1, 0.19)
			common_elements["Si"] = common_elements["O"] * rand_range(3.9, 4)
			uncommon_elements = {	"Al":0.5,
									"Fe":0.35,
									"Ca":0.3,
									"Na":0.25,
									"Mg":0.2,
									"K":0.2,
									"Ti":0.05,
									"H":0.02,
									"P":0.02,
									"U":0.02,
									"Np":0.004,
									"Pu":0.0003
								}
		elif depth == "mantle":
			common_elements["O"] = rand_range(0.15, 0.19)
			common_elements["Si"] = common_elements["O"] * rand_range(3.9, 4)
			uncommon_elements = {	"Al":0.5,
									"Fe":0.35,
									"Ca":0.3,
									"Na":0.25,
									"U":0.25,
									"Mg":0.2,
									"K":0.2,
									"Np":0.1,
									"Ti":0.05,
									"H":0.02,
									"P":0.02,
									"Pu":0.01
								}
		else:
			common_elements["Fe"] = rand_range(0.5, 0.95)
			common_elements["Ni"] = (1 - get_sum_of_dict(common_elements)) * rand_range(0, 0.9)
			common_elements["S"] = (1 - get_sum_of_dict(common_elements)) * rand_range(0, 0.9)
			uncommon_elements = {	"Cr":0.3,
									"Ta":0.2,
									"W":0.2,
									"Os":0.1,
									"Ir":0.1,
									"Ti":0.1,
									"Co":0.1,
									"Mn":0.1
								}
	else:
		if depth == "crust" or depth == "mantle":
			common_elements["N"] = randf()
			common_elements["H"] = (1 - get_sum_of_dict(common_elements)) * randf()
			common_elements["O"] = (1 - get_sum_of_dict(common_elements)) * randf()
			common_elements["C"] = (1 - get_sum_of_dict(common_elements)) * randf()
			common_elements["S"] = (1 - get_sum_of_dict(common_elements)) * randf()
			common_elements["He"] = (1 - get_sum_of_dict(common_elements)) * randf()
			uncommon_elements = {	"Al":0.5,
									"Fe":0.35,
									"Ca":0.3,
									"Na":0.25,
									"U":0.25,
									"Mg":0.2,
									"K":0.2,
									"Np":0.1,
									"Ti":0.05,
									"H":0.02,
									"P":0.02,
									"Pu":0.01
								}
		else:
			common_elements["Fe"] = rand_range(0.5, 0.95)
			common_elements["Ni"] = (1 - get_sum_of_dict(common_elements)) * rand_range(0, 0.9)
			common_elements["S"] = (1 - get_sum_of_dict(common_elements)) * rand_range(0, 0.9)
			uncommon_elements = {	"Cr":0.3,
									"Ta":0.2,
									"W":0.2,
									"Os":0.1,
									"Ir":0.1,
									"Ti":0.1,
									"Co":0.1,
									"Mn":0.1
								}
	var remaining = 1 - get_sum_of_dict(common_elements)
	var uncommon_element_count = 0
	for u_el in uncommon_elements.keys():
		if randf() < uncommon_elements[u_el] * 5.0:
			uncommon_element_count += 1
			uncommon_elements[u_el] = 1
	var ucr = [0, 1]#uncommon element ratios
	for _i in range(0, uncommon_element_count - 1):
		ucr.append(randf())
	ucr.sort()
	var result = {}
	var index = 1
	for u_el in uncommon_elements.keys():
		if uncommon_elements[u_el] == 1:
			result[u_el] = (ucr[index] - ucr[index - 1]) * remaining
			index += 1
	for c_el in common_elements.keys():
		result[c_el] = common_elements[c_el]
	return result

func add_surface_materials(temp:float, crust_comp:Dictionary):#Amount in kg
	var mat_info = {	"coal":{"chance":rand_range(0.1, 0.7), "amount":rand_range(50, 150)},
						"glass":{"chance":0.1, "amount":1},
						"sand":{"chance":0.8, "amount":50},
						"clay":{"chance":rand_range(0.05, 0.3), "amount":rand_range(30, 80)},
						"soil":{"chance":rand_range(0.1, 0.8), "amount":rand_range(30, 100)},
						"cellulose":{"chance":rand_range(0.01, 0.5), "amount":rand_range(1, 20)}
	}
	mat_info.sand.chance = pow(crust_comp.Si + crust_comp.O, 0.1) if crust_comp.has_all(["Si", "O"]) else 0.0
	var sand_glass_ratio = clamp(atan(0.01 * (temp + 273 - 1500)) * 1.05 / PI + 1/2, 0, 1)
	mat_info.glass.chance = mat_info.sand.chance * sand_glass_ratio
	mat_info.sand.chance *= (1 - sand_glass_ratio)
	for mat in mat_info:
		mat_info[mat].chance = clever_round(mat_info[mat].chance, 3)
		mat_info[mat].amount = clever_round(mat_info[mat].amount, 3)
	return mat_info

func show_tooltip(txt:String):
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	var txt2 = txt.split("\n")
	tooltip.visible = true
	move_child(tooltip, get_child_count())
	tooltip.show_text(txt2)

func hide_tooltip():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	tooltip.visible = false

var change_view_btn

func put_change_view_btn (info_str, icon_str):
	change_view_btn = TextureButton.new()
	var change_view_icon = load(icon_str)
	change_view_btn.texture_normal = change_view_icon
	add_child(change_view_btn)
	change_view_btn.rect_position = Vector2(-1, 720 - 63)
	change_view_btn.connect("mouse_entered", self, "on_change_view_over", [info_str])
	change_view_btn.connect("mouse_exited", self, "hide_tooltip")
	change_view_btn.connect("pressed", self, "on_change_view_click")

func on_change_view_over (view_str):
	show_tooltip(view_str)

func on_change_view_click ():
	$click.play()
	match c_v:
		"system":
			switch_view("galaxy")
		"galaxy":
			switch_view("cluster")
		"cluster":
			switch_view("supercluster")
		"supercluster":
			switch_view("universe")
		"universe":
			switch_view("dimension")

func YNPanel(text:String):
	var YN = ConfirmationDialog.new()
	$Control.add_child(YN)
	YN.dialog_text = text
	YN.popup_centered()

func get_star_class (temp):
	var cl = ""
	if temp < 600:
		cl = "Y" + String(floor(10 - (temp - 250) / 350 * 10))
	elif temp < 1400:
		cl = "T" + String(floor(10 - (temp - 600) / 800 * 10))
	elif temp < 2400:
		cl = "L" + String(floor(10 - (temp - 1400) / 1000 * 10))
	elif temp < 3700:
		cl = "M" + String(floor(10 - (temp - 2400) / 1300 * 10))
	elif temp < 5200:
		cl = "K" + String(floor(10 - (temp - 3700) / 1500 * 10))
	elif temp < 6000:
		cl = "G" + String(floor(10 - (temp - 5200) / 800 * 10))
	elif temp < 7500:
		cl = "F" + String(floor(10 - (temp - 6000) / 1500 * 10))
	elif temp < 10000:
		cl = "A" + String(floor(10 - (temp - 7500) / 2500 * 10))
	elif temp < 30000:
		cl = "B" + String(floor(10 - (temp - 10000) / 20000 * 10))
	elif temp < 70000:
		cl = "O" + String(floor(10 - (temp - 30000) / 40000 * 10))
	elif temp < 120000:
		cl = "Q" + String(floor(10 - (temp - 70000) / 50000 * 10))
	elif temp < 210000:
		cl = "R" + String(floor(10 - (temp - 120000) / 90000 * 10))
	else:
		cl = "Z"
	return cl

func get_star_modulate (star_class:String):
	var w = int(star_class[1]) / 10.0#weight for lerps
	var m
	var Y9 = Color(25, 0, 0, 255) / 255.0
	var Y0 = Color(66, 0, 0, 255) / 255.0
	var T0 = Color(117, 0, 0, 255) / 255.0
	var L0 = Color(189, 32, 23, 255) / 255.0
	var M0 = Color(255, 181, 108, 255) / 255.0
	var K0 = Color(255, 218, 181, 255) / 255.0
	var G0 = Color(255, 237, 227, 255) / 255.0
	var F0 = Color(249, 245, 255, 255) / 255.0
	var A0 = Color(213, 224, 255, 255) / 255.0
	var B0 = Color(162, 192, 255, 255) / 255.0
	var O0 = Color(140, 177, 255, 255) / 255.0
	var Q0 = Color(134, 255, 117, 255) / 255.0
	var R0 = Color(255, 151, 255, 255) / 255.0
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
#Returns a random integer between low and high inclusive
func rand_int(low:int, high:int):
	return randi() % (high - low + 1) + low

#Assumes that all values of dict are floats/integers
func get_sum_of_dict(dict:Dictionary):
	var sum = 0
	for el in dict.values():
		sum += el
	return sum

#Converts time in milliseconds to string format
func time_to_str (time):
	var seconds = floor(time / 1000)
	var second_zero = "0" if seconds < 10 else ""
	var minutes = floor(seconds / 60)
	var minute_zero = "0" if minutes < 10 else ""
	var hours = floor(minutes / 60)
	var days = floor (hours / 24)
	var years = floor (days / 365)
	var year_str = "" if years == 0 else String(years) + "y "
	var day_str = "" if days == 0 else String(days) + "d "
	var hour_str = "" if hours == 0 else String(hours) + ":"
	return year_str + day_str + hour_str + minute_zero + String(minutes) + ":" + second_zero + String(seconds)

func get_roman_num(num:int):
	if num > 3999:
		return String(num)
	var strs = [["","I","II","III","IV","V","VI","VII","VIII","IX"],["","X","XX","XXX","XL","L","LX","LXX","LXXX","XC"],["","C","CC","CCC","CD","D","DC","DCC","DCCC","CM"],["","M","MM","MMM"]];
	var num_str:String = String(num)

	var res = ""
	var n = num_str.length()
	var c = 0;
	while c < n:
		res = strs[c][int(num_str[n - c - 1])] + res;
		c += 1
	return res;

func e_notation(num:float):#e notation
	var e = floor(log10(num))
	var n = num * pow(10, -e)
	return String(clever_round(n)) + "e" + String(e)

func clever_round (num:float, sd:int = 4):#sd: significant digits
	var e = floor(log10(abs(num)))
	if sd < e + 1:
		return round(num)
	return stepify(num, pow(10, e - sd + 1))

func pow10(n, e):
	return n * pow(10, e)

func log10(n):
	return log(n) / log(10)

func _process(delta):
	if delta != 0:
		$FPS.text = String(round(1 / delta)) + " FPS"
	tooltip.rect_position = mouse_pos + Vector2(4, 4)
	if tooltip.rect_position.x + tooltip.max_width > 1280 - 5:
		tooltip.rect_position.x = 1280 - tooltip.max_width - 5
	if tooltip.rect_position.y + tooltip.height > 720 - 4:
		tooltip.rect_position.y = 720 - tooltip.height - 4

var mouse_pos = Vector2.ZERO

func _input(event):
	OS.get_locale()
	if event is InputEventMouse:
		mouse_pos = event.position

	#Press F11 to toggle fullscreen
	if Input.is_action_just_released("fullscreen"):
		OS.window_fullscreen = not OS.window_fullscreen

	#Press Z to view galaxy the system is in, etc. or go back
	if Input.is_action_just_released("change_view"):
		if c_v == "planet_details" and not planet_details.renaming:
			switch_view("system")
		elif c_v == "mining":
			switch_view("planet")
		elif not has_node("Loading"):
			on_change_view_click()

	if Input.is_action_just_released("right_click"):
		if c_v == "planet":
			#Cancel building
			view.obj.bldg_to_construct = ""
			$Control/BottomInfo.visible = false
			for id in bldg_blueprints:
				tiles[id]._on_Button_button_out()
		if len(panels) != 0:
			match panels[0]:
				"shop":
					toggle_shop_panel()
				"inventory":
					toggle_inventory()
				"construct":
					toggle_construct_panel()
			hide_tooltip()
	
	#Sell all minerals by pressing Shift C
	if Input.is_action_pressed("shift") and Input.is_action_just_released("construct") and minerals > 0:
		money += minerals * 5
		popup(tr("MINERAL_SOLD") % [String(minerals), String(minerals * 5)], 2)
		minerals = 0

func _on_en_mouse_entered():
	tooltip.get_node("Text")["custom_fonts/font"] = load("Resources/default_font.tres")
	show_tooltip("English")

func _on_en_mouse_exited():
	hide_tooltip()

func _on_fr_mouse_entered():
	tooltip.get_node("Text")["custom_fonts/font"] = load("Resources/default_font.tres")
	show_tooltip("Français")

func _on_fr_mouse_exited():
	hide_tooltip()

func _on_it_mouse_entered():
	tooltip.get_node("Text")["custom_fonts/font"] = load("Resources/default_font.tres")
	show_tooltip("Italiano")

func _on_it_mouse_exited():
	hide_tooltip()

var unicode:bool = false

func _on_ru_mouse_entered():
	tooltip.get_node("Text")["custom_fonts/font"] = load("Resources/unicode_font.tres")
	show_tooltip("Русский")

func _on_ru_mouse_exited():
	if not unicode:
		tooltip.get_node("Text")["custom_fonts/font"] = load("Resources/default_font.tres")
	hide_tooltip()

func _on_en_pressed():
	unicode = false
	TranslationServer.set_locale("en")
	change_language()

func _on_fr_pressed():
	unicode = false
	TranslationServer.set_locale("fr")
	change_language()

func _on_it_pressed():
	unicode = false
	TranslationServer.set_locale("it")
	change_language()

func _on_ru_pressed():
	unicode = true
	TranslationServer.set_locale("ru")
	change_language()

func change_language():
	$Title/Button.visible = false
	$Title/Button.visible = true
