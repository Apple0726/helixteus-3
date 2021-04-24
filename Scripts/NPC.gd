extends Area2D

export var NPC_id:int
onready var game = get_node("/root/Game")

func _ready():
	if NPC_id == 3 and game.fourth_ship_hints.op_grill_cave_spawn == -1:
		$Label.text = "???"
	else:
		$Label.text = tr("NPC_%s_NAME" % NPC_id)
	var dir_str = "res://Graphics/NPCs/%s.png" % NPC_id
	if ResourceLoader.exists(dir_str):
		$Sprite.texture = load(dir_str)
	else:
		$Sprite.texture = load("res://icon.png")

func connect_events(dialogue_id:int, dialogue_ref):
	if is_connected("body_entered", self, "_on_NPC_body_entered"):
		disconnect("body_entered", self, "_on_NPC_body_entered")
	connect("body_entered", self, "_on_NPC_body_entered", [dialogue_id, dialogue_ref])
	if not is_connected("body_exited", self, "_on_NPC_body_exited"):
		connect("body_exited", self, "_on_NPC_body_exited", [dialogue_ref])

func _on_NPC_body_entered(_body,  _dialogue_id:int, dialogue_ref):
	dialogue_ref.NPC_id = NPC_id
	dialogue_ref.dialogue_id = _dialogue_id
	dialogue_ref.get_node("HBox").visible = true
	
func _on_NPC_body_exited(_body, dialogue_ref):
	if dialogue_ref.visible:
		dialogue_ref.dialogue_id = -1
		dialogue_ref.dialogue_part_id = -1
		dialogue_ref.get_node("Text").visible = false
	dialogue_ref.NPC_id = -1
	dialogue_ref.get_node("HBox").visible = false
