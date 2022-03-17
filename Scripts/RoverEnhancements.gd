extends Panel
onready var game = get_node("/root/Game")

func _ready():
	var REs:Array = $Armor/Control.get_children()
	REs.append_array($Wheels/Control.get_children())
	REs.append_array($CC/Control.get_children())
	REs.append_array($Laser/Control.get_children())
	for RE in REs:
		if RE is Panel:
			RE.get_node("Button").connect("mouse_entered", self, "on_RE_mouse_entered", [RE.name])
			RE.get_node("Button").connect("mouse_exited", self, "on_RE_mouse_exited")
			RE.get_node("Button").connect("pressed", self, "on_RE_clicked", [RE.name])

func on_RE_mouse_entered(RE_name:String):
	game.show_tooltip("RE_" + tr(RE_name.to_upper()))

func on_RE_mouse_exited():
	game.hide_tooltip()

func on_RE_clicked(RE_name:String):
	pass


func _on_TextureButton_close_button_pressed():
	visible = false
