extends Panel

onready var game = get_node("/root/Game")
var type:String
var obj:String
var polygon
var is_selling = true
var obj_node
var money_node

func _ready():
	$Resource/Texture.rect_min_size = Vector2(36, 36)
	$Resource2/Texture.rect_min_size = Vector2(36, 36)
	$Resource2/Texture.texture_normal = preload("res://Graphics/Icons/money.png")

func _on_HSlider_mouse_entered():
	game.view.move_view = false

func _on_HSlider_mouse_exited():
	game.view.move_view = true

func refresh(_type:String = type, _obj:String = obj):
	type = _type
	obj = _obj
	$HSlider.value = 0
	rounded_value = 0
	money_value = 0
	if is_selling:
		obj_node = $Resource
		money_node = $Resource2
		if type == "Materials":
			$HSlider.max_value = game.mats[obj]
		elif type == "Metals":
			$HSlider.max_value = game.mets[obj]
		$HSlider.rounded = false
		$Buy.text = tr("SELL")
	else:
		obj_node = $Resource2
		money_node = $Resource
		$HSlider.max_value = game.money
		$HSlider.rounded = true
		$Buy.text = tr("BUY")
	obj_node.get_node("Texture").texture_normal = load("res://Graphics/" + type + "/" + obj + ".png")
	money_node.get_node("Texture").texture_normal = load("res://Graphics/Icons/money.png")
	obj_node.get_node("Text").text = "0 kg"
	money_node.get_node("Text").text = "0"

var rounded_value = 0
var money_value = 0
func _on_HSlider_value_changed(value):
	if is_selling:
		rounded_value = game.clever_round(value)
		obj_node.get_node("Text").text = "%s kg" % Helper.format_num(rounded_value, 6)
		if type == "Materials":
			money_value = floor(rounded_value * game.mat_info[obj].value)
			money_node.get_node("Text").text = Helper.format_num(money_value, 6)
		elif type == "Metals":
			money_value = floor(rounded_value * game.met_info[obj].value)
			money_node.get_node("Text").text = Helper.format_num(money_value, 6)
	else:
		money_value = value
		money_node.get_node("Text").text = Helper.format_num(value, 6)
		if type == "Materials":
			rounded_value = game.clever_round(0.02 * value / game.mat_info[obj].value)
		elif type == "Metals":
			rounded_value = game.clever_round(0.02 * value / game.met_info[obj].value)
		obj_node.get_node("Text").text = "%s kg" % Helper.format_num(rounded_value, 6)

func _on_Button_pressed():
	if is_selling:
		if type == "Materials":
			game.mats[obj] -= rounded_value
			if game.mats[obj] < 0:
				game.mats[obj] = 0
		elif type == "Metals":
			game.mets[obj] -= rounded_value
			if game.mets[obj] < 0:
				game.mets[obj] = 0
		game.money += money_value
		game.popup(tr("SALE_SUCCESS"), 1.5)
	else:
		game.money -= money_value
		if type == "Materials":
			game.mats[obj] += rounded_value
		elif type == "Metals":
			game.mets[obj] += rounded_value
		game.popup(tr("PURCHASE_SUCCESS"), 1.5)
	game.inventory.refresh()
	game.HUD.refresh()
	_on_close_button_pressed()

func _on_TextureButton_pressed():
	if is_selling:
		if game.money != 0:
			is_selling = false
		else:
			game.popup(tr("CANT_BUY"), 1.2)
			return
	else:
		if type == "Materials" and game.mats[obj] != 0:
			is_selling = true
		elif type == "Metals" and game.mets[obj] != 0:
			is_selling = true
		else:
			game.popup(tr("CANT_SELL"), 1.2)
			return
	refresh()

func _on_close_button_pressed():
	visible = false
