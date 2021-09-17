tool
extends RichTextLabel

onready var game = get_node("/root/Game")

export var label_text:String = ""
export var help_text:String = ""
export var adv_help:bool = false
export(int, "Left", "Center", "Right") var align

func _ready():
	if align == 0:
		bbcode_text = "%s [img]Graphics/Icons/help.png[/img]" % tr(label_text)
	elif align == 1:
		bbcode_text = "[center]%s [img]Graphics/Icons/help.png[/img][/center]" % tr(label_text)
	elif align == 2:
		bbcode_text = "[right]%s [img]Graphics/Icons/help.png[/img][/right]" % tr(label_text)


func _on_RichTextLabel_mouse_entered():
	if adv_help:
		game.show_adv_tooltip(help_text)
	else:
		game.show_tooltip(tr(help_text))


func _on_RichTextLabel_mouse_exited():
	if adv_help:
		game.hide_adv_tooltip()
	else:
		game.hide_tooltip()
