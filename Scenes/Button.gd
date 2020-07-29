extends Control

signal button_pressed
export var strength = 0.1
export var fade_duration = 0.1

#export var btn_text = ""

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
#func _ready():
#	var font = $Label.get_font("font")
#	#print(font.get_string_size($Label.text))
#	$Label.text = btn_text
#	$Label.rect_size.x = font.get_string_size($Label.text).x + 5
#	$Label.rect_position.x = -$Label.rect_size.x / 2.0
	#$TextureButton.rect_scale = 

func _ready():
	var fade_in = Animation.new()
	var anim_index = fade_in.add_track(Animation.TYPE_VALUE)
	fade_in.track_set_path(anim_index, "ColorRect:color")
	fade_in.track_insert_key(anim_index, 0, Color(1, 1, 1, 0))
	fade_in.track_insert_key(anim_index, fade_duration, Color(1, 1, 1, strength))
	fade_in.length = fade_duration
	$AnimationPlayer.add_animation("FadeIn", fade_in)

func _on_TextureButton_mouse_entered():
	$AnimationPlayer.play("FadeIn")
	pass # Replace with function body.


func _on_TextureButton_mouse_exited():
	$AnimationPlayer.play_backwards("FadeIn")
	pass # Replace with function body.


func _on_TextureButton_pressed():
	emit_signal("button_pressed")
