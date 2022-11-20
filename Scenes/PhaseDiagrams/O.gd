extends "PhaseDiagram.gd"

func _ready():
	place(54, 1, $MeltPoint)
	place(90, 1, $BoilPoint)
	place(54, 0.00146, $TriplePoint)
	place(155, 50.4, $SuperPoint)

var colors = {	"S":Color(0.8, 0.8, 1, 0.7),
				"L":Color(0.8, 0.8, 1, 1.0),
				"SC":Color(0.8, 0.8, 1, 0.4)}
