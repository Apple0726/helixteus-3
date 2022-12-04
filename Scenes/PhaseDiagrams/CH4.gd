extends "PhaseDiagram.gd"

func _ready():
	place(91, 1, $MeltPoint)
	place(112, 1, $BoilPoint)
	place(91, 0.117, $TriplePoint)
	place(191, 46, $SuperPoint)
