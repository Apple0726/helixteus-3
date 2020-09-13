extends AudioStreamPlayer

var ambienttracks = ['ambient1','ambient2', 'ambient3']

func _ready():
	randomize()
	var randomtrack = randi() % ambienttracks.size()
	var audiostream = load('res://Audio/' + ambienttracks[randomtrack] + '.ogg')
	set_stream(audiostream)
