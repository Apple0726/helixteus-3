extends Label

var velocity:Vector2
var missed:bool
var critical:bool
var damage:int

func _ready() -> void:
	modulate.a = 0.0
	if missed:
		text = tr("MISSED")
		velocity = Vector2.UP * 80.0
		label_settings.font_color = Color.YELLOW
	elif critical:
		label_settings.font_size = 72
		label_settings.shadow_color = 12
		text = str(damage) + "!"
	else:
		if damage < 0:
			text = "+" + str(abs(damage))
		else:
			text = str(damage)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)


func _process(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 600.0 * delta)
	position += velocity * delta
	if velocity == Vector2.ZERO:
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.4).set_delay(0.5)
		tween.tween_callback(queue_free)
		set_process(false)
