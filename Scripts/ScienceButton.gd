extends Control

var main_tree
var is_over:bool = false
onready var game = get_node("/root/Game")

func _ready():
	var font = theme.default_font
	$Panel.connect("mouse_entered", self, "on_mouse_entered")
	$Panel.connect("mouse_exited", self, "on_mouse_exited")
	$Panel/HBox/Texture.texture = load("res://Graphics/Science/" + name + ".png")
	refresh()
	rect_min_size.x = font.get_string_size(get_science_name(name)).x + 80
	if game.science_unlocked[name]:
		$Panel/HBox/VBox/Label["custom_colors/font_color"] = Color(0, 1, 0, 1)

func refresh():
	if modulate == Color.white:
		$Panel/HBox/VBox/Label.text = get_science_name(name)
		$Panel/HBox/VBox/Resource/Text.text = Helper.format_num(Data.science_unlocks[name].cost, 6)
	else:
		$Panel/HBox/VBox/Label.text = "?"
		$Panel/HBox/VBox/Resource/Text.text = "-"

func get_science_name(sc:String):
	match sc:
		"SA":
			return tr("SPACE_AGRICULTURE")
		"RC":
			return tr("ROVER_CONSTRUCTION")
		"SCT":
			return tr("SHIP_CONTROL")
		"SUP":
			return tr("SHIP_UPGRADE")
		"CD":
			return tr("CHEMICAL_DRIVE")
		"ID":
			return tr("ION_DRIVE")
		"FD":
			return tr("FUSION_DRIVE")
		"PD":
			return tr("PHOTON_DRIVE")
		"OL":
			return tr("ORANGE_LASER").format({"laser":tr("LASER")})
		"YL":
			return tr("YELLOW_LASER").format({"laser":tr("LASER")})
		"GL":
			return tr("GREEN_LASER").format({"laser":tr("LASER")})
		"BL":
			return tr("BLUE_LASER").format({"laser":tr("LASER")})
		"PL":
			return tr("PURPLE_LASER").format({"laser":tr("LASER")})
		"UVL":
			return tr("UV_LASER").format({"laser":tr("LASER")})
		"XRL":
			return tr("XRAY_LASER").format({"laser":tr("LASER")})
		"GRL":
			return tr("GAMMARAY_LASER").format({"laser":tr("LASER")})
		"UGRL":
			return tr("ULTRAGAMMARAY_LASER").format({"laser":tr("LASER")})
		"MAE":
			return tr("MACRO_ENGINEERING")
		"DS1":
			return tr("DYSON_SPHERE_X") % [1]
		"DS2":
			return tr("DYSON_SPHERE_X") % [2]
		"DS3":
			return tr("DYSON_SPHERE_X") % [3]
		"DS4":
			return tr("DYSON_SPHERE_X") % [4]
		"SE1":
			return tr("SPACE_ELEVATOR_X") % [1]
		"SE2":
			return tr("SPACE_ELEVATOR_X") % [2]
		"SE3":
			return tr("SPACE_ELEVATOR_X") % [3]

func on_mouse_entered():
	is_over = true
	game.show_tooltip(tr(name.to_upper() + "_DESC"))

func on_mouse_exited():
	is_over = false
	game.hide_tooltip()

func _input(event):
	if Input.is_action_just_released("left_click") and is_over:
		if not game.science_unlocked[name]:
			if game.SP >= Data.science_unlocks[name].cost:
				game.SP -= Data.science_unlocks[name].cost
				game.science_unlocked[name] = true
				game.popup(tr("RESEARCH_SUCCESS"), 1.5)
				game.HUD.refresh()
				$Panel/HBox/VBox/Label["custom_colors/font_color"] = Color(0, 1, 0, 1)
				main_tree.refresh()
			else:
				game.popup(tr("NOT_ENOUGH_SP"), 1.5)
