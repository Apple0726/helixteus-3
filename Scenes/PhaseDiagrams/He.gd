extends "PhaseDiagram.gd"

func _ready():
	place(1, 1, $MeltPoint)
	place(4.222, 1, $BoilPoint)
	place(2.177, 0.05, $TriplePoint)
	place(5.1953, 2.27, $SuperPoint)

var colors = {	"S":Color(0.87, 0.66, 1.0, 0.7),
				"L":Color(0.78, 0.43, 1.0, 1.0),
				"SC":Color(0.87, 0.66, 1.0, 0.4)}
