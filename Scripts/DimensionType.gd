tool
extends Panel

export var texture:Texture
export var btn_text:String = ""
var default_font = preload("res://Resources/default_theme.tres").default_font

func _ready():
	$TextureRect.texture = texture
	$RichTextLabel.help_text = tr("%s_DESC" % name.to_upper())
	if btn_text != "":
		var st:String = tr(btn_text)
		$Effects.text = st
		if default_font.get_string_size(st).x > 190:
			$Effects.autowrap = true
			$Effects.rect_min_size.x = 190
			$Effects.rect_min_size.y = default_font.get_wordwrap_string_size(st, 200).y + 10

func refresh(DRs:int, lv:int):
	$Effects.visible = name == "Dimensional_Power" or lv > 0 and btn_text != ""
	$RichTextLabel.bbcode_text = "[center]%s %s %s  %s" % [tr(name.to_upper()), tr("LV"), lv, "[img]Graphics/Icons/help.png[/img]"]
	$HBox/Progress.visible = lv > 0
	$HBox/Progress/DRProgress.text = "%s / %s" % [DRs, lv + 1]
	$HBox/Progress/TextureProgress.max_value = lv + 1
	$HBox/Progress/TextureProgress.value = DRs
