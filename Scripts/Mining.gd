extends Control

onready var game = get_node("/root/Game")
onready var p_i = game.planet_data[game.c_p]
onready var pickaxe = game.pickaxe
onready var id:int = game.c_t
onready var tile = game.tile_data[id]
onready var tile_texture = load("res://Graphics/Tiles/" + String(p_i["type"]) + ".jpg")
var mining = false
var progress = 0#Mining tile progress
var hardness = 1
var contents = {}

func _ready():
	#var tile_texture = load("res://Graphics/Tiles/" + String(p_i["type"]) + ".jpg")
	$Control/TextureRect.texture = tile_texture
	generate_rock()

func generate_rock():
	for thing in $Panel/VBoxContainer.get_children():
		$Panel/VBoxContainer.remove_child(thing)
	for mat in p_i.surface.keys():
		if randf() < p_i.surface[mat].chance:
			contents[mat] = game.clever_round(p_i.surface[mat].amount * rand_range(0.8, 1.2), 4)
			var hbox = HBoxContainer.new()
			var texture = TextureRect.new()
			var label = Label.new()
			hbox["custom_constants/separation"] = 15
			texture.texture = load("res://Graphics/Materials/" + mat + ".png")
			texture.expand = true
			texture.rect_min_size = Vector2(36, 36)
			label.text = String(contents[mat]) + " kg"
			$Panel/VBoxContainer.add_child(hbox)
			hbox.add_child(texture)
			hbox.add_child(label)
	$Panel.visible = false
	$Panel.visible = true#A weird workaround to make sure Panel has the right rekt_size

var mouse_pos

func _input(event):
	if event is InputEventMouse:
		mouse_pos = event.position
		$Pickaxe.position = mouse_pos - Vector2(448, 448)

func _on_Back_pressed():
	game.switch_view("planet")

var crumbles = []

func place_crumbles():
	for i in 5:
		var crumble = Sprite.new()
		crumble.texture = tile_texture
		crumble.scale /= 10
		crumble.centered = true
		add_child(crumble)
		crumble.position = mouse_pos
		crumbles.append({"sprite":crumble, "velocity":Vector2(rand_range(-2, 2), rand_range(-10, -4)), "angular_velocity":rand_range(-0.08, 0.08)})

func _process(delta):
	for cr in crumbles:
		cr.sprite.position += cr.velocity
		cr.velocity.y += 0.6
		cr.sprite.rotation += cr.angular_velocity
		if cr.sprite.position.y > 1000:
			remove_child(cr.sprite)
			crumbles.erase(cr)
	if mining:
		$Control/Bar1.value = progress * 8
		$Control/Bar2.value = (progress - 12.5) * 4
		$Control/Bar3.value = (progress - 37.5) * 4
		$Control/Bar4.value = (progress - 62.5) * 4
		$Control/Bar5.value = (progress - 87.5) * 8
		progress += pickaxe.speed / hardness
		if progress >= 100:
			progress = 0
			generate_rock()

func _on_Button_button_down():
	mining = true
	$AnimationPlayer.get_animation("Pickaxe swing").loop = true
	$AnimationPlayer.play("Pickaxe swing")


func _on_Button_button_up():
	mining = false
	$AnimationPlayer.get_animation("Pickaxe swing").loop = false
