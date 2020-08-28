extends Control

var tween:Tween

func _ready():
	tween = Tween.new()
	add_child(tween)

func _on_Speedups_pressed():
	$Contents.visible = true
	set_item_visibility("Speedups")
	$Contents/Info.text = "Speed-up items instantly accelerate construction time by the items's specified amount. Higher-tier items affect multiple buildings."
	set_btn_color($Tabs/Speedups)

func _on_Overclocks_pressed():
	$Contents.visible = true
	set_item_visibility("Overclocks")
	$Contents/Info.text = "Overclock items greatly boost resource production of the affected buildings. Higher levels boost more and last longer, as well as affecting multiple buildings."
	set_btn_color($Tabs/Overclocks)

func _on_Pickaxes_pressed():
	$Contents.visible = true
	set_item_visibility("Pickaxes")
	$Contents/Info.text = "Pickaxes allow you to manually mine a planet for various resources. Higher tier pickaxes mine faster and last longer."
	set_btn_color($Tabs/Pickaxes)

func set_btn_color(btn):
	for other_btn in $Tabs.get_children():
		other_btn["custom_colors/font_color"] = Color(1, 1, 1, 1)
		other_btn["custom_colors/font_color_hover"] = Color(1, 1, 1, 1)
		other_btn["custom_colors/font_color_pressed"] = Color(1, 1, 1, 1)
	btn["custom_colors/font_color"] = Color(0, 1, 1, 1)
	btn["custom_colors/font_color_hover"] = Color(0, 1, 1, 1)
	btn["custom_colors/font_color_pressed"] = Color(0, 1, 1, 1)

func set_item_visibility(type:String):
	for other_type in $Contents/HBoxContainer/Items.get_children():
		other_type.visible = false
	$Contents/HBoxContainer/Items.get_node(type).visible = true
	$Contents/HBoxContainer/ItemInfo/VBoxContainer/Name.text = ""
	$Contents/HBoxContainer/ItemInfo/VBoxContainer/Description.text = ""

var item_money_cost = 0.0

func set_item_info(item_name:String, item_desc:String, money_cost:float):
	$Contents/HBoxContainer/ItemInfo/VBoxContainer/Name.text = get_item_name(item_name)
	$Contents/HBoxContainer/ItemInfo/VBoxContainer/Description.text = item_desc
	item_money_cost = money_cost

func get_item_name(item_name:String):
	match item_name:
		"stick":
			return "Stick"
