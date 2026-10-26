extends Control

func _ready() -> void:
	$OK.pressed.connect(queue_free)

func setup(bldg:int):
	$Building.texture = load("res://Graphics/Buildings/%s.png" % Building.names[bldg])
	$Name.text = tr("%s_NAME" % Building.names[bldg].to_upper())
	$Description.text = tr("%s_DESC" % Building.names[bldg].to_upper())
