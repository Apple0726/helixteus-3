extends Panel

@onready var game = get_node("/root/Game")
@export var texture:Texture2D
@export var btn_text:String = ""
@export var subject:String = ""
var default_font = preload("res://Resources/default_theme.tres").default_font

func _ready():
	$TextureRect.texture = texture
	$RichTextLabel.help_text = tr("%s_DESC" % subject.to_upper())
	if btn_text != "":
		var st:String = tr(btn_text)
		$Effects.text = st
#		if default_font.get_string_size(st).x > 190:
#			$Effects.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
#			$Effects.custom_minimum_size.x = 190
			#$Effects.custom_minimum_size.y = default_font.get_wordwrap_string_size(st, 200).y + 10

func refresh(lv:int):
	$Effects.visible = subject == "dimensional_power" or lv > 0 and btn_text != ""
	$RichTextLabel.text = "[center]%s %s %s  %s" % [tr(subject.to_upper()), tr("LV"), lv, "[img]Graphics/Icons/help.png[/img]"]
	$Upgrade.text = "%s (%s %s)" % [tr("UPGRADE"), lv + 1, tr("DR")]
