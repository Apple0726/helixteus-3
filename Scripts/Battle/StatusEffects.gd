extends VBoxContainer

@onready var game = get_node("/root/Game")
var entity: BattleEntity

func _ready() -> void:
	for effect in get_children():
		effect.hide()
	$Burn/Icon.mouse_entered.connect(game.show_tooltip.bind(tr("BURN_DESC")))
	$Burn/Icon.mouse_exited.connect(game.hide_tooltip)
	$Stun/Icon.mouse_entered.connect(game.show_tooltip.bind(tr("STUN_DESC")))
	$Stun/Icon.mouse_exited.connect(game.hide_tooltip)
	$Frozen/Icon.mouse_entered.connect(game.show_tooltip.bind(tr("FROZEN_DESC")))
	$Frozen/Icon.mouse_exited.connect(game.hide_tooltip)
	$Exposed/Icon.mouse_entered.connect(game.show_tooltip.bind(tr("EXPOSED_DESC")))
	$Exposed/Icon.mouse_exited.connect(game.hide_tooltip)
	$Corroding/Icon.mouse_entered.connect(game.show_tooltip.bind(tr("CORRODING_DESC")))
	$Corroding/Icon.mouse_exited.connect(game.hide_tooltip)
	$Radioactive/Icon.mouse_entered.connect(game.show_tooltip.bind(tr("RADIOACTIVE_DESC")))
	$Radioactive/Icon.mouse_exited.connect(game.hide_tooltip)
	$Wet/Icon.mouse_entered.connect(game.show_tooltip.bind(tr("WET_DESC")))
	$Wet/Icon.mouse_exited.connect(game.hide_tooltip)
	$ExtraTurns/Icon.mouse_entered.connect(game.show_tooltip.bind(tr("EXTRA_TURNS_LEFT")))
	$ExtraTurns/Icon.mouse_exited.connect(game.hide_tooltip)

func update():
	$Burn.visible = entity.status_effects[Battle.StatusEffect.BURN] > 0
	$Stun.visible = entity.status_effects[Battle.StatusEffect.STUN] > 0
	$Frozen.visible = entity.status_effects[Battle.StatusEffect.FROZEN] > 0
	$Exposed.visible = entity.status_effects[Battle.StatusEffect.EXPOSED] > 0
	$Corroding.visible = entity.status_effects[Battle.StatusEffect.CORRODING] > 0
	$Radioactive.visible = entity.status_effects[Battle.StatusEffect.RADIOACTIVE] > 0
	$Wet.visible = entity.status_effects[Battle.StatusEffect.WET] > 0
	$ExtraTurns.visible = entity.status_effects[Battle.StatusEffect.EXTRA_TURNS] > 0
	for effect in entity.status_effects:
		if effect == Battle.StatusEffect.BURN:
			$Burn/Label.text = Helper.format_num(entity.status_effects[effect])
		elif effect == Battle.StatusEffect.STUN:
			$Stun/Label.text = Helper.format_num(entity.status_effects[effect])
		elif effect == Battle.StatusEffect.FROZEN:
			$Frozen/Label.text = Helper.format_num(entity.status_effects[effect])
		elif effect == Battle.StatusEffect.EXPOSED:
			$Exposed/Label.text = Helper.format_num(entity.status_effects[effect])
		elif effect == Battle.StatusEffect.CORRODING:
			$Corroding/Label.text = Helper.format_num(entity.status_effects[effect])
		elif effect == Battle.StatusEffect.RADIOACTIVE:
			$Radioactive/Label.text = Helper.format_num(entity.status_effects[effect])
		elif effect == Battle.StatusEffect.WET:
			$Wet/Label.text = Helper.format_num(entity.status_effects[effect])
		elif effect == Battle.StatusEffect.EXTRA_TURNS:
			$ExtraTurns/Label.text = Helper.format_num(entity.status_effects[effect])
