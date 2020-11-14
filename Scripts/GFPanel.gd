extends "Panel.gd"

func _ready():
	set_polygon($Background.rect_size)
	$Control/Expected.text = "%s: " % [tr("EXPECTED_RESOURCES")]
	refresh()

func _on_HSlider_value_changed(value):
	$Control/Sand.text = "%s kg" % [game.clever_round(value)]
	$Control/Glass.text = "%s kg" % [game.clever_round(value / 100.0)]

func refresh():
	var has_sand:bool = game.mats.sand > 0
	$Control.visible = has_sand
	$NoSand.visible = not has_sand
	if has_sand:
		$Control/HSlider.max_value = game.mats.sand
