extends Node2D


var tile_ID
func _ready():
	pass # Replace with function body.



func _on_TextureButton_pressed():
	print("tile pressed", tile_ID)


func _on_TextureButton_mouse_entered():
	$AnimationPlayer.play("TileFadeIn")
	pass # Replace with function body.


func _on_TextureButton_mouse_exited():
	$AnimationPlayer.play_backwards("TileFadeIn")
	pass # Replace with function body.
