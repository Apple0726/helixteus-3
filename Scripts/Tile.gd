extends Node2D

var tile_ID:int

onready var game = self.get_parent().get_parent()


var is_constructing:bool = false

#The building to be constructed
var constructing:String = ""

var bldg_str:String = ""
var bldg
var bldg_to_construct:Sprite
var construction_date
var construction_length
var constr_progress:float = 0
var bldg_info

func _process(delta):
	if bldg_str != "":
		$BuildingInformation.visible = true
		constr_progress = (OS.get_system_time_msecs() - construction_date) / float(construction_length)
		$TimeLeft/Bar.rect_scale.x = constr_progress
		$TimeLeft/TimeString.text = time_to_str(construction_length - OS.get_system_time_msecs() + construction_date)
		if constr_progress < 1:
			$TimeLeft.visible = true
		else:
			if is_constructing:
				is_constructing = false
				construction_finished()
			$TimeLeft.visible = false
			match bldg_str:
				"ME", "PP":
					#Number of seconds needed per mineral
					var prod = 1 / bldg_info["production"]
					var cap = bldg_info["capacity"]
					var c_d = bldg_info["collect_date"]
					var c_t = OS.get_system_time_msecs()
					if bldg_info["stored"] < cap:
						$BuildingInformation/CurrentBar.rect_scale.x = (c_t - c_d) / (prod * 1000)
						$BuildingInformation/CapacityBar.rect_scale.x = bldg_info["stored"] / float(cap)
						if c_t - c_d > prod * 1000:
							bldg_info["stored"] += 1
							bldg_info["collect_date"] += prod * 1000
					else:
						$BuildingInformation/CurrentBar.rect_scale.x = 0
						$BuildingInformation/CapacityBar.rect_scale.x = 1
		$BuildingInformation/ResourceStocked.text = String(bldg_info["stored"])
	else:
		$BuildingInformation.visible = false

#Code that runs once a building has finished construction (runs only once, perfect for giving EXP etc.)
func construction_finished():
	bldg_info["collect_date"] = OS.get_system_time_msecs()

func _on_Button_button_over():
	#Make sure there's nothing on the tile before putting graphics
	if bldg_str == "":
		var bldg_image
		match constructing:
			"ME":
				bldg_image = preload("res://Buildings/MineralExtractor.png")
			"PP":
				bldg_image = preload("res://Buildings/PowerPlant.png")
		$Building.texture = bldg_image
		$Building.modulate.a = 0.5


func _on_Button_button_out():
	if bldg_str == "":
		$Building.texture = null

func _input(event):
	if Input.is_action_just_released("right_click"):
		_on_Button_button_out()


func _on_Button_button_pressed():
	#Checks whether we're dragging or not. We don't want the click event to happen while the player is dragging
	if not self.get_parent().dragged:
		#Checks if we're actually constructing something when clicking a tile
		if constructing != "":
			if enough_resources():
				bldg_str = constructing
				constructing = ""
				_on_Button_button_out()
				displayBldg()
				$TimeLeft.visible = true
				game.money -= game.constr_cost["money"]
				game.energy -= game.constr_cost["energy"]
				is_constructing = true
				construction_date = OS.get_system_time_msecs()
				construction_length = game.constr_cost["time"] * 1000
			else:
				game.popup("Not enough resources", 1)
		elif bldg_str != "":
			match bldg_str:
				"ME":
					var mineral_space_available = game.mineral_capacity - game.minerals
					var stored = bldg_info["stored"]
					if mineral_space_available >= stored:
						bldg_info["stored"] = 0
						game.minerals += stored
					else:
						game.minerals = game.mineral_capacity
						bldg_info["stored"] -= mineral_space_available
					if stored == bldg_info["capacity"]:
						bldg_info["collect_date"] = OS.get_system_time_msecs()
				"PP":
					var stored = bldg_info["stored"]
					if stored == bldg_info["capacity"]:
						bldg_info["collect_date"] = OS.get_system_time_msecs()
					game.energy += stored
					bldg_info["stored"] = 0
	self.get_parent().dragged = false

func enough_resources():
	var output = false
	if game.money >= game.constr_cost["money"] and game.energy >= game.constr_cost["energy"]:
		output = true
	return output

func displayBldg():
	var bldg_image
	var bldg_icon
	match bldg_str:
		"ME":
			bldg_image = preload("res://Buildings/MineralExtractor.png")
			bldg_icon = preload("res://Icons/Minerals.png")
			bldg_info = {"stored":0, "production":game.bldg_info[bldg_str]["production"], "capacity":game.bldg_info[bldg_str]["capacity"]}
			$BuildingInformation.modulate = Color(0, 0.68, 1, 1)
		"PP":
			bldg_image = preload("res://Buildings/PowerPlant.png")
			bldg_icon = preload("res://Icons/Energy.png")
			bldg_info = {"stored":0, "production":game.bldg_info[bldg_str]["production"], "capacity":game.bldg_info[bldg_str]["capacity"]}
			$BuildingInformation.modulate = Color(0, 0.68, 0, 1)
	$Building.texture = bldg_image
	$Building.modulate.a = 1
	$Icon.texture = bldg_icon

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
