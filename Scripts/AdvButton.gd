tool
extends Button

var game
export var button_text:String = ""
export var icon_texture:Texture

func _ready():
	game = get_node("/root/Game") if not Engine.editor_hint else null
	$Label.text = tr(button_text)
	$Icon.texture = icon_texture

func _on_Button_pressed():
	for btn in get_parent().get_children():
		btn.get_node("AnimationPlayer").stop()
		btn.get_node("Label/TextureRect").visible = false
		btn.get_node("Label")["custom_colors/font_color"] = Color.white
	$Label["custom_colors/font_color"] = Color.cyan
	$Label/TextureRect.visible = true
	$AnimationPlayer.play("StarAnim", -1, game.u_i.time_speed if game else 1.0)

func _on_AnimationPlayer_animation_finished(anim_name):
	$AnimationPlayer.play("StarAnim", -1, game.u_i.time_speed if game else 1.0)
