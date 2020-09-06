extends Node

#When there are dictionaries within dictionaries (within dictionaries) in Game.gd data,
#they go here to make future editing easier

var base_metal_costs = 	{	"ME":{"lead":50, "copper":50, "iron":60},
							"PP":{"lead":50, "copper":75, "iron":40},
						}

var path_1 = {	"ME":{"value":0.12, "desc":"@i %s per second"},
				"PP":{"value":0.3, "desc":"@i %s per second"},
	
}
var path_2 = {	"ME":{"value":15, "desc":"Stores @i %s"},
				"PP":{"value":70, "desc":"Stores @i %s"},
	
}

var costs = {	"ME":{"money":100, "energy":40, "time":8},
				"PP":{"money":80, "time":14},

}
