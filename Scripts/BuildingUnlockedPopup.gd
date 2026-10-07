extends Control

func _ready() -> void:
	$OK.pressed.connect(queue_free)

func setup(bldg:int):
	$Building.texture = load("res://Graphics/Buildings/%s.png" % Building.names[bldg])
	$Description.text = tr("%s_DESC" % Building.names[bldg].to_upper())
