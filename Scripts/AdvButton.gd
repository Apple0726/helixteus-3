@tool
extends Button

var game
@export var button_text:String = "":
	get:
		return button_text
	set(value):
		button_text = value
		$Label.text = tr(button_text)

var adv_button_disabled:bool = false:
	get:
		return adv_button_disabled
	set(value):
		adv_button_disabled = value
		disabled = value
		if value:
			$Label.modulate.a = 0.5
		else:
			$Label.modulate.a = 1.0
			
@export var icon_texture:Texture2D

func _ready():
	game = get_node("/root/Game") if not Engine.is_editor_hint() else null
	$Icon.texture = icon_texture
	get_node("Label")["theme_override_colors/font_color"] = Color.WHITE

func _on_Button_pressed():
	for btn in get_parent().get_children():
		btn.get_node("AnimationPlayer").stop()
		btn.get_node("Label/TextureRect").visible = false
		btn.get_node("Label")["theme_override_colors/font_color"] = Color.WHITE
	$Label["theme_override_colors/font_color"] = Color.CYAN
	$Label/TextureRect.visible = true
	$AnimationPlayer.play("StarAnim", -1, game.u_i.time_speed if game and not game.u_i.is_empty() else 1.0)

func _on_AnimationPlayer_animation_finished(anim_name):
	$AnimationPlayer.play("StarAnim", -1, game.u_i.time_speed if game and not game.u_i.is_empty() else 1.0)
