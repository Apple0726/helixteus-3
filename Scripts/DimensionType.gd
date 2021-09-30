tool
extends Panel

export var texture:Texture
export var btn_text:String = ""
var level:int = 0

func _ready():
	$RichTextLabel.bbcode_text = "[center]%s %s %s  %s" % [tr(name.to_upper()), tr("LV"), level, "[img]Graphics/Icons/help.png[/img]"]
	$TextureRect.texture = texture
	$RichTextLabel.help_text = tr("%s_DESC" % name.to_upper())
	$Effects.visible = level > 0
	if btn_text != "":
		$Effects.text = tr(btn_text)
	refresh()

func refresh():
	$HBox/Progress.visible = level > 0
