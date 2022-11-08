extends Panel
onready var game = get_node("/root/Game")
onready var REs:Array = $Armor/Control.get_children()
var enhancements:Dictionary
var abilities:Array = ["armor_3", "laser_2", "laser_8"]

var children:Dictionary = {
	"armor_0":["armor_1"],
	"armor_1":["armor_2"],
	"armor_2":["armor_3"],
	"armor_4":["armor_5", "armor_7"],
	"armor_5":["armor_6"],
	"armor_7":["armor_8"],
	"armor_9":["armor_10"],
	"armor_10":["armor_11"],
	"armor_11":["armor_12"],
	"wheels_0":["wheels_1", "wheels_3"],
	"wheels_1":["wheels_2"],
	"wheels_3":["wheels_4"],
	"wheels_4":["wheels_5"],
	"wheels_6":["wheels_7"],
	"CC_0":["CC_1"],
	"CC_1":["CC_2"],
	"laser_0":["laser_1"],
	"laser_1":["laser_2"],
	"laser_3":["laser_4"],
	"laser_4":["laser_5"],
	"laser_6":["laser_7"],
	"laser_7":["laser_8"],
}

func _ready():
	REs.append_array($Wheels/Control.get_children())
	REs.append_array($CC/Control.get_children())
	REs.append_array($Laser/Control.get_children())
	for RE in REs:
		if RE.has_node("Button"):
			RE.get_node("Button").connect("mouse_entered", self, "on_RE_mouse_entered", [RE.name])
			RE.get_node("Button").connect("mouse_exited", self, "on_RE_mouse_exited")
			RE.get_node("Button").connect("pressed", self, "on_RE_clicked", [RE.name, RE.texture])

func on_RE_mouse_entered(RE_name:String):
	game.show_tooltip(Helper.get_RE_info(RE_name))

func on_RE_mouse_exited():
	game.hide_tooltip()

func on_RE_clicked(RE_name:String, texture:Texture):
	game.hide_tooltip()
	if enhancements.has(RE_name):
		remove_recursive(RE_name)
	else:
		if get_parent().REPs - get_parent().REPs_used <= 0:
			return
		var RE_parent:String = ""
		for parent in children.keys():
			if children[parent].has(RE_name):
				RE_parent = parent
				break
		if RE_parent == "" or enhancements.has(RE_parent):
			if RE_name in abilities:
				if get_parent().ability != "":
					game.popup(tr("ONE_ABILITY_ONLY"), 2.5)
					return
				get_parent().ability = RE_name
				get_node("../Stats/Ability/TextureRect").texture = texture
			enhancements[RE_name] = true
			get_parent().REPs_used += 1
	refresh()

func remove_recursive(RE_name):
	enhancements.erase(RE_name)
	get_parent().REPs_used -= 1
	if get_parent().ability == RE_name:
		get_parent().ability = ""
	if children.has(RE_name):
		for child in children[RE_name]:
			if enhancements.has(child):
				remove_recursive(child)

func _on_TextureButton_close_button_pressed():
	visible = false
	game.sub_panel = null


func _on_Control_visibility_changed():
	if visible:
		refresh()

func refresh():
	get_parent().refresh()
	enhancements = get_parent().enhancements
	for RE in REs:
		if RE.has_node("Button"):
			if enhancements.has(RE.name):
				RE.modulate = Color.white
			else:
				RE.modulate = Color(0.6, 0.6, 0.6)
		else:
			var enhancement:String = RE.name.substr(2, 99)
			var color:Color
			if enhancements.has(enhancement):
				color = Color(0.4, 0.88, 1.0)
			else:
				color = Color.black
			if RE is Line2D:
				RE.default_color = color
			elif RE is Node2D:
				for line in RE.get_children():
					line.default_color = color
