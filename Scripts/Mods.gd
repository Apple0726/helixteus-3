extends Node

func _ready():
	var mods = Directory.new()
	var error = mods.open("user://Mods")
	if error == OK:
		mods.list_dir_begin(true)
		var next = mods.get_next()
		while next != "":
			print(next)
			if ProjectSettings.load_resource_pack("user://Mods/%s" % next, true):
				next = next.rstrip(".zip")
				next = next.rstrip(".pck")
				var main = load("res://%s/Main.gd" % next)
				main = main.new()
				main._ready()
			next = mods.get_next()
		mods.list_dir_end()
	else:
		mods.make_dir("user://Mods")
