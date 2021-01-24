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
	tile = game.tile_data[game.c_t]
	match bldg_type:
		"GF":
			ratio = 1 / 10.0
			$Title.text = tr("GLASS_FACTORY")
		"SE":
			ratio = 40.0
			$Title.text = tr("STEAM_ENGINE")
		_:
			ratio = 0.0
	ratio *=  tile.bldg.path_3_value
	input_unit = ""
	output_unit = ""
	if input_type in ["mats", "mets"]:
		input_unit = "kg"
	if output_type in ["mats", "mets"]:
		output_unit = "kg"
	$Control/HBox/Remaining.visible = tile.bldg.has("qty1")
	$Control/HBox/HSlider.visible = not tile.bldg.has("qty1")
	var rsrc:float
	if input_type == "":#energy, money, minerals
		rsrc = min(game[input], tile.bldg.path_2_value)
		$Control/HBox/Texture.texture = load("res://Graphics/Icons/%s.png" % [input])
	else:#mat, met, etc.
		rsrc = min(game[input_type][input], tile.bldg.path_2_value)
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
	
	if tile.bldg.has("qty1"):
		set_process(true)
		$Control/Start.text = "%s (G)" % tr("STOP")
		$Control/Expected.text = "%s: " % [tr("RESOURCES_PRODUCED")]
	else:
		set_process(false)
		$Control/Expected.text = "%s: " % [tr("EXPECTED_RESOURCES")]
		var has_rsrc:bool = rsrc > 0
		$Control.visible = has_rsrc
		$NoRsrc.visible = not has_rsrc
		$Control/Start.text = "%s (G)" % tr("START")
		if has_rsrc:
			$Control/HBox/HSlider.max_value = rsrc
			$Control/HBox/HSlider.value = rsrc

func _on_Start_pressed():
	if tile.bldg.has("qty1"):
		set_process(false)
		$Control/Start.text = "%s (G)" % tr("START")
		$Control/Expected.text = "%s: " % [tr("EXPECTED_RESOURCES")]
		var prod_i = Helper.get_prod_info(tile)
		var rsrc_to_add = {}
		rsrc_to_add[input] = prod_i.qty_left
		if not input_type in ["mats", "mets"]:
			rsrc_to_add[input] = round(prod_i.qty_left)
		rsrc_to_add[output] = prod_i.qty_made
		if not output_type in ["mats", "mets"]:
			rsrc_to_add[output] = round(prod_i.qty_made)
		game.add_resources(rsrc_to_add)
		tile.bldg.erase("qty1")
		tile.bldg.erase("start_date")
		tile.bldg.erase("ratio")
		tile.bldg.erase("qty2")
		refresh2(bldg_type, input, output, input_type, output_type)
	else:
		var rsrc = $Control/HBox/HSlider.value
		var rsrc_to_deduct = {}
		rsrc_to_deduct[input] = rsrc
		game.deduct_resources(rsrc_to_deduct)
		tile.bldg.qty1 = rsrc
		tile.bldg.start_date = OS.get_system_time_msecs()
		tile.bldg.ratio = ratio
		tile.bldg.qty2 = rsrc * ratio
		set_process(true)
		$Control/Start.text = "%s (G)" % tr("STOP")
		$Control/Expected.text = "%s: " % [tr("RESOURCES_PRODUCED")]
	$Control/HBox/Remaining.visible = tile.bldg.has("qty1")
	$Control/HBox/HSlider.visible = not tile.bldg.has("qty1")

func _process(delta):
	if not tile or tile.empty():
		_on_close_button_pressed()
		set_process(false)
		return
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
