@tool
extends RichTextLabel

var game

@export var label_text:String = ""
@export var help_text:String = ""
@export var adv_help:bool = false
@export var translate_help:bool = true
@export var adv_icons:Array
@export var icon_size:int = 15
@export var align:int

func _ready():
	refresh()

func refresh():
	if not Engine.is_editor_hint():
		game = get_node("/root/Game")
	if align == 0:
		text = "%s [img]Graphics/Icons/help.png[/img]" % tr(label_text)
	elif align == 1:
		text = "[center]%s [img]Graphics/Icons/help.png[/img][/center]" % tr(label_text)
	elif align == 2:
		text = "[right]%s [img]Graphics/Icons/help.png[/img][/right]" % tr(label_text)
	
func _on_RichTextLabel_mouse_entered():
	var _help_text = help_text
	if translate_help:
		_help_text = tr(help_text)
	if adv_help:
		game.show_adv_tooltip(_help_text, adv_icons, icon_size)
	else:
		game.show_tooltip(_help_text)


func _on_RichTextLabel_mouse_exited():
	if adv_help:
		game.hide_adv_tooltip()
	else:
		game.hide_tooltip()


func _on_visibility_changed():
	refresh()
