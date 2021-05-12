extends Control

signal dialogue_finished;

onready var game = get_node("/root/Game")
var NPC_id:int = -1
var dialogue_id:int = -1
var dialogue_part_id:int = -1
var dialogue_lengths:Array = [[5, 3], [3, 1], [15, 1, 3, 5, 5, 4, 1, 2, 1, 1, 4, 4], [4, 3, 2], [3]]
var choices:Dictionary = {"4_2_3":2}
onready var vbox = $PanelContainer/VBoxContainer

func _ready():
	pass # Replace with function body.

func _input(event):
	if NPC_id == -1 or $PanelContainer.visible:
		return
	var F_released = Input.is_action_just_released("F")
	if (Input.is_action_just_released("left_click") or F_released) and $Text.visible:
		if $Text.visible_characters < len($Text.text):
			$Text.visible_characters = len($Text.text)
		else:
			var identifier:String = "%s_%s_%s" % [NPC_id, dialogue_id, dialogue_part_id]
			if choices.has(identifier):
				$PanelContainer.visible = true
				for btn in vbox.get_children():
					vbox.remove_child(btn)
					btn.queue_free()
				for i in choices[identifier]:
					var btn = Button.new()
					btn.text = tr("NPC_%s_%s" % [identifier, i + 1])
					vbox.add_child(btn)
					btn.connect("pressed", self, "on_btn_pressed", [identifier, i + 1])
			elif dialogue_part_id >= dialogue_lengths[NPC_id - 1][dialogue_id - 1] and $Text.visible_characters >= len($Text.text):
				$Text.visible = false
				dialogue_part_id = -1
				set_process(false)
				emit_signal("dialogue_finished", NPC_id, dialogue_id)
			else:
				dialogue_part_id += 1
				set_dialogue_text()
	elif F_released:
		if NPC_id != -1 and not $Text.visible:
			show_dialogue()

func on_btn_pressed(identifier:String, btn_id:int):
	if identifier == "4_2_3":
		if btn_id == 1:
			NPC_id = 4
			dialogue_id = 3
			show_dialogue()
			if game:
				game.money -= 50000000000000
		elif btn_id == 2:
			$Text.visible = false
			dialogue_part_id = -1
			emit_signal("dialogue_finished", NPC_id, dialogue_id)
			set_process(false)
	$PanelContainer.visible = false

func show_dialogue():
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
