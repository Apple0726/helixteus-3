extends HBoxContainer

func _ready():
	var mod_info_file = FileAccess.open("user://Mods/%s/info.json" % name, FileAccess.READ)
	var mod_info = JSON.parse_string(mod_info_file.get_as_text())
	var icon:ImageTexture
	if FileAccess.file_exists("user://Mods/%s/icon.png" % name):
		icon = ImageTexture.create_from_image(Image.load_from_file("user://Mods/%s/icon.png" % name))
	elif FileAccess.file_exists("user://Mods/%s/icon.jpeg" % name):
		icon = ImageTexture.create_from_image(Image.load_from_file("user://Mods/%s/icon.jpeg" % name))
	$Icon.texture = icon
	$Name.text = mod_info.name
	$Version.text = mod_info.version
	$Author.text = mod_info.author
	$Description.text = mod_info.description
	$Load.button_pressed = name in Mods.enabled_mod_list
