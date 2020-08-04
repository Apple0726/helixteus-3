extends Control
onready var game = self.get_parent()

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_TextureButton_pressed():
	if not get_node("../construct_panel").visible:
		game.add_construct_panel()
	else:
		game.remove_construct_panel()


func _on_StarSystem_pressed():
	game.switch_view("system")
