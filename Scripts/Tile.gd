extends Node2D

onready var game = self.get_parent().get_parent()

var tile_ID:int
var constructing:String = ""
var bldg_str:String
var bldg
var bldg_to_construct
var construction_date
var construction_length
var constr_progress:float = 0

func _process(delta):
	if bldg_str != "":
		constr_progress = (OS.get_system_time_msecs() - construction_date) / float(construction_length)
		$TimeLeft/Bar.rect_scale.x = constr_progress
		$TimeLeft/TimeString.text = time_to_str(construction_length - OS.get_system_time_msecs() + construction_date)
		if constr_progress < 1:
			$TimeLeft.visible = true
		else:
			$TimeLeft.visible = false
	
func _on_Button_button_over():
	#Make sure there's nothing on the tile before putting graphics
	if not bldg_to_construct and not bldg:
		match constructing:
			"ME":
				var ME_scene = preload("res://Scenes/MineralExtractor.tscn")
				bldg_to_construct = ME_scene.instance()
				self.add_child(bldg_to_construct)
				bldg_to_construct.modulate.a = 0.5


func _on_Button_button_out():
	if bldg_to_construct and bldg_to_construct.get_parent():
		self.remove_child(bldg_to_construct)
		bldg_to_construct = null

func _input(event):
	if Input.is_action_just_released("cancel"):
		_on_Button_button_out()


func _on_Button_button_pressed():
	#Checks if we're actually constructing something when clicking a tile
	if constructing != "" and not self.get_parent().dragged:
		if enough_resources():
			bldg_str = constructing
			constructing = ""
			_on_Button_button_out()
			displayBldg()
			$TimeLeft.visible = true
			game.money -= game.constr_cost["money"]
			game.energy -= game.constr_cost["energy"]
			construction_date = OS.get_system_time_msecs()
			construction_length = game.constr_cost["time"] * 1000
		else:
			game.popup("Not enough resources", 1)
	self.get_parent().dragged = false

func enough_resources():
	var output = false
	if game.money >= game.constr_cost["money"] and game.energy >= game.constr_cost["energy"]:
		output = true
	return output

func displayBldg():
	match bldg_str:
		"ME":
			var ME_scene = preload("res://Scenes/MineralExtractor.tscn")
			bldg = ME_scene.instance()
			self.add_child_below_node($Button, bldg)

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
