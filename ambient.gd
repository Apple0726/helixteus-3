extends AudioStreamPlayer

var ambienttracks = ['ambient1','ambient2']

func get_random_number():
	randomize()

func _ready():
	randomize()
	var randomtrack = randi() % ambienttracks.size()
	var audiostream = load('res://Audio/' + ambienttracks[randomtrack] + '.ogg')
	print(randomtrack)
	set_stream(audiostream)
	play()
