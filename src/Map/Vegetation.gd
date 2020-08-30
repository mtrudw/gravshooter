extends TileMap


export var min_damage = 5
var particles = preload("res://src/Map/TreeParticles.tscn")
func _ready():
	pass # Replace with function body.

sync func destroy_tiles(pos):
	for i in 2:
		for j in 2:
			set_cell(pos.x+i,pos.y+i,-1)
			set_cell(pos.x-i,pos.y+i,-1)
			set_cell(pos.x+i,pos.y-i,-1)
			set_cell(pos.x-i,pos.y-i,-1)

func destroy(damage, pos):
	if damage > min_damage:
		rpc_unreliable('destroy_tiles',world_to_map(pos))
		
	
	
