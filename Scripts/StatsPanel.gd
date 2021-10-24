extends "Panel.gd"


func _ready():
	set_polygon(rect_size)
	for grid in $Achievements/HBox/Slots.get_children():
		for ach in grid.get_children():
			ach.connect("mouse_entered", self, "on_ach_entered", [grid.name, ach.name])
			ach.connect("mouse_exited", self, "on_ach_exited")

func on_ach_entered(ach_type:String, ach_id:String):
	game.show_tooltip(game.achievements[ach_type.to_lower()][int(ach_id)])

func on_ach_exited():
	game.hide_tooltip()

func _on_Achievements_pressed():
	pass # Replace with function body.


func _on_Statistics_pressed():
	pass # Replace with function body.
