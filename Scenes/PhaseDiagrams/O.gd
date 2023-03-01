extends "PhaseDiagram.gd"

func _ready():
	place(54, 1, $MeltPoint)
	place(90, 1, $BoilPoint)
	place(54, 0.00146, $TriplePoint)
	place(155, 50.4, $SuperPoint)

