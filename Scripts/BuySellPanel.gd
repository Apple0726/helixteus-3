extends Panel

onready var game = get_node("/root/Game")
var type:String
var obj:String

func _ready():
	$Resource/Texture.rect_min_size = Vector2(36, 36)
	$Resource2/Texture.rect_min_size = Vector2(36, 36)
	$Resource2/Texture.texture_normal = preload("res://Graphics/Icons/Money.png")

func _on_HSlider_mouse_entered():
	game.view.move_view = false

func _on_HSlider_mouse_exited():
	game.view.move_view = true

func refresh(_type:String, _obj:String):
	type = _type
	obj = _obj
	$HSlider.value = 0
	rounded_value = 0
	money_value = 0
	$Resource/Texture.texture_normal = load("res://Graphics/" + type + "/" + obj + ".png")
	if type == "Materials":
		$HSlider.max_value = game.mats[obj]
	elif type == "Metals":
		$HSlider.max_value = game.mets[obj]
	$Resource/Text.text = "0 kg"
	$Resource2/Text.text = "0"

var rounded_value = 0
var money_value = 0
func _on_HSlider_value_changed(value):
	rounded_value = game.clever_round(value, 3)
	$Resource/Text.text = String(rounded_value) + " kg"
	if type == "Materials":
		money_value = floor(rounded_value * game.mat_info[obj].value)
		$Resource2/Text.text = String(money_value)
	elif type == "Metals":
		money_value = floor(rounded_value * game.met_info[obj].value)
		$Resource2/Text.text = String(money_value)
	

func _on_Button_pressed():
	if type == "Materials":
		game.mats[obj] -= rounded_value
	elif type == "Metals":
		game.mets[obj] -= rounded_value
	game.money += money_value
	game.inventory.refresh_values()
	game.popup(tr("SUCCESSFULLY_SOLD"), 1.5)
	visible = false
