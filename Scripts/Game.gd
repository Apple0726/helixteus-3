extends Node2D

onready var view_scene = preload("res://Scenes/View.tscn")
onready var construct_panel_scene = preload("res://Scenes/ConstructPanel.tscn")
onready var HUD_scene = preload("res://Scenes/HUD.tscn")
onready var planet_HUD_scene = preload("res://Scenes/PlanetHUD.tscn")
onready var tooltip_scene = preload("res://Scenes/Tooltip.tscn")

onready var construct_panel:Control = construct_panel_scene.instance()
onready var tooltip:Control = tooltip_scene.instance()

#Current view
var c_v = "planet"

#id of the universe/supercluster/etc. you're viewing the object in
var c_u = 0
var c_sc = 0
var c_c = 0
var c_g = 0
var c_s = 0
var c_p = 2

#HUD shows the player resources at the top
var HUD
#planet_HUD shows the buttons and other things that only shows while viewing a planet surface (i.e. construct)
var planet_HUD

var view

#Player resources
var money = 800
var minerals = 15
var mineral_capacity = 50
var energy = 200

#Stores information of all objects discovered
var galaxy_data = [{"pos":Vector2.ZERO, "diff":1, "discovered":false, "parent":0, "system_num":150, "systems":[], "view":{"pos":Vector2(640, 360), "zoom":0.3}}]
var system_data = [{"pos":Vector2.ZERO, "diff":1, "discovered":false, "parent":0, "planet_num":10, "planets":[], "view":{"pos":Vector2(640, 180), "zoom":0.3}, "stars":[{"type":"main-sequence", "class":"G", "size":1, "temperature":5500, "mass":1, "luminosity":1, "pos":Vector2(0, 0)}]}]
var planet_data = []
var tile_data = []

#Stores information on the building(s) about to be constructed
var constr_cost = {"money":0, "energy":0, "time":0}

#Stores all building information
var bldg_info = {"ME":{"name":"Mineral extractor", "desc":"Extracts minerals from the planet surface, giving you a constant supply of minerals.", "money":100, "energy":50, "time":5, "production":0.12, "capacity":15},
				 "PP":{"name":"Power plant", "desc":"Generates energy from... something", "money":80, "energy":0, "time":5, "production":0.3, "capacity":40}}

func _ready():
	$titlescreen.play()
	#noob
	#AudioServer.set_bus_mute(1,true)
	
func popup(txt, dur):
	$Popup.visible = true
	self.move_child($Popup, self.get_child_count())
	$Popup.init_popup(txt, dur)

#Executed once a building has been double clicked in the construction panel
func construct_building(bldg_type):
	var more_info:Label = $planet_HUD/MoreInfo
	more_info.text = "Right click to finish constructing"
	var font = planet_HUD.get_font("font")
	font.get_string_size(more_info.text)
	more_info.rect_size.x = font.get_string_size(more_info.text).x + 30
	more_info.rect_position.x = (1280 - more_info.rect_size.x) / 2.0
	more_info.visible = true
	view.obj.bldg_to_construct = bldg_type

func _load_game():
	#Loads planet scene
	
	#Music fading
	$AnimationPlayer.play("title song fade")
	$ambient.play()
	$AnimationPlayer.play("ambient fade in")
	
	view = view_scene.instance()
	
	self.remove_child($Title)
	
	generate_planets(0)
	#Home planet information
	planet_data[2]["name"] = "Home Planet"
	planet_data[2]["status"] = "conquered"
	planet_data[2]["size"] = rand_range(12000, 13000)
	planet_data[2]["angle"] = PI / 2
	planet_data[2]["tiles"] = []
	planet_data[2]["discovered"] = false
	generate_tiles(2)
	
	self.add_child(view)
	add_planet()
	
	HUD = HUD_scene.instance()
	self.add_child(HUD)
	HUD.name = "HUD"
	
	construct_panel.name = "construct_panel"
	construct_panel.rect_scale = Vector2(0.8, 0.8)
	construct_panel.visible = false
	self.add_child(construct_panel)
	
	tooltip.visible = false
	self.add_child(tooltip)
	
	self.move_child($FPS, self.get_child_count())

var mouse_pos = Vector2.ZERO

func _input(event):
	if event is InputEventMouse:
		mouse_pos = event.position
	
	#Press F11 to toggle fullscreen
	if Input.is_action_just_released("fullscreen"):
		OS.window_fullscreen = not OS.window_fullscreen
		
	#Right click to cancel building
	if c_v == "planet":
		if Input.is_action_just_released("right_click"):
			view.obj.bldg_to_construct = ""
			$planet_HUD/MoreInfo.visible = false
		
	#Sell all ores by pressing Shift C
	if Input.is_action_pressed("shift") and Input.is_action_just_released("construct") and minerals > 0:
		money += minerals * 5
		popup("You sold " + String(minerals) + " minerals for $" + String(minerals * 5) + "!", 2)
		minerals = 0
		

func add_construct_panel():
	if c_v == "planet" and not Input.is_action_pressed("shift"):
		construct_panel.visible = true
		#Play panel fade in animation
		get_node("construct_panel/AnimationPlayer").play("FadeIn")

func remove_construct_panel():
	if not Input.is_action_pressed("shift"):
		#Play panel fade out animation
		get_node("construct_panel/AnimationPlayer").play_backwards("FadeIn")
		#A timer so that the panel will only be invisible once the fade out is finished
		$Timer.start()

func _on_Timer_timeout():
	construct_panel.visible = false

func switch_view(new_view:String):
	hide_tooltip()
	match c_v:
		"planet":
			remove_planet()
		"system":
			remove_system()
		"galaxy":
			remove_galaxy()
	match new_view:
		"planet":
			add_planet()
		"system":
			add_system()
		"galaxy":
			add_galaxy()
	c_v = new_view

var change_view_btn

func add_galaxy():
	if not galaxy_data[c_g]["discovered"]:
		generate_systems(c_g)
	view.add_obj("System", galaxy_data[c_g]["view"]["pos"], galaxy_data[c_g]["view"]["zoom"])

func add_system():
	change_view_btn = TextureButton.new()
	var change_view_icon = preload("res://Graphics/Icons/GalaxyView.png")
	change_view_btn.texture_normal = change_view_icon
	self.add_child(change_view_btn)
	change_view_btn.rect_position = Vector2(-1, 720 - 63)
	change_view_btn.connect("mouse_entered", self, "on_change_view_over", ["View the galaxy this system is in"])
	change_view_btn.connect("mouse_exited", self, "hide_tooltip")
	if not system_data[c_s]["discovered"]:
		generate_planets(c_s)
	view.add_obj("System", system_data[c_s]["view"]["pos"], system_data[c_s]["view"]["zoom"])

func add_planet():
	if not planet_data[c_p]["discovered"]:
		generate_tiles(c_p)
	view.add_obj("Planet", planet_data[c_p]["view"]["pos"], planet_data[c_p]["view"]["zoom"])
	planet_HUD = planet_HUD_scene.instance()
	self.add_child(planet_HUD)
	planet_HUD.name = "planet_HUD"

func remove_galaxy():
	view.remove_obj("galaxy")

func remove_system():
	self.remove_child(change_view_btn)
	view.remove_obj("system")

func remove_planet():
	view.remove_obj("planet")
	self.remove_child(planet_HUD)
	planet_HUD = null

func generate_systems(id:int):
	randomize()
	var system_num = galaxy_data[id]["system_num"]
	#For reference, globular clusters are tightly packed old stars (class G etc)
	#Most of the stars in them are around the same temperature, but put some outliers
	#They have low metallicity
	
	#Open clusters are 
	for i in range(0, system_num):
		var s_i = {}
		s_i["status"] = "unconquered"
		s_i["parent"] = id
		s_i["view"] = {"pos":Vector2.ZERO, "zoom":1.0}
		s_i["planets"] = []
		s_i["discovered"] = false
		s_i["pos"] = Vector2(rand_range(-2000, 2000), rand_range(-2000, 2000))
		var num_stars = 1
#		while randf() < 0.3 / float(num_stars):
#			num_stars += 1
		var stars = []
		for _j in range(0, num_stars):
			var star = {}
			var a = 2.0
			
			#Solar masses
			var mass = -log(1 - randf()) / a
			var star_size = 1
			var star_class = ""
			#Temperature in K
			var temp = 0
			var inv_l = 0
			if mass >= 0.08 and mass < 0.45:
				inv_l = inverse_lerp(0.08, 0.45, mass)
				star_size = lerp(0.1, 0.7, inv_l)
				temp = lerp(2400, 3700, inv_l)
				star_class = "M"
			if mass >= 0.45 and mass < 0.8:
				inv_l = inverse_lerp(0.45, 0.8, mass)
				star_size = lerp(0.7, 0.96, inv_l)
				temp = lerp(3700, 5200, inv_l)
				star_class = "K"
			if mass >= 0.8 and mass < 1.04:
				inv_l = inverse_lerp(0.8, 1.04, mass)
				star_size = lerp(0.96, 1.15, inv_l)
				temp = lerp(5200, 6000, inv_l)
				star_class = "G"
			if mass >= 1.04 and mass < 1.4:
				inv_l = inverse_lerp(1.04, 1.4, mass)
				star_size = lerp(1.15, 1.4, inv_l)
				temp = lerp(6000, 7500, inv_l)
				star_class = "F"
			if mass >= 1.4 and mass < 2.1:
				inv_l = inverse_lerp(1.4, 2.1, mass)
				star_size = lerp(1.4, 1.8, inv_l)
				temp = lerp(7500, 10000, inv_l)
				star_class = "A"
			if mass >= 2.1 and mass < 16:
				inv_l = inverse_lerp(2.1, 16, mass)
				star_size = lerp(1.8, 6.6, inv_l)
				temp = lerp(10000, 30000, inv_l)
				star_class = "B"
			if mass >= 16 and mass < 100:
				inv_l = inverse_lerp(16, 100, mass)
				star_size = lerp(6.6, 22, inv_l)
				temp = lerp(30000, 70000, inv_l)
				star_class = "O"
			if mass >= 100 and mass < 1000:
				inv_l = inverse_lerp(100, 1000, mass)
				star_size = lerp(22, 80, inv_l)
				temp = lerp(70000, 120000, inv_l)
				star_class = "Q"#Green star
			if mass >= 1000 and mass < 10000:
				inv_l = inverse_lerp(1000, 10000, mass)
				star_size = lerp(60, 200, inv_l)
				temp = lerp(120000, 210000, inv_l)
				star_class = "R"#Pink star
			star_class += String(round(9 - lerp(0, 9, inv_l)))
			if mass >= 10000:
				star_class = "Z"#Black star
				star_size = pow(mass, 1/3.0) * (200 / pow(10000, 1/3.0))
				temp = 210000 * pow(1.45, mass / 10000.0 - 1)
			
			var star_type = "main-sequence"
			var rand_f = randf()
			if mass > 0.25 and rand_f < 0.2:
				star_type = "giant"
				star_size *= max(rand_range(50000, 100000) / temp, rand_range(1.1, 1.4))
			if rand_f < 0.015:
				mass = rand_range(10, 50)
				star_type = "supergiant"
				star_size *= max(rand_range(100000, 150000) / temp, rand_range(1.4, 2.1))
			if rand_f < 0.004:
				mass = rand_range(5, 30)
				star_type = "hypergiant"
				star_size *= max(rand_range(300000, 400000) / temp, rand_range(4.0, 7.0))
				var tier = 1
				while randf() < 0.3:
					tier += 1
					star_type = "hypergiant " + get_roman_num(tier)
					star_size *= 1.2
			
			#star["luminosity"] = pow(mass, rand_range(3, 4))
			star["luminosity"] = 4 * PI * pow(star_size, 2) * 5.67 * pow(10, -8) * pow(temp, 4)
			star["mass"] = mass
			star["size"] = star_size
			star["type"] = star_type
			star["class"] = star_class
			star["temperature"] = temp
			star["pos"] = Vector2.ZERO
			stars.append(star)
			
		var combined_star_size = 0
		for star in system_data[i]["stars"]:
			combined_star_size += star["size"]
		var planet_num = max(round(pow(combined_star_size, 0.3) * rand_int(2, 9)), 2)
		s_i["planet_num"] = planet_num
	galaxy_data[id]["discovered"] = true

func generate_planets(id:int):
	randomize()
	var combined_star_size = 0
	for star in system_data[id]["stars"]:
		combined_star_size += star["size"]
	var planet_num = system_data[id]["planet_num"]
	for i in range(1, planet_num + 1):
		#p_i = planet_info
		var p_i = {}
		p_i["status"] = "unconquered"
		p_i["ring"] = i
		p_i["type"] = rand_int(3, 10)
		p_i["size"] = 2000 + rand_range(0, 10000) * (i + 1)
		p_i["angle"] = rand_range(0, 2 * PI)
		p_i["distance"] = (combined_star_size + pow(i, 2) / 3.0) * 1.2
		p_i["parent"] = id
		p_i["view"] = {"pos":Vector2.ZERO, "zoom":1.0}
		p_i["tiles"] = []
		p_i["discovered"] = false
		var p_id = planet_data.size()
		p_i["id"] = p_id
		p_i["name"] = "Planet " + String(p_id)
		system_data[id]["planets"].append(p_id)
		planet_data.append(p_i)
	system_data[id]["discovered"] = true

func generate_tiles(id:int):
	#wid is number of tiles horizontally/vertically
	#So total number of tiles is wid squared
	var wid:int = round(pow(planet_data[id]["size"], 0.6) / 28.0)
	
	for _i in range(0, pow(wid, 2)):
		planet_data[id]["tiles"].append(tile_data.size())
		tile_data.append({	"is_constructing":false,
							"bldg_str":"",
							"construction_date":0,
							"construction_length":0,
							"bldg_info":{}})
	planet_data[id]["discovered"] = true

func show_tooltip(txt:String):
	var txt2 = txt.split("\n")
	tooltip.visible = true
	self.move_child(tooltip, self.get_child_count())
	tooltip.show_text(txt2)

func hide_tooltip():
	tooltip.visible = false

func on_change_view_over (view_str):
	show_tooltip(view_str)

#Returns a random integer between low and high inclusive
func rand_int(low:int, high:int):
	return randi() % (high - low + 1) + low
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

func _process(delta):
	if delta != 0:
		$FPS.text = String(round(1 / delta)) + " FPS"
	if HUD:
		$HUD/ColorRect/MoneyText.text = String(money)
		$HUD/ColorRect/MineralsText.text = String(minerals) + " / " + String(mineral_capacity)
		$HUD/ColorRect/EnergyText.text = String(energy)
	tooltip.rect_position = mouse_pos + Vector2(4, 4)
	if tooltip.rect_position.x + tooltip.max_width > 1280 - 4:
		tooltip.rect_position.x = 1280 - tooltip.max_width - 4
	if tooltip.rect_position.y + tooltip.height > 720 - 4:
		tooltip.rect_position.y = 720 - tooltip.height - 4

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
