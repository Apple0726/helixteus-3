extends "Panel.gd"

var tile
onready var sand_txt = $Control/HBox/Sand
onready var glass_txt = $Control/Glass
var ratio = 1 / 100.0

func _ready():
	set_polygon($Background.rect_size)
	set_process(false)

func _on_HSlider_value_changed(value):
	$Control/HBox/Sand.text = "%s kg" % [game.clever_round(value)]
	$Control/Glass.text = "%s kg" % [game.clever_round(value * ratio)]

func refresh():
	tile = game.tile_data[game.c_t]
	$Control/HBox/Remaining.visible = tile.has("qty1")
	$Control/HBox/HSlider.visible = not tile.has("qty1")
	if tile.has("qty1"):
		$Control/Expected.text = "%s: " % [tr("RESOURCES_PRODUCED")]
	else:
		$Control/Expected.text = "%s: " % [tr("EXPECTED_RESOURCES")]
		var has_sand:bool = game.mats.sand > 0
		$Control.visible = has_sand
		$NoSand.visible = not has_sand
		if has_sand:
			$Control/HBox/HSlider.max_value = game.mats.sand

func _on_Start_pressed():
	if tile.has("qty1"):
		set_process(false)
		$Control/Start.text = tr("START")
		var prod_i = Helper.get_prod_info(tile)
		game.add_resources({"sand":prod_i.qty_left, "glass":prod_i.qty_made})
		tile.erase("qty1")
		tile.erase("start_date")
		tile.erase("ratio")
		tile.erase("qty2")
	else:
		var sand = $Control/HBox/HSlider.value
		game.deduct_resources({"sand":sand})
		tile.qty1 = sand
		tile.start_date = OS.get_system_time_msecs()
		tile.ratio = ratio
		tile.qty2 = sand * ratio
		set_process(true)
		$Control/Start.text = tr("STOP")
	refresh()

func _process(delta):
	var prod_i = Helper.get_prod_info(tile)
	sand_txt.text = "%s kg" % [prod_i.qty_left]
	glass_txt.text = "%s kg" % [prod_i.qty_made]


func _on_close_button_pressed():
	game.toggle_panel(self)
