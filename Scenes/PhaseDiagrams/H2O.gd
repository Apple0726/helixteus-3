extends "PhaseDiagram.gd"

func _ready():
	place(273, 1, $MeltPoint)
	place(373, 1, $BoilPoint)
	place(273, 0.00612, $TriplePoint)
	place(647, 221, $SuperPoint)

var colors = {	"S":Color(0.48, 0.76, 1.0, 0.6),
				"L":Color(0.34, 0.84, 1.0, 1.0),
				"SC":Color(0.68, 0.86, 1.0, 0.4)}
