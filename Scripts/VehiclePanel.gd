extends Control

onready var game = get_node("/root/Game")
#Tween for fading in/out panel
var tween:Tween
var polygon:PoolVector2Array = [Vector2(106.5, 70), Vector2(106.5 + 1067, 70), Vector2(106.5 + 1067, 70 + 600), Vector2(106.5, 70 + 600)]
var HP_icon = load("res://Graphics/Icons/HP.png")
var atk_icon = load("res://Graphics/Icons/atk.png")
var def_icon = load("res://Graphics/Icons/def.png")
func _ready():
	tween = Tween.new()
	add_child(tween)

func refresh():
	var hbox = $HBox/VBox1/Rovers/HBox
	for rov in hbox.get_children():
		hbox.remove_child(rov)
	for rov in game.rover_data:
		if rov.c_p == game.c_p and rov.ready:
			var rover = TextureButton.new()
			rover.texture_normal = load("res://Graphics/Cave/Rover.png")
			rover.set_anchors_and_margins_preset(Control.PRESET_CENTER)
			hbox.add_child(rover)
			rover.connect("mouse_entered", self, "on_rover_enter", [rov])
			rover.connect("mouse_exited", self, "on_rover_exit")
			rover.connect("pressed", self, "on_rover_press", [rov])
	if hbox.get_child_count() == 0:
		$HBox/VBox1/Rovers.visible = false
	else:
		$HBox/VBox1/Rovers.visible = true

func on_rover_enter(rov:Dictionary):
	game.show_adv_tooltip("@i %s\n@i %s\n@i %s\n%s" % [rov.HP, rov.atk, rov.def, tr("CLICK_TO_USE_ROVER")], [HP_icon, atk_icon, def_icon], 19)

func on_rover_exit():
	game.hide_adv_tooltip()

func on_rover_press(rov:Dictionary):
	if game.c_v == "planet":
		game.view.obj.rover_selected = rov
		game.put_bottom_info(tr("CLICK_A_CAVE_TO_EXPLORE"))
		game.toggle_panel(self)
