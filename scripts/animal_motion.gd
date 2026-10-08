class_name WolfAnimalMotion
extends RefCounted

const CELL := 40.0
const GRID := 80
const MARGIN := 20.0
var region := 0
var collision := WolfCollisionIndex.new()
var navigation: AStar2D
var habitat_objects: Array = []
var water_points: Array[Vector2] = []

func configure(index: int,objects: Array) -> void:
	region=index
	collision.build(objects)
	navigation=null
	habitat_objects=objects.filter(func(object: Dictionary):return object.kind in ["bush","flowers","tree","rock"])
	water_points.clear()
	for object in objects:
		if object.kind!="water":continue
		if int(object.variant)==1:
			for y in range(400,2900,250):
				for side in [-1,1]:
					var bank := Vector2(WolfWorldData.river_x(y)+side*130,float(y))
					if walkable(bank):water_points.append(bank)
		else:
			for i in range(12):
				var bank: Vector2=object.p+Vector2.from_angle(i*TAU/12)*(190.0*float(object.scale)+50)
				if walkable(bank):water_points.append(bank)

func walkable(point: Vector2) -> bool:
	return point.x>=MARGIN and point.y>=MARGIN and point.x<=3200-MARGIN and point.y<=3200-MARGIN and collision.walkable(point) and not WolfWorldData.water_blocked(point,region)

func segment_free(from: Vector2,to: Vector2) -> bool:
	if not walkable(from) or not walkable(to):return false
	var delta := to-from
	var length_squared := delta.length_squared()
	if length_squared<0.001:return true
	# Analytic swept tests prevent even a fast animal cutting through a trunk.
	var lo := Vector2i(floori(minf(from.x,to.x)/WolfCollisionIndex.CELL),floori(minf(from.y,to.y)/WolfCollisionIndex.CELL))
	var hi := Vector2i(floori(maxf(from.x,to.x)/WolfCollisionIndex.CELL),floori(maxf(from.y,to.y)/WolfCollisionIndex.CELL))
	for y in range(lo.y,hi.y+1):
		for x in range(lo.x,hi.x+1):
			for obstacle in collision.buckets.get(Vector2i(x,y),[]):
				var t := clampf((obstacle.p-from).dot(delta)/length_squared,0,1)
				if (from+delta*t).distance_squared_to(obstacle.p)<float(obstacle.radius_squared):return false
	# River bends and bridge openings share the game's water rules.
	var samples := maxi(1,ceili(delta.length()/4.0))
	for step in range(1,samples):
		if WolfWorldData.water_blocked(from.lerp(to,float(step)/samples),region):return false
	return true

func nearest_free(point: Vector2,max_radius: float=360) -> Vector2:
	var center := point.clamp(Vector2(MARGIN,MARGIN),Vector2(3200-MARGIN,3200-MARGIN))
	if walkable(center):return center
	for radius in [16,32,48,72,100,140,190,250,320,360]:
		if radius>max_radius:break
		for angle in range(24):
			var candidate := center+Vector2.from_angle(float(angle)*TAU/24)*float(radius)
			if walkable(candidate):return candidate
	return Vector2(INF,INF)

func ecology_targets(animal: Dictionary) -> Dictionary:
	# Anchors are selected once and stay tied to vegetation or a real bank.
	# A free line back to the original home proves the initial connection;
	# later returns from a flight may use the same shared navigation graph.
	var home: Vector2=animal.home
	var forage := home
	var other_forage := home
	var shelter := home
	var best_food := INF
	var best_other := INF
	var best_cover := INF
	var refuges: Array[Vector2]=[home]
	for object in habitat_objects:
		var offset: Vector2=Vector2.from_angle(float(animal.get("phase",0)))*65
		var candidate: Vector2=object.p+offset if object.kind in ["tree","rock"] else object.p
		var distance := home.distance_to(candidate)
		if distance>620 or not walkable(candidate) or not segment_free(home,candidate):continue
		if object.kind=="flowers" or (animal.kind=="fox" and object.kind=="bush"):
			if distance<best_food:
				other_forage=forage;best_other=best_food
				forage=candidate;best_food=distance
			elif distance<best_other:other_forage=candidate;best_other=distance
		if object.kind in ["bush","tree","rock"]:
			if refuges.size()<18:refuges.append(candidate)
			if distance<best_cover and distance>20:shelter=candidate;best_cover=distance
	if best_other==INF:
		for offset in [Vector2(120,45),Vector2(-110,65),Vector2(65,-120)]:
			if segment_free(home,home+offset):other_forage=home+offset;break
	var water := home
	var water_distance := 850.0
	for bank in water_points:
		var distance := home.distance_to(bank)
		if distance<water_distance and segment_free(home,bank):water=bank;water_distance=distance
	return {"forage":forage,"other_forage":other_forage,"shelter":shelter,"water":water,"has_water":water!=home,"refuges":refuges}

func refuge_from(animal: Dictionary,threat: Vector2) -> Vector2:
	var position: Vector2=animal.p
	var ecology: Dictionary=animal.get("_ecology",{})
	var best: Vector2=ecology.get("shelter",animal.home)
	var score := -INF
	for candidate in ecology.get("refuges",[]):
		var separation: float=candidate.distance_to(threat)
		var distance: float=candidate.distance_to(position)
		if separation<position.distance_to(threat)+60 or distance<35:continue
		var value := separation-distance*0.35
		if value>score:best=candidate;score=value
	if score>-INF:return best
	# If the wolf stands between the animal and all known cover, retreat a
	# short safe distance first. This is still a walked route, never a jump.
	var away := threat.direction_to(position)
	if away.length_squared()<0.01:away=Vector2.from_angle(float(animal.get("phase",0)))
	for angle in [0.0,0.45,-0.45,0.9,-0.9]:
		var candidate := nearest_free(position+away.rotated(angle)*300,100)
		if candidate.is_finite() and candidate.distance_to(threat)>position.distance_to(threat)+80:return candidate
	return best

func group_forage_target(animal: Dictionary,animals: Array) -> Vector2:
	var original: Vector2=animal._ecology.forage
	var closest := 450.0
	var leader: Dictionary={}
	for neighbor in animals:
		if neighbor.kind!="deer" or float(neighbor.phase)>=float(animal.phase) or not neighbor.has("_ecology"):continue
		var distance: float=animal.home.distance_to(neighbor.home)
		if distance<closest:closest=distance;leader=neighbor
	if leader.is_empty():return original
	var offset: Vector2=leader.home.direction_to(animal.home)*110
	var target: Vector2=leader._ecology.forage+offset
	return target if segment_free(animal.home,target) else original

func _node_id(cell: Vector2i) -> int:
	return cell.x+cell.y*GRID

func _node_position(cell: Vector2i) -> Vector2:
	return Vector2(cell)*CELL+Vector2.ONE*CELL*0.5

func _build_navigation() -> void:
	navigation=AStar2D.new()
	for y in range(GRID):
		for x in range(GRID):
			var cell := Vector2i(x,y)
			var point := _node_position(cell)
			if walkable(point):navigation.add_point(_node_id(cell),point)
	# Validate the entire connection, not only the two endpoints. Narrow
	# passages around rocks and bridge corners cannot be cut diagonally.
	for y in range(GRID):
		for x in range(GRID):
			var cell := Vector2i(x,y)
			var source := _node_id(cell)
			if not navigation.has_point(source):continue
			for offset in [Vector2i(1,0),Vector2i(0,1),Vector2i(1,1),Vector2i(-1,1)]:
				var neighbor: Vector2i=cell+offset
				if neighbor.x<0 or neighbor.x>=GRID or neighbor.y>=GRID:continue
				var target := _node_id(neighbor)
				if navigation.has_point(target) and segment_free(_node_position(cell),_node_position(neighbor)):navigation.connect_points(source,target)

func _connection(point: Vector2) -> int:
	var center := Vector2i(point/CELL)
	var nearest := -1
	var best := INF
	for y in range(maxi(0,center.y-2),mini(GRID,center.y+3)):
		for x in range(maxi(0,center.x-2),mini(GRID,center.x+3)):
			var id := _node_id(Vector2i(x,y))
			if not navigation.has_point(id):continue
			var node: Vector2=navigation.get_point_position(id)
			var distance := point.distance_squared_to(node)
			if distance<best and segment_free(point,node):best=distance;nearest=id
	return nearest

func route(from: Vector2,to: Vector2) -> PackedVector2Array:
	if segment_free(from,to):return PackedVector2Array([to])
	if navigation==null:_build_navigation()
	var start := _connection(from)
	var end := _connection(to)
	if start<0 or end<0:return PackedVector2Array()
	var path: PackedVector2Array=navigation.get_point_path(start,end)
	if not path.is_empty():path.append(to)
	return path

func advance(animal: Dictionary,target: Vector2,speed: float,dt: float,now: float,use_navigation: bool=true) -> Vector2:
	var position: Vector2=animal.p
	if speed<=0 or dt<=0 or not walkable(position):return position
	var goal := nearest_free(target)
	if not goal.is_finite():return position
	var path: PackedVector2Array=animal.get("_motion_path",PackedVector2Array())
	var old_goal: Vector2=animal.get("_motion_goal",Vector2(INF,INF))
	var planned_at: float=animal.get("_motion_time",-100.0)
	if not old_goal.is_finite() or old_goal.distance_to(goal)>60 or now<planned_at or (path.is_empty() and now-planned_at>1):
		path=route(position,goal) if use_navigation or navigation!=null else PackedVector2Array([goal]) if segment_free(position,goal) else PackedVector2Array()
		animal._motion_goal=goal
		animal._motion_time=now
	# Remove only waypoints we really reached; there is no position catch-up.
	while not path.is_empty() and position.distance_to(path[0])<4:path.remove_at(0)
	if path.is_empty():
		animal._motion_path=path
		if not use_navigation and navigation==null:
			# Small wildlife steps use cheap local steering. A regional graph
			# is built only for a purposeful blocked wolf/long return route.
			var side := 1.0 if int(float(animal.get("phase",0))*10)%2==0 else -1.0
			for turn in [0.4*side,0.8*side,1.35*side,-0.4*side,-0.8*side,-1.35*side]:
				var candidate := position+position.direction_to(goal).rotated(turn)*minf(speed*minf(dt,0.10),position.distance_to(goal))
				if segment_free(position,candidate):return candidate
		return position
	var step := minf(speed*minf(dt,0.10),position.distance_to(path[0]))
	var next := position.move_toward(path[0],step)
	if not segment_free(position,next):
		animal._motion_path=PackedVector2Array()
		animal._motion_time=-100.0
		return position
	animal._motion_path=path
	return next
