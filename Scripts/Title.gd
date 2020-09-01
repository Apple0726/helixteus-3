extends Control

signal start_game

func _on_start_press():
	emit_signal("start_game")
