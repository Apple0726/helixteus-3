extends "PhaseDiagram.gd"

func _ready():
	place(195, 1, $MeltPoint)
	place(240, 1, $BoilPoint)
	place(195, 0.06, $TriplePoint)
	place(406, 111, $SuperPoint)

var colors = {	"S":Color(0.5, 0.45, 1.0, 0.6),
				"L":Color(0.7, 0.65, 1.0, 1.0),
				"SC":Color(0.5, 0.45, 1.0, 0.4)}
