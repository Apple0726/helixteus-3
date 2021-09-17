tool
extends Button

export var button_text:String = ""
export var icon_texture:Texture

func _ready():
	$Label.text = tr(button_text)
	$Icon.texture = icon_texture

func _on_Button_pressed():
	for btn in get_parent().get_children():
		btn.get_node("Label/TextureRect").visible = false
		btn.get_node("Label")["custom_colors/font_color"] = Color.white
	$Label["custom_colors/font_color"] = Color.cyan
	$Label/TextureRect.visible = true
	$AnimationPlayer.play("StarAnim")
