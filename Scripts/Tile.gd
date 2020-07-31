extends Node2D

onready var game = self.get_parent().get_parent()

var tile_ID:int
var constructing:String = ""
var bldg
var bldg_to_construct

func _on_Button_button_over():
	if not bldg_to_construct:
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
			bldg = constructing
			constructing = ""
			_on_Button_button_out()
			displayBldg()
			$TimeLeft.visible = true
			game.money -= game.constr_cost["money"]
			game.energy -= game.constr_cost["energy"]
		else:
			game.popup("Not enough resources", 1)
	self.get_parent().dragged = false

func enough_resources():
	var output = false
	if game.money >= game.constr_cost["money"] and game.energy >= game.constr_cost["energy"]:
		output = true
	return output

func displayBldg():
	match bldg:
		"ME":
			var ME_scene = preload("res://Scenes/MineralExtractor.tscn")
			bldg = ME_scene.instance()
			self.add_child_below_node($Button, bldg)
