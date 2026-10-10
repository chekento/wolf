class_name WolfVillageStealth
extends RefCounted

# Human patrols use world-space positions. Identical data drives 2D view,
# 3D meshes, collision-aware visibility and headless regression tests.
const VILLAGE := 14
const START := Vector2(125,1600)
const GUARD_RANGE := 445.0
const HALF_ANGLE := 0.59

static func guards(time: float) -> Array[Dictionary]:
	var people: Array[Dictionary]=[]
	for i in range(4):
		var phase := time*(0.40+float(i)*.11)+float(i)*1.35
		var x := 700.0+float(i)*600.0+sin(phase)*110.0
		var y := 1290.0 if i%2==0 else 1900.0
		var direction := Vector2(cos(phase*.45),1.0 if i%2==0 else -1.0).normalized()
		people.append({"p":Vector2(x,y),"facing":direction,"kind":"human","id":i})
	return people

static func sees(guard: Dictionary,wolf: Vector2,quiet: bool,objects: Array,pace: float=0) -> bool:
	var from: Vector2=guard.p
	var direction: Vector2=wolf-from
	var dist := direction.length()
	var visible_range := GUARD_RANGE*(0.58 if quiet and pace<85 else 1.0)
	if dist>visible_range or dist<1:return false
	if direction.normalized().dot(guard.facing.normalized())<cos(HALF_ANGLE):return false
	# House walls and trunks block genuine sight rather than being scenery.
	for object in objects:
		if object.kind not in ["house","tree","rock"]:continue
		var radius: float=90.0 if object.kind=="house" else 25.0*float(object.get("scale",1.0))
		var closest := Geometry2D.get_closest_point_to_segment(object.p,from,wolf)
		if object.p.distance_to(closest)<radius:return false
	return true

static func exposed(wolf: Vector2,quiet: bool,objects: Array,time: float,pace: float=0) -> bool:
	for human in guards(time):
		if sees(human,wolf,quiet,objects,pace):return true
	return false
