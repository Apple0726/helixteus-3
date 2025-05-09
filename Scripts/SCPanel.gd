extends "Panel.gd"

@onready var pie = $Control/PieGraph
@onready var hbox = $Control/HBoxContainer
@onready var vbox = $Control/VBoxContainer
@onready var hslider = $Control/HBoxContainer/HSlider
@onready var CC = $Control/Control
@onready var CC_bar = $Control/Control/TextureProgressBar
@onready var CC_stone = $Control/Control/Stone
@onready var CC_time = $Control/Control/Time
var tile
var stone_to_crush:Dictionary = {}
var expected_rsrc:Dictionary
var rsrc_nodes:Array

func _ready():
	set_polygon($GUI.size, $GUI.position)

func refresh():
	tile = game.tile_data[game.c_t]
	expected_rsrc = {}
	var is_crushing = tile.bldg.has("stone")
	set_process(is_crushing)
	pie.objects = []
	pie.other_str = tr("TRACE_ELEMENTS")
	pie.other_str_short = tr("TRACE")
	var total_stone:float
	var stone_dict:Dictionary
	if is_crushing:
		stone_dict = tile.bldg.stone
		total_stone = Helper.get_sum_of_dict(stone_dict)
		pie.get_node("Title").text = tr("COMP_OF_STONE_BEING_CR")
		$Control/Button.text = "%s (G)" % tr("STOP_CRUSHING")
		$Control/Label.text = tr("RESOURCES_EXTRACTED")
		rsrc_nodes = Helper.put_rsrc(vbox, 44, tile.bldg.expected_rsrc)
	else:
		stone_dict = game.stone
		total_stone = Helper.get_sum_of_dict(stone_dict)
		if total_stone == 0:
			game.stone.clear()
			$Desc.text = tr("NO_STONE")
			$Control.visible = false
			return
		else:
			pie.get_node("Title").text = tr("STONE_COMPOSITION")
			$Control/Button.text = "%s (G)" % tr("START_CRUSHING")
			$Control/Label.text = tr("EXPECTED_RESOURCES")
			Helper.get_SC_output(expected_rsrc, hslider.value, tile.bldg.path_3_value, total_stone)
			for el in game.stone:
				stone_to_crush[el] = game.stone[el] * hslider.value / total_stone
			Helper.put_rsrc(vbox, 44, expected_rsrc)
	for el in stone_dict:
		var dir_str = "res://Graphics/Elements/" + el + ".png"
		var texture
		if ResourceLoader.exists(dir_str):
			texture = load(dir_str)
		else:
			texture = preload("res://Graphics/Elements/Default.png")
		var fraction:float = stone_dict[el] / total_stone
		var pie_text = "%s\n%s%%" % [el, Helper.clever_round(fraction * 100.0, 2)]
		pie.objects.append({"value":fraction, "text":pie_text, "modulate":Helper.get_el_color(el), "texture":texture})
	pie.refresh()
	$Control/HBoxContainer/Label.text = "%s kg" % [Helper.format_num(round(hslider.value))]
	$Desc.text = tr("STONE_CRUSHER_DESC")
	$Control.visible = true
	hbox.visible = not is_crushing
	CC.visible = is_crushing
	hslider.max_value = min(total_stone, tile.bldg.path_2_value)
	hslider.min_value = 0

func _process(delta):
	if not visible:
		set_process(false)
		return
	var c_i = Helper.get_crush_info(tile)
	CC_bar.value = 1 - c_i.progress
	CC_stone.text = "%s kg" % [c_i.qty_left]
	CC_time.text = Helper.time_to_str(c_i.qty_left / c_i.crush_spd)
	for hbox in rsrc_nodes:
		hbox.rsrc.get_node("Text").text = "%s kg" % [Helper.format_num(tile.bldg.expected_rsrc[hbox.name] * (1 - CC_bar.value), true)]

func _on_h_slider_value_changed(value):
	refresh()


func _on_h_slider_mouse_entered():
	game.view.move_view = false


func _on_h_slider_mouse_exited():
	game.view.move_view = true


func _on_button_pressed():
	if not tile.bldg.has("stone"):
		var stone_qty = Helper.get_sum_of_dict(stone_to_crush)
		if stone_qty == 0:
			return
		for el in game.stone:
			game.stone[el] = max(0, game.stone[el] - stone_to_crush[el])
		tile.bldg.stone = stone_to_crush
		tile.bldg.stone_qty = stone_qty
		tile.bldg.start_date = Time.get_unix_time_from_system()
		tile.bldg.expected_rsrc = expected_rsrc
	else:
		var time = Time.get_unix_time_from_system()
		var crush_spd = tile.bldg.path_1_value * game.u_i.time_speed * tile.get("time_speed_bonus", 1.0)
		var qty_left = max(0, round(tile.bldg.stone_qty - (time - tile.bldg.start_date) * crush_spd))
		if qty_left > 0:
			var progress = (time - tile.bldg.start_date) * crush_spd / tile.bldg.stone_qty
			for el in tile.bldg.stone:
				game.stone[el] += qty_left / tile.bldg.stone_qty * tile.bldg.stone[el]
			var rsrc_collected = tile.bldg.expected_rsrc.duplicate(true)
			for rsrc in rsrc_collected:
				rsrc_collected[rsrc] = round(rsrc_collected[rsrc] * progress * 1000) / 1000
			game.add_resources(rsrc_collected)
		else:
			game.add_resources(tile.bldg.expected_rsrc)
		tile.bldg.erase("stone")
		tile.bldg.erase("stone_qty")
		tile.bldg.erase("start_date")
		tile.bldg.erase("expected_rsrc")
		game.popup(tr("RESOURCES_COLLECTED"), 1.5)
	game.HUD.refresh()
	refresh()
