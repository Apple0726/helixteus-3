extends Control

export var science:String
onready var game = get_node("/root/Game")

func _ready():
	var font = theme.default_font
	$PanelContainer.connect("mouse_entered", self, "on_mouse_entered")
	$PanelContainer.connect("mouse_exited", self, "on_mouse_exited")
	$PanelContainer/HBoxContainer/TextureRect.texture = load("res://Graphics/Science/" + science + ".png")
	$PanelContainer/HBoxContainer/VBoxContainer/Label.text = get_science_name(science)
	rect_min_size.x = font.get_string_size(get_science_name(science)).x + 80
	#print(font.get_string_size(get_science_name(science)))
	if game.science_unlocked[science]:
		$PanelContainer/HBoxContainer/VBoxContainer/Label["custom_colors/font_color"] = Color(0, 1, 0, 1)
	$PanelContainer/HBoxContainer/VBoxContainer/Resource/Text.text = String(Data.science_unlocks[science].cost)

func get_science_name(sc:String):
	match sc:
		"SA":
			return tr("SPACE_AGRICULTURE")
		"RC":
			return tr("ROVER_CONSTRUCTION")
		"OL":
			return tr("ORANGE_LASER").format({"laser":tr("LASER")})
		"YL":
			return tr("YELLOW_LASER").format({"laser":tr("LASER")})
		"GL":
			return tr("GREEN_LASER").format({"laser":tr("LASER")})

func on_mouse_entered():
	game.show_tooltip(science)

func on_mouse_exited():
	game.hide_tooltip()
