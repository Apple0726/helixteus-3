extends Node2D

func update_bar(progress:float, txt:String):
	$Text.text = txt
	$Bar.scale.x = progress
