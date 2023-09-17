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

func refresh(lv:int):
	$Effects.visible = subject == "dimensional_power" or lv > 0 and btn_text != ""
	$RichTextLabel.text = "[center]%s %s %s  %s" % [tr(subject.to_upper()), tr("LV"), lv, "[img]Graphics/Icons/help.png[/img]"]
	$Upgrade.text = "%s (%s %s)" % [tr("UPGRADE"), lv + 1, tr("DR")]

func animate_effect_button():
	$Effects/AnimationPlayer.play("Fade")
