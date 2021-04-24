extends Control

signal dialogue_finished;

var NPC_id:int = -1
var dialogue_id:int = -1
var dialogue_part_id:int = -1
var dialogue_lengths:Array = [[5, 3], [3, 1], [15, 1]]

func _ready():
	pass # Replace with function body.

func _input(event):
	if NPC_id == -1:
		return
	var F_released = Input.is_action_just_released("F")
	if (Input.is_action_just_released("left_click") or F_released) and $Text.visible:
		if dialogue_part_id >= dialogue_lengths[NPC_id - 1][dialogue_id - 1] and $Text.visible_characters >= len($Text.text):
			$Text.visible = false
			dialogue_part_id = -1
			emit_signal("dialogue_finished", NPC_id, dialogue_id)
			set_process(false)
		else:
			if $Text.visible_characters < len($Text.text):
				$Text.visible_characters = len($Text.text)
			else:
				dialogue_part_id += 1
				set_dialogue_text()
	elif F_released:
		if NPC_id != -1 and not $Text.visible:
			$Text.visible = true
			dialogue_part_id = 1
			set_dialogue_text()
			set_process(true)

func set_dialogue_text():
	$Text.visible_characters = 0
	$Text.text = tr("NPC_%s_%s_%s" % [NPC_id, dialogue_id, dialogue_part_id])
	
func _process(delta):
	if $Text.visible_characters < len($Text.text):
		$Text.visible_characters += ceil(delta * 30)

