extends "Panel.gd"

var tile
onready var storage_txt = $Control/HBox/AmountInStorage
onready var amount_produced_txt = $Control/AmountProduced
var ratio:float
var bldg_type:String
var input_type:String
var output_type:String
var input:String
var output:String
var input_unit:String
var output_unit:String

func _ready():
	set_polygon($Background.rect_size)
	set_process(false)

func _on_HSlider_value_changed(value):
	if input_type in ["mats", "mets"]:
		$Control/HBox/AmountInStorage.text = "%s %s" % [game.clever_round(value), input_unit]
	else:
		$Control/HBox/AmountInStorage.text = "%s %s" % [round(value), input_unit]
	if output_type in ["mats", "mets"]:
		$Control/AmountProduced.text = "%s %s" % [game.clever_round(value * ratio), output_unit]
	else:
		$Control/AmountProduced.text = "%s %s" % [round(value * ratio), output_unit]

func refresh2(_bldg_type:String, _input:String, _output:String, _input_type:String, _output_type:String):
	bldg_type = _bldg_type
	input_type = _input_type
	input = _input
	output_type = _output_type
	output = _output
	match bldg_type:
		"GF":
			ratio = 1 / 100.0
			$Title.text = tr("GLASS_FACTORY")
		"SE":
			ratio = 20.0
			$Title.text = tr("STEAM_ENGINE")
		_:
			ratio = 0.0
	input_unit = ""
	output_unit = ""
	if input_type in ["mats", "mets"]:
		input_unit = "kg"
	if output_type in ["mats", "mets"]:
		output_unit = "kg"
	tile = game.tile_data[game.c_t]
	$Control/HBox/Remaining.visible = tile.has("qty1")
	$Control/HBox/HSlider.visible = not tile.has("qty1")
	var rsrc:float
	if input_type == "":
		rsrc = game[input]
		$Control/HBox/Texture.texture = load("res://Graphics/Icons/%s.png" % [input])
	else:
		rsrc = game[input_type][input]
		if input_type == "mats":
			$Control/HBox/Texture.texture = load("res://Graphics/Materials/%s.png" % [input])
		elif input_type == "mets":
			$Control/HBox/Texture.texture = load("res://Graphics/Metals/%s.png" % [input])
	if output_type == "":
		$Control/Texture.texture = load("res://Graphics/Icons/%s.png" % [output])
	elif output_type == "mats":
		$Control/Texture.texture = load("res://Graphics/Materials/%s.png" % [output])
	elif output_type == "mets":
		$Control/Texture.texture = load("res://Graphics/Metals/%s.png" % [output])
	
	if tile.has("qty1"):
		$Control/Expected.text = "%s: " % [tr("RESOURCES_PRODUCED")]
	else:
		$Control/Expected.text = "%s: " % [tr("EXPECTED_RESOURCES")]
		var has_rsrc:bool = rsrc > 0
		$Control.visible = has_rsrc
		$NoRsrc.visible = not has_rsrc
		if has_rsrc:
			$Control/HBox/HSlider.max_value = rsrc
			$Control/HBox/HSlider.value = rsrc

func _on_Start_pressed():
	if tile.has("qty1"):
		set_process(false)
		$Control/Start.text = tr("START")
		var prod_i = Helper.get_prod_info(tile)
		var rsrc_to_add = {}
		rsrc_to_add[input] = prod_i.qty_left
		if not input_type in ["mats", "mets"]:
			rsrc_to_add[input] = round(prod_i.qty_left)
		rsrc_to_add[output] = prod_i.qty_made
		if not output_type in ["mats", "mets"]:
			rsrc_to_add[output] = round(prod_i.qty_made)
		game.add_resources(rsrc_to_add)
		tile.erase("qty1")
		tile.erase("start_date")
		tile.erase("ratio")
		tile.erase("qty2")
		refresh2(bldg_type, input, output, input_type, output_type)
	else:
		var rsrc = $Control/HBox/HSlider.value
		var rsrc_to_deduct = {}
		rsrc_to_deduct[input] = rsrc
		game.deduct_resources(rsrc_to_deduct)
		tile.qty1 = rsrc
		tile.start_date = OS.get_system_time_msecs()
		tile.ratio = ratio
		tile.qty2 = rsrc * ratio
		set_process(true)
		$Control/Start.text = tr("STOP")
	$Control/HBox/Remaining.visible = tile.has("qty1")
	$Control/HBox/HSlider.visible = not tile.has("qty1")

func _process(delta):
	var prod_i = Helper.get_prod_info(tile)
	if input_type in ["mats", "mets"]:
		storage_txt.text = "%s %s" % [prod_i.qty_left, input_unit]
	else:
		storage_txt.text = "%s %s" % [round(prod_i.qty_left), input_unit]
	if output_type in ["mats", "mets"]:
		amount_produced_txt.text = "%s %s" % [prod_i.qty_made, output_unit]
	else:
		amount_produced_txt.text = "%s %s" % [round(prod_i.qty_made), output_unit]


func _on_close_button_pressed():
	game.toggle_panel(self)
