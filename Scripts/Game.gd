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
var system_data = [{"pos":Vector2.ZERO, "diff":1, "parent":0, "planets":[], "view":{"pos":Vector2(640, 360), "zoom":1.0}, "stars":[{"type":"G", "size":1, "temperature":5500, "pos":Vector2(0, 0)}]}]
var planet_data = []

#Stores information on the building(s) about to be constructed
var constr_cost = {"money":0, "energy":0, "time":0}

#Stores all building information
var bldg_info = {"ME":{"name":"Mineral extractor", "desc":"Extracts minerals from the planet surface, giving you a constant supply of minerals.", "money":100, "energy":50, "time":20, "production":0.12, "capacity":15},
				 "PP":{"name":"Power plant", "desc":"Generates energy from... something", "money":80, "energy":0, "time":25, "production":0.2, "capacity":40}}

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
	
	generate_system(0)
	planet_data[2]["name"] = "Home Planet"
	planet_data[2]["status"] = "conquered"
	planet_data[2]["size"] = rand_range(12000, 13000)
	planet_data[2]["angle"] = PI / 2
	
	
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
	match new_view:
		"planet":
			add_planet()
		"system":
			add_system()
	c_v = new_view

func add_planet():
	view.add_obj("Planet", planet_data[c_p]["view"]["pos"], planet_data[c_p]["view"]["zoom"])
	planet_HUD = planet_HUD_scene.instance()
	self.add_child(planet_HUD)
	planet_HUD.name = "planet_HUD"

func remove_planet():
	view.remove_obj("planet")
	self.remove_child(planet_HUD)
	planet_HUD = null

func add_system():
	view.add_obj("System", system_data[c_s]["view"]["pos"], system_data[c_s]["view"]["zoom"])

func remove_system():
	view.remove_obj("system")

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

func generate_system(id:int):
	randomize()
	var combined_star_size = 0
	for star in system_data[id]["stars"]:
		combined_star_size += star["size"]
	var planet_num = max(round(pow(combined_star_size, 0.3) * rand_int(11, 12)), 2)
	for i in range(1, planet_num):
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
		var p_id = planet_data.size()
		p_i["id"] = p_id
		p_i["name"] = "Planet " + String(p_id)
		system_data[id]["planets"].append(p_id)
		planet_data.append(p_i)

func show_tooltip(txt:String):
	var txt2 = txt.split("\n")
	tooltip.visible = true
	tooltip.show_text(txt2)

func hide_tooltip():
	tooltip.visible = false

#Returns a random integer between low and high inclusive
func rand_int(low:int, high:int):
	return randi() % (high - low + 1) + low
