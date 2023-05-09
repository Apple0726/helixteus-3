extends Control

func update_bar(progress:float, txt:String):
	$Text.text = txt
	$ProgressBar.value = progress
