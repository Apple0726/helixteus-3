extends HBoxContainer

@onready var game = get_node("/root/Game")
var entity: BattleEntity

func _ready() -> void:
	$Attack/Icon.mouse_entered.connect(game.show_tooltip.bind(tr("ATTACK")))
	$Defense/Icon.mouse_entered.connect(game.show_tooltip.bind(tr("DEFENSE")))
	$Accuracy/Icon.mouse_entered.connect(game.show_tooltip.bind(tr("ACCURACY")))
	$Agility/Icon.mouse_entered.connect(game.show_tooltip.bind(tr("AGILITY")))
	$Attack/Icon.mouse_exited.connect(game.hide_tooltip)
	$Defense/Icon.mouse_exited.connect(game.hide_tooltip)
	$Accuracy/Icon.mouse_exited.connect(game.hide_tooltip)
	$Agility/Icon.mouse_exited.connect(game.hide_tooltip)

func update():
	$Attack.visible = entity.attack_buff != 0
	$Attack/Label.text = ("+%s" % Helper.format_num(entity.attack_buff)) if entity.attack_buff > 0 else Helper.format_num(entity.attack_buff)
	$Attack/Label.label_settings.font_color = Color.GREEN if entity.attack_buff > 0 else Color.RED
	$Defense.visible = entity.defense_buff != 0
	$Defense/Label.text = ("+%s" % Helper.format_num(entity.defense_buff)) if entity.defense_buff > 0 else Helper.format_num(entity.defense_buff)
	$Defense/Label.label_settings.font_color = Color.GREEN if entity.defense_buff > 0 else Color.RED
	$Accuracy.visible = entity.accuracy_buff != 0
	$Accuracy/Label.text = ("+%s" % Helper.format_num(entity.accuracy_buff)) if entity.accuracy_buff > 0 else Helper.format_num(entity.accuracy_buff)
	$Accuracy/Label.label_settings.font_color = Color.GREEN if entity.accuracy_buff > 0 else Color.RED
	$Agility.visible = entity.agility_buff != 0
	$Agility/Label.text = ("+%s" % Helper.format_num(entity.agility_buff)) if entity.agility_buff > 0 else Helper.format_num(entity.agility_buff)
	$Agility/Label.label_settings.font_color = Color.GREEN if entity.agility_buff > 0 else Color.RED
