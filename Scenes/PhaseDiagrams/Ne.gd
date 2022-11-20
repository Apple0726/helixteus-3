extends "PhaseDiagram.gd"

func _ready():
	place(24.56, 1, $MeltPoint)#T in K, P in bars
	place(27.1, 1, $BoilPoint)
	place(24.556, 0.4337, $TriplePoint)
	place(44.4918, 27.686, $SuperPoint)

var colors = {	"S":Color(0.5, 0.95, 0.95, 0.8),
				"L":Color(0.5, 0.88, 0.88, 1.0),
				"SC":Color(0.5, 0.75, 0.75, 0.4)}
