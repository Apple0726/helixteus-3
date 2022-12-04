extends "PhaseDiagram.gd"

func _ready():
	place(14, 1, $MeltPoint)
	place(21, 1, $BoilPoint)
	place(14, 0.07, $TriplePoint)
	place(33, 12.9, $SuperPoint)
