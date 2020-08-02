extends Node2D

onready var planet_scene = preload("res://Scenes/Planet.tscn")
onready var construct_panel_scene = preload("res://Scenes/ConstructPanel.tscn")
onready var HUD_scene = preload("res://Scenes/HUD.tscn")
onready var planet_HUD_scene = preload("res://Scenes/PlanetHUD.tscn")

onready var construct_panel:Control = construct_panel_scene.instance()

var planet
#HUD shows the player resources at the top
var HUD
#planet_HUD shows the buttons and other things that only shows while viewing a planet surface (i.e. construct)
var planet_HUD

#Player resources
var money = 800
var minerals = 15
var mineral_capacity = 50
var energy = 200

#Stores information on the building(s) about to be constructed
var constr_cost = {"money":0, "energy":0, "time":0}

#Stores all building information
var bldg_info = {"ME":{"name":"Mineral extractor", "desc":"Extracts minerals from the planet surface, giving you a constant supply of minerals.", "money":100, "energy":50, "time":20, "production":0.12, "capacity":15},
				 "PP":{"name":"Power plant", "desc":"Generates energy from... something", "money":80, "energy":0, "time":25, "production":0.2, "capacity":40}}

func _ready():
	construct_panel.name = "construct_panel"
	construct_panel.rect_scale = Vector2(0.8, 0.8)
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
	set_constructing(bldg_type)

func set_constructing(bldg_type):
	print(bldg_type)
	for tile in planet.tiles:
		tile.constructing = bldg_type

func _load_game():
	#Loads planet scene
	
	#Music fading
	$AnimationPlayer.play("title song fade")
	$ambient.play()
	$AnimationPlayer.play("ambient fade in")
	
	self.remove_child($Title)
	planet = planet_scene.instance()
	HUD = HUD_scene.instance()
	planet_HUD = planet_HUD_scene.instance()
	self.add_child(planet)
	self.add_child(HUD)
	self.add_child(planet_HUD)
	HUD.name = "HUD"
	planet_HUD.name = "planet_HUD"
	$HUD/ColorRect/MoneyText.text = String(money)
	$HUD/ColorRect/MineralsText.text = String(minerals) + " / " + String(mineral_capacity)
	$HUD/ColorRect/EnergyText.text = String(energy)
	self.add_child(construct_panel)
	construct_panel.visible = false
	self.move_child($FPS, self.get_child_count())

func _input(event):
	#Press F11 to toggle fullscreen
	if Input.is_action_just_released("fullscreen"):
		OS.window_fullscreen = not OS.window_fullscreen
		
	#Right click to cancel building
	if Input.is_action_just_released("right_click"):
		set_constructing("")
		$planet_HUD/MoreInfo.visible = false
		
	#Sell all ores by pressing Shift C
	if Input.is_action_pressed("shift") and Input.is_action_just_released("construct") and minerals > 0:
		money += minerals * 5
		popup("You sold " + String(minerals) + " minerals for $" + String(minerals * 5) + "!", 2)
		minerals = 0
		

func add_construct_panel():
	if not Input.is_action_pressed("shift"):
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

func _process(delta):
	if delta == 0:
		$FPS.text = "0 FPS"
	else:
		$FPS.text = String(round(1 / delta)) + " FPS"
	if HUD:
		$HUD/ColorRect/MoneyText.text = String(money)
		$HUD/ColorRect/MineralsText.text = String(minerals) + " / " + String(mineral_capacity)
		$HUD/ColorRect/EnergyText.text = String(energy)
