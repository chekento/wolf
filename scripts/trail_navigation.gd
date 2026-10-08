class_name WolfTrailNavigation
extends RefCounted

# A guide draws paths that use exactly the same swept obstacle and water rules
# as the animals. It never moves the player and shares the regional graph.
var motion: WolfAnimalMotion
var region := -1
var planned_from := Vector2(INF,INF)
var planned_goal := Vector2(INF,INF)
var planned_at := -100.0
var cached := PackedVector2Array()
var builds := 0

func configure(index: int,navigation: WolfAnimalMotion) -> void:
	if region==index and motion==navigation:return
	region=index
	motion=navigation
	planned_from=Vector2(INF,INF)
	planned_goal=Vector2(INF,INF)
	planned_at=-100.0
	cached=PackedVector2Array()

func route(from: Vector2,to: Vector2,now: float,force: bool=false) -> PackedVector2Array:
	if motion==null:return PackedVector2Array()
	var goal := motion.nearest_free(to)
	if not goal.is_finite() or not motion.walkable(from):return PackedVector2Array()
	while cached.size()>1 and from.distance_to(cached[0])<18:cached.remove_at(0)
	var stale := not planned_from.is_finite() or from.distance_to(planned_from)>60 or goal.distance_to(planned_goal)>1 or now<planned_at
	if not cached.is_empty() and not motion.segment_free(from,cached[0]):stale=true
	if cached.is_empty() and now-planned_at>=2:stale=true
	if force or stale:
		cached=motion.route(from,goal)
		planned_from=from;planned_goal=goal;planned_at=now
		builds+=1
	if cached.is_empty():return PackedVector2Array()
	var points := PackedVector2Array([from])
	for point in cached:
		if points[-1].distance_to(point)>0.01:points.append(point)
	return points

static func length(points: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1,points.size()):total+=points[i-1].distance_to(points[i])
	return total

static func bearing(delta: Vector2) -> String:
	if delta.length_squared()<0.01:return "Hier"
	var octant := posmod(roundi(fposmod(delta.angle()+PI/2,TAU)/TAU*8),8)
	return ["N","NO","O","SO","S","SW","W","NW"][octant]

static func next_direction(points: PackedVector2Array) -> Vector2:
	if points.size()<2:return Vector2.ZERO
	for i in range(1,points.size()):
		if points[0].distance_to(points[i])>=24:return points[i]-points[0]
	return points[-1]-points[0]
