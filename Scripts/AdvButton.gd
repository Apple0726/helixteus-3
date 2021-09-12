tool
extends Button

export var button_text:String = ""

func _ready():
	$Label.text = tr(button_text)

func _on_Button_pressed():
	for btn in get_parent().get_children():
		btn.get_node("Label/TextureRect").visible = false
		btn.get_node("Label")["custom_colors/font_color"] = Color.white
	$Label["custom_colors/font_color"] = Color.cyan
	$Label/TextureRect.visible = true
	$AnimationPlayer.play("StarAnim")
