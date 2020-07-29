extends Node2D

onready var planet_scene = preload("res://Scenes/Planet.tscn")
onready var construct_panel_scene = preload("res://Scenes/ConstructPanel.tscn")
onready var HUD_scene = preload("res://Scenes/HUD.tscn")
onready var planet_HUD_scene = preload("res://Scenes/PlanetHUD.tscn")
onready var construct_panel:Control = construct_panel_scene.instance()
var planet
var HUD
var planet_HUD
var money = 800
var minerals = 15
var minerals_capacity = 50
var energy = 200

func _ready():
	construct_panel.name = "construct_panel"
	construct_panel.rect_scale = Vector2(0.8, 0.8)

#Executed once a building has been double clicked in the construction panel
func construct_building(bldg_type):
	var more_info:Label = $planet_HUD/MoreInfo
	var font = planet_HUD.get_font("font")
	font.get_string_size(more_info.text)
	more_info.rect_size.x = font.get_string_size(more_info.text).x + 15
	more_info.rect_position.x = (1280 - more_info.rect_size.x) / 2.0
	more_info.visible = true
	set_constructing(bldg_type)

func set_constructing(bldg_type):
	for tile in planet.tiles:
		tile.constructing = bldg_type

func _load_game():
	#Loads planet scene
	self.remove_child($Title)
	planet = planet_scene.instance()
	HUD = HUD_scene.instance()
	planet_HUD = planet_HUD_scene.instance()
	self.add_child(planet)
	self.add_child(HUD)
	self.add_child(planet_HUD)
	planet_HUD.name = "planet_HUD"
	$HUD/ColorRect/MoneyText.text = String(money)
	$HUD/ColorRect/MineralsText.text = String(minerals) + " / " + String(minerals_capacity)
	$HUD/ColorRect/EnergyText.text = String(energy)
	self.add_child(construct_panel)
	construct_panel.visible = false

func _input(event):
	#Open construction panel when C is pressed
#	if Input.is_action_just_released("construct"):
#		if not get_node("construct_panel").visible:
#			add_construct_panel()
#		else:
#			remove_construct_panel()
	
	#Press F11 to toggle fullscreen
	if Input.is_action_just_released("fullscreen"):
		OS.window_fullscreen = not OS.window_fullscreen
		
	#Press esc to cancel building
	if Input.is_action_just_released("cancel"):
		set_constructing("")
		$planet_HUD/MoreInfo.visible = false

func add_construct_panel():
	construct_panel.visible = true
	#Play panel fade in animation
	get_node("construct_panel/AnimationPlayer").play("FadeIn")

func remove_construct_panel():
	#Play panel fade out animation
	get_node("construct_panel/AnimationPlayer").play_backwards("FadeIn")
	#A timer so that the panel will only be invisible once the fade out is finished
	$Timer.start()

func _on_Timer_timeout():
	construct_panel.visible = false
