class_name WolfCollisionIndex
extends RefCounted

const CELL := 128.0
var buckets: Dictionary = {}

func build(objects: Array) -> void:
	buckets.clear()
	for obj in objects:
		var radius := WolfWorldData.solid_radius(obj)+13.0
		if radius<=13:continue
		var min_cell := Vector2i(floori((obj.p.x-radius)/CELL),floori((obj.p.y-radius)/CELL))
		var max_cell := Vector2i(floori((obj.p.x+radius)/CELL),floori((obj.p.y+radius)/CELL))
		for y in range(min_cell.y,max_cell.y+1):
			for x in range(min_cell.x,max_cell.x+1):
				var key := Vector2i(x,y)
				if not buckets.has(key):buckets[key]=[]
				buckets[key].append({"p":obj.p,"radius_squared":radius*radius})

func walkable(point: Vector2) -> bool:
	var key := Vector2i(floori(point.x/CELL),floori(point.y/CELL))
	for obstacle in buckets.get(key,[]):
		if point.distance_squared_to(obstacle.p)<obstacle.radius_squared:return false
	return true
