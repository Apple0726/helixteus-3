extends Node2D

var id:int

onready var game = get_node("/root/Game")
onready var p_i = self.get_parent().p_i
onready var tile = game.tile_data[id]

#Mainly for construction_finished() function
#var is_constructing:bool
#
#var bldg_str:String
#var bldg
#var bldg_to_construct:Sprite
#var construction_date
#var construction_length
#var constr_progress:float = 0
#var bldg_info

func _ready():
	var tile_texture = load("res://Graphics/Tiles/" + String(p_i["type"]) + ".jpg")
	$Texture.texture = tile_texture
	if tile.is_constructing:
		$TimeLeft.visible = true
	display_bldg(tile.bldg_str, 1)
	display_icon()

func _process(_delta):
	if tile.bldg_str != "":
		$BuildingInformation.visible = true
		var constr_progress = (OS.get_system_time_msecs() - tile.construction_date) / float(tile.construction_length)
		$TimeLeft/Bar.rect_scale.x = constr_progress
		$TimeLeft/TimeString.text = game.time_to_str(tile.construction_length - OS.get_system_time_msecs() + tile.construction_date)
		if constr_progress < 1:
			$TimeLeft.visible = true
		else:
			if tile.is_constructing:
				tile.is_constructing = false
				construction_finished()
			$TimeLeft.visible = false
			match tile.bldg_str:
				"ME", "PP":
					#Number of seconds needed per mineral
					var prod = 1 / tile.bldg_info["production"]
					var cap = tile.bldg_info["capacity"]
					var stored = tile.bldg_info["stored"]
					var c_d = tile.bldg_info["collect_date"]
					var c_t = OS.get_system_time_msecs()
					if stored < cap:
						$BuildingInformation/CurrentBar.rect_scale.x = (c_t - c_d) / (prod * 1000)
						$BuildingInformation/CapacityBar.rect_scale.x = stored / float(cap)
						if c_t - c_d > prod * 1000:
							tile.bldg_info["stored"] += 1
							tile.bldg_info["collect_date"] += prod * 1000
					else:
						$BuildingInformation/CurrentBar.rect_scale.x = 0
						$BuildingInformation/CapacityBar.rect_scale.x = 1
					$BuildingInformation/ResourceStocked.text = String(stored)
	else:
		$BuildingInformation.visible = false

func construction_finished():
	pass

func _on_Button_button_over():
	#Make sure there's nothing on the tile before putting graphics
	if tile.bldg_str == "":
		display_bldg(self.get_parent().bldg_to_construct, 0.5)

func _on_Button_button_out():
	if tile.bldg_str == "":
		$Building.texture = null

func _input(_event):
	if Input.is_action_just_released("right_click"):
		_on_Button_button_out()


func _on_Button_button_pressed():
	var planet = self.get_parent()
	var view = planet.get_parent()
	
	#Checks whether we're dragging or not. We don't want the click event to happen while the player is dragging
	if not view.dragged:
		#Checks if tile is empty
		if tile.bldg_str == "":
			#If we're trying to construct something
			if planet.bldg_to_construct != "":
				if enough_resources():
					tile.bldg_str = planet.bldg_to_construct
					_on_Button_button_out()
					display_bldg(tile.bldg_str, 1)
					display_icon()
					$TimeLeft.visible = true
					game.money -= game.constr_cost["money"]
					game.energy -= game.constr_cost["energy"]
					tile.is_constructing = true
					tile.construction_date = OS.get_system_time_msecs()
					tile.construction_length = game.constr_cost["time"] * 1000
					add_bldg_info()
				else:
					game.popup("Not enough resources", 1)
			elif game.about_to_mine:
				game.get_node("Control/BottomInfo").visible = false
				game.c_t = id
				game.switch_view("mining")
		else:
			match tile.bldg_str:
				"ME":
					var mineral_space_available = game.mineral_capacity - game.minerals
					var stored = tile.bldg_info["stored"]
					if mineral_space_available >= stored:
						tile.bldg_info["stored"] = 0
						game.minerals += stored
					else:
						game.minerals = game.mineral_capacity
						tile.bldg_info["stored"] -= mineral_space_available
					if stored == tile.bldg_info["capacity"]:
						tile.bldg_info["collect_date"] = OS.get_system_time_msecs()
				"PP":
					var stored = tile.bldg_info["stored"]
					if stored == tile.bldg_info["capacity"]:
						tile.bldg_info["collect_date"] = OS.get_system_time_msecs()
					game.energy += stored
					tile.bldg_info["stored"] = 0
	view.dragged = false

func enough_resources():
	var output = false
	if game.money >= game.constr_cost["money"] and game.energy >= game.constr_cost["energy"]:
		output = true
	return output

func display_bldg(bldg_str:String, a:float):
	if bldg_str != "":
		var bldg_image
		match bldg_str:
			"ME":
				bldg_image = preload("res://Graphics/Buildings/MineralExtractor.png")
			"PP":
				bldg_image = preload("res://Graphics/Buildings/PowerPlant.png")
		$Building.texture = bldg_image
		$Building.modulate.a = a

func display_icon():
	if tile.bldg_str != "":
		var bldg_icon
		match tile.bldg_str:
			"ME":
				bldg_icon = preload("res://Graphics/Icons/Minerals.png")
				$BuildingInformation.modulate = Color(0, 0.68, 1, 1)
			"PP":
				bldg_icon = preload("res://Graphics/Icons/Energy.png")
				$BuildingInformation.modulate = Color(0, 0.68, 0, 1)
		$Icon.texture = bldg_icon

func add_bldg_info():
	if tile.bldg_str != "":
		match tile.bldg_str:
			"ME", "PP":
				tile.bldg_info = {"collect_date":tile.construction_date + tile.construction_length, "stored":0, "production":game.bldg_info[tile.bldg_str]["production"], "capacity":game.bldg_info[tile.bldg_str]["capacity"]}
